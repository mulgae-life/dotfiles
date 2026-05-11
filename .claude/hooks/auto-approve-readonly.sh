#!/usr/bin/env bash
# Claude Code PreToolUse 훅: Bash 명령어 자동 승인
# 비가역적/파괴적 명령(rm, git push/commit 등)은 "ask"로 사용자 승인 요청, 나머지는 자동 승인(allow)
# 사용자 명시 요청 시 승인하여 실행, 자율 작업 중 시도는 시스템 프롬프트(rules/work-principles.md)가 회피
# 안전 명령에서는 절대 ask 발동 안 함 → 자율 작업 흐름 중단 없음
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

# 위험 명령 사용자 승인 요청 헬퍼
# 사용자 명시 요청 시: 대표님이 승인하여 실행
# 자율 작업 중 시도: 대표님이 거부하여 차단 (정상적으론 시스템 프롬프트가 회피하므로 발동 드물어야 함)
ask_command() {
  cat <<'ASKEOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "위험 명령입니다. 사용자 승인이 필요합니다."
  }
}
ASKEOF
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
      SCRIPT_DANGEROUS_PATTERNS=(
        '\bos\.system\b'          # 셸 명령 문자열 실행 (인젝션 위험)
        '\bshutil\.rmtree\b'      # 디렉토리 재귀 삭제
      )
      for pattern in "${SCRIPT_DANGEROUS_PATTERNS[@]}"; do
        if [[ "$COMMAND" =~ $pattern ]]; then
          ask_command
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
# \b = 단어 경계 (GNU regex). "firmware"의 "rm" 등 오탐 방지
# 파이프(|)는 허용 — 위험한 건 파이프 뒤 명령어에서 잡힘
DANGEROUS_PATTERNS=(
  # ── 파일 삭제/파괴 (비가역적) ──
  '\brm\b'        '\brmdir\b'     '\bunlink\b'    '\bshred\b'
  '\btruncate\b'

  # ── sudo (권한 상승 + 비밀번호 프롬프트로 작업 중단) ──
  '\bsudo\b'

  # ── 시스템 (위험) ──
  '\breboot\b'    '\bshutdown\b'  '\bpoweroff\b'  '\bhalt\b'

  # ── 디스크 (비가역적) ──
  # dd는 실제 옵션(if=, of= 등)이 있을 때만 매칭 — 파이썬 변수명 dd 오탐 방지
  '\bdd\s+(if|of|bs|count|status|conv|iflag|oflag|ibs|obs|seek|skip)='
  '\bmkfs\b'      '\bfdisk\b'     '\bparted\b'

  # ── Git 쓰기 (비가역적/공유 영향) ──
  # (\S+\s+)* 로 글로벌 옵션(-c, --no-pager, -C path 등) 우회 방지
  '\bgit\s+(\S+\s+)*(push|reset|commit)\b'
  '\bgit\s+(\S+\s+)*(clean|rebase|merge|cherry-pick|revert|am|apply)\b'
  '\bgit\s+(\S+\s+)*branch\s+(-[dD]|--delete)\b'
  '\bgit\s+(\S+\s+)*stash\b'
  '\bgit\s+(\S+\s+)*tag\s+(-[df]|--delete)\b'

  # ── Git 상태 변경 (working tree/HEAD 이동) ──
  # checkout/switch: 브랜치 전환 시 현재 작업 컨텍스트 손실 + detached HEAD 위험
  # restore: working tree 변경 폐기 위험 (--staged는 unstage만이라 안전하지만 단순화 위해 통째로 ask)
  '\bgit\s+(\S+\s+)*checkout\b'
  '\bgit\s+(\S+\s+)*switch\b'
  '\bgit\s+(\S+\s+)*restore\b'

  # ── GitHub CLI 쓰기 ──
  '\bgh\s+(pr|issue|release|repo)\s+(create|close|delete|merge|edit|comment)\b'
  '\bgh\s+api\s+-X\b'
  '\bgh\s+api\b.*\s-[fF]\b'
  '\bgh\s+auth\s+(login|logout)\b'

  # ── Docker 삭제 ──
  '\bdocker\s+(rm|rmi)\b'
  '\bdocker(-|\s+)compose\s+(down|rm)\b'

  # ── 파일 in-place 수정 (Edit 도구 우회) ──
  '\bsed\s+(\S+\s+)*-i\b'                # sed -i / sed -i.bak
  '\bgawk\s+(\S+\s+)*-i\s+inplace\b'     # gawk -i inplace
  '\bawk\s+(\S+\s+)*-i\s+inplace\b'      # awk -i inplace

  # ── 링크 강제 덮어쓰기 (force overwrite) ──
  # cp/mv는 경로 변경·복사로 되돌리기 쉬워 allow (덮어쓰기 케이스는 의도적)
  '\bln\s+(\S+\s+)*-[a-zA-Z]*f'          # ln -f / ln -sf

  # ── 권한/소유자 변경 ──
  '\bchmod\b'
  '\bchown\b'

  # ── 프로세스 종료 ──
  '\bkill\b'
  '\bpkill\b'

  # ── Git staging ──
  '\bgit\s+(\S+\s+)*add\b'

  # ── 셸 우회 (따옴표/process sub 우회 방지) ──
  # echo "rm ..." | bash 처럼 stripping 우회 시도
  # bash <(...) process substitution
  '\|\s*(bash|sh)\b'
  '\b(bash|sh)\s+<\('

  # ── find -delete (rm 대체) ──
  # find -delete는 rm 키워드 없이 동일 효과
  '\bfind\b.*\s-delete\b'
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

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$TARGET" =~ $pattern ]]; then
    ask_command
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
