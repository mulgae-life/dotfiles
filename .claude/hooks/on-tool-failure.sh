#!/usr/bin/env bash
# PostToolUseFailure 훅: 빌드/테스트 실패 시 Claude에게 가이던스 주입

INPUT=$(cat)

# JSON 파싱
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
  ERROR=$(echo "$INPUT" | jq -r '.error // ""' 2>/dev/null)
elif command -v python3 &>/dev/null; then
  COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)
  ERROR=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',''))" 2>/dev/null)
else
  echo '{}'
  exit 0
fi

# 빌드 실패 감지
if echo "$COMMAND" | grep -qE '(npm run build|tsc|pnpm build|pnpm run build|yarn build|cargo build|make\b)'; then
  echo '{"hookSpecificOutput":{"additionalContext":"빌드 실패 감지. build-resolver 에이전트 위임을 고려하세요. 에러 메시지를 분석하고 최소한의 변경으로 수정하세요."}}'
  exit 0
fi

# 테스트 실패 감지
if echo "$COMMAND" | grep -qE '(npm test|npm run test|pnpm test|pytest|jest|vitest|cargo test)'; then
  echo '{"hookSpecificOutput":{"additionalContext":"테스트 실패 감지. 실패한 테스트의 에러 메시지를 정확히 읽고, 테스트 코드가 아닌 구현 코드의 문제를 먼저 확인하세요."}}'
  exit 0
fi

# 린트 실패 감지
if echo "$COMMAND" | grep -qE '(eslint|ruff|mypy|pylint|prettier)'; then
  echo '{"hookSpecificOutput":{"additionalContext":"린트/타입체크 실패 감지. 자동 수정이 가능한지 먼저 확인하세요 (--fix 옵션)."}}'
  exit 0
fi

# 기타 실패는 무시
echo '{}'
