#!/usr/bin/env bash
# Codex Stop 훅: 턴 완료 시 데스크톱 알림
# Claude Code의 Notification 훅(claude.ai)과 대응
# 작업 중단 없음 — 알림만 발화하고 즉시 종료

set -euo pipefail

# stdin은 무시 (Stop 훅은 lifecycle 알림 용도)
cat >/dev/null

# notify-send가 없으면 조용히 종료 (작업 흐름 보호)
if ! command -v notify-send &>/dev/null; then
  echo '{}'
  exit 0
fi

notify-send -u low "Codex" "작업 완료" 2>/dev/null || true

echo '{}'
exit 0
