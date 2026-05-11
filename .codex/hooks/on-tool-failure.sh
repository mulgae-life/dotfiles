#!/usr/bin/env bash
# Codex PostToolUse 훅: Bash 도구 실패 시 데스크톱 알림
# Claude Code의 on-tool-failure.sh와 대응
# 작업 중단 없음 — exit_code != 0 일 때만 알림, 그 외는 침묵

set -euo pipefail

INPUT=$(cat)

# JSON 파싱: jq → python3 → 그냥 종료
parse_field() {
  local field="$1"
  if command -v jq &>/dev/null; then
    echo "$INPUT" | jq -r "$field // empty" 2>/dev/null
  elif command -v python3 &>/dev/null; then
    echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
path = '$field'.lstrip('.').split('.')
v = d
for p in path:
    if isinstance(v, dict):
        v = v.get(p, '')
    else:
        v = ''
        break
print(v if v not in (None, '') else '')
" 2>/dev/null
  fi
}

EXIT_CODE=$(parse_field '.tool_output.exit_code')
COMMAND=$(parse_field '.tool_input.command')

# 실패가 아니면 침묵 (작업 흐름 보호)
if [[ "$EXIT_CODE" == "" || "$EXIT_CODE" == "0" ]]; then
  echo '{}'
  exit 0
fi

# notify-send 없으면 조용히 종료
if ! command -v notify-send &>/dev/null; then
  echo '{}'
  exit 0
fi

# 명령어 첫 30자 + exit code 표시
SHORT_CMD=$(echo "$COMMAND" | head -c 30)
notify-send -u normal "Codex 도구 실패" "exit=$EXIT_CODE — $SHORT_CMD" 2>/dev/null || true

echo '{}'
exit 0
