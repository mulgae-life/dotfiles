#!/usr/bin/env bash
# 3툴(Claude hook / Codex execpolicy / Gemini policy) 정책 회귀 테스트 단일 실행기
# 사용: bash scripts/verify-policies.sh [claude|codex|gemini]  (인자 없으면 전체)
# 케이스: scripts/policy-cases.tsv — 정책 파일 수정 시 케이스 추가 후 이 스크립트로 검증
# 배경: 매 수정마다 배터리를 재작성하던 것을 영속화 (2026-07-10 코드 리뷰 P2-2 수용)
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="$REPO/scripts/policy-cases.tsv"
HOOK="$REPO/.claude/hooks/auto-approve-readonly.sh"
CODEX_RULES="$REPO/.codex/rules/default.rules"
GEMINI_TOML="$REPO/.gemini/policies/safety.toml"
ONLY="${1:-all}"
TOTAL_PASS=0 TOTAL_FAIL=0

# ── Claude hook: stdin JSON → permissionDecision (파이프 대신 리다이렉트 — ask 오발동 회피) ──
run_claude() {
  local pass=0 fail=0 expected command payload decision
  while IFS=$'\t' read -r _tool expected command; do
    payload=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$command")
    decision=$(bash "$HOOK" <<< "$payload" | jq -r '.hookSpecificOutput.permissionDecision // "none"')
    if [[ "$decision" == "$expected" ]]; then
      pass=$((pass+1))
    else
      fail=$((fail+1)); echo "FAIL [기대=$expected 실제=$decision] $command"
    fi
  done < <(grep -P '^claude\t' "$CASES")
  echo "claude 소계: $pass PASS / $fail FAIL"
  TOTAL_PASS=$((TOTAL_PASS+pass)); TOTAL_FAIL=$((TOTAL_FAIL+fail))
}

# ── Codex execpolicy: 실제 엔진으로 판정 (무매칭 = none) ──
run_codex() {
  if ! command -v codex &>/dev/null; then
    echo "codex: CLI 없음 — 건너뜀"; return
  fi
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
  echo "codex 소계: $pass PASS / $fail FAIL"
  TOTAL_PASS=$((TOTAL_PASS+pass)); TOTAL_FAIL=$((TOTAL_FAIL+fail))
}

# ── Gemini: 엔진 복제 러너(node) — TOML은 python tomllib로 추출 ──
run_gemini() {
  if ! command -v node &>/dev/null; then
    echo "gemini: node 없음 — 건너뜀"; return
  fi
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
  TOTAL_PASS=$((TOTAL_PASS+p)); TOTAL_FAIL=$((TOTAL_FAIL+f))
  return $rc
}

[[ "$ONLY" == all || "$ONLY" == claude ]] && run_claude
[[ "$ONLY" == all || "$ONLY" == codex ]] && run_codex
[[ "$ONLY" == all || "$ONLY" == gemini ]] && run_gemini

echo "────────────────────────"
echo "합계: $TOTAL_PASS PASS / $TOTAL_FAIL FAIL"
[[ $TOTAL_FAIL -eq 0 ]]
