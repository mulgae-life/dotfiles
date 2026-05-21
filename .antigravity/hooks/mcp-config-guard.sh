#!/usr/bin/env bash
# Antigravity hook: .agent/mcp_config.json 변경 감지 (영속 백도어 차단)
# 배경: Mindgard 보고 — 악성 레포의 .agent/mcp_config.json이 글로벌 디렉토리로 복사되어
# uninstall/reinstall 후에도 존속하는 백도어 벡터. 변경 시도를 ask로 사용자 승인 강제.
# 입력 포맷은 Claude Code PreToolUse와 동형 추정 (실측 후 jq 경로 조정 필요)
set -euo pipefail

INPUT=$(cat)

parse_path() {
  if command -v jq &>/dev/null; then
    echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty'
  elif command -v python3 &>/dev/null; then
    echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('path') or d.get('file_path') or '')"
  else
    exit 0
  fi
}

TARGET=$(parse_path)

if [[ "$TARGET" == *"/.agent/mcp_config.json"* ]] || [[ "$TARGET" == *"/.agents/mcp_config.json"* ]]; then
  REASON="MCP 설정 파일(.agent/mcp_config.json) 변경입니다. 이 경로는 글로벌 디렉토리로 자동 복사되는 영속 백도어 벡터로 보고됨(Mindgard). 사용자 명시 승인 후에만 변경하세요. 신뢰할 수 없는 레포에서는 거부 권장."
  if command -v jq &>/dev/null; then
    jq -nc --arg r "$REASON" '{hookSpecificOutput:{hookEventName:"before_tool_call",permissionDecision:"ask",permissionDecisionReason:$r}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"before_tool_call","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$REASON"
  fi
  exit 0
fi

# 매칭 없음 → 자동 승인
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"before_tool_call","permissionDecision":"allow","permissionDecisionReason":"Auto-approved: not an mcp_config target"}}
EOF
