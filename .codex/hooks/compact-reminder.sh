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
    "additionalContext": "리마인더: 방금 컨텍스트가 요약·압축됐다. 요약은 손실 압축이다 — 요약 속 파일 상태·수치·결정사항을 사실로 단정하지 말고, 행동에 쓰기 전 관련 파일을 직접 다시 읽어 확인하라. 진행 중이던 작업과 다음 단계는 배경으로 파악해 두라. 이번 턴의 할 일은 압축 뒤 사용자 메시지가 정한다 — 새 요청이나 스킬 호출이면 이전 작업을 재개하지 말고 그것을 수행하며, 이전 작업은 필요한 재료로만 쓴다. 지금 호출된 스킬은 이전 호출 이력과 무관하게 실행하라. 사용자 메시지가 없을 때만 중단 지점에서 이어가라. 프로젝트 루트에 .codex/lessons.md가 있으면 다시 읽어 반영하라."
  }
}
JSONEOF
exit 0
