# Claude Opus 5 조사 원문 (2026-08-13)

> 조사 주체: 서브에이전트 3개 (공식 문서 / Claude Code·SDK 실무 / 커뮤니티)
> 소스 신뢰도: platform.claude.com·anthropic.com/news·code.claude.com·SDK CHANGELOG·HN 원문·Simon Willison·Zvi·Snorkel AI = 1차. Reddit은 크롤러 차단으로 전건 2차 요약(explainx 등). 시스템 카드 PDF는 10MB 초과로 미열람 — ASL 등급은 검색 요약 기반. Artificial Analysis·LMArena 수치는 SEO 블로그 집계(2차) — 인용 전 원 리더보드 재확인 필요.
> 에이전트 보고 전문: `.claude/scratch/opus5-report-{official,practical,community}.md`

## 1. 모델 개요 · 스펙

- **2026-07-24 GA**. ID `claude-opus-5` (날짜 접미사 없음). Bedrock `anthropic.claude-opus-5`, Google Cloud·Foundry·Claude Platform on AWS는 접두사 없음 — 4개 플랫폼 전부 제공
- 포지셔닝: "For complex agentic coding and enterprise work". Opus 4.8 대비 "step-change improvement"(deep reasoning·agentic·long-horizon·test-time compute scaling), **Fable 5의 프런티어 지능에 근접하면서 가격 절반**. Claude Pro 최강 모델·Claude Max 신규 기본
- 스펙: 컨텍스트 1M(기본=최대), 최대 출력 128K(동기) / **300K(Batch API, `output-300k-2026-03-24` 베타)**, 신뢰 지식 컷오프 **2026-05**(4.8은 2026-01), 토크나이저 4.7 세대 동일
- 가격(/1M): **$5/$25 (Opus 4.8 동가)**. 캐시 쓰기 $6.25(5m)/$10(1h), 읽기 $0.50. Batch 50% 할인. Fast mode $10/$50(2배, 출력 ~2.5배, Claude API 전용 research preview)
- Fable 5의 30일 데이터 보존 강제 같은 제약 없음. **별도 레이트리밋 버킷**(Opus 4.x 합산 풀과 분리)

## 2. API 변경 (Opus 4.8 대비)

- **파괴적 변경 2건**: ① `thinking` 생략 시 **adaptive thinking이 기본 실행**(4.8은 사고 없음) — `max_tokens`가 사고+응답 합산 하드 리밋이라 재검토 필수 ② `thinking: disabled`는 **effort `high` 이하에서만** — `xhigh`/`max` 조합은 400, 요청 단위 검증
- sampling(`temperature`/`top_p`/`top_k`)·마지막 assistant prefill 400은 4.7 이후와 동일(신규 변경 없음)
- effort 5단계(`low`~`max`), API 기본 `high`. 공식: "Start with `high` ... use `low` and `medium` liberally as your primary control" — **4.7/4.8의 `xhigh` 시작 권고와 방향이 다름**. 구모델 effort 설정 재사용 금지, 스윕 재실행. `xhigh`/`max` 시 `max_tokens` 64K+
- 신규 베타: **`fallbacks: "default"`**(`server-side-fallback-2026-07-01` — 거절 카테고리별 권장 폴백 자동, 구형 `-06-01`은 배열만), **대화 중 도구 변경**(`mid-conversation-tool-changes-2026-07-01` — `tool_addition`/`tool_removal` 블록+`defer_loading`, 캐시 보존)
- 프롬프트 캐시 최소 **512 토큰**(4.8은 1,024)
- **미지원 주의**: web fetch 도구(마이그레이션 체크리스트+도구 문서 교차 확인), Priority Tier(신규 약정 판매 자체 중단)
- 안전: 사이버 분류기 탑재, 거절은 HTTP 200 + `stop_reason: "refusal"` — content 읽기 전 확인. 소스 코드 취약점 탐색 허용 / 바이너리 스캐닝·침투 테스트·익스플로잇 작성 차단(→ Opus 4.8 폴백). Cyber Verification Program으로 완화판 접근 가능

## 3. 프롬프팅 가이던스 (전용 가이드 존재)

- 1차 소스: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 — 전제는 "4.8 프롬프트로 잘 동작", 조정 필요 행동만 다룸
- **검증 스캐폴딩 삭제**(핵심·통념 역전): 스스로 검증하므로 "verify"/"double-check"/"use a subagent to verify" 지시는 과잉 검증 유발 — 고쳐 쓰지 말고 **삭제**. 하네스 검증 단계도 동일. 모델 외부 검증(테스트·승인 게이트)은 유지
- **서브에이전트 위임 억제**(4.8과 정반대): 4.8용 "더 위임하라" 지침 제거, 스폰 수 상한 명시
- **장황함은 effort로 못 잡음**: effort는 사고량만 조절. 응답·산출물 길이는 프롬프트로 별도 지시(산출물 분량 제약 따로)
- 범위 규율: 요청 범위 밖 확장 방지 지시, 자기 수정 내레이션 축소 지시, 코드 리뷰는 "전부 보고+별도 필터"(심각도 필터를 문자 그대로 따라 recall 하락)
- thinking 끄면 결함 2종(도구 호출 평문 유출·`<thinking>` 태그 유출) — "thinking 켠 채 `low` effort가 비슷한 비용에 더 나음"이 공식 완화책
- **컨텍스트 감량("unhobbling")**: Anthropic이 Opus 5·Fable 5용 Claude Code 시스템 프롬프트 80%+ 삭제, 평가 손실 없음. 처방 "얇은 프롬프트, 두꺼운 아티팩트, 얇은 스킬" (claude.com/blog context engineering)

