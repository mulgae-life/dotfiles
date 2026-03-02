#!/usr/bin/env bash
# Claude Code PreToolUse 훅: Bash 명령어 자동 승인
# 비가역적/파괴적 명령(rm, git push/commit 등)만 차단, 나머지는 자동 승인
# 자율 코딩·검증 작업이 중단 없이 진행되도록 최소 차단 정책
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

# "ask" 반환 헬퍼
ask_user() {
  cat <<'ASKEOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "State-changing command detected"
  }
}
ASKEOF
  exit 0
}

# ── 위험 명령어 패턴 체크 ─────────────────────────────────
# \b = 단어 경계 (GNU regex). "firmware"의 "rm" 등 오탐 방지
# 파이프(|)는 허용 — 위험한 건 파이프 뒤 명령어에서 잡힘
DANGEROUS_PATTERNS=(
  # ── 파일 삭제/파괴 (비가역적) ──
  '\brm\b'        '\brmdir\b'     '\bunlink\b'    '\bshred\b'
  '\btruncate\b'

  # ── 시스템 (위험) ──
  '\bsudo\b'      '\bsu\b'
  '\breboot\b'    '\bshutdown\b'  '\bpoweroff\b'  '\bhalt\b'

  # ── 디스크 (비가역적) ──
  '\bdd\b'        '\bmkfs\b'      '\bfdisk\b'     '\bparted\b'

  # ── Git 쓰기 (비가역적/공유 영향) ──
  # (\S+\s+)* 로 글로벌 옵션(-c, --no-pager, -C path 등) 우회 방지
  '\bgit\s+(\S+\s+)*(push|reset|commit)\b'
  '\bgit\s+(\S+\s+)*(clean|rebase|merge|cherry-pick|revert|am|apply)\b'
  '\bgit\s+(\S+\s+)*branch\s+(-[dD]|--delete)\b'
  '\bgit\s+(\S+\s+)*stash\s+(drop|clear)\b'
  '\bgit\s+(\S+\s+)*tag\s+(-[df]|--delete)\b'

  # ── GitHub CLI 쓰기 ──
  '\bgh\s+(pr|issue|release|repo)\s+(create|close|delete|merge|edit|comment)\b'
  '\bgh\s+api\s+-X\b'
  '\bgh\s+api\b.*\s-[fF]\b'
  '\bgh\s+auth\s+(login|logout)\b'

  # ── Docker 삭제 ──
  '\bdocker\s+(rm|rmi)\b'
  '\bdocker(-|\s+)compose\s+(down|rm)\b'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    ask_user
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
