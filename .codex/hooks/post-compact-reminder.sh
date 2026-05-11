#!/usr/bin/env bash
# Codex PostCompact 훅: 컨텍스트 압축 후 핵심 규칙 재주입
# Claude Code의 SessionStart:compact 훅과 대응
# 작업 중단 없음 — systemMessage로 리마인더만 출력
# matcher = "^(manual|auto)$" 로 manual/auto 양쪽 모두 트리거

set -euo pipefail

# stdin은 무시 (lifecycle metadata만 들어옴)
cat >/dev/null

# systemMessage는 모델 컨텍스트에 추가되지만 사용자 입력 대기는 발동 안 됨
cat <<'JSONEOF'
{
  "systemMessage": "리마인더: 한국어 응답 유지. 변경 이유 설명 필수. 현재 작업 상태를 먼저 확인하세요."
}
JSONEOF
exit 0
