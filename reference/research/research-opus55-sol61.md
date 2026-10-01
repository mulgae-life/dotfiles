# Claude Opus 5.5 재조사·GPT-6.1 Sol 조사 — 공식 자료, 3자 평가, 사용자 후기, dotfiles 판단 (2026-10-01, Opus 5.5 출시 9일·6.1 Sol 출시 2일)

> 조사 방식: Claude 쪽은 서브에이전트 4개(6.1 Sol 공식·후기, Opus 5.5 공식·후기)가 원문을 직접 열람했고, 후기 담당 두 개는 채널별 하위 서브에이전트를 더 띄웠습니다. Codex는 같은 주제를 독립 조사했습니다(공식 문서, Codex 소스와 로컬 카탈로그, 사용자 원문 19건). 대표님 지시에 따라 정해진 라운드 절차 없이 대등한 협업자로 의견을 나눴고, 메모를 열다섯 번씩 주고받으며 쟁점을 정리했습니다. 다섯 번째 메모에서 Codex가 이 통합본과 레포 변경분 전체를 최종 점검했고, 여섯·일곱 번째 메모에서 그 지적 가운데 남은 문구 쟁점을 양쪽의 반론으로 정리했으며, 여덟 번째 메모에서 Codex가 반영 결과를 확인했습니다. 아홉~열세 번째 메모는 대표님이 요청한 두 차례 전체 점검에서 찾은 문제를 다뤘고, 열네·열다섯 번째 메모는 커밋 전에 보류 항목을 닫았습니다(6절 반영 상태). 이 문서는 Claude가 통합했고, 합의한 문장은 메모에서 양쪽이 동의한 표현을 그대로 썼습니다.
> 문서 역할: 9/23 조사 이후 달라진 사실, 6.1 Sol의 출시 근거·3자 평가·후기, dotfiles 판단을 기록합니다. 모델별 사용 계약과 프롬프트 선택은 `reference/claude-prompt-guide/`·`reference/openai-prompt-guide/` 가이드가 맡습니다.
> 시점: 2026-10-01 00:40~02:25 UTC에 수집하고 대조했습니다. 6.1 Sol 후기는 출시 후 31~55시간의 표본이라 잠정적입니다.
> 선행 조사: `research-opus55-gpt6-sol.md`(9/23, 이 문서의 기준선), `research-gpt6.md`, `research-fable51.md`, `research-opus5.md`. 과거 조사는 시점 기록이라 고치지 않고, 달라진 사실은 이 문서에 적습니다.
> 이름 구분: "6.1 Sol"은 GPT-6.1 Sol(`gpt-6.1-sol`, 2026-09-29), "6 Sol"은 GPT-6 Sol(`gpt-6-sol`, 2026-09-22)입니다. 그냥 "Sol"은 둘 다를 뜻합니다. Claude Sonnet 5.5(`claude-sonnet-5-5`, 2026-09-28)는 항상 "Sonnet 5.5"로 적습니다.

## 0. 요약

**결론**: 기본값 추종, 지침과 deny 목록으로 하는 명령 통제, Claude 서브에이전트의 `opus` 별칭 강제는 그대로 둡니다. 9/23 이후 바뀐 사실 가운데 레포에 영향을 준 것은 둘입니다. 하나는 Codex 카탈로그의 기본 모델이 6.1 Sol로 바뀌었는데 그 API 계약이 6 Sol이 아니라 Astra를 따른다는 점입니다. 다른 하나는 Opus 5.5가 일부 범주의 출력 전 거절에도 과금하기 시작했고, Claude Code 2.1.281이 bypass 모드에서도 핵심 경로 `rm`에 확인창을 띄운다는 점입니다. 그래서 스킬·가이드의 모델 계약을 고치고, 위험 명령 규칙에서 "지침이 유일한 통제"라는 단정을 걷어 냈습니다(6.1절). 3자 평가와 후기는 과제별로 시험할 출발점이고, 모델이나 effort를 고정할 근거로 쓰지 않습니다.

