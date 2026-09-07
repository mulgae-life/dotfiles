#!/usr/bin/env bash
# 2툴(Codex execpolicy / Gemini policy) 정책 회귀 테스트 단일 실행기
# 사용: bash scripts/verify-policies.sh [codex|gemini]  (인자 없으면 전체)
# 케이스: scripts/policy-cases.tsv — 정책 파일 수정 시 케이스 추가 후 이 스크립트로 검증
# 배경: 매 수정마다 배터리를 재작성하던 것을 영속화 (2026-07-10 코드 리뷰 P2-2 수용)
# Claude 훅(auto-approve-readonly.sh)은 은퇴 — 러너와 케이스는 .archive/2026-07-18_hook-retirement/ 참조
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="$REPO/scripts/policy-cases.tsv"
CODEX_RULES="$REPO/.codex/rules/default.rules"
GEMINI_TOML="$REPO/.gemini/policies/safety.toml"
ONLY="${1:-all}"
case "$ONLY" in
  all|codex|gemini) ;;
  *) echo "사용법: bash scripts/verify-policies.sh [codex|gemini]" >&2; exit 2 ;;
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

# ── Gemini: 엔진 복제 러너(node) — TOML은 python tomllib로 추출 ──
run_gemini() {
  if ! command -v node &>/dev/null; then
    echo "gemini: node 없음 — 건너뜀"; return
  fi
  RAN=$((RAN+1))
  local out rc
  out=$(python3 - "$GEMINI_TOML" "$CASES" <<'EOF' | node "$REPO/scripts/gemini-policy-engine.mjs"
import tomllib, json, sys
with open(sys.argv[1], 'rb') as f:
    rules = tomllib.load(f)["rule"]
cases = []
with open(sys.argv[2], encoding='utf-8') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        tool, expected, command = line.split('\t', 2)
        if tool == 'gemini':
            cases.append([command, expected])
print(json.dumps({"rules": rules, "cases": cases}, ensure_ascii=False))
EOF
  ); rc=$?
  echo "$out" | grep -E '^FAIL|소계|무효'
  local p f
  p=$(echo "$out" | grep -c '^PASS' || true)
  f=$(echo "$out" | grep -c '^FAIL' || true)
  # 엔진은 FAIL·무효 규칙이 있을 때만 rc≠0 이고 그때는 FAIL 줄이 함께 찍힘 → FAIL 줄 없이 rc≠0 이면 파서·엔진 자체 오류
  if (( rc != 0 && f == 0 )); then
    echo "FAIL [gemini 검사기 오류 rc=$rc — 정책 판정 아님]"; f=1
  fi
  if (( p + f == 0 )); then
    echo "FAIL [gemini 케이스 0건 — $CASES 확인]"; f=1
  fi
  TOTAL_PASS=$((TOTAL_PASS+p)); TOTAL_FAIL=$((TOTAL_FAIL+f))
}

[[ "$ONLY" == all || "$ONLY" == codex ]] && run_codex
[[ "$ONLY" == all || "$ONLY" == gemini ]] && run_gemini

echo "────────────────────────"
echo "합계: $TOTAL_PASS PASS / $TOTAL_FAIL FAIL"
if (( RAN == 0 )); then
  echo "실행된 검사기 없음 — 실패로 판정" >&2; exit 1
fi
[[ $TOTAL_FAIL -eq 0 ]]
