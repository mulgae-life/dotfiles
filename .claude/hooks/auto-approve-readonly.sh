#!/usr/bin/env bash
# Claude Code PreToolUse 훅: Bash 명령어 자동 승인
# 비가역적/파괴적 명령(rm, git push/commit 등)은 "ask"로 사용자 승인 요청, 나머지는 자동 승인(allow)
# 사용자 명시 요청 시 승인하여 실행, 자율 작업 중 시도는 시스템 프롬프트(rules/work-principles.md)가 회피
# 안전 명령에서는 절대 ask 발동 안 함 → 자율 작업 흐름 중단 없음
# ask 사유는 카테고리별로 분기 — 차단 시점에 정확한 대체 방법을 함께 노출하여
# 사용자 의사결정과 Claude의 다음 행동 교정을 모두 돕는다
set -euo pipefail

INPUT=$(cat)

# JSON 파싱: jq → python3 → python 순서로 시도
parse_command() {
  if command -v jq &>/dev/null; then
    echo "$INPUT" | jq -r '.tool_input.command // empty'
  elif command -v python3 &>/dev/null; then
    echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))"
  elif command -v python &>/dev/null; then
    echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))"
  else
    exit 0
  fi
}

COMMAND=$(parse_command)

[[ -z "$COMMAND" ]] && exit 0

# 위험 명령 사용자 승인 요청 헬퍼 (카테고리별 사유 분기)
# 사용자 명시 요청 시: 대표님이 승인하여 실행
# 자율 작업 중 시도: 대표님이 거부하여 차단 (정상적으론 시스템 프롬프트가 회피하므로 발동 드물어야 함)
# reason은 사용자에게 보이고 거부 시 Claude에게도 전달되어 다음 시도 교정에 사용된다
ask_command() {
  local category="${1:-GENERIC}"
  local reason
  case "$category" in
    FILE_DELETE)
      reason="파일 삭제는 비가역적입니다. 보존이 목적이면 .archive/<YYYY-MM-DD>_<태그>/로 mv를 검토하세요. 사용자가 명시적으로 삭제를 요청한 경우에만 승인하세요."
      ;;
    SYSTEM)
      reason="시스템 레벨 명령(sudo/reboot/dd/mkfs 등)입니다. 환경 전체에 영향을 주므로 사용자 명시 승인이 필수입니다."
      ;;
    GIT_WRITE)
      reason="Git 쓰기(push/commit/reset/rebase/merge 등)입니다. 이력·리모트가 바뀝니다. 사용자 명시 승인 후에만 진행하세요."
      ;;
    GIT_STATE)
      reason="Git 상태 변경(checkout/switch/restore/stash/add)입니다. working tree·staging이 바뀝니다. 현재 작업 컨텍스트를 사용자와 먼저 확인하세요."
      ;;
    GH_CLI)
      reason="GitHub CLI 쓰기 작업입니다. 외부 시스템(PR/이슈/릴리즈)에 영향이 있으므로 사용자 명시 승인 후 진행하세요."
      ;;
    DOCKER_DELETE)
      reason="Docker 리소스 삭제(rm/rmi/down)입니다. 컨테이너·이미지·볼륨 손실 가능. 사용자 확인 후 진행하세요."
      ;;
    INPLACE)
      reason="파일 in-place 수정(sed -i/awk -i inplace)은 차단됩니다. 파일 수정은 Read + Edit 도구를 사용하세요. Bash 우회는 harness가 diff를 추적하지 못합니다."
      ;;
    LINK_FORCE)
      reason="링크 강제 덮어쓰기(ln -sf 등)입니다. 기존 링크/파일이 덮어쓰일 수 있습니다. 사용자 명시 승인 후 진행하세요."
      ;;
    PERMISSION)
      reason="권한/소유자 변경(chmod/chown)입니다. 보안 상태가 바뀝니다. 사용자가 명시 요청한 경우에만 진행하세요."
      ;;
    SHELL_BYPASS)
      reason="셸 우회 패턴(echo|bash, bash <(...), find -delete 등)은 차단됩니다. 우회 자체가 금지되며, 원본 명령을 직접 호출하면 정상적으로 정책이 작동합니다."
      ;;
    SCRIPT_INJECTION)
      reason="인라인 스크립트 내 위험 호출(os.system/shutil.rmtree)입니다. 파괴적 동작은 명시 도구(Edit/Bash rm 등) 경유로 수행하세요."
      ;;
    *)
      reason="위험 명령입니다. 사용자 승인이 필요합니다."
      ;;
  esac

  if command -v jq &>/dev/null; then
    jq -nc --arg r "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $r
      }
    }'
  else
    # jq 없을 때 fallback — 큰따옴표/백슬래시만 escape (한국어 메시지 안전)
    local esc
    esc=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$esc"
  fi
  exit 0
}