## 4. Claude Code · SDK · 플랫폼

- Claude Code **v2.1.219+**: `opus` 별칭의 기본 Opus(전체 기본은 Sonnet 5), fast mode 기본 모델. effort 기본 `high`, 구모델과 달리 최초 실행 시 effort 강제 hold 없음 — **이전 설정이 그대로 승계되므로 구식 고정값 확인 필요**
- 자동 폴백: Opus 5 사이버 플래그 → Opus 4.8 재실행, 생물학 플래그는 폴백 없이 거부(자체 분류기)
- SDK 최소: Python **0.120.0** / TS **0.115.0** (2026-07-24). session budgets·advisor·inference_geo는 0.121.0/0.116.0 (2026-08-07)
- 플랫폼 기능 차: fast mode·서버사이드 fallbacks·Models/Batches API·advisor·Managed Agents는 **Claude API 전용**. Foundry는 Azure 호스팅 배포에서 구조화 출력·서버 도구·MCP·Files API 미지원(설계상 400). Claude Code `opus` 별칭이 Foundry에선 아직 Opus 4.6
- 공식 선택 기준: "확신 없으면 Opus 5부터". Fable 5는 최고 역량 필요 시만. "Tuning effort is often a better lever than switching models"

## 5. 커뮤니티 평판 (출시 ~3주)

- **벤치마크와 실사용 평판이 정면으로 갈림**. 벤치: Snorkel(1차) Senior SWE-bench 28.2%(4.8 25.0%, GPT-5.6 Sol 24.4%), 디버깅 85% vs Sol 5%. AA Intelligence Index 1위(63.0%, Fable 62.1%) — 단 2차·미확인. LMArena는 Fable 1위로 갈린다는 집계(2차)
- 실사용 최다 불만은 성능이 아니라 **장황함·말투**("Claude Slop", "neurotic", "unusably annoying") + **과잉 확장**(요청 밖 전면 재구축, 자기 확장 브리프 구현, "paranoid over-engineering mess"). 4.8은 "usually good at asking for clarification"이었다는 대비
- 개선 컨센서스: **거부율 급감** — GPQA 거부율 Opus 5 0% vs Fable 5 42%(Vals AI, Zvi 인용). Fable 오탐 심한 생물학·보안 인접 주제의 우회 경로로 활용
- 실사용 요령 컨센서스(공식과 수렴): effort `high` 시작·`low`/`medium` 적극, 검증 지시 삭제, 위임 상한, 백지 프롬프트가 레거시 누적보다 나음("기존 프롬프트가 기본 동작에 **누적**되어 증상 2배"), git 커밋 안전망, `ultracode` 조합 경고
- 기타 이슈: 출시 직후 인프라 불안정(HN "Elevated Errors", 1.5h 장애 보고), 비용 증가 체감(단가 동일하나 토큰 3배 구조 — Sol 31K vs Opus 5 93K 출력), 과신·조기 완료 선언, 과잉 사과 성격

## 6. 모델 분업 (커뮤니티 컨센서스)

- 기준은 **"제약의 유무"**: Opus 5 = 제약 있는 작업(스펙·버그 수정·범위 정해진 리팩토링). Fable 5 = 열린 작업(아키텍처·대규모 마이그레이션·수일 자율 실행). 한 줄: "초기 계획의 품질이 실행 비용보다 중요할 때만 Fable"
- Zvi 3분할: Fable 5 = 지능 집약(대화·감독·글쓰기) / GPT-5.6 Sol = 검색·범용·전사 / Opus 5 = 잘 정의된 코딩·범위 한정 작업·분류기 회피
- 품질 체감은 여전히 Fable 우위("feels considerably smarter"), 반대 유인은 가격 절반+거부율
- Mythos 5 급은 아님: 취약점 발견은 근접하나 익스플로잇 전환은 의도적으로 뒤처지게 설계(Zvi·OSS-Fuzz 평가)

## 7. 기존 자료와의 차이 (반영 필요)

- claude-api 스킬 캐시(2026-06-24)와 상충: **web fetch를 Opus 5 지원으로 기술(실제 미지원)**, web fetch 신버전(`20260309`/`20260318`) 미반영, Sonnet 5 도입가 $2/$10 정가 확정(인상 미시행), effort 권장이 `xhigh` 뉘앙스(실제는 `high` 시작)
- claude-5-fable-prompt-guide.md의 비교 축이 "Opus 4.8 대비"로 한 세대 밀림 — Fable 5 fallback 대상도 Opus 5 등장으로 갱신 여지

## 미확인 항목

- 시스템 카드 PDF 미열람(10MB 초과) — ASL-3 배포·CB-1/CB-2·사이버 역량 서술은 검색 요약 기반, 확정 인용 금지
- 발표문 세부(라이프사이언스·법률·트레이딩, "안전장치 개입 85% 감소") — WebSearch 요약만, 본문 축자 미확인
- AA·LMArena·SWE-bench Pro·Frontier-Bench 수치 — 2차 집계, 원 리더보드 미확인
- Claude Agent SDK의 Opus 5 대응 릴리즈 — 미조사
