#!/usr/bin/env bash
# Codex execpolicy 정책 회귀 테스트 실행기
# 사용: bash scripts/verify-policies.sh [codex]  (인자 없으면 전체)
# 케이스: scripts/policy-cases.tsv — 정책 파일 수정 시 케이스 추가 후 이 스크립트로 검증
# 배경: 매 수정마다 배터리를 재작성하던 것을 영속화 (2026-07-10 코드 리뷰 P2-2 수용)
# Claude 훅(auto-approve-readonly.sh)은 은퇴 — 러너와 케이스는 .archive/2026-07-18_hook-retirement/ 참조
# Gemini CLI 층도 은퇴 — 러너와 케이스는 .archive/2026-09-07_gemini-cli-retirement/ 참조
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="$REPO/scripts/policy-cases.tsv"
CODEX_RULES="$REPO/.codex/rules/default.rules"
ONLY="${1:-all}"
case "$ONLY" in
  all|codex) ;;
  *) echo "사용법: bash scripts/verify-policies.sh [codex]" >&2; exit 2 ;;
esac
[[ -f "$CASES" ]] || { echo "케이스 파일 없음: $CASES" >&2; exit 1; }
TOTAL_PASS=0 TOTAL_FAIL=0
RAN=0  # 실제 실행된 검사기 수 — 0이면 검사 없이 통과한 것이므로 실패 판정

# ── Codex execpolicy: 실제 엔진으로 판정 (무매칭 = none) ──
run_codex() {
  if ! command -v codex &>/dev/null; then
    echo "codex: CLI 없음 — 건너뜀"; return
  fi
  RAN=$((RAN+1))
  local pass=0 fail=0 expected command decision
  while IFS=$'\t' read -r _tool expected command; do
    # 케이스는 따옴표 없는 단순 토큰만 사용 (의도적 word splitting)
    # shellcheck disable=SC2086
    decision=$(codex execpolicy check --rules "$CODEX_RULES" $command 2>/dev/null | jq -r '.decision // "none"')
    if [[ "$decision" == "$expected" ]]; then
      pass=$((pass+1))
    else
      fail=$((fail+1)); echo "FAIL [기대=$expected 실제=$decision] $command"
    fi
  done < <(grep -P '^codex\t' "$CASES")
  # 케이스 0건이면 검사 없이 통과한 것 → 실패 (검사기 단위로 판정해야 다른 검사기의 PASS에 가려지지 않음)
  if (( pass + fail == 0 )); then
    echo "FAIL [codex 케이스 0건 — $CASES 확인]"; fail=1
  fi
  echo "codex 소계: $pass PASS / $fail FAIL"
  TOTAL_PASS=$((TOTAL_PASS+pass)); TOTAL_FAIL=$((TOTAL_FAIL+fail))
}

[[ "$ONLY" == all || "$ONLY" == codex ]] && run_codex

echo "────────────────────────"
echo "합계: $TOTAL_PASS PASS / $TOTAL_FAIL FAIL"
if (( RAN == 0 )); then
  echo "실행된 검사기 없음 — 실패로 판정" >&2; exit 1
fi
[[ $TOTAL_FAIL -eq 0 ]]