# ── /tmp 한정 파일조작 허용 판정 ──────────────────────────
# /tmp는 임시 디렉토리(망쳐도 프로젝트 무관)라, 대상이 모두 /tmp면 파일조작형 위험명령
# (rm/chmod/chown/sed -i/truncate/ln -sf/find -delete 등)을 ask 없이 통과시킨다.
# "위험은 대상이 어디냐에서 온다"는 경로 기반 정책 — 경로 무관 위험(sudo/git/docker/
# echo|bash)은 별도 카테고리라 이 함수를 거치지 않고 항상 ask 유지.
#   케이스1: cmd [opts] /tmp/대상...            (절대경로가 전부 /tmp, 최소 1개)
#   케이스2: cd /tmp[/...] && <cmd 상대경로>     (cwd가 /tmp이므로 상대경로 허용)
# 공통 차단: 줄바꿈/.. 경로탈출/메타문자(; | & $ ` < > ( )) → 복합·체인·치환 우회 봉쇄
# 첫 토큰(cd 체인은 && 뒤 첫 토큰)이 파일조작 명령 화이트리스트일 때만 적용 →
# env/nohup/timeout/sudo/bash -c 같은 래퍼·인터프리터 경유는 화이트리스트 밖이라 차단.
# 판정은 stripped(따옴표 제거) 명령 기반이므로 sed 정규식 내부 메타(`$` 앵커 등)는
# 따옴표와 함께 소거되고, 따옴표로 감싼 경로는 절대경로로 안 잡혀 보수적으로 거부된다.
_is_fileop_first() {
  # 첫 토큰이 "대상 경로형" 파일조작 명령인지 (TMP_EXEMPT_CATEGORIES와 매핑)
  local f
  f=$(echo "$1" | awk '{print $1}')
  case "$f" in
    rm|rmdir|unlink|shred|truncate|chmod|chown|sed|gawk|awk|ln|find) return 0 ;;
    *) return 1 ;;
  esac
}

