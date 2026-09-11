#!/usr/bin/env bash
# Codex SessionStart(compact) 훅: 컨텍스트 압축 직후 리마인더를 모델 컨텍스트에 주입
# Claude Code의 SessionStart(matcher: compact) 훅과 대응
# PostCompact는 systemMessage를 UI 경고로만 표시하고 모델에 전달하지 않아 SessionStart의 additionalContext를 사용
# matcher = "^compact$" — startup/resume/clear에는 발동하지 않음

set -euo pipefail

# stdin은 무시 (lifecycle metadata만 들어옴)
cat >/dev/null

cat <<'JSONEOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "리마인더: 방금 컨텍스트가 요약·압축됐다. 요약은 손실 압축이다 — 요약 속 파일 상태·수치·결정사항을 사실로 단정하지 말고, 작업 재개 전 관련 파일을 직접 다시 읽어 확인하라. 진행 중이던 작업과 다음 단계를 먼저 파악하라. 프로젝트 루트에 .codex/lessons.md가 있으면 다시 읽어 반영하라."
  }
}
JSONEOF
exit 0
