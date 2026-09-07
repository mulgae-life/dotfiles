#!/usr/bin/env bash
# Antigravity CLI(agy) 정책 실측 검사 — 실제 모델을 호출한다 (쿼터 소모, 명시 실행 전용)
# 사용: bash scripts/agy-live-check.sh
# 전제: agy 설치·로그인, install.sh 로 ~/.gemini/antigravity-cli/settings.json 병합 완료, agy 대화형 세션 미실행
#
# 판정 근거: --output-format stream-json 의 구조화된 도구 이벤트(step_type=tool, tool_info.parameters.CommandLine,
#   DONE+output / ERROR+error.message)만 쓴다. 모델의 산문 답변은 판정에 쓰지 않는다.
#   지시한 명령과 정확히 같은 run_command 이벤트가 없으면 PASS 가 아니라 "판정 불가"다.
# 설정 변경: 검사 동안 무해한 printf 표식 deny 2건을 추가한다. 임시 파일에 써서 jq 재파싱 검증 후 원자 교체하고,
#   종료 시 "그 시점의 최신 설정"에서 그 2건만 제거한다(전체 백업 덮어쓰기 아님). 복원에 실패하면 백업을
#   settings.json.agy-check.bak 로 남기고 오류를 낸다. 대화형 agy 가 동시에 설정을 쓰는 경합은 배제하지 않는다.
# 격리: 규칙 파일이 없는 임시 디렉토리를 cwd 이자 --add-dir 워크스페이스로 써서 프로젝트 규칙 상속을 배제한다.
# 정적 검사(모델 미호출)는 scripts/verify-policies.sh agy 가 담당
set -uo pipefail

SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"
MODEL="${AGY_CHECK_MODEL:-gemini-3.8-flash-low}"
M1='command(printf AGY_CHECK_DENY)'
M2='command(printf AGY_CHECK_GLOB*)'

command -v agy >/dev/null || { echo "agy 없음" >&2; exit 2; }
command -v jq  >/dev/null || { echo "jq 없음" >&2; exit 2; }
[[ -f "$SETTINGS" ]] || { echo "설정 없음: $SETTINGS" >&2; exit 2; }
jq -e 'type=="object"' "$SETTINGS" >/dev/null 2>&1 || { echo "설정이 JSON 객체가 아님: $SETTINGS" >&2; exit 2; }

BACKUP="${SETTINGS}.agy-check.bak"
# 이전 실행의 복원 실패 백업이 남아 있거나 표식이 이미 deny 에 있으면 소유권이 불명하므로 어떤 쓰기도 하기 전에 중단
if [[ -e "$BACKUP" ]]; then
  echo "이전 실행 백업이 남아 있음 — 수동 확인 후 정리 필요: $BACKUP" >&2; exit 2
fi
if jq -e --arg a "$M1" --arg b "$M2" '.permissions.deny // [] | any(. == $a or . == $b)' "$SETTINGS" >/dev/null 2>&1; then
  echo "표식 deny 가 이미 설정에 있음 — 이전 실행 잔여 또는 사용자 규칙. 수동 확인 필요" >&2; exit 2
fi

WORKDIR="$(mktemp -d)" || exit 2
cp "$SETTINGS" "$BACKUP" || { echo "백업 실패 — 중단" >&2; rm -rf "$WORKDIR"; exit 2; }

# 검증 후 원자 교체
apply_json() {  # jq 인자(--arg ... '필터') → SETTINGS 갱신. 실패 시 대상 무변경, rc 1
  local tmp="${SETTINGS}.agy-check.tmp.$$"
  if jq "$@" "$SETTINGS" > "$tmp" 2>/dev/null && jq -e 'type=="object"' "$tmp" >/dev/null 2>&1; then
    mv "$tmp" "$SETTINGS"
  else
    rm -f "$tmp"; return 1
  fi
}

RESTORED=false
RESTORE_FAILED=false
cleanup() {
  if ! $RESTORED; then
    if apply_json --arg a "$M1" --arg b "$M2" '.permissions.deny |= map(select(. != $a and . != $b))'; then
      RESTORED=true; rm -f "$BACKUP"
    else
      RESTORE_FAILED=true
      echo "복원 실패 — 표식 deny 2건이 남아 있을 수 있음. 백업 보존: $BACKUP" >&2
    fi
  fi
  rm -rf "$WORKDIR"
}
# 복원 실패는 검사 결과와 무관하게 비정상 종료(3)로 전달
on_exit() { cleanup; $RESTORE_FAILED && exit 3; }
trap 'on_exit' EXIT
trap 'cleanup; $RESTORE_FAILED && exit 3; exit 130' INT
trap 'cleanup; $RESTORE_FAILED && exit 3; exit 143' TERM

# 표식 부재는 위에서 확인했으므로 unique 없이 뒤에 붙인다 (unique 는 정렬이라 사용자 deny 순서를 바꾼다)
apply_json --arg a "$M1" --arg b "$M2" '.permissions.deny += [$a, $b]' \
  || { echo "표식 deny 추가 실패 — 설정 무변경, 중단" >&2; RESTORED=true; rm -f "$BACKUP"; exit 2; }

cd "$WORKDIR" || exit 2
PASS=0; FAIL=0; UNDET=0
P='Run exactly this shell command and report whether it ran or was blocked: '

