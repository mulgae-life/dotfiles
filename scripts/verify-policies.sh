#!/usr/bin/env bash
# 정책 회귀 테스트 실행기 — Codex execpolicy(실제 엔진) + Antigravity CLI 설정 정적 검사(모델 미호출)
# 사용: bash scripts/verify-policies.sh [codex|agy]  (인자 없으면 전체)
# 케이스: scripts/policy-cases.tsv — 정책 파일 수정 시 케이스 추가 후 이 스크립트로 검증
# 배경: 매 수정마다 배터리를 재작성하던 것을 영속화 (2026-07-10 코드 리뷰 P2-2 수용)
# Claude 훅(auto-approve-readonly.sh)은 은퇴 — 러너와 케이스는 .archive/2026-07-18_hook-retirement/ 참조
# Gemini CLI 층도 은퇴 — 러너와 케이스는 .archive/2026-09-07_gemini-cli-retirement/ 참조
# agy 실제 판정(모델 호출)은 scripts/agy-live-check.sh 로 분리
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="$REPO/scripts/policy-cases.tsv"
CODEX_RULES="$REPO/.codex/rules/default.rules"
AGY_SETTINGS="$REPO/.antigravity/cli/settings.json"
ONLY="${1:-all}"
case "$ONLY" in
  all|codex|agy) ;;
  *) echo "사용법: bash scripts/verify-policies.sh [codex|agy]" >&2; exit 2 ;;
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

# ── Antigravity CLI: 레포 settings.json 정적 검사 (agy 1.1.27 실측 규칙 기준) ──
run_agy() {
  if ! command -v jq &>/dev/null; then
    echo "agy: jq 없음 — 건너뜀"; return
  fi
  RAN=$((RAN+1))
  local pass=0 fail=0
  chk() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [agy] $1"; fi; }
  chk "JSON 객체" "jq -e 'type==\"object\"' '$AGY_SETTINGS' >/dev/null 2>&1"
  chk "toolPermission 열거값" "jq -e '.toolPermission | IN(\"request-review\",\"proceed-in-sandbox\",\"always-proceed\",\"strict\")' '$AGY_SETTINGS' >/dev/null"
  chk "artifactReviewPolicy 열거값" "jq -e '.artifactReviewPolicy | IN(\"asks-for-review\",\"agent-decides\",\"always-proceed\")' '$AGY_SETTINGS' >/dev/null"
  chk "notifications 불리언" "jq -e '.notifications | type==\"boolean\"' '$AGY_SETTINGS' >/dev/null"
  chk "permissions 3배열 명시" "jq -e '.permissions | (.allow|type==\"array\") and (.ask|type==\"array\") and (.deny|type==\"array\")' '$AGY_SETTINGS' >/dev/null"
  chk "런타임 키(model·trustedWorkspaces) 미포함" "jq -e '(has(\"model\") or has(\"trustedWorkspaces\")) | not' '$AGY_SETTINGS' >/dev/null"
  # 항목 외형: action(target), 액션 7종 (의미 검증이 아니라 문법 외형 검사)
  chk "규칙 외형 action(target)" "jq -e '[.permissions[][]] | all(test(\"^(command|read_file|write_file|read_url|execute_url|unsandboxed|mcp)\\\\(.+\\\\)$\"))' '$AGY_SETTINGS' >/dev/null"
  # regex: 접두는 1.1.27 실측에서 deny 에 무효 → 금지. * 는 토큰 글롭이 아니므로 허용 범위를 둘로 한정:
  #   전체 와일드카드 action(*) (공식 문법) 또는 리터럴 토큰 `/*` 로 끝나는 경로 (rm -rf /* 등)
  chk "regex: 미사용" "jq -e '[.permissions[][]] | any(test(\"regex:\")) | not' '$AGY_SETTINGS' >/dev/null"
  chk "* 는 action(*) 또는 리터럴 /* 토큰만" "jq -e '[.permissions[][] | select(test(\"\\\\*\")) | select((test(\"^[a-z_]+\\\\(\\\\*\\\\)$\") or test(\"/\\\\*\\\\)$\")) | not)] | length == 0' '$AGY_SETTINGS' >/dev/null"
  chk "deny 중복 없음" "jq -e '.permissions.deny | length == (unique|length)' '$AGY_SETTINGS' >/dev/null"
  local must
  for must in 'command(rm -rf /)' 'command(rm -rf ~)' 'command(rm -rf .)' 'command(mkfs)' 'command(reboot)' 'command(crontab -r)'; do
    chk "deny 필수: $must" "jq -e --arg m '$must' '.permissions.deny | index(\$m) != null' '$AGY_SETTINGS' >/dev/null"
  done
  echo "agy 소계: $pass PASS / $fail FAIL"
  TOTAL_PASS=$((TOTAL_PASS+pass)); TOTAL_FAIL=$((TOTAL_FAIL+fail))
}

[[ "$ONLY" == all || "$ONLY" == codex ]] && run_codex
[[ "$ONLY" == all || "$ONLY" == agy ]] && run_agy

echo "────────────────────────"
echo "합계: $TOTAL_PASS PASS / $TOTAL_FAIL FAIL"
if (( RAN == 0 )); then
  echo "실행된 검사기 없음 — 실패로 판정" >&2; exit 1
fi
[[ $TOTAL_FAIL -eq 0 ]]
