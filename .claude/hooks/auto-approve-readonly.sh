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
  # 절대경로(/...)·홈(~...) 토큰만 검사 — 옵션/mode/size/스크립트 인자는 자동 무시
  # 서브셸 + set -f 로 glob(/tmp/*) 확장을 막아 hook cwd 오염을 방지
  ( set -f
    local found_tmp=0 tok
    for tok in $1; do
      case "$tok" in
        /tmp/?*) found_tmp=1 ;;  # /tmp 하위 절대경로
        /*)      exit 1 ;;       # 그 외 절대경로 → 프로젝트/시스템 대상, 거부
        '~'*)    exit 1 ;;       # 홈 확장 거부
      esac
    done
    if [[ "$2" == abs_only ]]; then
      [[ $found_tmp -eq 1 ]]     # 명시적 /tmp 절대경로 대상 최소 1개 필수
    fi )                         # tmp_relative: 비-/tmp 절대경로만 없으면 통과
}

is_tmp_scoped() {
  local cmd="$1"
  [[ "$cmd" == *$'\n'* ]] && return 1   # 줄바꿈 = 다중 명령 우회 차단
  [[ "$cmd" == *".."* ]]  && return 1   # 경로 탈출 차단
  if [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]] ]]; then
    # 케이스2: cd /tmp[/...] && <cmd> (정확히 하나의 cd…&&)
    # cd 대상에 $·백틱 금지 — 런타임 확장(예: $DIR=..)으로 /tmp 탈출 가능하므로 리터럴 경로만
    local re='^[[:space:]]*cd[[:space:]]+(/tmp|/tmp/[^[:space:]$`]+)[[:space:]]+&&[[:space:]]+([^[:space:]].*)$'
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

# 케이스3(선두 && 체인): `cd /tmp/… && <파일조작> && … ; 기타` 처럼 뒤에 다른 명령이
# 이어지는 복합 명령에서, 위반 세그먼트가 "선두 && 체인 구간" 안에 있으면 /tmp 한정으로 판정.
# 안전 근거: cd가 리터럴 /tmp 경로이고 &&로 직결되므로 cd 실패 시 후속이 실행되지 않고(단락),
# 성공 시 cwd가 /tmp 하위로 고정된다. 구간 내 선행 세그먼트를 전부 "검증된 파일조작 외부명령"
# (cwd 변경 불가)으로 제한하므로 위반 세그먼트 실행 시점의 cwd가 /tmp임이 보장된다.
# 선두 구간 밖(; 이후 등)은 eval/따옴표 트릭/cd 실패 경로로 cwd 보장 불가 → 비적용(ask 유지).
is_tmp_scoped_chain() {
  local cmd="$1" seg="$2"
  [[ "$cmd" == *$'\n'* ]]  && return 1   # 줄바꿈 = 다중 명령 우회 차단
  [[ "$cmd" == *".."* ]]   && return 1   # 경로 탈출 차단
  [[ "$cmd" == *$'\x01'* ]] && return 1  # 내부 마커 문자 충돌 방지
  # 위반 세그먼트 자체: 확장/리다이렉트 금지 + 파일조작 명령 시작 + 비-/tmp 절대경로 없음
  case "$seg" in *'$'*|*'<'*|*'>'*) return 1 ;; esac
  _is_fileop_first "$seg" || return 1
  _tmp_targets_ok "$seg" tmp_relative || return 1
  # 동일 문자열 세그먼트가 2회 이상 등장하면 선두 구간 밖 실행분과 위치 구분 불가 → 거부
  # (printf에 개행 필수 — 미종결 마지막 줄은 read 루프가 버림)
  local n=0 s
  while IFS= read -r s; do
    [[ "$s" == "$seg" ]] && n=$((n+1))
  done < <(printf '%s\n' "$cmd" | tr ';|&`(){}' '\n')
  [[ $n -eq 1 ]] || return 1
  # 선두 && 체인 구간 추출: &&를 마커로 보호한 뒤 첫 구분자(;|단독&/리다이렉트/서브셸)에서 절단
  # 주의: 클래스는 변수 경유 필수 — ${...%%[...}]} 인라인은 클래스 내 }가 확장 종결자로 파싱됨
  local m=$'\x01' prefix cutcls='[;|&<>`(){}]*'
  prefix="${cmd//&&/$m}"
  prefix="${prefix%%$cutcls}"
  # 구간 내 순서 검사: 첫 세그먼트는 리터럴 cd /tmp…($ 확장 금지), 이후 세그먼트는
  # 위반 세그먼트에 도달할 때까지 전부 "검증된 파일조작" 또는 "리터럴 /tmp cd"여야 한다
  # (리터럴 /tmp cd는 성공 시 cwd가 여전히 /tmp 하위, 실패 시 && 단락 → 어느 쪽도 안전)
  local i=0 piece cd_re='^[[:space:]]*cd[[:space:]]+/tmp(/[^[:space:]$]+)?[[:space:]]*$'
  while IFS= read -r piece; do
    if [[ $i -eq 0 ]]; then
      [[ "$piece" =~ $cd_re ]] || return 1
    elif ! [[ "$piece" =~ $cd_re ]]; then
      [[ "$piece" == "$seg" ]] && return 0
      case "$piece" in *'$'*) return 1 ;; esac
      _is_fileop_first "$piece" || return 1
      _tmp_targets_ok "$piece" tmp_relative || return 1
    fi
    i=$((i+1))
  done < <(printf '%s\n' "$prefix" | tr "$m" '\n')
  return 1   # 위반 세그먼트가 선두 구간 밖 → 비적용
}

# 케이스4(위치 무관 /tmp 절대경로): 위반 세그먼트 자체가 파일조작 명령으로 시작하고
# 대상 절대경로가 전부 /tmp 하위(최소 1개)면, 멀티라인·`;`·파이프 뒤 등 위치와 무관하게 허용.
# 안전 근거: 절대경로는 cwd가 어디로 이동했든 항상 같은 파일을 가리키므로, 케이스2·3처럼
# "cwd가 /tmp임"을 보장할 필요가 없다. 선행 세그먼트(cd 실패·비-/tmp cd 등)는 판정에 무관.
# 세그먼트 내 $·리다이렉트·`..`는 여전히 거부 — 런타임 확장/탈출로 /tmp 밖을 겨냥할 수 있으므로.
# (상대경로 인자는 케이스1과 동일하게 옵션/스크립트 인자로 간주되어 미검사 — 기존 정책 유지)
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
  'GIT_STATE:\bgit[[:blank:]]+'"$SKIP"'stash\b'
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
      # 선두 && 체인 내 세그먼트(케이스3), 위치 무관 /tmp 절대경로 세그먼트(케이스4) 판정
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