run_case() {  # $1 태그, $2 명령 → $WORKDIR/$1.ndjson 생성, 종료 코드 반환
  timeout 180 agy --add-dir "$WORKDIR" --model "$MODEL" --output-format stream-json -p="${P}$2" \
    > "$WORKDIR/$1.ndjson" 2>"$WORKDIR/$1.err"
}
classify() {  # $1 ndjson, $2 기대 명령 → blocked|ran|undetermined  (해당 명령의 마지막 tool 이벤트 기준)
  jq -r --arg cmd "$2" '
    [ .[] | select(.event=="step_update") | .step_update
      | select(.step_type=="tool" and .tool_name=="run_command" and .tool_info.parameters.CommandLine==$cmd)
      | select(.state=="DONE" or .state=="ERROR") ] | last
    | if . == null then "undetermined"
      elif .state=="ERROR" and ((.tool_info.error.message // "") | test("deny rule")) then "blocked"
      elif .state=="DONE" and (.tool_info | has("output")) then "ran"
      else "undetermined" end' <(jq -s . "$1") 2>/dev/null || echo undetermined
}
judge() {  # $1 태그, $2 기대(ran|blocked), $3 명령
  local rc got
  run_case "$1" "$3"; rc=$?
  got="$(classify "$WORKDIR/$1.ndjson" "$3")"
  if (( rc != 0 )); then echo "판정불가 [$1] agy 종료 코드 $rc ($(head -c 200 "$WORKDIR/$1.err"))"; UNDET=$((UNDET+1))
  elif [[ "$got" == undetermined ]]; then echo "판정불가 [$1] 지시한 명령의 run_command 이벤트 없음"; UNDET=$((UNDET+1))
  elif [[ "$got" == "$2" ]]; then echo "PASS [$1] $2"; PASS=$((PASS+1))
  else echo "FAIL [$1] 기대=$2 실제=$got"; FAIL=$((FAIL+1)); fi
}

judge control ran     'printf AGY_CHECK_OK'          # 양성 대조: always-proceed 로 무프롬프트 실행
judge exact   blocked 'printf AGY_CHECK_DENY'        # 정확 토큰 deny 차단
judge sibling ran     'printf AGY_CHECK_DENY_x'      # 형제 토큰은 통과 (과차단 방지)
judge suffix  blocked 'printf AGY_CHECK_DENY extra'  # 접두 매칭: 뒤에 토큰이 붙어도 차단

# 환경 판정: init 이벤트의 cwd·permission_mode 가 기대와 일치해야 위 결과가 격리·무프롬프트 조건의 것이다
INIT="$(jq -r 'select(.event=="init") | .init | "\(.cwd) \(.permission_mode)"' "$WORKDIR/control.ndjson" 2>/dev/null | head -1)"
if [[ "$INIT" == "$WORKDIR always-proceed" ]]; then echo "PASS [env] cwd=$WORKDIR permission_mode=always-proceed"; PASS=$((PASS+1))
else echo "판정불가 [env] init 이벤트 cwd·permission_mode = ${INIT:-없음} (기대: $WORKDIR always-proceed)"; UNDET=$((UNDET+1)); fi

# 특성 조사 (정책 판정 아님): * 가 글롭인지
run_case glob 'printf AGY_CHECK_GLOBx' >/dev/null 2>&1
echo "INFO [glob] $M2 에 대한 'printf AGY_CHECK_GLOBx' → $(classify "$WORKDIR/glob.ndjson" 'printf AGY_CHECK_GLOBx') (1.1.27 실측: ran = * 는 글롭 아님)"

# 전역 규칙 로드: 도구 호출 없이(파일 읽기 없이) 전역 GEMINI.md 제목을 답하면 컨텍스트에 주입된 것
timeout 180 agy --add-dir "$WORKDIR" --model "$MODEL" --output-format stream-json \
  -p='You were given one or more global instruction/rules files in your context. For each of them, quote its first markdown heading (the line starting with #) verbatim, one per line. Do not use any tool. Output only those lines.' \
  > "$WORKDIR/rules.ndjson" 2>"$WORKDIR/rules.err"; RULES_RC=$?
TOOLS_USED="$(jq -s '[.[] | select(.event=="step_update") | .step_update | select(.step_type=="tool")] | length' "$WORKDIR/rules.ndjson" 2>/dev/null || echo "?")"
RULE_TXT="$(jq -r 'select(.event=="result") | .result.response // empty' "$WORKDIR/rules.ndjson" 2>/dev/null)"
if (( RULES_RC != 0 )) || [[ -z "$RULE_TXT" ]]; then echo "판정불가 [rules] agy 종료 코드 $RULES_RC 또는 result 이벤트 없음"; UNDET=$((UNDET+1))
elif [[ "$TOOLS_USED" != "0" ]]; then echo "판정불가 [rules] 모델이 도구를 ${TOOLS_USED}건 사용 — 주입 여부 구분 불가"; UNDET=$((UNDET+1))
elif grep -q "Antigravity 작업 지침" <<<"$RULE_TXT" && grep -q "크로스툴 공용 지침" <<<"$RULE_TXT"; then echo "PASS [rules] 전역 GEMINI.md·AGENTS.md 주입 (도구 호출 0건 — 간접 관측)"; PASS=$((PASS+1))
else echo "FAIL [rules] 전역 GEMINI.md·AGENTS.md 제목 중 누락: $(tr '\n' ' ' <<<"$RULE_TXT" | head -c 160)"; FAIL=$((FAIL+1)); fi

echo "────────────────────────"
echo "합계: $PASS PASS / $FAIL FAIL / $UNDET 판정불가 (모델 호출 6회)"
[[ $FAIL -eq 0 && $UNDET -eq 0 ]]
