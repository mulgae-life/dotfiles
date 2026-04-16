#!/usr/bin/env bash
# Gemini CLI 데스크톱 알림 훅
# Notification 이벤트 발생 시 notify-send로 알림 전송

INPUT=$(cat)

# JSON 파싱: jq → python3 순서로 폴백
if command -v jq &>/dev/null; then
  TITLE=$(echo "$INPUT" | jq -r '.title // "알림"' 2>/dev/null)
  MESSAGE=$(echo "$INPUT" | jq -r '.message // ""' 2>/dev/null)
elif command -v python3 &>/dev/null; then
  TITLE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title','알림'))" 2>/dev/null)
  MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
else
  echo '{}'
  exit 0
fi

notify-send "Gemini CLI" "${TITLE}: ${MESSAGE}" 2>/dev/null || true

echo '{}'
