#!/usr/bin/env bash
# Claude Code PreToolUse 훅: 읽기 전용 Bash 명령어 자동 승인
# 위험 패턴(파일 수정/삭제, 네트워크 쓰기 등)이 없으면 자동 승인
# 위험 패턴이 감지되면 "ask" 반환 (settings.json allow 패턴도 무시하고 사용자 확인 강제)
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

# ── 1단계: 리다이렉션 체크 ──────────────────────────────
# 안전한 리다이렉션(/dev/null, 파일디스크립터 복제) 제거 후 잔여 > >> 검사
# "ask" 반환 헬퍼: settings.json allow 패턴을 무시하고 사용자 확인 강제
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

REDIR_CHECK=$(echo "$COMMAND" | sed 's|[0-9]*>/dev/null||g; s|[0-9]*>&[0-9]*||g')
if [[ "$REDIR_CHECK" == *'>>'* ]] || [[ "$REDIR_CHECK" == *'>'* ]]; then
  ask_user
fi

# ── 2단계: 위험 명령어 패턴 체크 ─────────────────────────
# \b = 단어 경계 (GNU regex). "firmware"의 "rm" 등 오탐 방지
# 파이프(|)는 허용 — 위험한 건 파이프 뒤 명령어에서 잡힘
DANGEROUS_PATTERNS=(
  # ── 파일 삭제/이동/복사/생성 ──
  '\brm\b'        '\brmdir\b'     '\bunlink\b'    '\bshred\b'
  '\bmv\b'        '\bcp\b'
  '\bmkdir\b'     '\btouch\b'     '\bln\b'
  '\btee\b'       '\btruncate\b'  '\bpatch\b'
  '\bsed\b.*\s-i'

  # ── 권한/소유자 ──
  '\bchmod\b'     '\bchown\b'     '\bchgrp\b'

  # ── 프로세스/시스템 ──
  '\bkill\b'      '\bpkill\b'     '\bkillall\b'
  '\bsudo\b'      '\bsu\b'
  '\breboot\b'    '\bshutdown\b'  '\bpoweroff\b'  '\bhalt\b'

  # ── 네트워크 (쓰기 가능) ──
  '\bcurl\b'      '\bwget\b'
  '\bssh\b'       '\bscp\b'       '\bsftp\b'      '\brsync\b'
  '\bnc\b'        '\bncat\b'

  # ── 패키지 관리 (설치/제거) ──
  '\bapt\s+(install|remove|purge|upgrade|dist-upgrade)\b'
  '\byum\s+(install|remove)\b'
  '\bdnf\s+(install|remove)\b'
  '\bbrew\s+(install|uninstall|upgrade)\b'
  '\bnpm\s+(install|uninstall|publish|ci)\b'
  '\bpip3?\s+(install|uninstall)\b'
  '\bpnpm\s+(install|add|remove)\b'
  '\byarn\s+(add|remove)\b'

  # ── 임의 코드 실행 ──
  '\beval\b'      '\bexec\b'      '\bsource\b'

  # ── Git 쓰기 ──
  '\bgit\s+(add|push|reset|checkout|switch|restore|rebase|merge|commit)\b'
  '\bgit\s+stash\s+(save|push|drop|pop|clear|apply)\b'
  '\bgit\s+stash\s*([;&|]|$)'
  '\bgit\s+branch\s+(-[dD]|--delete)\b'
  '\bgit\s+(clean|cherry-pick|revert|am|apply)\b'
  '\bgit\s+tag\s+[A-Za-z0-9]'
  '\bgit\s+tag\s+(-[daf]|--delete)\b'
  '\bgit\s+-C\s+\S+\s+(add|push|reset|checkout|switch|restore|rebase|merge|commit|clean|cherry-pick|revert)\b'

  # ── Docker 쓰기 ──
  '\bdocker\s+(run|exec|rm|rmi|stop|kill|start|restart|build|push|pull|create|tag|login|logout|commit)\b'
  '\bdocker\s+compose\s+(up|down|rm|build|create|pull|restart|stop|kill|start)\b'

  # ── 서비스/시스템 ──
  '\bsystemctl\s+(start|stop|restart|enable|disable)\b'
  '\bservice\s+\S+\s+(start|stop|restart)\b'

  # ── 디스크 ──
  '\bdd\b'        '\bmkfs\b'      '\bfdisk\b'     '\bparted\b'

  # ── 크론 ──
  '\bcrontab\s+-[er]\b'

  # ── 네트워크 인터페이스 쓰기 ──
  '\bip\s+(addr|route|link|neigh|rule)\s+(add|del|delete|flush|set)\b'

  # ── GitHub CLI 쓰기 ──
  '\bgh\s+(pr|issue|release|repo)\s+(create|close|delete|merge|edit|comment)\b'
  '\bgh\s+api\s+-X\b'
  '\bgh\s+api\b.*\s-[fF]\b'
  '\bgh\s+auth\s+(login|logout)\b'
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