_tmp_targets_ok() {
  # 인자: $1=명령 문자열, $2=모드(abs_only|tmp_relative)
  # 서브셸 + set -f 로 glob(/tmp/*) 확장을 막아 hook cwd 오염을 방지
  #
  # tmp_relative(케이스2·3·5): cwd=/tmp가 체인으로 보장 → 상대경로도 /tmp 하위.
  #   비-/tmp 절대경로·홈(~)만 거부하고 bare 토큰은 무시.
  # abs_only(케이스1·4): cwd 미상(프로젝트일 수 있음) → bare 상대 토큰이 프로젝트 파일일 수
  #   있다. v2.5까지는 bare를 전부 옵션/인자로 간주해 무시했으나 `rm 상대파일 /tmp/x`가
  #   통과하는 혼합 대상 구멍이 됨(2026-07-10 리뷰). v2.6: 명령별 positional 문법으로
  #   정당한 비경로 bare(mode/owner/size/스크립트/find 표현식)만 소거하고, 남는 bare는
  #   상대경로 대상으로 보고 거부. 소거 판정이 애매한 형태는 거부(과탐=안전측, ask로 폴백).
  ( set -f
    local mode="$2" found_tmp=0 tmp_count=0 tok
    if [[ "$mode" == tmp_relative ]]; then
      for tok in $1; do
        case "$tok" in
          /tmp/?*) : ;;            # /tmp 하위 절대경로
          /*)      exit 1 ;;       # 그 외 절대경로 → 프로젝트/시스템 대상, 거부
          '~'*)    exit 1 ;;       # 홈 확장 거부
        esac
      done
      exit 0
    fi
    # ── abs_only: 명령별 bare 토큰 소거 규칙 ──
    set -- $1
    [[ $# -ge 1 ]] || exit 1
    local name="$1"; shift
    local consumed=0   # chmod/chown/sed/awk: 첫 bare 1개(mode/owner/스크립트) 소거 여부
    local in_expr=0    # find: 첫 '-' 토큰 이후 = 표현식 영역 (경로 positional 종료)
    local expect_val=0 # truncate -s 등 분리형 값 옵션의 다음 토큰 소거
    for tok in "$@"; do
      if [[ $expect_val -eq 1 ]]; then expect_val=0; continue; fi
      case "$tok" in
        /tmp/?*) found_tmp=1; tmp_count=$((tmp_count+1)); continue ;;
        /*|'~'*) exit 1 ;;
      esac
      case "$name" in
        find)
          # find [경로...] [표현식...]: 첫 '-' 전의 bare는 검색 경로 → /tmp 아니면 거부
          if [[ "$tok" == -* ]]; then in_expr=1; continue; fi
          [[ $in_expr -eq 1 ]] && continue   # 표현식 인자(-name foo 등)는 경로 아님
          exit 1 ;;
        truncate)
          if [[ "$tok" == -s || "$tok" == --size ]]; then expect_val=1; continue; fi
          [[ "$tok" == -* ]] && continue
          exit 1 ;;                           # 값 옵션 밖 bare = 파일 대상 → 거부
        chmod|chown|sed|awk|gawk)
          [[ "$tok" == -* ]] && continue
          if [[ $consumed -eq 0 ]]; then consumed=1; continue; fi  # mode/owner/스크립트
          exit 1 ;;                           # 두 번째 bare부터는 파일 대상 → 거부
        *)
          # rm/rmdir/unlink/shred/ln: 모든 positional이 경로 → bare 상대 토큰 즉시 거부
          [[ "$tok" == -* ]] && continue
          exit 1 ;;
      esac
    done
    # ln -sf /tmp/a 단독형은 cwd(프로젝트일 수 있음)에 링크를 생성 → TARGET·LINK 둘 다
    # /tmp 명시(2개 이상)를 요구. 그 외 명령은 /tmp 대상 최소 1개.
    if [[ "$name" == ln ]]; then
      [[ $tmp_count -ge 2 ]]
    else
      [[ $found_tmp -eq 1 ]]
    fi )
}

is_tmp_scoped() {
  local cmd="$1"
  [[ "$cmd" == *$'\n'* ]] && return 1   # 줄바꿈 = 다중 명령 우회 차단
  [[ "$cmd" == *".."* ]]  && return 1   # 경로 탈출 차단
  if [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]] ]]; then
    # 케이스2: cd /tmp[/...] && <cmd> (정확히 하나의 cd…&&)
    # cd 대상에 $·백틱 금지 — 런타임 확장(예: $DIR=..)으로 /tmp 탈출 가능하므로 리터럴 경로만
    # 셸 메타문자(| ; & < > 괄호)도 금지 — 경로 클래스가 `|cat` 등을 흡수하면
    # `cd /tmp/x|cat && sed -i f`가 케이스2로 오인식되는데, 실제 bash는 (cd|cat) && sed로
    # 파싱해 cd가 파이프 서브셸에 격리 → 부모 cwd 불변 → sed가 프로젝트 파일 수정 (v2.5 봉쇄)
    local re='^[[:space:]]*cd[[:space:]]+(/tmp|/tmp/[^[:space:]$`|;&<>(){}]+)[[:space:]]+&&[[:space:]]+([^[:space:]].*)$'
    [[ "$cmd" =~ $re ]] || return 1
    local rest="${BASH_REMATCH[2]}"
    case "$rest" in
      *'&'*|*';'*|*'|'*|*'$'*|*'`'*|*'<'*|*'>'*|*'('*|*')'*) return 1 ;;
    esac
    _is_fileop_first "$rest" || return 1   # && 뒤 첫 토큰이 파일조작 명령이어야
    _tmp_targets_ok "$rest" tmp_relative
  else
    # 케이스1: cmd [opts] /tmp/대상...
    case "$cmd" in
      *'&'*|*';'*|*'|'*|*'$'*|*'`'*|*'<'*|*'>'*|*'('*|*')'*) return 1 ;;
    esac
    _is_fileop_first "$cmd" || return 1    # 첫 토큰이 파일조작 명령이어야 (래퍼 차단)
    _tmp_targets_ok "$cmd" abs_only
  fi
}

# 케이스3+5(&&-직결 cd /tmp 체인 — 위치 무관): `A ; B && cd /tmp/… && <파일조작> && C | D`
# 처럼 복합 명령 어디에 있든, 위반 세그먼트가 "리터럴 cd /tmp에 &&로 직결된 체인" 안에 있으면
# /tmp 한정으로 판정. (v2.5: 선두 한정이던 케이스3을 위치 무관으로 일반화 — 케이스5)
# 안전 근거 — "seg 실행 시점 cwd=/tmp"의 정적 증명 4요소:
#   ① 런(run) 경계는 진짜 독립 문장 경계인 `;`/줄바꿈만 인정 → 런 내부 파싱이 외부와 무관.
#      `|`(선행 파이프는 cd를 서브셸로 격리)·`||`(cd 스킵 경로 존재)·단독`&`·리다이렉트·
#      서브셸 문자는 경계가 아니라 절단 문자 → 체인 무효화(보수적 거부).
#   ② && 직결 단락: anchor cd 실패 시 seg 미실행, 성공 시 cwd가 /tmp 하위로 고정.
#      이 보장은 체인이 명령 어디에 있든 동일 — "선두" 요건은 불필요한 과잉 제약이었음.
#   ③ 런 내 seg 이전 모든 조각을 "단독으로도 auto-allow되는 비-빌트인 화이트리스트"
#      (조회성 READ_CMD·검증된 파일조작·cd)로 제한 → eval/source/export(PATH 변조)/
#      변수대입/함수정의 등 셸 의미 변조(명령 섀도잉) 조각 발견 시 런 전체 무효.
#      (따옴표 스트리핑이 eval 인자를 소거해 hook이 내용을 못 보므로 명령어 단위로 차단)
#   ④ anchor 상태 추적: 리터럴 /tmp cd → 성립, 그 외 cd → 소멸(이후 재성립 가능),
#      조회성/파일조작 조각 → cwd 변경 불가라 유지. seg 도달 시점에 성립 상태여야 allow.
# 런타임에 경계를 소거하는 이스케이프(\; 리터럴 인자, \줄바꿈 라인 연속)와 파이프 끝
# 줄바꿈(| 뒤 개행 = 라인 연속)은 정적 경계 판정을 깨므로 명령 전체에서 발견 시 거부.
# 의도적 미확장(케이스6 없음 — 정적 증명 불가 영역): $ 확장(워드 스플리팅으로 런타임에
# 대상 파일 추가 주입 가능), 서브셸 (cd /tmp && …), 루프/래퍼(xargs·bash -c) 경유.
is_tmp_scoped_chain() {
  local cmd="$1" seg="$2" nl=$'\n'
  [[ "$cmd" == *".."* ]]    && return 1  # 경로 탈출 차단
  [[ "$cmd" == *$'\x01'* ]] && return 1  # 내부 마커 문자 충돌 방지
  # 경계 소거 형태 거부 — 런 분할(;/줄바꿈)의 전제 보호
  [[ "$cmd" == *'\;'* ]]     && return 1  # \; = 리터럴 인자(find -exec 등) → 경계 아님
  [[ "$cmd" == *'\'"$nl"* ]] && return 1  # \줄바꿈 = 라인 연속 → 경계 아님
  local pipe_eol='\|[[:blank:]]*'$'\n'
  [[ "$cmd" =~ $pipe_eol ]]  && return 1  # |/|| 끝 줄바꿈 = 파이프 라인 연속 → 경계 아님
  # 위반 세그먼트 자체: 확장/리다이렉트 금지 + 파일조작 명령 시작 + 비-/tmp 절대경로 없음
  case "$seg" in *'$'*|*'<'*|*'>'*) return 1 ;; esac
  _is_fileop_first "$seg" || return 1
  _tmp_targets_ok "$seg" tmp_relative || return 1
  # 동일 문자열 세그먼트가 2회 이상 등장하면 체인 안/밖 실행분과 위치 구분 불가 → 거부
  # (caller와 동일 분할 기준 — printf에 개행 필수, 미종결 마지막 줄은 read 루프가 버림)
  local n=0 s
  while IFS= read -r s; do
    [[ "$s" == "$seg" ]] && n=$((n+1))
  done < <(printf '%s\n' "$cmd" | tr ';|&`(){}'"$nl" '\n')
  [[ $n -eq 1 ]] || return 1
  # &&를 마커로 보호 → 안전 경계(;/줄바꿈)로 런 분할 → seg가 속한 런에서 anchor 판정
  # 주의: 클래스는 변수 경유 필수 — ${...%%[...}]} 인라인은 클래스 내 }가 확장 종결자로 파싱됨
  local m=$'\x01' run prefix piece first anchored cutcls='[|&<>`(){}]*'
  local cd_re='^[[:space:]]*cd[[:space:]]+/tmp(/[^[:space:]$]+)?[[:space:]]*$'
  local runs="${cmd//&&/$m}"
  runs="${runs//;/$nl}"
  while IFS= read -r run; do
    prefix="${run%%$cutcls}"   # 첫 절단 문자(| & < > ` ( ) { })부터 뒤를 제거
    anchored=0
    while IFS= read -r piece; do
      if [[ "$piece" == "$seg" ]]; then
        [[ $anchored -eq 1 ]] && return 0
        return 1               # seg 도달했으나 anchor 미성립 (유일성 보장 → 즉시 확정)
      fi
      if [[ "$piece" =~ $cd_re ]]; then
        anchored=1             # 리터럴 /tmp cd → cwd 고정 (실패 시 && 단락이라 안전)
      else
        first=$(echo "$piece" | awk '{print $1}')
        if [[ "$first" == cd ]]; then
          anchored=0           # 비-/tmp·비리터럴 cd → cwd 보장 소멸 (이후 재anchor 가능)
        elif [[ -n "$first" && "$first" =~ $READ_CMD_RE ]]; then
          :                    # 조회성 명령 — cwd·셸 의미 변경 불가 ($ 포함해도 인자 효과뿐)
        elif [[ "$piece" != *'$'* ]] && _is_fileop_first "$piece" && _tmp_targets_ok "$piece" tmp_relative; then
          :                    # 검증된 파일조작 — cwd 변경 불가 (대상 검증은 심층 방어)
        else
          break                # 화이트리스트 밖 조각(eval/대입/미지 명령) → 이 런 무효
        fi
      fi
    done < <(printf '%s\n' "$prefix" | tr "$m" '\n')
  done < <(printf '%s\n' "$runs")
  return 1   # seg가 어떤 유효 체인에도 속하지 않음 → 비적용
}

# 케이스4(위치 무관 /tmp 절대경로): 위반 세그먼트 자체가 파일조작 명령으로 시작하고
# 대상 절대경로가 전부 /tmp 하위(최소 1개)면, 멀티라인·`;`·파이프 뒤 등 위치와 무관하게 허용.
# 안전 근거: 절대경로는 cwd가 어디로 이동했든 항상 같은 파일을 가리키므로, 케이스2·3처럼
# "cwd가 /tmp임"을 보장할 필요가 없다. 선행 세그먼트(cd 실패·비-/tmp cd 등)는 판정에 무관.
# 세그먼트 내 $·리다이렉트·`..`는 여전히 거부 — 런타임 확장/탈출로 /tmp 밖을 겨냥할 수 있으므로.
# (bare 상대 토큰은 케이스1과 동일하게 v2.6 명령별 positional 문법으로 검사 — 혼합 대상 거부)
is_tmp_scoped_abs() {
  local seg="$1"
  [[ "$seg" == *".."* ]] && return 1
  case "$seg" in *'$'*|*'<'*|*'>'*) return 1 ;; esac
  _is_fileop_first "$seg" || return 1
  _tmp_targets_ok "$seg" abs_only
}

# ── 인라인 스크립트 명령 → 셸 패턴 대신 스크립트 전용 패턴 체크 ──
# python3 -c "...", python -c "...", ruby -e "...", perl -e "..." 등
# 인라인 코드 내부의 셸 키워드(unlink 등)가 오탐되는 것 방지하되,
# 스크립트 내에서 셸 명령을 실행하는 위험 패턴은 별도로 차단
FIRST_TOKEN=$(echo "$COMMAND" | head -1 | awk '{print $1}')
case "$FIRST_TOKEN" in
  python|python3|ruby|perl|node)
    if echo "$COMMAND" | head -1 | grep -qE '^\s*(python3?|ruby|perl|node)\s+-(c|e)\b'; then
      # 인라인 스크립트 내에서 셸 명령 실행/파괴적 동작 감지
      # 정밀 fine-grained 차단은 지침(work-principles.md '셸 우회' 항목)으로 통제 — hook은 최소 보호만
      SCRIPT_DANGEROUS_PATTERNS=(
        'SCRIPT_INJECTION:\bos\.system\b'      # 셸 명령 문자열 실행 (인젝션 위험)
        'SCRIPT_INJECTION:\bshutil\.rmtree\b'  # 디렉토리 재귀 삭제
      )
      for entry in "${SCRIPT_DANGEROUS_PATTERNS[@]}"; do
        category="${entry%%:*}"
        pattern="${entry#*:}"
        if [[ "$COMMAND" =~ $pattern ]]; then
          ask_command "$category"
        fi
      done
      # 위험 패턴 없음 → 안전한 인라인 스크립트
      cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Auto-approved: safe inline script"
  }
}
EOF
      exit 0
    fi
    ;;
esac

# ── 위험 명령어 패턴 체크 ─────────────────────────────────
# 정책: 위험단어가 '명령어'로 실행될 때만 ask. grep/cat 등 조회성 명령의 인자·검색어로
# 등장하면 무시(allow). 명령을 세그먼트(; | & ( ) { } ` 줄바꿈)로 나눠, 세그먼트의 첫
# 명령어가 조회성(READ_CMD)이면 그 안의 위험단어를 무시한다. 누락 시 과탐(안전측 실패).
#   allow: `ps aux | grep rm`, `grep rm install.sh`, `which shred`, `cat shutdown.md`
#   ask  : `sudo ls`, `xargs rm`, `FOO=1 rm x`, `if x; then rm y`, `foo && rm z`
NL=$'\n'
# SKIP: 명령어와 핵심 옵션(-i, push) 사이 다른 옵션을 건너뛴다 (세그먼트 내부라 구분자 무관)
SKIP='([^[:space:]]+[[:blank:]]+)*'

# 조회성(read-only) 명령: 인자가 실행/수정되지 않아 위험단어가 인자로 와도 안전.
# sed/awk/gawk/find/xargs/env/sudo/sh/bash/eval 등 '인자를 실행'하거나 '-i/-delete로
# 수정·삭제'하는 명령은 제외 → 위험 패턴이 직접 검사한다. (목록 누락 시 과탐=안전)
READ_CMD_RE='^(grep|egrep|fgrep|zgrep|rg|ag|ack|cat|bat|zcat|tac|nl|less|more|most|head|tail|which|type|whatis|man|help|apropos|info|echo|printf|ls|dir|vdir|wc|sort|uniq|cut|paste|tr|column|fold|fmt|jq|yq|history|comm|diff|colordiff|sdiff|strings|od|xxd|hexdump|file|stat|tree|basename|dirname|realpath|readlink|pwd|date|printenv|cal|seq|rev|cksum|md5sum|sha1sum|sha256sum|sha512sum|base64|cmp|tee|cp|mv|touch|mkdir|vim|vi|view|nano|emacs|code)$'

# 파이프 우회류: 세그먼트로 나누면 파이프(|) 컨텍스트가 깨지므로 원본 전체에서 먼저 검사.
BYPASS_PATTERNS=(
  'SHELL_BYPASS:\|[[:blank:]]*(bash|sh)\b'                    # echo ... | bash
  'SHELL_BYPASS:\b(bash|sh)[[:blank:]]+<\('                   # bash <(...)
  'SHELL_BYPASS:\bfind\b[^;|&'"$NL"']*[[:blank:]]-delete\b'   # find ... -delete
)

# 세그먼트별 위험 패턴 (세그먼트 내 위치무관 \b — 첫 토큰이 READ_CMD면 검사 전에 skip).
# 첫 매칭에서 ask하므로 배열 순서가 우선순위 (DOCKER가 FILE_DELETE보다 앞).
DANGEROUS_PATTERNS=(
  # Docker 삭제 (rm 키워드 포함이라 FILE_DELETE보다 앞)
  'DOCKER_DELETE:\bdocker[[:blank:]]+(rm|rmi)\b'
  'DOCKER_DELETE:\bdocker(-|[[:blank:]]+)compose[[:blank:]]+(down|rm)\b'

  # 파일 in-place 수정 (Edit 도구 우회)
  'INPLACE:\bsed[[:blank:]]+'"$SKIP"'-i\b'                      # sed -i / sed -i.bak
  'INPLACE:\bsed[[:blank:]]+'"$SKIP"'--in-place\b'             # sed --in-place
  'INPLACE:\bgawk[[:blank:]]+'"$SKIP"'-i[[:blank:]]+inplace\b'  # gawk -i inplace
  'INPLACE:\bawk[[:blank:]]+'"$SKIP"'-i[[:blank:]]+inplace\b'   # awk -i inplace

  # 링크 강제 덮어쓰기 (cp/mv는 allow)
  'LINK_FORCE:\bln[[:blank:]]+'"$SKIP"'-[a-zA-Z]*f'            # ln -f / ln -sf

  # Git 쓰기 — SKIP으로 글로벌 옵션(-c, -C path) 우회 방지
  'GIT_WRITE:\bgit[[:blank:]]+'"$SKIP"'(push|reset|commit)\b'
  'GIT_WRITE:\bgit[[:blank:]]+'"$SKIP"'(clean|rebase|merge|cherry-pick|revert|am|apply)\b'
  'GIT_WRITE:\bgit[[:blank:]]+'"$SKIP"'branch[[:blank:]]+(-[dD]|--delete)\b'
  'GIT_WRITE:\bgit[[:blank:]]+'"$SKIP"'tag[[:blank:]]+(-[df]|--delete)\b'

  # Git 상태 변경 (working tree/staging/HEAD 이동)
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'checkout\b'
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'switch\b'
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'restore\b'
  # stash: list/show(조회)는 allow, push/pop/apply/drop/clear/branch/create/store·옵션(-u 등)·단독(=push)만 ask
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'stash([[:blank:]]+(push|save|pop|apply|drop|clear|branch|create|store)\b|[[:blank:]]+-|[[:blank:]]*$)'
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'add\b'

  # GitHub CLI 쓰기
  'GH_CLI:\bgh[[:blank:]]+(pr|issue|release|repo)[[:blank:]]+(create|close|delete|merge|edit|comment)\b'
  # api 쓰기 플래그: SKIP으로 위치무관 + 결합형(-XDELETE)·롱폼(--method 등) 동의어 커버
  'GH_CLI:\bgh[[:blank:]]+api[[:blank:]]'"$SKIP"'(-X|-[fF]|--method\b|--field\b|--raw-field\b|--input\b)'
  'GH_CLI:\bgh[[:blank:]]+auth[[:blank:]]+(login|logout)\b'

  # 권한/소유자 변경
  'PERMISSION:\bchmod\b'
  'PERMISSION:\bchown\b'

  # 시스템 (sudo/재부팅/디스크)
  'SYSTEM:\bsudo\b'
  'SYSTEM:\breboot\b'
  'SYSTEM:\bshutdown\b'
  'SYSTEM:\bpoweroff\b'
  'SYSTEM:\bhalt\b'
  # dd는 실제 옵션(if=, of= 등)이 있을 때만 매칭 — 변수명 dd 오탐 방지
  'SYSTEM:\bdd[[:blank:]]+(if|of|bs|count|status|conv|iflag|oflag|ibs|obs|seek|skip)='
  'SYSTEM:\bmkfs\b'
  'SYSTEM:\bfdisk\b'
  'SYSTEM:\bparted\b'

  # 파일 삭제/파괴 (가장 범용적이므로 마지막)
  'FILE_DELETE:\brm\b'
  'FILE_DELETE:\brmdir\b'
  'FILE_DELETE:\bunlink\b'
  'FILE_DELETE:\bshred\b'
  'FILE_DELETE:\btruncate\b'
)

# 비실행 텍스트 제거 — 패턴 매칭 전 정규화 (hook은 bash 파서가 아니라 텍스트 매칭이므로)
#   1) 따옴표 내부 문자열 ("reboot" 오탐 방지)
#   2) # 주석 (주석 속 "rm 금지" 등 오탐 방지)
# 순서 중요: 따옴표 먼저 → 따옴표 안의 #는 함께 소거 → 남은 #만 진짜 주석으로 제거
# bash 주석 규칙 준수: 줄 시작 또는 공백 뒤의 #만 주석 (URL의 #frag, a#b 같은 단어 중간 #는 미제거)
COMMAND_STRIPPED=$(echo "$COMMAND" \
  | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g' \
        -e 's/[[:space:]]#.*$//' -e 's/^[[:space:]]*#.*$//')

# 셸 인터프리터 호출(bash -c "...", sh -c "...", eval "...") 감지 시
# stripping을 건너뛰고 원본에 패턴 매칭 — 따옴표 내부 우회 차단
# (python/ruby/perl/node 인라인은 위쪽 case에서 별도 처리)
if echo "$COMMAND" | head -1 | grep -qE '^\s*(bash|sh)\s+-c\b|^\s*eval\b'; then
  TARGET="$COMMAND"
else
  TARGET="$COMMAND_STRIPPED"
fi

# `&&` 직후 줄바꿈은 bash에서 순수 라인 연속(list 미완성 → 다음 줄로 이어짐)이라
# `a &&\nb` == `a && b`. 새 명령 경계를 만들지 못하므로 공백으로 정규화해도 의미 동일.
# 가독성용 멀티라인 `&&` 체인(cd /tmp/... && sed -i ... &&\npython ...)이
# is_tmp_scoped(케이스1·2)의 멀티라인 차단에 걸리지 않게 하고, is_tmp_scoped_chain
# (케이스3+5 — v2.5부터 멀티라인 자체는 런 경계로 처리)의 체인 조각이 갈라지지 않게 한다.
# `;`/단독 줄바꿈은 독립 명령 경계(cd 실패 후에도 실행됨)라 정규화하지 않는다.
# 주의: ${var/pat/&& } 형태는 bash 5.2 patsub_replacement의 `&`(=매치 텍스트) 확장으로
# 무한 루프가 되므로, `&`를 치환문에 쓰지 않는 prefix/suffix 조립으로 처리한다.
_cont_re=$'&&[[:blank:]]*\n[[:blank:]]*'
while [[ "$TARGET" =~ $_cont_re ]]; do
  TARGET="${TARGET%%"${BASH_REMATCH[0]}"*}&& ${TARGET#*"${BASH_REMATCH[0]}"}"
done

# /tmp 한정으로 자동 허용할 "대상 경로형" 카테고리 (경로 무관 위험은 제외)
# SYSTEM/GIT/GH/DOCKER는 대상 경로와 무관한 위험이라 항상 ask 유지.
TMP_EXEMPT_CATEGORIES=" FILE_DELETE INPLACE PERMISSION LINK_FORCE "

# ── 1단계: 파이프 우회류 (원본 전체) ──────────────────────
# echo|bash·bash<()는 메타문자(|, ())로 is_tmp_scoped 미통과, find -delete /tmp만 실질 허용.
for entry in "${BYPASS_PATTERNS[@]}"; do
  category="${entry%%:*}"
  pattern="${entry#*:}"
  if [[ "$TARGET" =~ $pattern ]]; then
    is_tmp_scoped "$TARGET" && continue
    ask_command "$category"
  fi
done

# ── 2단계: 세그먼트 분할 → 조회성 명령 예외 → 위험 패턴 ────
# 구분자(; | & ( ) { } ` 줄바꿈)를 줄바꿈으로 치환해 명령 세그먼트로 나눈다.
segments=$(printf '%s' "$TARGET" | tr ';|&`(){}'"$NL" '\n')
while IFS= read -r seg; do
  [[ -z "${seg//[[:space:]]/}" ]] && continue
  # env prefix(VAR=val)를 건너뛴 첫 명령어 토큰 추출
  read -ra _toks <<< "$seg"
  first=""
  for t in "${_toks[@]}"; do
    [[ "$t" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && continue
    first="$t"; break
  done
  # 첫 명령어가 조회성(grep/cat/which 등)이면 인자 위험단어를 무시(allow)
  [[ "$first" =~ $READ_CMD_RE ]] && continue
  for entry in "${DANGEROUS_PATTERNS[@]}"; do
    category="${entry%%:*}"
    pattern="${entry#*:}"
    if [[ "$seg" =~ $pattern ]]; then
      # 대상이 전부 /tmp인 파일조작이면 무시 — 명령 전체(케이스1·2),
      # 위치 무관 cd /tmp && 체인 내 세그먼트(케이스3+5), 위치 무관 /tmp 절대경로 세그먼트(케이스4) 판정
      if [[ "$TMP_EXEMPT_CATEGORIES" == *" $category "* ]]; then
        if is_tmp_scoped "$TARGET" || is_tmp_scoped_chain "$TARGET" "$seg" || is_tmp_scoped_abs "$seg"; then
          continue
        fi
      fi
      ask_command "$category"
    fi
  done
done <<< "$segments"

# ── 위험 패턴 없음 → 자동 승인 ──────────────────────────
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Auto-approved: no dangerous pattern detected"
  }
}
EOF
exit 0