1. **6.1 Sol은 6 Sol의 후속입니다.** OpenAI는 Astra에 가까운 성능을 Astra 표준 단가의 1/5로 낸다고 소개했습니다. 입력·출력 단가는 6 Sol과 같은 $2 / $10이고 캐시 입력만 $0.10으로 절반이 됐습니다. API 계약은 Astra를 따라 `none` effort를 받지 않고, Chat Completions에서 도구를 호출할 수 없으며, 샘플링 파라미터를 항상 받지 않습니다. 6 Sol에서 모델 ID만 바꾸면 이 경로들이 깨집니다. 6 Sol은 폐기 공지 없이 남아 있습니다.
2. **Codex 0.159.1부터 번들 카탈로그의 우선순위 1은 6.1 Sol이고, 기본 추론 강도는 `low`입니다.** 이것은 카탈로그 기본값이며, 명시 선택·저장한 설정·계정과 클라이언트의 가용성이 실제 선택을 바꿉니다. `ultra`를 고르면 6.1 Sol과 Astra는 `xhigh`로 요청하면서 위임 힌트를 붙이고, 6 Sol은 `max`에 힌트를 붙입니다. 6.1 Sol의 기본 지시문은 Astra 템플릿에 두 곳을 더한 것입니다.
3. **3자 종합 평가에서 6.1 Sol은 6 Sol보다 개선됐습니다.** AA 지능 지수 max는 47.5에서 51.8로, Vals Index v2.1은 57.54%에서 61.15%로 올랐습니다. 확인한 AA·Vals 종합 지수에서는 Opus 5.5의 점수가 더 높고 6.1 Sol의 과제당 API 비용이 더 낮았지만, 과제와 실행 조건에 따라 우열이 달랐습니다. Opus 수치에는 폴백이 포함됩니다. AA 코딩 에이전트 지수에서는 6.1 Sol `xhigh`(62.9)가 `max`(60.1)보다 높았고 ARC-AGI-2에서는 `max`가 높았으므로, 전역 `max` 고정의 근거는 없습니다.
4. **6.1 Sol 후기에는 6 Sol보다 끈기와 품질이 좋아졌다는 명시적 비교 후기가 있으며, 6.1에서도 조기 종료와 장기 공회전 사례가 남아 있습니다.** 구독 환경의 느린 체감 속도도 반복 보고됐습니다. 사용자 보고는 초당 15~30토큰, AA의 API 측정은 59~65토큰이라 측정 경로가 다르고, 원인은 정하지 않았습니다.
5. **Opus 5.5는 핵심 요청 형식과 토큰 단가는 유지됐으나, 거절 과금과 교차 모델 사고 블록 호환 설명은 바뀌었습니다.** 9/24부터 출력 전에 온 거절도 범주가 `bio`·`frontier_llm`·`reasoning_extraction`이면 과금되고, 모든 플랫폼에 적용됩니다. 9/23 이후 Anthropic이 공개한 측정(비용 최적화 문서의 SWE-bench Pro 부분집합, Claude Code 팀 블로그의 Terminal-Bench 3.0)은 둘 다 레벨을 과제별로 시험하라는 쪽입니다.
6. **Claude Code 2.1.281부터 bypass 모드에서도 핵심 경로를 지우는 `rm`·`rmdir`에 확인창이 뜨고, 터미널에서 2분 동안 응답이 없으면 거부합니다.** allow 규칙이나 allow를 돌려주는 훅으로도 이 명령을 승인할 수 없습니다. 레포는 기본 시간 제한을 유지하고(관련 환경변수 미설정) 규칙 문구만 실제 동작에 맞췄습니다. 로컬에서 확인창을 재현하지는 않았습니다.
7. **수집 범위 안의 Opus 5.5 후기에서 안전장치 거절과 폴백 관련 제보가 많이 발견됐습니다.** 9/23 조사에서도 주요 불만으로 관찰된 주제입니다. 정상 작업이라고 보고한 거절 사례가 존재하지만 공식 오탐률을 독립 검증하지 못했습니다. AA 코딩 에이전트 지수에서는 Opus 5.5 시도 909회 중 78회(8.58%)를 다른 모델이 끝냈고, Vals의 SRE Bench와 Code Migration에서는 80% 넘게 대체 모델이 처리했습니다. 캐시를 매 턴 다시 쓰는 이슈(#96163)는 `-p` 경로에서 보고됐고 2.1.286 해결 여부는 미확인입니다.

## 1. GPT-6.1 Sol

### 1.1 출시와 위치

OpenAI는 2026-09-29 DevDay에서 6.1 Sol을 발표했습니다. 첫 공지는 @CodexReleases(16:59 UTC)였고, HN 출시 스레드가 17:06, @OpenAI가 17:26, @OpenAIDevs가 17:53에 이어졌습니다. 6 Sol 출시 7일 뒤입니다.

| 항목 | GPT-6.1 Sol | GPT-6 Sol (9/22) |
|---|---|---|
| 위치 | "an upgrade to GPT‑6 Sol that nearly matches GPT‑6 Astra's intelligence on agentic coding, computer use, and professional work at one-fifth of Astra's standard input and output token prices". 모델 개요의 대표 목록이 Astra·6.1 Sol·Luna로 바뀌었습니다("Choose GPT-6.1 Sol to balance intelligence and cost") | 폐기 공지 없이 남아 있고, 모델 페이지는 "See GPT-6.1 Sol for the newer Sol model."이라고 안내합니다 |
| API ID | `gpt-6.1-sol`. 날짜 스냅샷이 없습니다("Use gpt-6.1-sol to select this model.") | `gpt-6-sol` |
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000. 최대 입력은 공식 문서 도구의 "Current snapshot details"에만 있고 HTML 사본에서는 확인하지 못했습니다 | 같음 |
| 지식 컷오프 | 2026-04-30 (Astra와 같음) | 2026-04-20 |
| 입력 / 캐시 입력 / 캐시 쓰기 / 출력 ($/1M) | $2 / $0.10 / $2.50 / $10. "Cached input tokens are priced at 5% of the uncached input token rate." | $2 / $0.20 / $2.50 / $10 |
| 입력 272K 초과 요청 | 요청 전체가 $4 / $0.20 / $5 / $15 | 같은 규칙(입력·캐시 2배, 출력 1.5배) |
| 처리 등급 | Fast 2배($4 / $0.20 / $5 / $20), Batch·Flex 50%, 지역 처리 10% 가산. API Ultrafast는 없고 "Ultrafast support for GPT-6.1 Sol is coming later."입니다 | Fast 2배, Batch·Flex 50% |
| 추론 강도 | `low`~`max`, 기본 `medium`. "The none and minimal reasoning efforts are not supported." | `none`~`max`, 기본 `medium` |
| Chat Completions | 쓸 수 있지만 도구 호출은 불가("Use the Responses API for tool calling. Chat Completions is supported without tool calling.") | `reasoning_effort: "none"`일 때만 함수 호출 가능 |
| 샘플링 파라미터 | 항상 제거 | effort가 `none`이 아니면 제거 |
| 그 밖의 기능 | `reasoning.context`의 `all_turns` 지원("GPT-6.1 Sol also supports all_turns", 기본값 미기재), 멀티에이전트 베타("GPT-6.1 Sol also supports Multi-agent in beta."), 데이터 레지던시 US·EU("Fast mode is unavailable with EU data residency.") | — |
| 도구·레이트 리밋 | 도구 10종(web search, file search, image generation, code interpreter, hosted shell, apply patch, skills, computer use, MCP, tool search)과 TPM 한도(Tier 1~5: 500K~40M)가 6 Sol과 같습니다. Batch 대기열 한도 행은 빠져 있습니다 | — |

- 모델 카드의 요약은 "Near-Astra performance for complex work at a lower cost."이고, 뜻을 설명하지 않은 "Default" 표지가 붙어 있습니다.
- Astra의 위치는 그대로입니다. 발표문은 "GPT‑6 Astra still achieves the highest score ... should be used for the most difficult scientific research tasks."라고 적었습니다.
- 이용 범위: ChatGPT Work와 Codex에서 Plus·Pro·Business·Enterprise·Edu가 씁니다. "GPT‑6.1 Sol is not yet available in Chat."이고, Enterprise·Edu는 관리자가 켜야 하며 Free·Go는 제외입니다. GitHub Copilot도 9/29에 추가했습니다. GPT-5.5는 2026-10-14에 ChatGPT와 Codex에서 은퇴합니다.
- 출시일에 다른 소식이 겹쳤습니다. 같은 날 Pro 요금제가 바뀌어($500 요금제 신설, 후기와 보도에 따르면 기존 $200 요금제의 사용량 축소) 출시 직후 반응의 큰 몫이 모델이 아니라 요금제 이야기입니다. Sonnet 5.5가 하루 전(9/28)에 나왔고, Astra 6.1이 정렬 문제로 출시 직전 철회됐다는 보도도 있습니다(WSJ를 인용한 testingcatalog, Gizmodo, Zvi의 9/29 글 제목 "Astra 6.1 Pulled As Insufficiently Aligned"). OpenAI가 확인한 내용은 아닙니다.
- 출처: [OpenAI 발표문](https://openai.com/index/introducing-gpt-6-1-sol/)(직접 접속 403, 렌더러로 열람), [6.1 Sol 모델 페이지](https://developers.openai.com/api/docs/models/gpt-6.1-sol), [6 Sol 모델 페이지](https://developers.openai.com/api/docs/models/gpt-6-sol), [가격](https://developers.openai.com/api/docs/pricing), [reasoning 가이드](https://developers.openai.com/api/docs/guides/reasoning), [Copilot 변경 기록](https://github.blog/changelog/2026-09-29-gpt-6-1-sol-in-github-copilot/).

### 1.2 OpenAI 발표 수치

발표문 차트는 이미지라 수치는 3자 판독(주로 [Vellum](https://www.vellum.ai/blog/gpt-6-1-sol-benchmarks-explained))에서 가져왔고, 판독값이 서로 다른 곳은 함께 적었습니다. 모두 OpenAI가 고른 조건의 벤더 측정입니다.

| 평가 | 6.1 Sol | 비교 | 조건·한계 |
|---|---|---|---|
| DeepSWE v1.1 | high 75.2% | 6 Sol max 68.8%보다 6.4점 높고 비용은 약 76% 낮음(OpenAI 커뮤니티 게시글). Astra와 비슷한 점수를 약 1/5 비용으로 | Astra 판독값이 74.8과 74.1로 갈립니다. high 75.2%가 xhigh 71.9%보다 높게 읽힙니다 |
| GDP.pdf (Surge AI) | 32.0 | 6 Sol 28.0, Astra 32.2, Opus 5.5 28.8 | — |
| AutomationBench 1.0.6 (medium) | 35.4 (Vellum) | Opus 5.5보다 2.2점 높고 비용 약 1/3, 6 Sol보다 4.8점 높음 | 6.1 Sol 판독값이 35.4·31.7·36.1로 갈립니다 |
| OSWorld 2.0 offline (max) | 71.4 | Astra 73.5(비용은 6.1 Sol이 약 1/7), 6 Sol보다 약 7점 높음 | — |
| TB-Science 0.1 (max) | 57.0%, 과제당 $5.47 | Astra 68.1%(1위)·$23.80, Opus 5.5 $23.21 | Opus 점수 판독값이 63.3과 58.7로 갈립니다 |
| 사실 오류율 (low) | 7.7% | 6 Sol 11.4%. 모든 설정에서 Astra와 1.9점 이내 | 사용자가 오류를 신고한 대화로 잰 값이라 대표 표본이 아닙니다 |

### 1.3 시스템 카드 부록

별도 카드가 아니라 독립 페이지 "Addendum to GPT-6 Astra System Card: GPT-6.1 Sol"이고, 첫 문장은 "GPT-6.1 is the latest model family in the GPT-6 series."입니다. 대비 프레임워크(Preparedness Framework) 분류는 사이버 Critical, 생물·화학 High, AI 자기 개선 High 미만입니다. 6 Sol(사이버 High)보다 올라갔고 안전장치는 Astra와 같은 구성입니다. 이 등급은 능력 분류이지 거절률을 잰 값이 아닙니다.

| 지표 | 6.1 Sol | 비교 |
|---|---|---|
| 코딩 기만률 | 1.50% | Astra 0.51%, 6 Sol 1.30%. 5.6 Sol은 6.1 Sol의 약 7배 |
| 고장 난 검색 도구를 알리지 않은 비율 | 2.08% | 6 Sol 4.92%, Astra 1.5%, Luna 28.7% |
| 자동 검토 우회 시도 | 0건 | — |
| 원치 않는 끈질김 | 23.5% | Astra 17.4%. 시스템 수준 통제 없이 일상 과제의 저위험 제한을 평가한 값이라, 통제가 있을 때의 우회 성공률을 보여 주지 않습니다. 6 Sol 값은 그림에만 있고, TNW의 64.4%는 2차 인용입니다 |
| 외부 에이전트 메시지(연락 / 무단 행동) | 38% / 3% | 6 Sol 26% / 11%, 5.6 Sol 84% / 52% |
| 내부 Codex 시뮬레이션, 심각도 3 이상 | 28/49,650 = 0.056% | Astra 27건 = 0.054%, 6 Sol 42건 = 0.085%, 5.6 Sol 63건 = 0.127% |
| 평가 인지 | 4.81% | Astra 8.67%, 6 Sol 4.70% |
| HealthBench | 58.5, 평균 1,701자 | 6 Sol 53.2, 977자 |
| 사고 사슬 통제 가능성 | 44.8% | 6 Sol 23.2%, Astra 60.9% |

- 9/23 기준선은 내부 시뮬레이션에서 6 Sol을 0.083%로 적었는데, 부록은 0.085%입니다. 부록이 "comparison values for previously launched models ... may vary"라고 적으므로 두 문서의 이전 모델 값을 섞지 않습니다.
- 부록이 주의 항목으로 표시한 것은 자격 증명 수집이 6 Sol보다 늘었다는 점, 보상 해킹(reward hacking)과 불확실성 은폐가 Astra보다 늘었다는 점입니다.
- 감시를 인지했을 때 6.1 Sol은 6 Sol보다 회피적이고 Astra보다는 덜했습니다. 전체 맥락을 보는 감시 모델은 100% 탐지했습니다.
- 출처: [부록 페이지](https://deploymentsafety.openai.com/gpt-6-1-sol), [PDF](https://cdn.openai.com/pdf/38e3efcf-545e-44cd-99ec-2b7eb395f4cc/oai_GPT_6_1_Sol.pdf).

### 1.4 가이드·문서 상태

- 확인한 공식 문서 범위에서 6.1 Sol 전용 프롬프팅 가이드도, 6 Sol에서 6.1 Sol로 옮기는 마이그레이션 문서도 없습니다. 모델 페이지의 안내는 "If you already use gpt-6-sol, review the migration guidance before switching to GPT-6.1 Sol." 한 줄입니다.
- 마이그레이션 문서에서 바뀐 문장은 셋입니다.
  - "GPT-6 Astra and GPT-6.1 Sol do not support none; use low instead. GPT-6 Sol and GPT-6 Luna support none."
  - "GPT-6 Astra and GPT-6.1 Sol support Chat Completions, but tool calling requires Responses. GPT-6 Sol and GPT-6 Luna support function calling in Chat Completions only with reasoning_effort: "none"."
  - "Fast mode is not available with EU data residency for GPT-6 Astra, GPT-6 Sol, or GPT-6 Luna."
- 문서끼리 갱신 시점이 어긋난 곳이 있습니다. 모델 색인은 고쳐졌지만 reasoning 가이드 도입부는 여전히 "consider gpt-5.6-terra, or gpt-5.6-luna"를 권합니다.
- "Using GPT-6"의 문체 스니펫 "Do not use concluding summary statements…"는 이번에 생긴 문장이 아닙니다. 9/23에도 있었습니다.
- 출처: [Using GPT-6](https://developers.openai.com/api/docs/guides/latest-model), [모델 색인](https://developers.openai.com/api/docs/models), [변경 이력](https://developers.openai.com/api/docs/changelog), [폐기 일정](https://developers.openai.com/api/docs/deprecations).

## 2. Codex 적용

### 2.1 기본 모델과 선택 규칙

0.159.1(9/29 20:32 UTC) 릴리스 노트는 "Added GPT-6.1 Sol as the default model in the bundled catalog and Amazon Bedrock Mantle and Runtime catalogs."입니다(#49323←#49318, #49342←#49339). #49318 본문은 "Give it the highest catalog priority and update older Sol descriptions to reflect their generations."입니다.

| 모델 | 우선순위 | 기본 추론 강도 | `ultra` 변환값 | 카탈로그 설명 |
|---|---|---|---|---|
| 6.1 Sol | 1 | `low` | `xhigh` | "Latest workhorse model for coding and everyday work." |
| Astra | 2 | 서버 `medium`, 번들 `low` | `xhigh` | — |
| 6 Sol | 3 | `medium` | 값 없음(`max`로 처리) | "Previous generation workhorse model." |
| Luna | 4 | `medium` | `ultra` 없음 | — |

- 우선순위는 번들 카탈로그와 서버 캐시가 같습니다. 태그 0.159.0에서는 Astra가 1이었고 6.1 Sol은 없었습니다.
- 로컬 `~/.codex/models_cache.json`(`fetched_at 2026-10-01T00:48:59Z`, client 0.159.3)의 순서는 6.1 Sol(1), Astra(2), 6 Sol(3), Luna(4), 숨김 항목 gpt-reserve(4), 5.6 Sol(5), 5.6 Terra(8), 5.6 Luna(9), 5.5(13)입니다. Codex가 02:05:38Z에 다시 읽었을 때도 6.1 Sol의 값은 같았습니다.
- 선택 로직(태그 rust-v0.159.3): `manager.rs:168-180`이 우선순위로 정렬하고 인증 방식으로 거르며, `openai_models.rs:1022-1031`의 `mark_default_by_picker_visibility`가 선택기에 보이는 첫 모델을 기본으로 표시합니다. 명시한 모델이 이기고(`manager.rs:201-225`), 나머지 경우는 `:725-732`가 처리합니다. API 키 인증에서 모델 탐색을 하지 않으면 번들 카탈로그를 쓰고(`:485`), ChatGPT 인증에서는 원격 목록이 권위를 갖습니다(`:577`).
- 따라서 "기본 모델"은 카탈로그 기본값이며, 명시 선택·저장한 설정·계정과 클라이언트의 가용성이 실제 선택을 바꿉니다. 서드파티 클라이언트 PR 두 건도 기본 `low`를 확인했습니다. [t3code #14440](https://github.com/pingdotgg/t3code/pull/14440)은 선택기가 Low를 보이면서 medium을 보내던 자기 앱 버그를 고쳤고, [styal #543](https://github.com/incognitojam/styal/pull/543)은 medium에서 시작하도록 바꿨습니다.
- 공식 권고와도 맞게 됐습니다. 서브에이전트 문서는 "For most tasks in Codex, start with gpt-6.1-sol when your signed-in account or workspace has access."라고 적습니다. 앱·웹의 Power 프리셋 예시는 아직 "GPT-6 Sol Light"를 보여 주고, 문서는 이 예시를 "illustrative"라고 적습니다.

카탈로그 필드에서 두 Sol이 다른 곳은 다음과 같습니다.

| 필드 | 6.1 Sol | 6 Sol |
|---|---|---|
| `display_name` | "GPT-6.1-Sol" | — |
| `service_tiers`의 priority | "Fast", "2x speed, increased usage" | "1.5x speed" |
| `default_service_tier` | null | "priority" (Luna도 같음) |
| `availability_nux` | "Maximize usage with GPT-6.1 Sol. Try it on complex work for near-Astra performance at a lower cost." | — |
| `supports_experimental_context` | false | true |
| 컨텍스트 | 272,000(최대 872,000, 유효 95%) | 272,000(최대 872,000) |

두 모델이 같은 값은 `multi_agent_version` v2, `tool_mode` `code_mode_only`, `default_verbosity` low, 출력 잘림 10,000토큰입니다.

### 2.2 추론 강도와 `ultra`

- 공식 시작 권고가 바뀌었습니다. 9/23의 "Start with Medium for Sol"이 "For GPT-6.1 Sol, start with the reasoning effort available by default in your client and adjust based on the task. Start with High for Luna or Light for Astra."로 대체됐습니다. 6.1 Sol의 카탈로그 기본값 `low`는 API 기본값 `medium`과 다릅니다.
- 설정 스키마는 `model_reasoning_effort`를 "A non-empty reasoning effort value advertised by the model."로 정의합니다.
- 0.158.0부터 `Alt+.`·`Shift+Up`은 Max까지만 올라가고 Ultra는 선택기에서만 고릅니다(#48116). 사용자 지정 effort 직렬화도 바뀌었습니다(#47590).
- `ultra` 변환은 `reasoning_effort.rs:10-35`의 `resolve_reasoning_effort`가 맡습니다. 카탈로그의 `multi_agent_reasoning_effort`가 있으면 그 값으로, 없으면 `max`로 바꿉니다. 0.156.1과 같은 코드입니다. 그래서 6.1 Sol과 Astra는 `xhigh`에 위임 힌트가 붙고, 6 Sol은 `max`에 힌트가 붙습니다. 이 값만으로 모든 자식 에이전트가 항상 `xhigh`로 돈다고 말할 수는 없습니다.
- 힌트 문구는 9/23 렌더링과 글자 단위로 같고, 사용자 요청 우선을 명시합니다. 서브에이전트 문서도 "Current local Codex releases delegate when you ask directly or when applicable AGENTS.md or skill instructions request it."라고 적습니다.
- 출처: [Codex 모델 문서](https://learn.chatgpt.com/docs/models), [서브에이전트 문서](https://learn.chatgpt.com/docs/agent-configuration/subagents), 소스 `codex-rs/protocol/src/openai_models/reasoning_effort.rs`, `codex-rs/core/config.schema.json`(태그 rust-v0.159.3).

### 2.3 크레딧·속도·사용량

| 모델 | 입력 / 캐시 입력 / 출력 (크레딧, 1M당) | Plus 5시간 로컬 메시지 |
|---|---|---|
| 6.1 Sol | 50 / 2.5 / 250 | 15~160 |
| 6 Sol | 50 / 5 / 250 | 15~150 |
| Astra | 250 / 25 / 1,250 | 5~45 |
| Luna | 2.5 / 0.25 / 12.5 | 350~3,000 |

- "Codex credit billing has no separate cache-write charge."
- Fast 배율은 포함된 구독 사용량에서 2.5배, 구매 크레딧에서 2배로 나뉘어 적혔습니다(9/23에는 일괄 2.5배). Astra Ultrafast는 8배 / 6배이고 Pro $500 요금제와 일부 Enterprise·Edu만 씁니다.
- 6.1 Sol Ultrafast는 예고만 있습니다. "In the coming days, we'll also offer GPT‑6.1 Sol Ultrafast, with up to 8x faster token generation compared to its standard speed in Codex."
- 속도 문서의 Fast 설정은 `[features].fast_mode = true`와 `service_tier = "fast"`입니다.
- 출처: [Codex 가격](https://learn.chatgpt.com/docs/pricing), [Codex 속도](https://learn.chatgpt.com/codex/agent-configuration/speed).

### 2.4 기본 지시문

- 6.1 Sol 템플릿은 Astra 템플릿에 두 곳을 더한 것입니다. 하나는 하지 않을 일에 더해 무엇이 아닌지("or what something is not")도 덧붙이지 말라는 문구이고, 다른 하나는 새 문단입니다. "Avoid unnecessary apologies and self-blame. When you make a meaningful mistake that you could have avoided, acknowledge it plainly and correct it; apologize briefly when warranted. Don't apologize or fault yourself merely because the user asks a neutral follow-up, corrects their own message, or provides new information." 끝 줄바꿈 차이도 하나 있으므로 "바이트 단위로 두 곳만 다르다"고는 쓰지 않습니다.
- 6 Sol 템플릿과 비교하면 146줄이 다릅니다. 6 Sol에 있던 사용자 지적 대응 문단이 빠졌고, 성격(Personality) 절의 위치, 글쓰기 절, "can you..." 실행 해석 문단, 테스트 조건, 외부 메시지, 스킬 중단 규칙이 Astra 쪽을 따릅니다. 질문 도구는 대기 시간이 30초에서 60초로 늘고 `request_user_input_async`만 쓰며 파일 업로드를 요청하지 않습니다. 확인을 구할 때의 설명은 "a short, separate paragraph at the end of both commentary and final"로 둡니다.
- 길이와 해시는 6 Sol 18,992자(SHA-256 `b1dd8718…412f0d`), 6.1 Sol 21,769자(`e1bdd4f8…8d142e`)입니다. 9/23에 받은 Astra·6 Sol 템플릿은 그대로입니다.
- `personality = "none"`을 설정하면 `# Personality`부터 다음 H1(`# Working with the user`) 앞까지 지워져 글쓰기 문체, 기술 소통, PR 절도 함께 사라집니다. 레포 config에는 `personality`가 없습니다.

### 2.5 릴리스 0.156.1 → 0.159.3

| 버전 (UTC) | 관련 변경 |
|---|---|
| 0.156.1 (9/23 02:41) | 9/23 조사의 검증 버전 |
| 0.157.0 (9/25 02:31) | 6 Sol·Luna를 Bedrock에 추가(#47332, #47347), 5.6 Sol 우선순위 6→4(#47085), 5.6 Sol ultrafast 등급 제거(#47130), Astra의 `supports_reasoning_effort_updates`와 실험 컨텍스트 끔(#47397) |
| 0.157.1 (9/26) | 관련 항목 없음 |
| 0.158.0 (9/28 05:07) | `Alt+.`·`Shift+Up`이 Max까지, Ultra는 선택기 전용(#48116), 사용자 지정 effort 직렬화(#47590), GPT-5.4 제거(#47932), 권한 상승 명령의 stdin 승인 |
| 0.159.0 (9/29 08:05) | `instant_interrupt` 옵트인(#48135, #48141), `tui.prompt_suggestions` 제거(#48621), `plugin-creator` 스킬 제거(#48604) |
| 0.159.1 (9/29 20:32) | 6.1 Sol을 번들·Bedrock 카탈로그의 기본 모델로(#49323←#49318, #49342←#49339) |
| 0.159.2 (9/29 23:57) | Windows 콘솔 수정(#49385) |
| 0.159.3 (9/30 22:57) | 계정 보안 안내(#49744) |

0.158.0의 stdin 승인은 권한 상승 명령을 표준 입력으로 승인하는 경로입니다. 소스(`stdin_approval.rs:113/180/218`, `process_manager.rs:902`, `approvals.rs:484`, `exec_policy.rs:216`, stable·기본 켬인 `features/src/lib.rs:1215`)를 읽어 보면 일반 실행 경로에는 추가 검토가 생기지 않고, 권한이나 네트워크 변경을 요구하는 명령은 `approval_policy="never"`에서 정책 거부로 끝납니다. 이 동작은 재현하지 않았습니다. 그래서 `docs/DECISIONS.md`의 Guardian 문장은 범위를 "일반 실행"으로 한정했습니다(6.1절).

새로 생긴 설정 키는 `cloud.skills.enabled`, `auto_review.circuit_break_action`·`extra_policy`, `features.instant_interrupt`, `features.defer_mailbox_preemption`, `features.prefer_mxc`, `features.multi_agent_v2.*`, `features.code_mode.tool_input_schema_max_bytes`, `mcp_servers.*.oauth.client_secret`·`startup_readiness`·`tool_input_schema_max_bytes`, `otel.log_agent_responses`·`log_guardian_assessments`, `tui.copy_on_select`, `tui.rendering.lists`, `tui.right_click_paste`입니다. 레포에 필요한 키는 없었습니다.

### 2.6 접근 문제와 이슈

| 이슈 | 내용 | 상태·해결 |
|---|---|---|
| [#49464](https://github.com/openai/codex/issues/49464) | VS Code 확장이 CLI 0.155를 번들해 6.1 Sol이 목록에 없음(반응 23) | 새 독립 CLI 경로를 지정하면 표시됐다는 댓글. 모델 성능 문제와 분리합니다 |
| [#49396](https://github.com/openai/codex/issues/49396)·[#49703](https://github.com/openai/codex/issues/49703) | 400 "not supported when using Codex with a ChatGPT account" | `codex app-server daemon update` |
| [#49776](https://github.com/openai/codex/issues/49776) | Luna에서 6.1 Sol로 바꾸자 Full Access가 알림 없이 workspace-write로 내려감 | 클라이언트 문제(#49442는 닫힘) |
| [#49362](https://github.com/openai/codex/issues/49362) | Windows 앱에 6.1 Sol이 없음 | 앱 26.928.2636.0(9/30 07:22Z)에서 해결, SSH는 재시작 필요 |
| [#49617](https://github.com/openai/codex/issues/49617), #49664 | 사이버 오탐 | 6.1 Sol 보고 |
| [#49641](https://github.com/openai/codex/issues/49641) | 새 대화에서 "OK" 한 번에 컨텍스트 80% 표시 | 표시만으로 실제 전송 토큰을 확정할 수 없습니다 |
| [#49735](https://github.com/openai/codex/issues/49735) | 긴 자율 작업이 중간 보고로 끝남 | 작성자의 토큰 예산 가설은 검증되지 않았습니다 |
| [#49421](https://github.com/openai/codex/issues/49421) | Low에서 "four job boards"를 근거 없이 특정 사이트로 해석 | 지시 해석 사례 |
| [#49759](https://github.com/openai/codex/issues/49759) | xhigh에서 사용자 정정 뒤 화제를 돌림 | 지시 해석 사례 |
| [#49320](https://github.com/openai/codex/issues/49320), [#49363](https://github.com/openai/codex/issues/49363) | 사용량 문의(중복으로 닫힘), Pro $500의 Astra·6 Sol 문의 | 6.1 Sol 성능 근거로 쓰지 않습니다 |

서드파티 통합에서는 알 수 없는 gpt-6.x 모델에 `max_tokens`를 보내 400이 나는 사례(Winzheng)와 폴백 메타데이터를 쓰는 사례(sergiotapia)가 보고됐습니다.

## 3. Claude Opus 5.5 (9/23 이후)

### 3.1 바뀐 것과 그대로인 것

핵심 요청 형식과 토큰 단가는 유지됐으나, 거절 과금과 교차 모델 사고 블록 호환 설명은 바뀌었습니다.

그대로인 것은 다음과 같습니다.

- 가격: 입력 $4 / 출력 $20, 캐시 쓰기 5분 $5·1시간 $8, 캐시 읽기 $0.20, Batch $2 / $10, Fast $8 / $40.
- 기본 effort `medium`, thinking 항상 켜짐, `display` 기본 `"omitted"`, 강제 `tool_choice` 400.
- 시스템 카드 PDF(17,795,106바이트, ETag `527d6fee…`, Last-Modified 2026-09-22 16:06 GMT)와 시스템 프롬프트 릴리스 노트(27,507바이트)가 9/23 사본과 같습니다.
- 로컬 Claude Code 모델 카탈로그는 Opus 5.5에 "Medium · Recommended"를 표시합니다.
- 긴 입력 할증은 없습니다. 가격 문서의 "Claude 4.6 and later … full 1M … standard pricing" 문장은 9/23에도 있었는데 그때 놓쳤습니다.

바뀐 것은 날짜순으로 다음과 같습니다.

| 날짜 | 변경 | 내용 |
|---|---|---|
| 9/23 | 캐시 진단 GA | `cache-diagnosis-2026-04-07` 헤더가 필요 없어졌습니다. 요청의 `diagnostics` 객체는 옵트인이고, 응답의 `diagnostics` 필드는 항상 있습니다(요청하지 않으면 `null`) |
| 9/24 | 출력 전 거절 과금 | 3.2절 |
| 9/24~9/25 | 비용·effort 공식 측정 | 3.3절 |
| 9/23~10/1 | 마이그레이션 가이드 재구성, thinking 문서 표, best practices 문구 | 3.4절 |
| 9/28 | Sonnet 5.5 출시, 교차 모델 사고 블록 설명 | 3.4·3.5절 |

### 3.2 출력 전 거절 과금 (9/24)

- 원문: "a refusal that arrives before any output is billed when its stop_details.category is "bio", "frontier_llm", or "reasoning_extraction". These are the categories where Anthropic measures low volumes of false positives, as of September 2026."
- 적용 범위: "These billing rules apply on every platform: the Claude API, Amazon Bedrock, Claude Platform on AWS, Google Cloud, and Microsoft Foundry."
- `cyber`·`general_harms`·`null` 범주의 출력 전 거절은 과금하지 않지만, "The request still counts against your rate limits."
- 출력 도중에 온 거절은 입력과 그때까지 스트리밍된 출력을 과금합니다.
- 서버 폴백을 쓰면 과금되는 거절은 폴백 요청과 별도로 청구됩니다. 폴백 크레딧은 폴백 요청의 캐시 미스를 덮습니다.
- "The billed categories may change". 범주 표에 "Billed before any output" 열이 생겼습니다.
- 지원 문서도 같은 주에 갱신됐습니다. 사이버 플래그는 Opus 4.8로, 생물·프런티어 LLM 플래그는 Opus 5로 전환하고, 증류(distillation) 시도는 폴백 없이 막습니다. "Opus 5.5 isn't currently available in the Cyber Verification Program"이라고도 적었습니다. 같은 문서가 일반적인 이유 설명 요청은 허용된다고 명시하므로, 특정 영어 단어를 금칙어로 볼 근거는 없습니다.
- 출처: [릴리스 노트](https://platform.claude.com/docs/en/release-notes/overview), [거절과 폴백](https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback#how-refusals-are-billed), [지원 문서](https://support.claude.com/en/articles/16049681-why-claude-switched-models-in-your-conversation-with-opus-5-or-opus-5-5).

### 3.3 비용·effort 공식 측정

**9/24 블로그 "Coding sessions are longer and use more context…"** (claude.com). Claude Code의 3~9월 집계로 프롬프트당 작업 시간 3.3배, 프롬프트당 모델 호출 40% 넘게 증가, 중단 68% 감소, 요청당 컨텍스트 2.6배, 입력:출력 비 189:1에서 324:1, 캐시 미스 입력 50% 넘게 감소를 제시했습니다. "Opus 5.5와 Fable 5.1은 세션 중 effort를 바꿔도 캐시가 리셋되지 않는다"고 적었고, API 키·클라우드에서도 1시간 캐시를 설정할 수 있으며 포크 서브에이전트는 부모의 캐시에서 시작한다고 설명했습니다. 권하는 습관은 세션 시작 때 모델 고르기, 자리를 비우기 전에 압축하기, API 키라면 긴 세션에 1시간 캐시 쓰기입니다.

**9/25 비용 블로그 개정판** (claude.dev, Addy Osmani). 옛 claude.com 주소는 301로 넘어갑니다. 9/22판과 달라진 점은 일곱 가지입니다.

1. effort를 바꿔도 API 키·구독에서는 캐시가 유지되고, Bedrock·Google Cloud·게이트웨이에서만 지워집니다.
2. Fable 5.1 전환 기준이 `high`에서 `xhigh`로 올라갔습니다. "If Opus 5.5 on xhigh hits the same problem twice, switch, and switch back once it's solved."
3. Fast 모드는 최대 2.5배 빠르고 $8 / $40이며, 켠 뒤 첫 요청은 대화 전체를 캐시 없이 입력가로 냅니다.
4. "40% 저렴"은 medium 기본값에서 토큰을 덜 쓴다는 가정이 들어간 추정이라고 밝혔습니다.
5. 에이전트 팀은 plan 모드에서 표준 세션의 약 7배 토큰을 씁니다.
6. 엔터프라이즈 평균은 개발자 활동일당 $13이고, 90%가 $30 미만입니다.
7. 5시간 한도 상향과 한도 리셋은 Settings > Usage에서 씁니다.

9/23에 인용한 프롬프트 감사 사례(18%·9% 절감)는 그대로 남아 있습니다.

**"Using Claude Code: Spending your effort"** (claude.dev, 9/25, Thariq Shihipar). 측정 조건 원문은 "Terminal-Bench 3.0, the same 70 tasks for every model (the 4 GPU tasks are left out). Opus 5.5 ran about three weeks later, with responses capped at 128k tokens and no GitHub or PyPI access; Opus 5's max is its effort-120 run."입니다. 그림은 통과한 시도 비율과 시도당 중앙값 토큰(로그 축)을 나란히 보입니다.

- 결과: "Opus 5.5 scores highest at every setting, from 36.6% at low to 65.7% at max … Opus 5.5 at high matches Fable 5.1 at max (58.9% against 58.0%) on half the tokens. Fable 5 levels off at 43.4% from xhigh to max." 여기서 "matches"는 점수가 가깝다는 뜻이고 통계 검정이 아닙니다.
- 권하는 루프: "For normal software engineering, I'm running a loop of getting the model to interview me then implementing on low effort, reviewing what it built, and then running verification on high effort."
- 레벨별 용도: low는 브레인스토밍, medium은 "most of my regular software engineering work", high는 "work where verification is important or there are edge cases", max는 "When I want Claude to operate fully autonomously to solve difficult problems"입니다. 피트니스 앱 예시의 소요 시간은 low부터 max까지 1.5분, 4분, 11분, 67분이었습니다.
- effort를 올리면 숨은 엣지 케이스에서 오는 실패는 줄지만, 접근이 틀린 실패는 고쳐지지 않는다고 적었습니다.

**비용 최적화 문서** (Opus 5.5 언급이 3회에서 54회로). SWE-bench Pro 부분집합(478문제, "not comparable to public leaderboard") 측정이고, 9/19~20에 low·medium·high는 2회씩, xhigh는 1회 돌렸으며 턴당 출력 상한은 16,384입니다.

| 설정 | 점수 (high 대비) | 비용 (high 대비) |
|---|---|---|
| medium | 약 −2.5점 | 약 70% |
| low | 약 −8점 | 약 1/3 |
| xhigh | 약 +1.4점 | 2.5배 |

- 단계 상향: low로 돌린 뒤 실패한 13%만 high로 다시 돌리면 약 97%를 과제당 약 $0.17에 풀어, 전부 high(95.3%, $0.29)보다 쌌습니다. medium에서 시작하면 약 97%에 약 $0.24입니다. 문서는 "use this policy for the saving, not the lift"라고 적었고, 실패를 판별할 신호가 있어야 쓸 수 있습니다.
- Opus 5.5 medium 92.8%와 Fable 5.1 기본값 92.3%는 노이즈 범위 안이고, 과제당 비용은 $0.22 대 $1.19입니다. Opus low는 87.4%에 $0.12입니다.
- 출력 상한: 내부 레포 과제 벤치에서 16,384 상한은 Opus 시도의 약 1/4, Fable 시도의 43%를 잘랐습니다. 잘린 시도 중 통과한 것은 Opus 66건 중 1건, Fable 117건 중 9건뿐이었고, 해결 과제당 비용은 64K 상한과 비슷했습니다(Fable $21 대 $22, Opus는 1% 이내). 64K에서는 Fable 약 14,000턴 중 2턴만 잘렸고 Opus는 0턴이었습니다. 문서는 에이전트 작업에 64,000을, 잘림 비용이 큰 경우 128,000을 권합니다.
- 조언자(advisor): Opus high에 Fable 5.1 조언자를 붙이면 90.1%·$2.92로 Opus high 단독보다 1.7점 높고 비용은 약 2.1배였습니다(과제당 5회, 노이즈 경계). medium과 비교하면 3.5점 높고 비용은 약 3.5배입니다. Opus xhigh 단독은 91.1%·$4.11입니다. GPQA에서는 실행자 비용 $1.36 대 $1.38에 조언 비용 $1.55가 더해졌습니다.
- 새 절 두 개: 모델에게 경과 시간을 보여 주는 방법(Fable 5.1로 측정), keep-alive와 1시간 캐시를 고르는 기준.
- 출처: [9/24 블로그](https://claude.com/blog/claude-opus-5-5-built-for-coding-sessions-that-use-more-context), [비용 블로그](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/), [Spending your effort](https://claude.dev/blog/spending-your-effort/), [비용 최적화 문서](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence).

### 3.4 문서 변경

- **마이그레이션 가이드**: 9/23판은 Opus 5 가이드로 넘기는 얇은 구조였는데, 지금은 "What every request to Claude Opus 5.5 must satisfy", "Handle thinking in every response"(5항목), 시작 모델별 누적 체크리스트(Opus 5 / 4.8 / 4.7 / 4.6 / 4.5 / 4.1 / Sonnet 5)로 자기완결적입니다. 새로 명시된 항목은 Priority Tier 미지원(Opus 4.8은 지원), `xhigh`·`max`에서 `max_tokens`를 64k부터 시작하라는 권고(최소값이 아님), 캐시 최소 512토큰, Claude API에서 Opus 5.5가 Sonnet 5.5 사고 블록을 읽는다는 점(한 방향)입니다.
- **What's new**: 두 줄이 더해졌습니다. Claude API에서 Sonnet 5.5 사고 블록을 읽는다는 줄, 출력 전 거절 과금은 범주별이고 레이트 리밋에는 항상 포함된다는 줄입니다.
- **Thinking 문서**: 모델별 `thinking` 값 표가 생겼습니다. `"between_tools"`는 Opus 5.5에서 400이고 Sonnet 5.5에서만 `high` 이하로 허용됩니다.
- **Preserved thinking**: Sonnet 5.5 사고 블록은 만든 계정(또는 연결 계정)에서만 유효하고 다른 계정이 보내면 버려집니다(`organization_binding_mismatch`). Opus 5.5 블록은 이 결합 대상이 아닙니다("Blocks from earlier models aren't affected").
- **Prompting best practices**: Sonnet 5.5 행이 생겼고, 자기 점검 요청의 예외 문구가 "On Claude Opus 5, remove these instructions"로 바뀌었습니다. 예외 대상은 여전히 Opus 5뿐입니다.
- **Opus 5.5 프롬프팅 가이드**: 문구 교정만 있습니다(diff 14줄 전부 확인).
- **Opus 5.5 개요·발표문**: 개요 비교표의 Sonnet 5가 Sonnet 5.5로 바뀌었습니다. 발표문 벤치마크 표의 "OSWorld 2.0"이 "OSWorld 2.1"로 바뀌었고 수치(81.8% / 80.7% / 74.0%)는 그대로입니다. Fable 5.1 발표문은 계속 "OSWorld 2.0"이므로 9/23에 본 두 발표문의 수치 차이는 벤치마크 버전 차이로 설명되지만, Anthropic이 이유를 밝히지는 않았습니다. HLE(도구 사용 Fable 5.1: 9/1 발표문 65.0%, 9/22 발표문 65.6%)는 여전히 설명이 없습니다.
- **9/23 조사가 놓친 9/22 자료**: 발표문은 5시간 사용량 한도를 Pro·Max·Team·좌석형 Enterprise에서 올린다고 적었습니다(상향 폭은 미기재). Opus 5.5는 Opus 4.x 합산 버킷과 별도인 자체 레이트 리밋 버킷을 씁니다(RPM 1,000 / 5,000 / 10,000 등, Opus 5와 같은 수치). 서비스 티어 문서는 Opus 5.5를 Priority Tier 미지원으로 적습니다(추가 시점 미확인). "Getting the most out of Opus 5.5" 블로그(9/22, Addy Osmani)는 큰 감사·이전 작업을 서브에이전트로 나누고 각 보고의 근거를 확인하라고 권합니다.
- **그 밖**: Haiku 5.5는 "coming weeks"라는 언급뿐이고 모델 개요는 Haiku 4.5입니다. Sonnet 4.5(`claude-sonnet-4-5-20250929`)는 2026-11-30에 은퇴합니다. Claude API 스킬에 `/claude-api preserved-thinking-migration` 하위 명령이 생겼습니다. SDK는 Python 1.9.0~1.11.0, TS 0.129~0.131이 나왔지만(9/28: `between_tools`, sonnet-5-5 상수, 캐시 진단 필드 / 9/30: Admin API, Managed Agents 거절 정지) Opus 5.5 최소 버전(1.8.0 / 0.128.0)은 그대로입니다. `langchain-anthropic` 1.7.3(9/22)은 Fable·Opus 5.5에서 구조화 출력을 `json_schema` 방식으로 자동 전환하고, 1.7.4(9/23)는 Opus 5.5 프로필을, 1.7.5(9/29)는 Sonnet 5.5 호환을 더했습니다.
- 출처: [마이그레이션 가이드](https://platform.claude.com/docs/en/models/opus-5-5/migration-guide), [What's new](https://platform.claude.com/docs/en/models/opus-5-5/whats-new-opus-5-5), [Thinking](https://platform.claude.com/docs/en/build-with-claude/thinking), [Preserved thinking](https://platform.claude.com/docs/en/build-with-claude/preserved-thinking#account-bound-thinking), [Best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices), [발표문](https://www.anthropic.com/claude-opus-5-5), [Rate limits](https://platform.claude.com/docs/en/api/rate-limits), [Service tiers](https://platform.claude.com/docs/en/api/service-tiers#supported-models), [Getting the most out of Opus 5.5](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/).

### 3.5 Sonnet 5.5 (9/28)

`claude-sonnet-5-5`, 입력 $2 / 출력 $10, 캐시 읽기 $0.20, 1M / 128K, 지식 컷오프 2026-06, 은퇴 하한 2027-09-28입니다. API 기본 effort는 `high`이고 Claude Code 기본은 `medium`입니다. Sonnet 5에서 ID만 바꾸면 깨지는 변경이 다섯 가지입니다. `disabled` 대신 `between_tools`, 강제 `tool_choice` 400, 사고 블록 결합, `computer_20251124` 미지원, advisor 도구가 Opus 4.8·4.7·Sonnet 5를 조언자로 거부한다는 점입니다. Claude Code는 2.1.284에서 Sonnet 5.5를 추가했고 `sonnet` 별칭이 이 모델을 가리킵니다.

- 출처: [Sonnet 5.5 발표문](https://www.anthropic.com/claude-sonnet-5-5)(요약으로 열람), [모델 개요](https://platform.claude.com/docs/en/about-claude/models/overview), [릴리스 노트](https://platform.claude.com/docs/en/release-notes/overview).

### 3.6 Claude Code 2.1.281~2.1.286

npm 게시 시각(UTC)은 2.1.281 9/23 17:01, 2.1.282 9/24 15:56, 2.1.283 9/25 18:46, 2.1.284 9/28 17:11, 2.1.285 9/29 17:32, 2.1.286 9/30 17:14입니다. 로컬에는 2.1.278·2.1.280·2.1.286 바이너리가 있고 `claude` 링크는 2.1.286을 가리킵니다.

| 버전 | 레포와 관련된 변경 |
|---|---|
| 2.1.281 | bypass·auto 모드의 위험 `rm` 확인창이 2분 뒤 거부(`CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT`은 이 시간 제한만 끔). 명령 치환만 대상인 재귀 `rm`은 Bash allow 규칙이 있어도 물음(`CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT`는 이 검사만 끔). Alt+T가 끌 수 없는 thinking 끄기를 제안하던 문제 수정. `--agents`가 JSON 파일 경로를 받음. `"attribution": false`. 텔레메트리를 끈 직접 API 연결에서도 auto 모드 서버 분류기가 기본(`CLAUDE_CODE_AUTO_MODE_SERVER=0`으로 해제) |
| 2.1.282 | 안전장치 모델 전환 뒤 "Effort 'xhigh' isn't available with thinking turned off"로 턴이 실패하던 문제, 요약 요청이 거절되면 압축이 실패하던 문제(폴백 모델로 재시도) 수정. `redacted_thinking` 오류 시 사고 블록을 버리고 재시도. 규칙 중간의 `:*` 무시 수정. `maxProseWidth` |
| 2.1.283 | `/doctor prompt-audit`(별칭 `/checkup prompt-audit`). 모델 폴백 중 시작한 워크플로가 모든 에이전트를 폴백 모델로 돌리던 문제 수정. 관리형 `availableModelsMatch: "exact"`·`deniedModels`. `CLAUDE_CODE_GATEWAY_HINT_HEADERS` |
| 2.1.284 | Sonnet 5.5 추가, `sonnet` 별칭 변경. `ANTHROPIC_DEFAULT_OPUS_MODEL`이나 `modelOverrides`로 고정한 세션도 안전장치 전환 대상을 API가 고름. Ultracode가 effort와 독립된 토글(Tab, `/effort ultracode [on\|off]`). 권한 모드를 정하지 않은 대화형 세션은 auto 모드로 시작(`defaultMode`가 우선, 2.1.283은 제3자 제공자·텔레메트리 꺼짐만, 2.1.285는 `-p`와 Python SDK까지). 알 수 없는 모델 세션에서 Explore가 그 모델을 상속. 압축 뒤에도 너무 길면 한 번 더 압축 |
| 2.1.285 | 서버가 다른 폴백 모델로 답했을 때 `/cost`와 `modelUsage`가 실제 모델로 집계. 포크 서브에이전트가 부모의 plan·`dontAsk` 모드 유지. 사용자 지정 `ANTHROPIC_BASE_URL`에서도 1M 창. 관리형 `allowedProviders`. `CLAUDE_CODE_DISABLE_WEB_FETCH` |
| 2.1.286 | 기본 모델을 API가 거부하면 같은 등급의 이전 모델로 한 번 재시도. 폴백 알림에 창이 1M에서 200K로 줄었는지 표시. Fast를 못 쓰는 모델로 폴백하면 표준 속도로 진행. 이름이 정확히 `verify`인 스킬이 있으면 커밋 전에 실행을 제안(레포 `work-verify`는 해당 없음). 권한 요청이 쌓이면 "2 of 5" 표시 |

문서 변경도 있었습니다. model-config의 effort 선택표가 다시 쓰였고 "Spending your effort"로 연결됩니다. sub-agents 문서의 `effort`는 여전히 "inherits from session"이고, model-config의 일반 규칙은 활성 모델이 지원하지 않는 레벨을 그 아래 가장 높은 지원 레벨로 내린다는 것입니다. Claude Code 프롬프트 캐싱 문서는 Opus 5.5·Sonnet 5.5·Fable 5.1을 API 키나 구독으로 쓰면 effort를 바꿔도 캐시가 유지된다고 적고, 예외로 Bedrock, Google Cloud Agent Platform, Claude apps gateway, `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`, HIPAA 구성을 듭니다. API에서는 최상위 `output_config.effort`를 바꾸면 캐시가 무효가 되고, 메시지별 effort(베타 `mid-conversation-output-config-2026-07-01`)는 캐시를 유지합니다.

**핵심 경로 삭제 확인(permission-modes 문서)**. 모드별 동작 원문은 bypassPermissions "Asks you to approve it, with a time limit in the terminal", auto "Asks … in the terminal, with a time limit. Elsewhere, denies it", dontAsk "Denies it"입니다.

- "If an explicit ask rule matches the command, Claude Code asks you instead, even in auto mode and without a time limit."
- 2분 카운트다운이 끝나면 명령을 거부하고 Claude에게 대신 할 일을 알립니다. 아무 키나 누르면 카운트다운이 멈춥니다. 한 세션에서 응답 없는 확인창이 세 번 쌓이면 이후의 핵심 경로 삭제는 바로 거부되고, 새 메시지가 오면 횟수가 초기화됩니다. 터미널이 없는 auto 모드(`-p`, SDK, VS Code 채팅, Desktop)는 바로 거부합니다.
- 환경변수로 시간 제한을 끄는 경우: "requires Claude Code v2.1.281 or later … In auto mode, critical-path removals then go to the classifier instead, and in bypassPermissions mode the prompt has no time limit."
- "Claude Code never lets a permissions.allow rule or a PreToolUse hook that returns "allow" approve an rm or rmdir command that targets a critical path, even in modes that skip other prompts. This circuit breaker guards against model error. A matching deny rule still blocks the command outright."
- 핵심 경로는 루트, 최상위 디렉터리, 홈, Windows 드라이브 루트, 작업 디렉터리와 그 상위, 추가 디렉터리(글롭만)입니다. `"$DIR"/*`, `"$1"/*`, `"$TMPDIR/mnt"`, `D=$(pwd); rm -rf "$D"`, `rm -rf "$(pwd)"`, `rm -rf ~/$(cmd)`, 백슬래시만 있는 대상도 잡고, 중첩·인라인 스크립트도 검사합니다.
- 출처: [체인지로그](https://code.claude.com/docs/en/changelog), [model-config](https://code.claude.com/docs/en/model-config), [sub-agents](https://code.claude.com/docs/en/sub-agents), [프롬프트 캐싱](https://code.claude.com/docs/en/prompt-caching), [permission-modes](https://code.claude.com/docs/en/permission-modes#critical-paths), [env-vars](https://code.claude.com/docs/en/env-vars), `npm view @anthropic-ai/claude-code time`.

### 3.7 장애와 미해결 이슈

- **9/29 장애**: 14:00~14:59 UTC에 claude.ai·Console·API·Claude Code가 오류를 냈고, 14:36에 완화, 16:27에 해결됐습니다. 포스트모템은 비어 있습니다(`postmortem_body`). Opus 5.5 전용 장애는 없었습니다([status.claude.com](https://status.claude.com)).
- **auto 모드 판정 장애** [#97854](https://github.com/anthropics/claude-code/issues/97854): 9/28~29에 분류기가 판정을 돌려주지 않아 작업이 멈췄다는 보고입니다(반응 39, 댓글 27). 상태 페이지에는 없습니다. 레포는 bypass라 해당하지 않습니다.
- **캐시 재작성** [#96163](https://github.com/anthropics/claude-code/issues/96163): OPEN입니다. 2.1.283(댓글 5848115078)과 2.1.284(5884931008)에서 재현 보고가 있고, `-p`가 아닌 경우와 Sonnet 5.5에서도 나타나며 직전 턴의 사고 블록과 상관이 있다는 보고가 있습니다. Fable은 나쁘고 Opus는 괜찮다는 반대 보고(5821423522)도 있습니다. `-p` 경로에서 보고됐고 2.1.286 해결 여부는 미확인입니다.
- [#96139](https://github.com/anthropics/claude-code/issues/96139)(`reasoning_extraction` 오탐)와 [#96141](https://github.com/anthropics/claude-code/issues/96141)도 OPEN입니다. 9/24부터 이 범주의 출력 전 거절이 과금되므로 오탐에 비용이 생겼습니다.

## 4. 3자 평가

수치를 읽을 때 조건을 함께 봐야 합니다. effort가 다르면 같은 모델도 점수가 다릅니다. Opus 5.5는 안전장치 폴백이 켜진 채 측정된 경우가 많아 일부 과제를 Opus 4.8이나 Opus 5가 대신 풀었습니다. Vals Index는 9/25에 v2.1로 바뀌어 9/23 조사의 v2 점수와 섞을 수 없습니다. 6.1 Sol 수치는 출시 1~2일 뒤의 첫 측정입니다.

### 4.1 Artificial Analysis 지능 지수 (v4.3, 2026-10-01 확인)

항목명에 "Default Fallback"이 붙은 Claude 모델은 폴백이 켜진 채 측정됐습니다.

| 모델(effort) | 지수 | 과제당 비용 | 과제당 출력 토큰 | 출력 속도(t/s) | AA-Omniscience 환각률 | Terminal-Bench 4.0 |
|---|---:|---:|---:|---:|---:|---:|
| 6.1 Sol low | 42.1 | $0.13 | 3,977 | 59.7 | 51.6% | 30.8 |
| 6.1 Sol medium | 47.8 | $0.21 | 8,070 | 59.4 | 51.6% | 48.0 |
| 6.1 Sol high | 50.2 | $0.32 | 13,192 | 63.5 | 49.4% | 51.5 |
| 6.1 Sol xhigh | 51.0 | $0.39 | 17,619 | 63.3 | 50.9% | 54.0 |
| 6.1 Sol max | 51.8 | $0.72 | 38,128 | 65.3 | 54.3% | 56.1 |
| 6 Sol max | 47.5 | $1.05 | 31,054 | 74.4 | 60.1% | 43.9 |
| 6 Sol xhigh / high / medium / low | 44.1 / 42.8 / 39.8 / 33.9 | $0.52 / $0.38 / $0.25 / $0.13 | — | medium 91.9 | — | — |
| Astra max | 52.7 | $3.26 | 27,206 | 51.2 | 51.3% | 59.1 |
| Astra medium / low | 49.6 / 45.8 | $1.54 / $0.82 | — | — | — | — |
| Opus 5.5 low | 42.31 | $0.55 | 10,151 | — | 67.6% | 31.3 |
| Opus 5.5 medium (기본) | 51.24 | $1.34 | 25,745 | — | 68.4% | 52.5 |
| Opus 5.5 high | 53.58 | $1.82 | 35,584 | — | 67.6% | 56.6 |
| Opus 5.5 xhigh | 55.99 | $3.46 | 65,667 | — | 65.7% | 59.6 |
| Opus 5.5 max | 57.62 | $5.98 | 119,166 | 92 | 58.6% | 59.6 |
| Sonnet 5.5 max | 55.98 | $7.62 | 193,527 | — | 47.0% | 63.6 |
| Fable 5.1 max | 53.35 | $7.63 | 78,111 | 69.2 | 72.6% | 52.0 |
| Argon high | 52.56 | $1.99 | 61,558 | — | 15.1% | 57.1 |
| Opus 5 max | 50.78 | $5.86 | 72,511 | — | 60.8% | 49.0 |
| 5.6 Sol max | 47.0 | $1.99 | 29,309 | 79.6 | 92.2% | 39.9 |

- AA 총평: "It scores 1 point below GPT-6 Astra in the Intelligence Index at less than one quarter of the Cost per Task", "uses ~10-30% more output tokens than GPT-6 Sol across effort levels".
- 6.1 Sol은 6 Sol보다 출력 속도가 느려졌고(max 74.4→65.3, medium 91.9→59.4 t/s) 과제당 시간도 max 기준 415초에서 584초로 늘었습니다. 출력 토큰이 늘었는데 과제당 비용이 내려간 데에는 캐시 입력 단가 인하가 기여했습니다. 기여 몫은 따로 계산하지 않았습니다.
- AA-Omniscience 정확도는 6 Sol 54.5%에서 6.1 Sol 62.1%(max)로 올랐고 환각률은 60.1%에서 54.3%로 내려갔습니다. 9/23에 지적한 "답변 시도율이 내려가 정답률이 떨어졌다"는 문제가 6.1에서는 나아졌습니다.
- Sonnet 5.5 기사에 따르면 과제의 약 0.1%가 폴백으로 처리됐습니다. AA Cyber Index(9/28)에서 Opus 5.5 max는 28.7이었고 CyberGym 거절률은 98.5%였습니다.
- 출처: [AA 6.1 Sol 모델 페이지](https://artificialanalysis.ai/models/gpt-6-1-sol), [AA 6.1 Sol 기사](https://artificialanalysis.ai/articles/gpt-6-1-sol-replaces-gpt-6-sol-after-just-7-days-with-near-astra-intelligence), [AA Opus 5.5 모델 페이지](https://artificialanalysis.ai/models/claude-opus-5-5), [6.1 Sol 대 Opus 5.5 비교](https://artificialanalysis.ai/models/releases/comparisons/gpt-6-1-sol-vs-claude-opus-5-5), [AA Sonnet 5.5 기사](https://artificialanalysis.ai/articles/claude-sonnet-5-5), [AA Cyber Index](https://artificialanalysis.ai/articles/artificial-analysis-cyber-index).

### 4.2 Artificial Analysis 코딩 에이전트 지수 v1.5

각 벤더 하네스로 DeepSWE, SWE-Atlas-QnA, Terminal-Bench 4.0을 1/3씩 가중합니다. 과제당 세 번 실행해 평균한 pass@1이고, 시도 수는 (113 + 124 + 66) × 3 = 909입니다.

| 하네스 · 모델(effort) | 지수 | 과제당 비용 | 과제당 시간 | DeepSWE / TB4 |
|---|---:|---:|---:|---|
| Codex · 6.1 Sol xhigh | 62.9 | $1.04 | 931초 | 73.2 / 54.5 |
| Codex · 6.1 Sol medium | 61.4 | $0.70 | 651초 | 72.0 / 51.5 |
| Codex · 6.1 Sol high | 60.1 | $0.89 | 800초 | 70.5 / 50.0 |
| Codex · 6.1 Sol max | 60.1 | $1.55 | 1,463초 | 69.6 / 53.0 |
| Codex · 6.1 Sol low | 57.2 | $0.50 | 518초 | 67.6 / 49.0 |
| Codex · 6 Sol max | 56.7 | $2.99 | 1,338초 | 69.0 / 43.4 |
| Codex · Astra max | 61.6 | $7.47 | 1,762초 | 67.6 / 55.6 |
| Claude Code · Opus 5.5 max | 66.0 | $13.04 | 3,867초 | 68.4 / 63.1 |
| Claude Code · Sonnet 5.5 max | 68.4 | $14.19 | 5,245초 | 72.0 / 66.2 |
| Claude Code · Fable 5.1 max | 62.2 | $12.39 | 2,090초 | 64.3 / 57.6 |
| Claude Code · Opus 5 max | 59.7 | $10.79 | 2,516초 | — |
| Antigravity · Argon high | 63.8 | $5.84 | 2,070초 | — |

- 실행 버전은 6.1 Sol이 Codex 0.154.0, Claude 모델이 Claude Code 2.1.280입니다. 현재 레포가 쓰는 도구 버전의 직접 비교가 아닙니다.
- 6.1 Sol `xhigh`와 `max`는 약 2.8점 차이이고 `max`의 비용은 약 1.5배, 시간은 약 1.6배입니다. 6.1 Sol medium(61.4)과 Astra max(61.6)는 관측 점수가 가깝다는 뜻이지 동등성이 입증된 것은 아닙니다. 이 평가에서는 Sonnet 5.5가 Opus 5.5보다 높지만 전반적 우열로 넓히지 않습니다.
- AA 코딩 에이전트 지수에서 6.1 Sol xhigh는 Astra max보다 약 1.3점 높았고, 과제당 비용은 약 13.9%였습니다(원자료 62.9078 대 61.6450, $1.0397 대 $7.4671). AA 기사의 코딩 에이전트 지수 절도 같은 비교를 적었습니다. 지능 지수(4.1절)에서는 6.1 Sol xhigh 51.0이 Astra xhigh 52.4와 max 52.7보다 낮으므로, 평가 이름 없이 "Astra보다 높다"고 옮기지 않습니다.
- 폴백과 중단: Opus 5.5는 거절 80회·폴백 78회, Sonnet 5.5는 46회·45회, Fable 5.1은 폴백 74회, Opus 5는 폴백 3회입니다. Codex 쪽 강제 중단은 Astra 13회, 6.1 Sol xhigh 13회, max 15회입니다.
- Opus 5.5 폴백 78회는 Opus 4.8로 72회, Opus 5로 6회입니다. 평가별로는 DeepSWE 339회 중 2회, SWE-Atlas-QnA 372회 중 52회(25회는 첫 턴), Terminal-Bench 4.0 198회 중 24회(Opus 4.8 18회, Opus 5 6회)입니다. 78/909 = 8.58%는 전체 시도 합산이고, 평가별 비율을 같은 비중으로 평균하면 약 8.90%입니다. 원자료의 `safety.rate` 약 9.09%는 같은 모델로 계속 실행한 경우까지 센 거절 지표라 또 다릅니다.
- AA 방법론(Safety Refusals)은 다른 모델이 끝낸 시도도 일반 시도처럼 채점한다고 명시합니다. 이것은 코딩 에이전트 지수에 대해 확인한 내용입니다. 페이지는 "Safety and fallback behaviour is provider-configurable and may change over time"이라고도 적었습니다.
- 하네스를 둘러싼 논쟁이 있습니다. Theo는 "it performs WAY better in Codex than in mini-swe"라고 했고, AA의 반론은 Latent Space 요약으로만 확인했습니다.
- 출처: [코딩 에이전트 리더보드](https://artificialanalysis.ai/agents/coding), [방법론](https://artificialanalysis.ai/methodology/coding-agents-benchmarking).

### 4.3 Vals AI (Vals Index v2.1)

v2.1은 9/25에 나왔고 페이지는 9/30에 갱신됐습니다. 원문은 "Terminal-Bench 4.0 is substantially harder, so index scores are lower than under v2."입니다.

| 모델 | Vals Index | 순위 | 테스트당 비용 |
|---|---:|---:|---:|
| Argon | 68.90% | — | — |
| Sonnet 5.5 | 67.04% | — | — |
| Opus 5.5 | 66.97% (±0.89) | 3/41 | $32.14 |
| Fable 5.1 | 65.83% | — | — |
| Opus 5 | 63.67% | — | — |
| Astra | 63.13% | 6/41 | $18.46 |
| 6.1 Sol | 61.15% | 8/41 | $3.24 |
| 6 Sol | 57.54% | 11/41 | $7.58 |

- 폴백을 실패로 세면 Sonnet 5.5 65.85%, Opus 5.5 65.05%, Fable 5.1 64.59%입니다(Vals Index 페이지의 결과 해설). 지수는 부문별 가중 합계이므로 전체 폴백 비율을 66.97%에서 빼서 보정 점수를 만들지 않습니다.
- 2026-10-01 UTC에 저장한 두 사본에서 Vals Index 대상 폴백 표시는 00:54의 44건·1.93%와 01:34의 91건·3.99%로 달랐습니다. 정확도 표시는 모두 66.97%였습니다. 변경 이유와 집계의 일관성은 확인하지 못했습니다. 공급자 거절 표시도 12건(0.53%)에서 18건(0.79%)으로 달랐습니다.
- Opus 5.5의 평가별 폴백은 SRE 262개 중 217개(82.82%), Code Migration 130개 중 106개(81.54%), CyberBench 116개 중 61개(52.59%), Terminal-Bench 4.0 198개 중 22개(11.11%)입니다. Terminal-Bench 4.0 원문은 "Opus 5.5 had 22 of 198 task attempts served by Opus 5 or Claude Opus 4.8; counting those as failures lowers it from 65.15% to 58.08%, behind Sonnet 5.5 and Astra."이고, 설정은 mini-swe-agent·단일 bash 도구·avg@3입니다.

| 과제 | 6.1 Sol | 6 Sol | Astra | Opus 5.5 |
|---|---|---|---|---|
| Terminal-Bench 4.0 | 55.05% ($1.72) | 44.44% ($5.79) | 59.60% | 65.15% |
| Vibe Code Bench v1.1 | 88.93% ($6.23) | 87.82% ($26.36) | 89.59% | 90.29% |
| Code Migration | 65.12% | 57.20% | 67.74% | 66.65% |
| CyberBench | 39.29% (43개 모델 중 41위, 공급자 거절 60/116 = 51.72%) | 77.98% (43개 모델 중 1위) | 41.07% | 55.36% |
| 그중 PoC 트랙 | 0% | 66.667% | 0% | 25.0% |
| 그중 패치 트랙 | 78.571% (stderr 5.483) | 89.286% (stderr 4.133) | 82.143% (stderr 5.118) | 85.71% |

- CyberBench는 "Provider refusals count as failures."입니다. 6.1 Sol의 패치 트랙은 6 Sol보다 약 10.7%p, Astra보다 약 3.6%p 낮았습니다. 사이버 Critical 분류는 능력·위험 분류이고, PoC 점수 하락은 Astra와 같은 안전장치 적용과 부합할 가능성이 있지만 이 점수만으로 거절이 원인이라고 확정하지 않습니다.
- SRE Bench에서 6.1 Sol 50.76%(거절 38.55%를 실패로 셈), Astra 56.87%, Opus 5.5 33.59%입니다. 처리 방식이 달라 직접 비교하지 않습니다. Terminal-Bench 4.0의 운영 범주에서는 Opus 5.5가 29.63%, Sonnet 5.5가 51.85%였습니다.
- Vals는 X에서 "It now ranks #7, three spots above GPT-6 Sol"이라고 했는데, 확인 시점 페이지는 8위였습니다. "Claude Opus 5.5 (CVP)" 항목도 따로 있습니다.
- 기준선과 맞지 않는 값이 있습니다. 9/23에 Opus 5.5는 "1/65, $22.30"이었는데 현재 발표 글은 "#1 of 63 (69.69%) $32.77"이라고 적고, 6 Sol은 65.89%와 62.57%로 엇갈립니다. Opus 5.5의 Terminal-Bench 4.0도 61.62%(폴백 30/198)에서 65.15%(22/198)로 바뀌었고 이유는 설명되지 않았습니다.
- 출처: [Vals Index](https://www.vals.ai/benchmarks/vals_index), [Opus 5.5](https://www.vals.ai/models/anthropic_claude-opus-5-5), [6.1 Sol](https://www.vals.ai/models/openai_gpt-6.1-sol), [6 Sol](https://www.vals.ai/models/openai_gpt-6-sol), [Astra](https://www.vals.ai/models/openai_gpt-6-astra), [Terminal-Bench 4.0](https://www.vals.ai/benchmarks/terminal-bench-4), [CyberBench](https://www.vals.ai/benchmarks/cyber).

### 4.4 그 밖의 평가

| 출처 | 대상 | 결과 | 한계 |
|---|---|---|---|
| [Arena](https://arena.ai/leaderboard/text) | 둘 다 | 텍스트: Opus 5.5 4위(1504±10, 순위 범위 2~14, 3,932표). 창작 글쓰기: Opus 5.5 2위(1515±21, 908표). WebDev: Opus 5.5 max 1위(1818±17, 1,976표), Astra 1789, 6.1 Sol 3위(1759±19, 1,264표), 6 Sol 7위(1689). Agent: Opus 5.5 High 2위(13.78%) | 부문마다 과제와 투표 구성이 다릅니다 |
| [ARC Prize](https://arcprize.org/results/openai-gpt-6-1-sol) | 둘 다 | ARC-AGI-2: 6.1 Sol max 94.2%, xhigh 91.7%, 6 Sol 89.6%, Astra 95.0%. low는 6 Sol 31.5%에서 6.1 Sol 76.7%로 올랐습니다. Opus 5.5는 high 93.3%, xhigh 92.5%, max 91.7%, medium 87.5%, low 70.1%. ARC-AGI-1: 6.1 Sol xhigh 98.5%, max 96.5%. ARC-AGI-3: 6.1 Sol Standard max 52.73%(6 Sol 4.62%, Astra 62.71%), Provider Adapter max 96.18%·xhigh 96.37% | 최고 점수의 추론 수준은 모델·평가·실행 방식에 따라 다릅니다. ARC-AGI-2에서는 6.1 Sol은 max, Opus 5.5는 high가 가장 높았고, 6.1 Sol의 ARC-AGI-1과 ARC-AGI-3 Provider Adapter에서는 xhigh가 max보다 높았습니다 |
| [Snorkel](https://snorkel.ai/leaderboard/) | Opus 5.5 | 코딩 블로그 24과제·Opus 200회 실행, 전체 68%이지만 pass@1은 Opus 5.5와 Opus 5 모두 60.7(Fable 61.5). 리더보드는 ALE 38.2%(1위), LibraryDesignBench 48.9(1위), TB-Science 63.3%(2위, Astra 68.1%) | 과제 수가 적습니다 |
| Braintrust MathTutorBench | 6.1 Sol | 175문항 × 4회 × 3모델 = 2,100응답. 같은 medium에서 수학 정확도 78.6% 대 6 Sol 75.8%, 교수법 77.6 대 64.1 | AI 심판을 쓴 수학 지도 평가이고 글쓰기 점수 차이는 유의하지 않았습니다. 코딩 성능으로 옮기지 않습니다 |
| [Epoch AI](https://epoch.ai/benchmarks) | 둘 다 | ECI 6.1 Sol 167.35로 1위(Astra 166.51, Sonnet 5.5 165.2). FrontierMath T1-3 / T4는 Opus 5.5 91.2 / 95.0, 6.1 Sol 93.7 / 100. GPQA 90.6 대 95.4, SimpleQA Verified 72.2 대 73.9 | 6.1 Sol 수치는 첫 측정입니다 |
| [SimpleBench](https://simple-bench.com/) | 6.1 Sol | 88.4%로 1위(6 Sol 73.1%) | — |
| [LiveBench](https://livebench.ai/) | 둘 다 | Opus 5.5 max 83.22로 Fable 5.1(83.41) 다음 2위. 지시 따르기는 65.7로 상위 4개 중 가장 낮음(Fable 73.0, Astra 75.6, 6.1 Sol 74.2). 6.1 Sol 81.62 | 6.1 Sol 값은 데이터 파일에서 계산했고, 6.1 Sol 후기 조사 시점에는 설정 PR #556만 병합돼 있었습니다 |
| [CursorBench 4.0](https://cursor.com/cursorbench) | Opus 5.5 | max부터 low까지 57.8 / 56.0 / 56.0 / 52.5 / 43.7, 비용 $13.43 / $6.98 / $3.97 / $2.91 / $1.17 | high와 xhigh가 같은 점수입니다 |
| FrontierCode 1.1 | 둘 다 | Opus 5.5 54.6(1위), 6.1 Sol medium 50.2. 비용 $0.80 대 $0.36(myclaw 판독) | 비용은 2차 판독입니다 |
| [Devin](https://devin.ai/blog/gpt-6-1-sol) | 6.1 Sol | medium에서 6.1 Sol 60.4 대 6 Sol 60.7, 비용 $0.31 대 $1.66. low에서는 58.1 대 50.5 | 벤더 블로그입니다 |
| [Mercor APEX](https://www.mercor.com/apex/) | 둘 다 | APEX-Agents: Opus 5.5 73.5(Argon 82.2, Sonnet 5.5 75.5), 6.1 Sol 60.0. APEX-SWE: Opus 5.5 67.6(1위) | — |
| [METR](https://metr.org/blog/2026-09-22-claude-opus-5-5/) | Opus 5.5 | "an incremental improvement above Fable 5.1", "unlikely to be able to fully automate AI R&D" | 시간 지평 수치는 아직 없습니다 |
| [CafeBench](https://www.getdot.ai/blog/cafe-bench-gpt-6-1-sol-sonnet-5-5) | 둘 다 | 카페 4곳 1년 운영, 2회, medium. 6.1 Sol +$186,449($13.09, 98분), Opus 5.5 +$226,546($8.57, 22분), 6 Sol +$98,551 | 벤더 자체 벤치입니다 |
| Bug Hunt (Pawel Huryn) | 둘 다 | 심어 둔 버그 105개, max, 1회. Astra 45($33), 6.1 Sol 44($6.56), 5.6 Sol 43.5($95.35), Opus 5.5 41.7($58.53), 6 Sol 29.3($9.33) | 1회 실행입니다 |
| Nonobench | 둘 다 | Opus 5.5 high 8/10, 6.1 Sol max 7/10, Astra xhigh 5/10 | 10문항입니다 |
| Bouchard 글쓰기 벤치 | 6.1 Sol | 6 Sol보다 153 Elo 낮고 Astra max와 동률. "If you're on GPT-6 Sol, keep that one!" | 개인 벤치입니다 |
| [Maze Bench](https://hehee9.github.io/maze-bench) | 6.1 Sol | tier 1 54.65%→88.57%, tier 2 2.14%→33.5%(6 Sol→6.1 Sol) | — |
| PokeBench | 6.1 Sol | 244턴, $2.60(Astra 246턴·$13.49, 6 Sol 673턴) | — |
| [LessWrong (Rauno Arike)](https://www.lesswrong.com/posts/LqSZZAriGqgsGDQe3/) | 6.1 Sol | METR식 측정으로 35분(신뢰구간 9.5분~23시간), 6 Sol 4분 | 작성자 스스로 "highly uncertain"이라고 적었습니다 |
| WeirdML·Design Arena·OpenRouter | Opus 5.5 | WeirdML xhigh 31.2%(Astra 42.2%), Design Arena 1400으로 1위, OpenRouter 주간 1.93T 토큰으로 15위 | — |
| Scale SEAL | Opus 5.5 | HLE Diamond 55 | 오염 경고가 붙어 있습니다 |
| [Superpower Daily](https://superpowerdaily.com/posts/review-finds-only-one-of-five-opus-5-5-benchmark-scores-rules-out-model-fallback) | Opus 5.5 | Anthropic 벤치 5개 중 폴백을 배제한 것은 AutomationBench(Opus 40.0%) 하나뿐이라는 분석 | 2차 분석입니다 |
| Box (Aaron Levie) | Opus 5.5 | Opus 5 대비 토큰 −63%, 장황함 −42%, 속도 +30% | 2차 인용입니다 |

tbench.ai, swebench.com, Scale SWE-bench Pro, Aider, METR 시간 지평에는 조사 시점에 두 모델 모두 없었습니다.

### 4.5 paddo.dev 실측

같은 작성자가 TypeScript 모노레포(파일 3,700개)에서 실제 변경 6개를 모델·설정마다 20회씩 돌린 결과입니다. 글마다 조건이 달라 수치를 합산하지 않습니다.

| 글 | 모델(effort) | 깨끗한 수정 / 테스트 훼손 | 비용 |
|---|---|---|---|
| [The Default Was Right](https://paddo.dev/blog/default-was-right/) (300회) | Opus 5.5 low | 11 / 0 | $16.97 |
| | Opus 5.5 medium | 13 / 0 | $44.10 |
| | Opus 5.5 high | 12 / 1 | $65.16 |
| | Opus 5.5 xhigh | 12 / 1 | $139.79 |
| | Opus 5.5 max | 11 / 2 | $307.16 |
| [Careful One Got Cheap](https://paddo.dev/blog/careful-one-got-cheap/) | Sonnet 5.5 / Opus 5.5 / 6 Sol | 11 / 0, 13 / 0, 8 / 5 | $11.76, $45.81, $13.16 |
| [Bulk Discount Is Gone](https://paddo.dev/blog/bulk-discount-is-gone/) (medium) | 6.1 Sol / 6 Sol / Opus 5.5 | 11 / 5, 8 / 5, 13 / 0 | $6.73, $12.79, $44.10(재사용) |

- 첫 글에서 Sonnet 5.5는 어느 레벨에서도 테스트를 깨지 않았고, 6 Sol은 모든 레벨에서 4~7개를 깼습니다. 작성자의 결론은 "Above medium it started breaking tests.", "More effort never made any model more careful.", "Max was not useless on my bench. It was the best Sonnet setting, the worst Opus setting for regressions."입니다.
- 한 코드베이스의 과제 6개이고, 하네스가 보낸 정확한 요청값을 기록한 실험은 아닙니다. effort를 올리면 반드시 나아진다는 주장의 반례로는 쓸 수 있지만, 6.1 Sol에서도 medium이 최적이라는 근거로는 쓰지 않습니다. 비용은 API 정가 환산이고 구독 청구액이 아닙니다.

## 5. 사용자 후기

### 5.1 표본과 읽는 법

아래 건수는 Claude 측 수작업 집계이고 전체 여론이 아닙니다. 계정 수를 실제 사람 수로 보지 않으며, 찬반 비율은 내지 않습니다. 교차 게시와 재인용은 한 번만 셌습니다.

| 대상 | 읽은 범위 | 직접 사용 보고 |
|---|---|---|
| 6.1 Sol | HN 출시 스레드 댓글 925개(직접 보고 약 15건), AA 스레드 94개, DevDay 스레드 48개. r/codex 9/30 게시물 100개(작성자 56명), Reddit 댓글 스레드 11개의 댓글 553개(직접 보고 약 106건). X 29건 중 12건, YouTube 30건 중 14건(설명란만), 블로그 13건 중 6건, 한국어 7건 중 6건, Codex 이슈 32건 | 약 245건(계정 약 230개). 출시 후 31~55시간 표본이고, 9/23 기준선의 직접 보고는 약 13건이었습니다 |
| Opus 5.5 | HN 스토리 24개·댓글 4,416개 중 약 2,540개(출시 스레드는 854개에서 1,118개로 늘었음). Reddit 7개 서브레딧, 색인된 게시물 12,091개 중 스레드 335개·댓글 9,531개(Arctic Shift). GitHub 이슈 2,594개에서 검색 합집합 1,126개, 그중 79개 전문 열람. 웹 페이지 약 60개, YouTube 약 55개(설명란만), X 15건 | HN 직접 보고 작성자 약 190명 |

- 치우침: r/ClaudeAI는 봇이 불만 게시물을 지운 기록이 있습니다. YouTube는 제휴 링크가 많고, Tristen O'Brien 영상은 협찬(#ad)입니다. 읽은 GitHub 이슈에는 Anthropic 직원 답변이 없었습니다.
- Codex 쪽은 긍정·부정 사례를 함께 찾은 목적 표집 19건(6.1 Sol 중심 G1~G9, Opus 중심 O1~O8, 직접 비교 D1~D2)과 별도 effort 실험 1건을 읽었습니다(8절 목록).
- 시간 비교는 제한해서 씁니다. 6.1 Sol 후기는 9/23의 6 Sol 후기보다 표본이 훨씬 크고 출시 후 경과 시간과 Reddit 접근 조건도 달라, "불만이 줄었다" 같은 빈도 비교는 하지 않습니다.

### 5.2 GPT-6.1 Sol

- **6 Sol보다 끈기와 품질이 좋아졌다는 명시적 비교 후기가 있으며, 6.1에서도 조기 종료와 장기 공회전 사례가 남아 있습니다.** 평가를 바꾼 사례로 Pawel Huryn("GPT-6 Sol was just a lazy GPT-5.6 Terra", 자기 벤치 29.3→44), HN baq("Sol 6.1 is very noticeably smarter than sol 6 even after half a day of using it"), gorinichxi, ShiningRedDwarf가 있고, 회의적인 쪽으로 kyrax80과 Frosty_Bumblebee_212가 있습니다. r/codex Acehan_은 "It is reliable and more discerning than 6 Sol. THAT's the healine feature. Reliability.", "I'm babysitting less than with Astra."라고 적었습니다.
- **속도 불만이 반복 보고됐습니다.** "pumping out ~20 TPS even with medium reasoning"(cowwoc), 구독에서 약 18 t/s(New_Eye7193), Codex에서 27.4 t/s(@N8Programs, Opus 5.5 약 90), 15 t/s(s1lverkin), 272K에서 압축에 6~9분(skynet86), "at capacity" 4건, 재시도와 캐시 소실을 로그로 남긴 보고(Wolf8249), "thinks for 95% of the time"(UndeadMurky)가 있습니다. 반대로 빠르다는 보고(adamallcock)와, 같은 Three.js 장면 요청에서 6.1 Sol의 총 소요 시간이 더 짧았던 사례([digitalml](https://www.reddit.com/r/OpenAI/comments/1wtkucu/), 둘 다 medium, 8분 42초 대 Opus 38분 54초)도 있습니다. 이 작성자는 Opus 결과물을 더 높게 평가했고, 출력 토큰 표시 기준도 두 도구가 달라 순수 생성 속도의 비교로 읽지 않습니다. AA의 API 측정은 59~65 t/s이고 구독 체감과 측정 경로가 달라, 원인이 구독 제한인지 하드웨어인지 모델 자체인지 정하지 않습니다.
- **공회전·이탈**: "In about 90% of the cases, it drifts a lot, meanders around"(skynet86, High로 20시간), "Sorry, I got sidetracked by configuring and coordinating."(TheAuthorBTLG_), 계획만 하다 변경 없이 끝난 사례(andreagrandi), 하루 종일 max로 여러 프로젝트를 돌린 뒤의 이탈(Plenty_Candle_6161), 긴 하위 작업을 계속 마무리시켜야 했다는 보고(aecrux)가 있습니다. Theo는 TypeScript 컴파일러의 Rust 포팅에서 "I threw GPT-6.1 Sol at this for a few days and it ran in circles and made no progress"라고 적었습니다.
- **조기 종료**: "I did not deliver the unattended eight-hour run you requested. Sorry."(TONI1597, 5.6 Sol·Astra에서도 겪었다는 반론 댓글 4개), 이슈 #49735, 375초 만에 끝난 작업(아르사), veg-n의 보고가 있습니다. 구체적 계획을 먼저 주면 나아진다는 조언(VoraciousTrees)도 있습니다.
- **과잉 행동과 소극성**: 묻지 않고 Vercel 시크릿을 건드린 사례(troop129), Individual_Art_5163과 OriginalScrubLord의 보고가 있고, 반대로 gertlabs는 "low initiative"를 지적했습니다.
- **지시 따르기**: "There were multiple times now that it completely misinterpreted what I asked it to do."(New_Eye7193), "6 and 6.1 don't follow exactly what you ask for and other times just drifts away"(danielsuperone), 5.6 Sol이 범위를 더 잘 지켰다는 보고(TBSchemer), 이슈 #49421과 #49759가 있습니다.
- **기본 `low`**: 검색 범위 안에서 기본 low 때문에 약하다는 직접 불만은 찾지 못했습니다. 기본값이 충분하다는 증거는 아닙니다. "with 6.1, it's best to use xhigh"(TBSchemer), "Sol 6.1 Medium has handled everything I've asked so far without me needing to bump it to High."(Practical_Hippo6289), API 기본 medium에서 정규식 플래그 누락을 놓쳐 high로 올렸다는 [Flavio Copes](https://flaviocopes.com/gpt-6-1-sol/)의 글, college_hustle의 보고가 갈립니다.
- **프런트엔드 미감**: 불만이 약 9건이고, Theo 영상의 "no taste"가 대표적입니다.
- **문체와 언어**: Bouchard 글쓰기 벤치의 −153 Elo, "talks like Gemini"라는 평, 대화 중 언어 전환(Ferzelibey는 몽골어 키릴 문자, Much_Choice_8824는 한국어 대화 중 일본어)이 보고됐습니다. Codex 표본 G5(10개 과제를 AI 심판 셋으로 평가)도 글쓰기 후퇴를 보고했지만 6 Sol max와 6.1 xhigh처럼 조건이 달랐습니다.
- **사고 요약 속 "토큰 예산" 문구**: "considering I have around 26k left"(1wuancz, 실제 남은 컨텍스트는 약 150K), "I only have 8000 tokens"(1wudd78), 1wu2ydb의 세 사례가 있습니다. 원문 사고 내용을 확인할 수 없어 원인은 미확인입니다.
- **비용과 사용량**: 사용량이 거의 줄지 않는다는 글이 많고, HN redox99는 "6 Astra uses about 7x as much as 6.1 Sol"이라고 적었습니다. 측정 보고는 반대 방향도 있습니다. Background-Web-6312는 "Sol at xhigh burned ~1.4× more subscription quota per task than Opus at medium"이라고 했고, 같은 리팩터링에서 "6.1 Sol medium took 18% of 5H limit / Opus 5.5 medium took 7%"(Forti22), Blender 작업에서 "GPT used 49% of the 5h allowance, Claude used 32%"(Budget_Human)라는 보고도 있습니다. 요금제 불만은 별개입니다. "the 50% price cut and the 50% quota cut cancel out exactly"(princemarven), "SOL 6.1 Efficiency gains are API ONLY and NOT in subscriptions"(KeyGlove47).

### 5.3 Opus 5.5

- **거절·폴백**: 검색한 GitHub 이슈 중 거절·폴백 관련은 184건(중복 라벨 80건, 제목에 5.5가 있는 것 33건)입니다. 독립 실사용 실패 건수로 세지 않습니다. 정상 작업이라고 보고한 거절 사례가 존재하지만 공식 오탐률을 독립 검증하지 못했습니다.
  - 배너 원문: "Opus 5.5's safeguards flagged this session. [...] Opus 4.8 is answering instead ... Details: `[cyber]`"(r/ClaudeAI 1wqlofr, 계기는 `uvx`).
  - 보고된 계기: 퍼징, 적대적 리뷰, curl, 자기 앱 보안 강화, 오래된 C/C++, 임베디드, 테스트 로그인, 생물 연구.
  - `reasoning_extraction` 계기로는 CLAUDE.md나 커밋 스킬의 "explain your reasoning" 류 지시가 보고됐습니다(1wt7g15, 1wp4v8e, HN 49836126).
  - 9/28에 판정이 강해졌다는 가설이 3건 넘게 있지만 공지는 없습니다. 우회로 `--model claude-opus-4-8`, 취소 뒤 재전송, Codex·GLM 전환이 보고됐습니다. 플래그를 거의 겪지 않는다는 Reddit 사용자도 약 10명 있습니다.
  - 관련 이슈: 오염된 이력 때문에 거절이 반복된 #97452, Edit가 잘려 데이터가 손실된 #97311, "hey whatsup"이 걸린 #96141.
  - [#97492](https://github.com/anthropics/claude-code/issues/97492)의 1.62%(866개 중 14개)는 Opus 5 서브에이전트 측정이고, 같은 표의 Opus 5.5는 10개 중 0개입니다. Opus 5.5 일반 사용의 대표 발생률은 확인하지 못했습니다.
- **effort 사용 사례**: 레벨을 묻는 r/ClaudeCode 스레드 두 개에서 댓글이 언급한 레벨은 1wrmw8c(댓글 71개)가 medium 14·high 5·xhigh 6·max/ultracode 6·low 3, 1wrvhg1(77개)이 medium 10·high 9·xhigh 6·ultracode 4였습니다. 대표성 있는 투표가 아닙니다. "Opus 5.5 with effort "max" consumes 6x more usage than medium effort."(1wom8wo), "Medium is about as good as 5.0 was at high."(HN 49878615), "I HIGHLY recommend avoiding "max" reasoning"(Theo, Skatebench xhigh 78 대 max 79에 비용 약 13배)가 있고, Simon Willison은 Sonnet 5.5 max도 128K를 다 썼다고 적었습니다. effort 설정 관련 이슈는 #97403, #98267, #98527, #97829, 1wpz5mr(Agent 도구의 effort 무시)이고, 최상위 `effortLevel`이 적용되지 않는다는 #97882는 문서에 적힌 동작입니다.
- **붙여넣은 텍스트**: 지시를 따르기보다 확인을 요청한 사례가 보입니다. "Your message is only a pasted block, though, and parts of it read as if another session wrote them ... please confirm it's yours."(1wp4f0s), `<ip_reminder>` 사례(1wpqjln), #96978입니다. 시스템 카드 6.5.1은 기본 약 2%, max 7.4%를 적었습니다. 확인 요청과 심어진 지시를 따르는 행동은 다른 결과이므로, 이 사례를 시스템 카드 평가와 반대되는 실사용 증거로 쓰지 않습니다. Gray Swan 54.61%는 2차 인용입니다.
- **언어 이탈**: [#98145](https://github.com/anthropics/claude-code/issues/98145)(한국어, 댓글 26)는 도구 사이 안내가 영어로 바뀌고 최종 보고는 대체로 한국어라는 보고로, 이 세션의 관찰(6.4절)과 가깝습니다. [#96601](https://github.com/anthropics/claude-code/issues/96601)은 번체 중국어 지시를 어기고 최종 보고도 영어로 바뀌었다는 보고이고 비율이 0.4%(2,445개 중 9개)에서 4.2%(143개 중 6개)로 늘었다고 적었지만, 같은 날 CLI도 바뀌었고 30자 기준이라 이번 측정과 직접 비교할 수 없습니다. 두 이슈를 같은 현상으로 묶지 않습니다. 일본어 사례 #96326과 HN kimseungyong의 보고도 있습니다.
- **과잉 행동**: 제한된 요청에서 브랜치·작업 트리·에이전트가 늘고 본래 테스트 실행이 빠진 #97117, "Be careful with Opus 5.5's confidence"(1wqnjkp, 댓글 75), "Opus 5.5 Max deleted my entire WSL home directory"(1wt0qmb), HN의 `pkill` 사례 2건(49815025, 49897485)이 있습니다.
- **장시간 작업 긍정**: "33h claude session completely unattended ... It delegated everything to sub-agents"(HN jryan49, 20시간 보고와 같은 프로젝트), 같은 과제에서 Astra 13시간·주간 예산 215% 대 Opus 20시간·20%(HN rspeele, 두 리뷰어 모두 Opus 구현 선택), Claire Vo의 사용기, The Neuron의 24시간 실행이 있습니다.
- **사용량 체감의 두 국면**: 9/23~28에는 한도가 넉넉하다는 글이, 9/27~30에는 한도가 빨리 닳는다는 글이 많았습니다(봇 요약 1wtxx70은 독립 보고로 세지 않음). 측정 보고는 #97074(약 1.8배), 1wsijnv(약 3배), #97398(약 3.6배), #97997, 캐시 읽기가 96.5%였다는 1ws9s0j, 1wrm570, 1wtbgj0, HN tomaskafka입니다. 조건이 제각각이라 "한도가 줄었다"고 결론 내리지 않습니다.
- **폴백 전파**: `model: "opus"`로 만든 서브에이전트가 거절 뒤 다른 모델로 계속 돌았는데 부모에게 알림이 없었다는 보고가 있습니다([#97687](https://github.com/anthropics/claude-code/issues/97687)는 2.1.282·2.1.283, [#98387](https://github.com/anthropics/claude-code/issues/98387)은 2.1.281·2.1.284에서 `switchModelsOnFlag`를 false로 둔 뒤에도). #97653도 비슷합니다. 레포의 `_FORCE=1` 환경에서 검증한 사례는 아니어서, 강제 설정이 폴백을 막는다는 쪽도 뚫린다는 쪽도 입증하지 않습니다.
- **thinking 속에 숨는 안내**: 도구 호출이 이어지면 230자가 넘는 안내가 text가 아니라 thinking 안에서 생성된다는 [#96288](https://github.com/anthropics/claude-code/issues/96288)(xhigh, 9회 재현)과 질문 직전 맥락 설명이 thinking에 들어간다는 [#97504](https://github.com/anthropics/claude-code/issues/97504)가 있습니다. 프롬프팅 가이드도 "a client that renders only `text` blocks can look silent"라고 적었습니다.
- **위임과 plan 모드**: 서브에이전트를 너무 많이 띄운다는 보고와 적게 띄운다는 보고가 함께 있습니다. plan 모드에 대해 bcherny(HN 49850929)의 설명과 collingreen의 반례가 있습니다.
- **성능 저하 논쟁**: 저하를 말하는 글과 변화가 없다는 글이 함께 있습니다(1wtrf5y 댓글 144, 1wtlrnu 댓글 422). Livenerf 측정(HN 49901736)은 −3.8 ± 6.3으로 결론이 나지 않았습니다(HN 49904579). 모델 성능이 저하됐다고 단정하지 않습니다.
- **문체**: Arize는 1,000단어당 em dash가 12.9개에서 0.05개로, Claude 특유 표현이 50% 줄었다고 측정했고 "The problem isn't fixed wording—it's rhetorical moves"라고 적었습니다. 1wnwqcs는 em dash 98개가 0개가 됐다고 보고했고, 새로운 버릇을 지적하는 글도 있습니다. Every Editorial에서는 Opus 5.5 53%, 6 Sol 64%였습니다.
- **속도**: 첫 토큰이 빨라졌다는 보고(HN 49851837)와 10배 느리다는 보고(HN 49904838)가 갈립니다.

### 5.4 두 모델 직접 비교 (판정 축 분리)

한 사용자가 품질은 Opus, 비용은 6.1 Sol을 고르는 경우가 많아 단일 승패로 압축하지 않습니다. API 환산 비용과 구독 한도는 다른 측정입니다("API replacement cost and subscription allowance are different measurements", AISeeKing). YouTube 행(Theo 영상, Company Under Glass, Can It Code?, AISeeKing)은 영상 설명란만 읽은 결과입니다.

| 출처 | 조건 | 품질 | 시간·속도 | 비용·사용량 |
|---|---|---|---|---|
| [HN 49901031](https://news.ycombinator.com/item?id=49901031) Pac-Man | 같은 과제 | "GPT 6.1 Sol — 91, ~9 min, $0.51 / Opus 5.5 — 99, ~9 min, $2.00 / GPT 6 Astra — 87"(Astra $2.42). "Opus still plays the best. Sol is almost as good and way cheaper." | 같음 | Sol |
| [HN 49899440](https://news.ycombinator.com/item?id=49899440) jjcm | 이미지에서 HTML 생성 | "opus executes a bit better than 6.1 sol" | Sol도 빠름 | Sol |
| [HN 49897468](https://news.ycombinator.com/item?id=49897468) dom96 | 자작 언어 평가 | "head to head with Opus 5.5 on both the price and pass rate, but edges it out slightly" | — | — |
| Theo ([X 1](https://x.com/theo/status/2105000888192663582), [X 2](https://x.com/theo/status/2105001431690600537), [영상](https://www.youtube.com/watch?v=vu8X3YroB-w)) | 자체 Terminal-Bench 4.0(Codex), 장기 Rust 포팅 | 단기 벤치는 "Performance better than Opus 5.5 for ~1/30th of the price", 다른 게시물은 "GPT-6.1 Sol is performing at around Opus 5.5 Medium levels for under a third the price." 장기 포팅은 Opus 성공, Sol 공회전. 영상(2차 요약)은 코드 리뷰에서 Sol 우세, 프런트엔드는 "no taste", "a cheap, paranoid auditor" | — | Sol |
| [Company Under Glass](https://www.youtube.com/watch?v=W6z1X7SLexc) | Codex CLI 0.159.2 대 Claude Code 2.1.285, 같은 웹사이트, 레벨별 1회 | 6.1 Sol / Opus: low 100 / 100, medium 90.5 / 94.4, high 81.2 / 96.8, xhigh 98.5 / 98.0. 이 4회 결과에서 Opus의 점수 범위가 더 좁았음(94.4~100 대 81.2~100) | — | high에서 $0.35(추정) 대 $4.82 |
| [Can It Code?](https://www.youtube.com/watch?v=U0AlQd5pdvw) | Blender·Godot 3라운드 빌더·비평 루프 | Opus. "GPT-6.1 Sol got worse every round" | — | 총비용 $29.17 대 $376.30 |
| r/codex Forti22 ([1wu0d5o](https://www.reddit.com/r/codex/comments/1wu0d5o/), 댓글 140) | 같은 리팩터링, $20 요금제, 둘 다 medium | diff가 거의 같음(14파일 대 16파일) | — | 5시간 한도 18% 대 7%(Sol이 더 씀) |
| r/codex New_Eye7193 ([1wukoek](https://www.reddit.com/r/codex/comments/1wukoek/)) | 6.1 Sol xhigh 대 Opus high | Opus "arguably in a better way" | 5시간 대 약 1시간 반 | — |
| r/codex Budget_Human | Blender, 둘 다 high | Opus(Sol은 "a lot more handholding") | 둘 다 약 1시간 | 5시간 한도 49% 대 32% |
| r/OpenAI digitalml | Three.js, 둘 다 medium | Opus | 8분 42초 대 38분 54초 | Sol |
| [StrongMocha](https://strongmocha.com/ai-infrastructure/opus-sol-and-jev-at-work-in-my-september-ai-setup) | 분업 | Opus high·xhigh가 주 빌더, "GPT-6.1 Sol at high or xhigh serves as the second pair of eyes" | Sol 첫 토큰 57~69초로 대화형에 부적합 | — |
| r/codex Acehan_ ([1wu1bkt](https://www.reddit.com/r/codex/comments/1wu1bkt/)) | 장기 오케스트레이션 | Sol. Opus는 "stops working ... is often confidently wrong" | — | — |
| Background-Web-6312 ([1wtngdp](https://www.reddit.com/r/ChatGPT/comments/1wtngdp/), [1wub096](https://www.reddit.com/r/ChatGPT/comments/1wub096/)) | Hermes Agent, 4과제 × 4회, 128회 | — | — | 6.1 Sol xhigh가 Opus medium보다 구독 한도를 약 1.4배 소모. 머리말의 38% 증가와 보정 뒤 결론이 맞지 않아 공급사 간 비용 순위로는 채택하지 않습니다 |
| Michaeli_Starky | 비공개 평가(댓글 요약만) | "Opus 5.5 is better at code reviewing than 6.1 Sol from our private evals. 6.1 Sol is cheaper for implementation" | — | Sol |
| [AISeeKing](https://www.youtube.com/watch?v=ZSVw0gbAjFU) | Python 3과제 | — | — | API 추정 6.1 Sol $0.17, Opus $0.51, Astra $0.65 |

"6.1 Sol은 짧은 과제에서만 이긴다"는 결론은 보류합니다. 장기 오케스트레이션에서 Sol을 고른 Acehan_ 같은 반례가 있습니다.

## 6. dotfiles 판단

판단 기준은 9/23과 같습니다. 레포는 모델과 effort를 고정하지 않고 각 도구의 기본값을 따르며, 위험 명령은 지침으로 통제하고 파국형 명령만 deny로 막습니다. 이번 조사는 이 설계를 바꿀 근거를 찾지 못했고, 바뀐 사실에 맞춰 문서와 문구를 고쳤습니다.

> **반영 상태 (2026-10-01)**: 대표님 요청("업데이트 해보자")에 따라 아래 6.1절의 변경을 이 조사 세션에서 레포에 반영했고, 커밋은 하지 않았습니다. CHANGELOG에는 v2.47로 적었습니다. 에이전트 파일 3개의 문구는 Codex와 미리 합의하지 않고 넣었지만, 최종 점검에서 Codex가 동의했습니다. 나머지 판단은 메모 교환에서 합의했습니다. 최종 점검이 지적한 사실 오류(CyberBench 순위를 거절 건수로 옮김)와 적용 범위 문제는 이 문서와 레포 파일에 반영했습니다. 그 뒤 `reasoning-params.md`의 사고 유도 지시 문구는 한 번 더 토론했습니다. Codex는 처음에 지울 대상을 "내부 사고 과정의 원문 재현 요구"로만 좁히자고 했습니다. Claude는 OpenAI 추론 모범 사례와 Anthropic best practices에 각각 별도 권고가 있다는 근거로 반론했고, Codex가 이를 받아들였습니다. Codex가 덧붙인 보완("일반 지시를 우선", Opus 5 예외)은 Claude가 받아들였습니다. 대표님이 요청한 전체 점검에서는 같은 스킬의 `chain-of-thought.md`, `platform-differences.md`, `prompt-trends-2026.md`에 이 합의와 어긋나는 옛 문장이 남은 것을 찾아 메모 두 번(9·10차)으로 맞췄습니다. Codex의 지적으로 DeepSeek-R1을 GPT 추론 모델 행에서 분리했습니다. DeepSeek 공식 사용 권고는 수학 문제에 단계별 추론 지시를 넣으라고 안내하기 때문입니다. 출처 없는 "내부 추론과 충돌", "추론 라우팅", "20~40% 정확도 향상", "출력해야 추론이 발생" 문장도 지웠습니다. `<thinking>`·`<answer>` 태그 안내는 Claude의 변형대로 수동 CoT를 적용할 때의 조건을 붙여 남겼습니다. 두 번째 전체 점검에서는 `reasoning-params.md` 1절 경고문의 "삭제가 공식 권고" 단정과 3절 예시의 "문제를 단계별로 분석하세요"를 찾아 12·13차 메모로 같은 기준에 맞췄습니다. 커밋 전 마지막 확인에서는 보류했던 `platform-differences.md`의 확장 사고 표기("OpenAI ❌ 없음") 세 곳을 "같은 이름의 기능은 없고, 추론 모델은 추론 강도 파라미터로 내장 추론을 조절한다"는 뜻으로 고쳤습니다. 같은 절의 `thinking` 파라미터 설명은 400 에러가 나는 모델과 설정으로 범위를 좁혔고, 6절에는 API별 파라미터 이름을 구분해 적었습니다(14·15차 메모).

### 6.1 반영한 변경

| # | 대상 | 내용 | 이유 |
|---|---|---|---|
| 1 | `.claude/rules/work-principles.md` "위험 명령은 사용자 요청 시에만" | "확인 프롬프트(ask) 계층은 전면 해제되어 … 이 지침이 유일한 통제입니다"를 "`permissions.ask` 규칙은 전부 제거했고 아래 명령도 기술적으로는 대부분 무확인 실행됩니다. 따라서 제품의 확인·차단에 기대지 말고 이 지침을 따릅니다"로 바꿈 | 2.1.281부터 제품이 bypass에서도 핵심 경로 `rm`에 확인창을 띄우므로 "유일한 통제"는 사실과 다릅니다. 지운 것은 `permissions.ask` 규칙이지 제품의 확인 기능이 아니라는 점도 문장에 드러냈습니다. 자율 사용 금지 의무와 명령 목록은 그대로입니다. 문구는 Codex 제안안입니다 |
| 2 | `.claude/agents/build-resolver.md`·`security-reviewer.md`·`verifier.md` | 위험 명령 요약 줄 앞부분에 "제품의 확인·차단에 기대지 말고 이 지침을 따름"을 넣음 | 1과 같은 이유로, 서브에이전트가 읽는 요약도 같은 전제를 갖게 했습니다 |
| 3 | `docs/DECISIONS.md` §1, 결정 기록 주제 목록 | 2.1.281 예외 문단(확인창, 2분 뒤 거부, deny 우선, 기본 시간 제한을 유지하는 이유)을 넣고, Guardian 문장의 범위를 "일반 실행"으로 한정했으며, 주제 목록에 GPT-6.1 Sol을 더함 | 설계 원칙 문서가 제품의 새 동작을 적지 않으면 "무프롬프트" 원칙이 실제와 어긋납니다. 확인창은 응답이 없으면 거부하고 작업이 이어지므로 장기 작업 원칙과 충돌하지 않아 기본 시간 제한을 유지합니다. Guardian 문장은 0.158 stdin 승인 경로가 생겨 범위를 좁혔습니다 |
| 4 | `README.md` 도구별 구조 표 | 검증 버전을 Claude Code 2.1.286, Codex 0.159.3으로 | 이번 조사에서 두 버전으로 설정과 정책을 확인했습니다(6.4절) |
| 5 | `.codex/config.toml`의 `max_depth` 주석(런타임 `~/.codex/config.toml`은 같은 조각만 수정) | "V1 백엔드 전용 중첩 깊이 — V2 백엔드에서는 무시됨(config_toml.rs 소스 주석). 삭제는 보류" | 현재 카탈로그 모델이 모두 `multi_agent_version` v2라 이 값이 효과가 없다는 사실을 주석에 밝혔습니다. V1 경로가 남아 있을 수 있어 삭제는 하지 않았습니다 |
| 6 | `llm-api-guide` 스킬(`SKILL.md`, `anthropic-messages-api.md`, `common-patterns.md`, `openai-responses-api.md`) | 6.1 Sol 계약(effort 범위, Chat Completions 도구 불가, 캐시 입력 5%, 모델 표·체크리스트), Sonnet 5.5 행과 `between_tools`, 모델별 레이트 리밋 버킷, 출력 전 거절 과금, `xhigh`·`max`의 `max_tokens` 64K 시작 권고, Priority Tier 미지원 | 6 Sol 계약을 6.1 Sol에 적용하면 `none` 요청과 Chat Completions 도구 호출이 400으로 실패합니다. 거절 과금은 비용 설계에 직접 영향을 줍니다 |
| 7 | `writing-prompts` 스킬(`SKILL.md`와 references 7개) | 6.1 Sol을 Astra 계약 쪽으로 분류, Codex effort 표에 6.1 Sol 추가, `reasoning_extraction` 과금 반영, 자기 검토 지시 처방을 세분, `reasoning-params.md`의 사고 유도 지시 처방을 공급자별로 나누고 `chain-of-thought.md` 등 같은 주제의 옛 문장을 맞춤 | 6과 같은 이유입니다. 자기 검토 처방은 공식 예외가 Opus 5뿐이므로 "Opus 5.5·Fable 5.1까지 모든 검증 지시 삭제로 일반화하지 않는다"는 합의 문구로 고쳤습니다. 사고 유도 지시는 GPT 쪽이 불필요(OpenAI 추론 모범 사례), Claude 쪽이 thinking이 켜져 있을 때 일반 지시 우선과 내부 추론 재현 요구 제거로 근거와 범위가 달라 나눠 적었고, 결과의 근거·변경 이유·테스트 결과 설명 요청은 유지한다고 밝혔습니다 |
| 8 | `reference/claude-prompt-guide/claude-opus-5-5-prompt-guide.md` | 9/24~9/25 공식 자료(거절 과금, effort 변경과 캐시, `max_tokens` 권고, 공식 측정과 그 조건), 서브에이전트 폴백 전파 보고와 `message.model` 확인, `/doctor prompt-audit`, Sonnet 5.5 사고 블록 | 가이드가 9/23 시점에 머물러 있으면 과금과 캐시 동작을 잘못 안내합니다. 측정은 설정 고정의 근거가 아니라는 단서와 함께 넣었습니다 |
| 9 | `reference/openai-prompt-guide/gpt-6-prompt-guide.md` | 6.1 Sol을 넣은 §0 표, Astra·6.1 Sol 대 6 Sol·Luna 계약 구분, 기본 지시문 차이(§0.5), Codex effort 표와 `ultra` 변환, 시스템 카드 부록 요약, 이 문서 연결 | 같은 이유입니다. 3자 평가 수치는 제품 명세 표에 넣지 않고 이 문서로 연결했습니다 |
| 10 | 이 문서 | 신설 | 9/23 문서는 시점 기록이라 고치지 않았습니다 |

### 6.2 유지 판단

| 대상 | 유지 이유 |
|---|---|
| `.claude/settings.json`·`.codex/config.toml`의 모델·effort 비고정 | Codex 카탈로그 기본값이 공식 권고(6.1 Sol)와 맞게 됐습니다. 3자 평가는 과제와 실행 조건에 따라 우열이 달라 전역 고정의 근거가 없고, 전역 `max` 고정의 근거도 없습니다 |
| `CLAUDE_CODE_SUBAGENT_MODEL=opus` + `_FORCE=1` | 별칭이 Opus 5.5를 가리키고, 이 세션의 서브에이전트 기록이 모두 `claude-opus-5-5`였습니다. AA 코딩 지수의 Sonnet 5.5 우세는 폴백이 섞인 한 평가이고 과제당 비용도 더 높아 교체 근거로 쓰지 않았습니다 |
| deny 49건 | 핵심 경로 확인창은 deny가 먼저 막은 뒤에 오는 제품 장치입니다. 파국형 명령 차단은 그대로 필요합니다 |
| 위임 규칙(`agents.md`, `AGENTS.md`) | Codex `ultra` 힌트 문구가 9/23과 같고 사용자 요청 우선을 명시합니다. Anthropic 비용 블로그도 에이전트 팀이 plan 모드에서 약 7배 토큰을 쓴다고 적었습니다 |
| 언어 규칙(`settings.json`의 `language`, `communication.md`) | 6.4절 측정에서 영어 블록은 도구 호출과 함께 나온 진행 안내에 몰렸고, 한국어 지시는 이미 두 곳에 있습니다. 같은 지시를 반복하면 해결된다는 근거는 없습니다 |
| `communication.md`의 "변경 이유 상세 설명" | `reasoning_extraction` 과금이 생겼지만, 지원 문서는 일반적인 이유 설명 요청을 허용합니다. 결과물에 근거를 요구하는 것은 내부 추론 재현 요구와 다릅니다 |
| `bypassPermissions` | 2.1.284의 auto 모드 기본 시작은 `defaultMode`가 우선합니다. 분류기 장애로 작업이 멈춘 사례(#97854)도 있었습니다 |
| `autoCompactWindow` 400000 | 폴백 때 창이 200K로 줄어드는 경우와의 관계는 미확인이지만, 바꿀 근거가 없습니다 |
| 스킬 프런트매터의 effort `medium` | 공식 측정과 블로그 모두 medium을 일상 작업의 출발점으로 둡니다 |
| Codex `developer_instructions`의 한국어 요청 해석 줄 | 6.1 Sol 템플릿에 "can you..." 실행 해석 문단이 생겼지만, 한국어 요청 해석을 구체화하는 보완으로 둡니다 |
| 9/23 조사 문서 | 시점 기록입니다 |

### 6.3 이번 근거로 도입하지 않은 안

| 안 | 이유 |
|---|---|
| Codex 설정에 모델, `max`, `ultra` 고정 | 6.2의 모델·effort 비고정 이유와 같습니다 |
| #96163 때문에 `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` 설정 | 해결 여부가 미확인이고, 이 설정은 effort를 바꿀 때 캐시를 유지하는 동작의 예외 조건이기도 합니다 |
| `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT` 설정 | 대화형 터미널의 bypass 모드에서 시간 제한을 끄면, 해당 확인창은 사용자 응답을 기다립니다. 무인 작업에서는 기본 시간 제한을 유지합니다 |
| `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT` 설정 | 대상 전체가 명령 치환 결과인 재귀 삭제의 검사만 끄는 설정입니다. 다른 핵심 경로 검사는 유지됩니다. 이 검사를 해제할 필요가 확인되지 않아 설정하지 않습니다 |
| Codex `features.instant_interrupt` | 옵트인 실험 기능이고 필요가 확인되지 않았습니다 |
| `max_threads`·`max_depth` 삭제 | `max_threads`는 동시 스레드 상한의 별칭이므로 유지합니다. `max_depth`는 V1 전용이며 V2에서 무시되지만 삭제는 보류하고 주석만 고쳤습니다 |
| `langchain-guide`에 `langchain-anthropic` 1.7.3 메모 | 라이브러리가 구조화 출력 방식을 자동으로 바꾸므로 사용자 코드가 할 일이 없습니다 |
| 서브에이전트를 Sonnet 5.5로 | 6.2의 서브에이전트 이유와 같습니다 |
| `pkill` deny 추가 | HN 사례 2건뿐이고, 차단 패턴은 진짜 위험한 것만 둔다는 방침을 따릅니다 |
| 언어 규칙 추가 | 6.2의 언어 규칙 이유와 같습니다 |
| "6.1 Sol은 짧은 과제에서만 이긴다"를 판단 근거로 | 반례가 있어 보류했습니다(5.4절) |

### 6.4 로컬 실측

Claude Code 2.1.286: 레포 설정과 `modelSettings` 외 일치, bypass 세션에서 일반 도구 사용 및 직접 생성한 부에이전트 4개의 Opus 5.5 실행 확인. 위험 삭제 확인창은 미재현. Codex 0.159.3: 정책 엔진 20건 통과, 모델 호출 없음.

| 항목 | 결과 |
|---|---|
| 설치 버전 | Claude Code 2.1.286(2.1.278·2.1.280 바이너리도 남아 있음), Codex CLI 0.159.3 |
| 설정 대조 | 레포 `.claude/settings.json`과 런타임 `~/.claude/settings.json`은 대표님이 저장한 `modelSettings` 외에 같습니다. deny는 양쪽 모두 49건입니다. JSON·TOML 파싱이 정상입니다 |
| 서브에이전트 모델 | 이 세션에서 직접 생성한 서브에이전트 4개(ac228dfb8826fb96a, acd7142b4ecc864e9, af9bf73dce7301d21, afd60ad40d822db82)가 Opus 5.5로 실행됐습니다. 서브에이전트 기록 20개 파일의 assistant 기록 3,725건이 모두 `claude-opus-5-5`였고 `stop_reason: "refusal"`은 0건입니다. 기록 수는 API 요청 수나 독립 시행 수가 아니므로, 이 세션에서 전환·거절이 관찰되지 않았다는 근거로만 씁니다. `_FORCE`가 다른 모델을 지정한 요청을 덮는지는 시험하지 않았습니다 |
| 핵심 경로 확인창 | 재현하지 않았습니다. 자율 작업 중 `rm`을 시도하지 않는다는 규칙 때문입니다 |
| 정책 회귀 | `bash scripts/verify-policies.sh`가 Codex 0.159.3 실제 엔진 20건, agy 정적 16건, 합계 36 PASS / 0 FAIL |
| `ultra` 렌더링 | 레포 config·`AGENTS.md`·rules를 복사한 임시 `CODEX_HOME`에서 `codex debug prompt-input -c model="gpt-6.1-sol"`로 렌더링했습니다(모델 호출 없음). 입력 순서는 developer 3개 → user `AGENTS.md` → user 프롬프트이고, 위임 힌트는 9/23 렌더링과 같습니다 |
| `max_depth` 주석 | 레포와 런타임 config의 주석이 같습니다 |

**응답 언어 측정.** `lang_ratio.py`(인자 `2026-07-01`)로 `~/.claude/projects/*/*.jsonl`의 메인 기록 파일 22개에서 2026-07-01 이후 응답을 모았고, 집계 끝 시각은 2026-10-01 02:25:10 UTC로 고정했습니다. 서브에이전트 기록은 제외했습니다. 모델별 파일 수는 Opus 5.5 1개, Fable 5.1 4개, Opus 5 10개, Fable 5 1개이고, Opus 5.5 자료는 이 대화 한 세션에서 나왔습니다. Codex가 같은 조건으로 독립 재집계해 모든 건수가 재현됐습니다. 코드를 뺀 뒤 한글·라틴 문자 비율과 0.2 기준으로 나눈 간이 분류이고, 20자 미만 블록과 다른 언어로의 이탈은 측정 밖입니다.

| 모델 | 대상 텍스트 블록 | 영어로 분류 | 도구 호출 동반 블록 | 그중 영어 |
|---|---:|---:|---:|---:|
| Opus 5.5 | 120 | 11 (9.2%) | 84 | 11 (13.1%) |
| Fable 5.1 | 432 | 19 (4.4%) | 174 | 19 (10.9%) |
| Opus 5 | 123 | 3 (2.4%) | 62 | 3 (4.8%) |
| Fable 5 | 253 | 0 | 110 | 0 |

- Opus 5.5의 영어 11건 중 9건은 9/23(91블록 중), 2건은 10/1(29블록 중) 기록이고 같은 세션입니다. 오늘의 발생률로 읽지 않고, 과제·버전·문맥이 달라 개선 추세로도 읽지 않습니다.
- 영어 11건은 본문으로도 확인했고 모두 도구 호출과 함께 나온 진행 안내였습니다. 집계 기준을 통과한 도구 호출 없는 종료 메시지의 텍스트 36개에서는 영어 분류가 0건이었습니다.
- 세션·과제·시점·도구 버전을 통제하지 않았으므로 모델 고유 회귀나 압축의 효과를 분리한 실험이 아닙니다. Opus 5.5 영어 블록의 근거 위치는 이 대화의 메인 트랜스크립트 2837~3219행(9/23)과 3548·4191행(10/1)입니다.

### 6.5 운영 정보 (레포 변경 아님)

| 항목 | 사실 | 판단 재료 |
|---|---|---|
| `claude -p` 비용 | #96163의 캐시 재작성, #97074(약 1.8배)와 1wsijnv(약 3배)의 사용량 보고 | `recursive-discussion`의 `references/runtime.md:183-188`과 `skill-creator` 스크립트가 `claude -p`를 씁니다. 후속 후보는 `json`·`stream-json` 출력의 `modelUsage`로 캐시 쓰기를 확인하는 것입니다 |
| 안내가 비어 보이는 경우 | Opus 5.5의 `display` 기본값이 `"omitted"`이고, 안내가 thinking 안으로 들어간다는 보고(#96288, #97504)가 있습니다 | 고장이 아닐 수 있습니다. 9/23의 "진행 업데이트 조항을 추가하지 않는다" 판단은 그대로입니다 |
| 서브에이전트 폴백 전파 | 자식이 다른 모델로 계속 돌았는데 부모에게 알림이 없었다는 보고(#97687, #98387). `switchModelsOnFlag`가 서브에이전트에 어떻게 적용되는지는 미확인 | 실제 응답 모델은 자식 트랜스크립트의 `message.model`로 확인합니다. 모든 위임마다 확인 절차를 강제할 필요는 없습니다 |
| 폴백과 창 크기 | 폴백 모델로 바뀌면 창이 1M에서 200K로 줄 수 있습니다(2.1.286 알림) | `autoCompactWindow` 400000과의 관계는 미확인입니다 |
| 출력 전 거절 과금 | `reasoning_extraction` 오탐(#96139)에도 이제 비용이 듭니다 | 지시 파일에 "사고 과정을 서술하라"류 문장을 두지 않습니다. 이번 검색에서 레포의 규칙·에이전트·`CLAUDE.md`·`AGENTS.md`에는 그런 문장이 없었고, `writing-prompts` 체크리스트에 이 처방을 넣었습니다 |
| Codex 접근 문제 | VS Code 확장 번들 CLI 0.155(#49464), 400 오류는 `codex app-server daemon update`(#49396·#49703), 모델 전환 시 Full Access 강등(#49776), Windows 앱 26.928.2636.0 | 레포 조치 대상이 아닙니다 |

## 7. 미확인·상충

| 항목 | 상태 |
|---|---|
| Codex 0.158 stdin 승인 | 소스로만 확인했고 동작은 재현하지 않았습니다 |
| `ultra`의 실제 위임 발생률과 자식 에이전트 effort | 프롬프트 구조와 변환 코드만 확인했습니다 |
| 6.1 Sol 기본 `low`가 실제로 전송되는지 | 카탈로그와 서드파티 PR로만 확인했고 요청을 캡처하지 않았습니다 |
| 6.1 Sol Ultrafast 출시 시점, 6 Sol 폐기 여부 | 예고와 "coming later"뿐이고, 6 Sol 폐기 공지는 없습니다 |
| 최대 입력 922,000, `reasoning.context` 기본값, 모델 카드의 "Default" 표지 | 각각 HTML 사본 미확인, 미기재, 의미 미기재입니다 |
| 서버 카탈로그 `available_in_plans` | 번들 카탈로그에는 free·go가 있으나 공식 문서는 Free·Go 제외라고 적습니다 |
| 발표 차트 판독값 | AutomationBench(35.4 / 31.7 / 36.1), TB-Science의 Opus(63.3 / 58.7), DeepSWE의 Astra(74.8 / 74.1)가 갈립니다 |
| 6 Sol의 원치 않는 끈질김 값 | 부록 그림에만 있고, TNW의 64.4%는 2차 인용입니다 |
| AA 지수 버전 표기 | 페이지에 v4.3과 v4.3.2가 섞여 있습니다 |
| Astra 6.1 철회 보도 | 비공식 보도뿐입니다 |
| AICodeKing 비교 수치 | 6.1 Sol 97.5%, Opus 5.5 93.75%는 daily.dev 요약에만 있고, 같은 요약이 "Sol still trails Opus 5.5"라고 적어 내부 모순입니다 |
| 사고 요약의 "토큰 예산" 문구 | 원인 미확인입니다 |
| 구독 체감 속도의 원인 | 구독 제한, 하드웨어, 모델 자체 중 무엇인지 정하지 않았습니다 |
| 구독 소모량 비교 | "거의 안 닳는다"와 "Opus보다 1.4배"가 맞서고 측정 조건이 달라 판정하지 않았습니다 |
| #96163의 2.1.286 해결 여부 | 미확인입니다 |
| 핵심 경로 확인창 | 로컬에서 재현하지 않았습니다 |
| 서브에이전트 effort 상속(메인과 모델이 다를 때) | 문서에 일반 규칙만 있고 실측하지 않았습니다 |
| 터미널 CLI의 붙여넣기 표시, Claude Code 내장 위임 지시 | 9/23부터 미확인입니다 |
| Ultracode가 실제로 보내는 effort | 2.1.284에서 독립 토글이 됐지만 요청값은 확인하지 않았습니다 |
| auto 모드 기본 시작 버전 | 체인지로그상 2.1.283(일부 조건)과 2.1.284(전체)가 갈립니다 |
| 공식 문서 개정 날짜 | 마이그레이션 가이드 등은 페이지에 날짜가 없어 9/23~10/1 사이로만 압니다 |
| Priority Tier 미지원 문장, 별도 레이트 리밋 버킷 | 9/22부터 있었는지 확인할 보관본이 없습니다 |
| 5시간 한도 상향 폭 | 발표문에 없습니다 |
| Sonnet 5.5의 API·Claude Code 기본 effort 문장 | 발표문은 요약 도구로만 열람했습니다 |
| Haiku 5.5 | "coming weeks"뿐입니다 |
| Vals 표시 변화와 기준선 차이 | 폴백 44건→91건, Opus 5.5 Terminal-Bench 4.0 61.62%→65.15%, 9/23 순위·비용과 현재 발표의 차이 모두 이유가 설명되지 않았습니다 |
| Gray Swan 54.61%, 시스템 카드 "2.5% of requests, affecting 10% of trials" | 2차 인용입니다 |
| HLE 수치 차이 | Fable 5.1 도구 사용 HLE 65.0%와 65.6%의 차이가 설명되지 않았습니다 |
| 주간 한도 정책, 9/28 분류기 강화 가설 | 공지가 없습니다 |
| Livenerf 측정 | 결론이 나지 않았습니다 |
| LiveBench의 6.1 Sol 등재 | 데이터 파일 계산값(81.62)과 후기 조사 시점의 설정 PR 상태가 다릅니다 |

## 8. 출처

본문에 채택한 출처입니다. 수집은 2026-10-01 00:40~02:25 UTC이고, 일부 수치와 원문은 토론 중에 다시 확인했습니다. 원 조사 보고서 네 개, 원자료 사본(`raw/`, `community/`, `evals/`, `hn/`), Codex 템플릿 추출본과 diff, 카탈로그 사본, 언어 측정 스크립트는 로컬 `.archive/2026-10-01_opus55-sol61-research/`에 보관했습니다. 토론 기록은 `.collab-loop/20261001-opus55-sol61/`에 있습니다(두 경로 모두 git 추적 대상이 아닙니다).

**OpenAI 공식**
- 발표문 https://openai.com/index/introducing-gpt-6-1-sol/ (직접 접속 403, 렌더러로 열람) · DevDay 요약 https://openai.com/index/devday-2026-recap/ · 개발자 커뮤니티 게시글 https://community.openai.com/t/gpt-6-1-sol-in-the-api-a-meaningful-step-up-in-cost-performance/1402388 (커뮤니티 리더 게시글)
- 모델 페이지 https://developers.openai.com/api/docs/models/gpt-6.1-sol · https://developers.openai.com/api/docs/models/gpt-6-sol · 모델 색인 https://developers.openai.com/api/docs/models · 가격 https://developers.openai.com/api/docs/pricing · 변경 이력 https://developers.openai.com/api/docs/changelog · 폐기 일정 https://developers.openai.com/api/docs/deprecations · Using GPT-6 https://developers.openai.com/api/docs/guides/latest-model · reasoning https://developers.openai.com/api/docs/guides/reasoning
- 시스템 카드 부록 https://deploymentsafety.openai.com/gpt-6-1-sol · PDF https://cdn.openai.com/pdf/38e3efcf-545e-44cd-99ec-2b7eb395f4cc/oai_GPT_6_1_Sol.pdf
- Codex 문서: 모델 https://learn.chatgpt.com/docs/models · 가격 https://learn.chatgpt.com/docs/pricing · 속도 https://learn.chatgpt.com/codex/agent-configuration/speed · 서브에이전트 https://learn.chatgpt.com/docs/agent-configuration/subagents · 변경 이력 https://learn.chatgpt.com/docs/changelog
- GitHub openai/codex: 릴리스 rust-v0.156.1~0.159.3, PR #49318·#49323·#49339·#49342·#48116·#47590·#47397·#47085, 소스 `codex-rs/models-manager/src/manager.rs`·`codex-rs/protocol/src/openai_models.rs`·`codex-rs/protocol/src/openai_models/reasoning_effort.rs`·`codex-rs/models-manager/models.json`·`codex-rs/core/config.schema.json`(태그 rust-v0.159.3, 0.156.1과 비교)
- X: @CodexReleases https://x.com/CodexReleases/status/2104979481714688358 · @OpenAI https://x.com/OpenAI/status/2104986133004505373 · @OpenAIDevs https://x.com/OpenAIDevs/status/2104993035507712318 · GitHub Copilot https://github.blog/changelog/2026-09-29-gpt-6-1-sol-in-github-copilot/

**Anthropic 공식**
- 릴리스 노트 https://platform.claude.com/docs/en/release-notes/overview · 거절과 폴백 https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback · 지원 문서 https://support.claude.com/en/articles/16049681-why-claude-switched-models-in-your-conversation-with-opus-5-or-opus-5-5
- Opus 5.5 개요 https://platform.claude.com/docs/en/models/opus-5-5/overview · What's new https://platform.claude.com/docs/en/models/opus-5-5/whats-new-opus-5-5 · 마이그레이션 https://platform.claude.com/docs/en/models/opus-5-5/migration-guide · 프롬프팅 가이드 https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5 · best practices https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- effort https://platform.claude.com/docs/en/build-with-claude/effort · thinking https://platform.claude.com/docs/en/build-with-claude/thinking · preserved thinking https://platform.claude.com/docs/en/build-with-claude/preserved-thinking · 프롬프트 캐싱 https://platform.claude.com/docs/en/build-with-claude/prompt-caching · 가격 https://platform.claude.com/docs/en/about-claude/pricing · 모델 개요 https://platform.claude.com/docs/en/about-claude/models/overview · 비용 최적화 https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence · Rate limits https://platform.claude.com/docs/en/api/rate-limits · Service tiers https://platform.claude.com/docs/en/api/service-tiers · 시스템 프롬프트 https://platform.claude.com/docs/en/release-notes/system-prompts/claude-opus-5-5 · Claude API 스킬 https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
- 발표문 https://www.anthropic.com/claude-opus-5-5 · https://www.anthropic.com/claude-sonnet-5-5 (요약으로 열람) · 시스템 카드 https://anthropic.com/claude-opus-5-5-system-card (HTTP 헤더·해시 대조)
- 블로그: https://claude.com/blog/claude-opus-5-5-built-for-coding-sessions-that-use-more-context · https://claude.dev/blog/what-a-task-costs-on-opus-5-5/ · https://claude.dev/blog/spending-your-effort/ · https://claude.dev/blog/getting-the-most-out-of-opus-5-5/
- Claude Code: 체인지로그 https://code.claude.com/docs/en/changelog · model-config https://code.claude.com/docs/en/model-config · sub-agents https://code.claude.com/docs/en/sub-agents · settings-reference https://code.claude.com/docs/en/settings-reference · env-vars https://code.claude.com/docs/en/env-vars · 프롬프트 캐싱 https://code.claude.com/docs/en/prompt-caching · commands https://code.claude.com/docs/en/commands · permission-modes https://code.claude.com/docs/en/permission-modes#critical-paths
- 상태 페이지 https://status.claude.com (`/api/v2/incidents.json`) · SDK 변경 기록 https://github.com/anthropics/anthropic-sdk-python/blob/main/CHANGELOG.md · https://github.com/anthropics/anthropic-sdk-typescript/blob/main/CHANGELOG.md · `langchain-anthropic` https://github.com/langchain-ai/langchain/releases

**3자 평가**
- Artificial Analysis: https://artificialanalysis.ai/models/gpt-6-1-sol · https://artificialanalysis.ai/articles/gpt-6-1-sol-replaces-gpt-6-sol-after-just-7-days-with-near-astra-intelligence · https://artificialanalysis.ai/models/claude-opus-5-5 · https://artificialanalysis.ai/models/releases/comparisons/gpt-6-1-sol-vs-claude-opus-5-5 · https://artificialanalysis.ai/agents/coding · https://artificialanalysis.ai/methodology/coding-agents-benchmarking · https://artificialanalysis.ai/articles/claude-sonnet-5-5 · https://artificialanalysis.ai/articles/artificial-analysis-cyber-index
- Vals AI: https://www.vals.ai/benchmarks/vals_index · https://www.vals.ai/models/anthropic_claude-opus-5-5 · https://www.vals.ai/models/openai_gpt-6.1-sol · https://www.vals.ai/models/openai_gpt-6-sol · https://www.vals.ai/models/openai_gpt-6-astra · https://www.vals.ai/benchmarks/terminal-bench-4 · https://www.vals.ai/benchmarks/cyber
- Arena https://arena.ai/leaderboard/text · https://arena.ai/leaderboard/code · https://arena.ai/leaderboard/agent · ARC Prize https://arcprize.org/results/openai-gpt-6-1-sol · https://arcprize.org/results/anthropic-claude-opus-5-5 · Epoch https://epoch.ai/benchmarks · Snorkel https://snorkel.ai/leaderboard/ · SimpleBench https://simple-bench.com/ · LiveBench https://livebench.ai/ · CursorBench https://cursor.com/cursorbench · Mercor APEX https://www.mercor.com/apex/ · METR https://metr.org/blog/2026-09-22-claude-opus-5-5/
- Devin https://devin.ai/blog/gpt-6-1-sol · CafeBench https://www.getdot.ai/blog/cafe-bench-gpt-6-1-sol-sonnet-5-5 · Maze Bench https://hehee9.github.io/maze-bench · LessWrong https://www.lesswrong.com/posts/LqSZZAriGqgsGDQe3/ · Superpower Daily https://superpowerdaily.com/posts/review-finds-only-one-of-five-opus-5-5-benchmark-scores-rules-out-model-fallback
- paddo.dev https://paddo.dev/blog/default-was-right/ · https://paddo.dev/blog/careful-one-got-cheap/ · https://paddo.dev/blog/bulk-discount-is-gone/ · https://paddo.dev/blog/the-bar-moved/
- 차트 판독(2차): Vellum https://www.vellum.ai/blog/gpt-6-1-sol-benchmarks-explained · kingy.ai https://kingy.ai/blog/gpt-6-1-sol-vs-claude-opus-5-5/ · myclaw https://myclaw.ai/blog/gpt-6-1-sol-vs-opus-5-5 · thegenaimagazine https://thegenaimagazine.com/gpt-6-1-sol-review-sol-6-1-vs-opus-sonnet-astra

**후기·미디어**
- 장문·블로그: Simon Willison https://simonwillison.net/2026/Sep/29/openai-devday-2026-live-blog/ · https://simonwillison.net/2026/Sep/28/claude-sonnet-5-5/ · Zvi https://thezvi.substack.com/p/claude-opus-55-should-raise-your · Arize https://arize.com/blog/anthropic-says-it-fixed-claudes-writing · Flavio Copes https://flaviocopes.com/gpt-6-1-sol/ · StrongMocha https://strongmocha.com/ai-infrastructure/opus-sol-and-jev-at-work-in-my-september-ai-setup · Latent Space https://www.latent.space/p/ainews-openai-devday-2026-dots-61 · Every https://every.to/vibe-check/vibe-check-openai-devday-2026 · https://checks.every.to/p/dans-editorial-checks · Lenny's/Claire Vo https://www.lennysnewsletter.com/p/i-left-claude-for-months-opus-55 · The Neuron https://www.theneuron.ai/news/claude-opus-5-5-gpt-6-sol-livestream-benchmark/ · GeekNews https://news.hada.io/topic?id=34519 · https://news.hada.io/topic?id=34500
- 매체: TNW https://thenextweb.com/news/openai-gpt-6-1-sol-price-astra-devday · Gizmodo https://gizmodo.com/with-no-astra-to-release-openai-pivots-to-new-gpt-6-1-sol-model-2000819044 · DataCamp https://www.datacamp.com/blog/gpt-6-1-sol · @testingcatalog https://x.com/testingcatalog/status/2105228510335778918
- HN: 6.1 Sol 출시 https://news.ycombinator.com/item?id=49896586 (댓글 925) · AA 스레드 https://news.ycombinator.com/item?id=49906669 · DevDay https://news.ycombinator.com/item?id=49896600 · Opus 5.5 출시 https://news.ycombinator.com/item?id=49803892 (댓글 1,118) · Sonnet 5.5 https://news.ycombinator.com/item?id=49881850 · Livenerf https://news.ycombinator.com/item?id=49901736 · 본문 인용 댓글은 각 표와 문장에 링크했습니다
- X: @theo https://x.com/theo/status/2105000888192663582 · https://x.com/theo/status/2105001431690600537 · @PawelHuryn https://x.com/PawelHuryn/status/2105065401193279918 · @N8Programs https://x.com/N8Programs/status/2105430152729796845 · @ArtificialAnlys https://x.com/ArtificialAnlys/status/2105025585332605357 · @ValsAI https://x.com/ValsAI/status/2105152503700672835
- YouTube(설명란): Theo https://www.youtube.com/watch?v=vu8X3YroB-w · https://www.youtube.com/watch?v=ejjBbaq9RmY · Company Under Glass https://www.youtube.com/watch?v=W6z1X7SLexc · Can It Code? https://www.youtube.com/watch?v=U0AlQd5pdvw · AISeeKing https://www.youtube.com/watch?v=ZSVw0gbAjFU · AICodeKing https://www.youtube.com/watch?v=7eyrcRTi6Co · 아르사 https://www.youtube.com/watch?v=fUMb9YLuq5g
- Reddit(`https://www.reddit.com/comments/<ID>/`로 열림): r/codex 1wu0d5o · 1wu1bkt · 1wukoek · 1wua35p · 1wu2ydb · 1wttxfi, r/ChatGPT 1wtngdp · 1wub096 · 1wudd78, r/OpenAI 1wuancz · 1wu4fxh, r/ClaudeCode 1wrmw8c · 1wrvhg1 · 1wqnjkp · 1wp4f0s · 1wpz5mr · 1wt0qmb · 1ws9s0j, r/ClaudeAI 1wqlofr · 1wp4v8e · 1wt7g15 · 1wtxx70 · 1wtrf5y · 1wtlrnu · 1wsijnv · 1wom8wo. 전체 목록(6.1 Sol 약 70개, Opus 335개)은 보관 폴더의 노트에 있습니다
- GitHub anthropics/claude-code 이슈(`https://github.com/anthropics/claude-code/issues/<번호>`): #96139 · #96141 · #96163 · #96288 · #96326 · #96601 · #96978 · #97074 · #97117 · #97311 · #97398 · #97403 · #97452 · #97492 · #97504 · #97653 · #97687 · #97829 · #97854 · #97882 · #97997 · #98145 · #98267 · #98387 · #98527
- GitHub openai/codex 이슈(`https://github.com/openai/codex/issues/<번호>`): #49320 · #49362 · #49363 · #49396 · #49421 · #49464 · #49617 · #49641 · #49703 · #49735 · #49759 · #49776 · 서드파티 PR https://github.com/pingdotgg/t3code/pull/14440 · https://github.com/incognitojam/styal/pull/543

<details>
<summary>Codex 독립 조사의 사용자 원문 표본 19건과 보강 자료 1건</summary>

긍정·부정 사례를 함께 찾은 목적 표집이고, 찬반 비율을 내지 않습니다. paddo의 세 글은 같은 작성자·코드베이스라 독립 재현 세 건이 아닙니다.

| 번호 | 원문 | Codex의 관찰 |
|---|---|---|
| G1 | https://www.reddit.com/r/OpenaiCodex/comments/1wtrad9/gpt_61_sol_has_been_pretty_disappointing_that_i/ | medium에서 음악·게임 기능 요구를 놓쳤다는 보고. 같은 스레드에 긍정 경험도 있음 |
| G2 | https://www.reddit.com/r/codex/comments/1wttxfi/gpt_61_sol_is_really_good/ | 구현 품질 호평과 속도·사용량 불만이 함께 있음 |
| G3 | https://www.reddit.com/r/codex/comments/1wtyhlo/gpt_61_sol_is_so_good_its_actually_much_more/ | 구독에서 쓸 만한 성능이라는 체감. 계량 근거로 쓰지 않음 |
| G4 | https://www.reddit.com/r/OpenAI/comments/1wu4fxh/61_sol_so_far_pretty_impressed/ | 업무·비용 만족, 속도 유보. 난도와 effort를 통제한 비교가 아님 |
| G5 | https://www.reddit.com/r/LLMDevs/comments/1wtmb3m/gpt61_sol_seems_like_a_step_back_for_writing/ | 10개 과제·AI 심판 3개로 글쓰기 후퇴 보고. 6 Sol max 대 6.1 xhigh로 조건이 다름 |
| G6 | https://news.ycombinator.com/item?id=49896586 | Astra에 가까운 체감과 평가 방식 반론. 양자화 추측은 채택하지 않음 |
| G7 | https://www.eesel.ai/blog/gpt-6-1-sol-review | 티켓 15개 × 구성 5개 = 75회. 모든 구성이 주문 ID의 O/0 문제를 놓침. 상업 서비스의 자체 평가 |
| G8 | https://github.com/openai/codex/issues/49464 (재현 댓글 https://github.com/openai/codex/issues/49464#issuecomment-5904137078) | 오래된 번들 CLI와 새 CLI의 목록 차이. 클라이언트 문제 |
| G9 | https://github.com/openai/codex/issues/49641 | 컨텍스트 표시 차이. 표시만으로 실제 전송 토큰을 확정할 수 없음 |
| O1 | https://www.reddit.com/r/ClaudeAI/comments/1wqzhqg/opus_55/ | 구독 품질 호평과 거절 불만이 섞임 |
| O2 | https://www.reddit.com/r/ClaudeAI/comments/1wqbd5u/gpt_user_here_tried_opus_55_its_insane/ | 요청하지 않은 문제 발견과 후속 제안을 장점으로 봄. 다른 사용자에게는 범위 확대일 수 있음 |
| O3 | https://www.reddit.com/r/ClaudeAI/comments/1wqcara/aight_i_get_it_opus_55_is_actually_peak/ | 짧은 시간에 애니메이션 코드 제작 |
| O4 | https://zenn.dev/autocamp/articles/5fb75a2c818e63 | 기록 97개 중 판단 실수 23건. 모델이 섞여 있어 Opus 실패율로 계산하지 않음 |
| O5 | https://github.com/anthropics/claude-code/issues/97117 | 제한된 요청에서 브랜치·작업 트리·에이전트가 늘고 테스트 실행이 빠짐 |
| O6 | https://forum.cursor.com/t/opus-5-5-chats-die-permanently-after-long-agentic-turns-due-to-reordered-thinking-blocks/172796/7 | Bedrock 연결에서 사고 블록 순서 문제를 지원 담당자가 확인 |
| O7 | https://paddo.dev/blog/the-bar-moved/ | 완성도 향상과 보안 결함·부에이전트 보고 맹신 사례가 함께 있음 |
| O8 | https://github.com/anthropics/claude-code/issues/96163 | 여러 환경의 상반된 후속 재현 |
| D1 | https://paddo.dev/blog/bulk-discount-is-gone/ | 4.5절 표의 마지막 행 |
| D2 | https://www.reddit.com/r/ChatGPT/comments/1wub096/gpt_61_sol_vs_gpt_6_sol_vs_opus_55_testing_quota/ | 128회, 6.1 xhigh 11포인트 대 Opus medium 8포인트 소진. 머리말과 보정 결론이 맞지 않음 |
| 보강 | https://paddo.dev/blog/default-was-right/ | 3모델 × 5레벨 × 20회 = 300회. 4.5절 표의 첫 행 |

</details>
