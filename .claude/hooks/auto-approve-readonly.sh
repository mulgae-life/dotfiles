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
    PROCESS)
      reason="프로세스 종료(kill/pkill/killall)입니다. 대상 PID/패턴을 사용자와 먼저 확인하세요."
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
# 각 항목은 "카테고리:정규식" 형식. 카테고리는 ask_command 사유 분기 키.
# \b = 단어 경계 (GNU regex). "firmware"의 "rm" 등 오탐 방지
# 파이프(|)는 허용 — 위험한 건 파이프 뒤 명령어에서 잡힘
#
# 우선순위: for 루프가 첫 매칭에서 exit하므로 배열 순서가 곧 우선순위
# 더 구체적인 카테고리(SHELL_BYPASS, DOCKER_DELETE 등)를 광범위한 FILE_DELETE 앞에 둠
# 예: `docker rm` / `echo rm | bash`가 FILE_DELETE로 흡수되지 않도록 차단
DANGEROUS_PATTERNS=(
  # ── 셸 우회 (따옴표/process sub 우회 방지 — 최우선) ──
  # echo "rm ..." | bash 처럼 stripping 우회 시도
  # bash <(...) process substitution
  # find -delete는 rm 키워드 없이 동일 효과
  'SHELL_BYPASS:\|\s*(bash|sh)\b'
  'SHELL_BYPASS:\b(bash|sh)\s+<\('
  'SHELL_BYPASS:\bfind\b.*\s-delete\b'

  # ── Docker 삭제 (rm 키워드 포함이라 FILE_DELETE보다 앞) ──
  'DOCKER_DELETE:\bdocker\s+(rm|rmi)\b'
  'DOCKER_DELETE:\bdocker(-|\s+)compose\s+(down|rm)\b'

  # ── 파일 in-place 수정 (Edit 도구 우회) ──
  'INPLACE:\bsed\s+(\S+\s+)*-i\b'                # sed -i / sed -i.bak
  'INPLACE:\bsed\s+(\S+\s+)*--in-place\b'        # sed --in-place (GNU long option)
  'INPLACE:\bgawk\s+(\S+\s+)*-i\s+inplace\b'     # gawk -i inplace
  'INPLACE:\bawk\s+(\S+\s+)*-i\s+inplace\b'      # awk -i inplace

  # ── 링크 강제 덮어쓰기 (force overwrite) ──
  # cp/mv는 경로 변경·복사로 되돌리기 쉬워 allow (덮어쓰기 케이스는 의도적)
  'LINK_FORCE:\bln\s+(\S+\s+)*-[a-zA-Z]*f'       # ln -f / ln -sf

  # ── Git 쓰기 (비가역적/공유 영향) ──
  # (\S+\s+)* 로 글로벌 옵션(-c, --no-pager, -C path 등) 우회 방지
  'GIT_WRITE:\bgit\s+(\S+\s+)*(push|reset|commit)\b'
  'GIT_WRITE:\bgit\s+(\S+\s+)*(clean|rebase|merge|cherry-pick|revert|am|apply)\b'
  'GIT_WRITE:\bgit\s+(\S+\s+)*branch\s+(-[dD]|--delete)\b'
  'GIT_WRITE:\bgit\s+(\S+\s+)*tag\s+(-[df]|--delete)\b'

  # ── Git 상태 변경 (working tree/staging/HEAD 이동) ──
  # work-principles.md 분류 정합: stash·add는 "Git 상태 변경" 카테고리로 통일
  # checkout/switch: 브랜치 전환 시 현재 작업 컨텍스트 손실 + detached HEAD 위험
  # restore: working tree 변경 폐기 위험 (--staged는 unstage만이라 안전하지만 단순화 위해 통째로 ask)
  'GIT_STATE:\bgit\s+(\S+\s+)*checkout\b'
  'GIT_STATE:\bgit\s+(\S+\s+)*switch\b'
  'GIT_STATE:\bgit\s+(\S+\s+)*restore\b'
  'GIT_STATE:\bgit\s+(\S+\s+)*stash\b'
  'GIT_STATE:\bgit\s+(\S+\s+)*add\b'

  # ── GitHub CLI 쓰기 ──
  'GH_CLI:\bgh\s+(pr|issue|release|repo)\s+(create|close|delete|merge|edit|comment)\b'
  'GH_CLI:\bgh\s+api\s+-X\b'
  'GH_CLI:\bgh\s+api\b.*\s-[fF]\b'
  'GH_CLI:\bgh\s+auth\s+(login|logout)\b'

  # ── 권한/소유자 변경 ──
  'PERMISSION:\bchmod\b'
  'PERMISSION:\bchown\b'

  # ── 프로세스 종료 ──
  'PROCESS:\bkill\b'
  'PROCESS:\bpkill\b'
  'PROCESS:\bkillall\b'

  # ── 시스템 (sudo/재부팅/디스크) ──
  'SYSTEM:\bsudo\b'
  'SYSTEM:\breboot\b'
  'SYSTEM:\bshutdown\b'
  'SYSTEM:\bpoweroff\b'
  'SYSTEM:\bhalt\b'
  # dd는 실제 옵션(if=, of= 등)이 있을 때만 매칭 — 파이썬 변수명 dd 오탐 방지
  'SYSTEM:\bdd\s+(if|of|bs|count|status|conv|iflag|oflag|ibs|obs|seek|skip)='
  'SYSTEM:\bmkfs\b'
  'SYSTEM:\bfdisk\b'
  'SYSTEM:\bparted\b'

  # ── 파일 삭제/파괴 (비가역적 — 가장 범용적이므로 마지막) ──
  'FILE_DELETE:\brm\b'
  'FILE_DELETE:\brmdir\b'
  'FILE_DELETE:\bunlink\b'
  'FILE_DELETE:\bshred\b'
  'FILE_DELETE:\btruncate\b'
)

# 따옴표 내부 문자열 제거 (echo "reboot" 같은 오탐 방지)
# 큰따옴표/작은따옴표 내용을 빈 문자열로 치환 후 패턴 매칭
COMMAND_STRIPPED=$(echo "$COMMAND" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')

# 셸 인터프리터 호출(bash -c "...", sh -c "...", eval "...") 감지 시
# stripping을 건너뛰고 원본에 패턴 매칭 — 따옴표 내부 우회 차단
# (python/ruby/perl/node 인라인은 위쪽 case에서 별도 처리)
if echo "$COMMAND" | head -1 | grep -qE '^\s*(bash|sh)\s+-c\b|^\s*eval\b'; then
  TARGET="$COMMAND"
else
  TARGET="$COMMAND_STRIPPED"
fi

for entry in "${DANGEROUS_PATTERNS[@]}"; do
  category="${entry%%:*}"
  pattern="${entry#*:}"
  if [[ "$TARGET" =~ $pattern ]]; then
    ask_command "$category"
  fi
done

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
