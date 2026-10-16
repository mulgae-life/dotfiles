# Gemini 4 Argon 조사 — 공식 계약, 정정 기록, dotfiles 판단 (2026-10-16, GA 3일 차)

> 조사 방식: Claude와 Codex가 같은 질문 여덟 개를 독립 조사한 뒤 서로의 결과를 원문으로 다시 확인했습니다. 공식 페이지는 HTML 원문으로 받아 읽었고, AI Studio 개발 가이드는 JS 렌더링이라 헤드리스 Chromium으로 펼쳤습니다. API 호출과 agy 실측은 하지 않았습니다.
> 문서 역할: 출시 시점의 사실, 조사 중 바로잡은 오류, dotfiles 판단을 기록합니다. 프롬프트 작성 계약은 `reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`가 맡습니다.
> 시점: 2026-10-16 04:50~06:30 UTC. 과거 조사는 시점 기록이라 고치지 않습니다.

## 0. 요약

**결론**: Argon 전용 풀 가이드와 `writing-prompts` 패턴 요약을 새로 만들고, Gemini 3.x 문서에서 출시와 함께 낡은 곳을 고쳤습니다. 설치·권한·agy 설정은 바꾸지 않았습니다.

1. **`gemini-4-argon`은 2026-10-13 GA된 안정판입니다.** 9/30에 Fairwind 사이버 방어 파트너에게 먼저 공개됐습니다. Gemini 4 계열의 첫 모델이며, Pro·Flash 체계를 없앤다는 공식 문장은 없습니다.
2. **창은 입력·사고·출력이 함께 쓰는 1,048,576 토큰입니다.** Interactions 동기 출력은 최대 65,536이고 GenerateContent 직접 비스트리밍 REST는 요청당 32,768입니다. 그 이상은 API마다 다른 장문 출력 방식을 씁니다(최신 SDK는 자동 이어 쓰기).
3. **Gemini API와 Cloud의 계약이 다릅니다.** `thinking_budget`(Gemini API GenerateContent는 경고 후 변환, Cloud는 400), 암시 캐싱 최소 길이(4,096 / 6,144), 장문 출력(Interactions `background` / Cloud는 GenerateContent `continuation_token`만)이 갈립니다.
4. **명시 캐싱이 없고, 사고 수준은 `low`·`medium`(기본)·`high`뿐입니다.**
5. **Argon 전용 운용 권고가 공식으로 있습니다.** AI Studio 개발 가이드의 "5 practical tips"(의도 선합의, 검증 수단, 멀티모달 참조, 조율자, 회고)입니다. 일반 프롬프팅 문서에는 아직 Gemini 3 절만 있습니다.
6. **출시와 같은 주에 3.x 상태가 바뀌었습니다.** Gemini API에서 3.7 Flash와 3.5 Flash가 2026-10-08 폐기돼 각각 3.8·3.6으로 자동 연결되고, 3.8 가이드의 일상 작업 대안이 3.6 Flash로 바뀌었습니다. Cloud는 3.7을 2027-01-28, 3.6을 2026-11-19에 종료할 예정입니다.

## 1. 합의한 사실

| 항목 | 내용 | 출처 |
|------|------|------|
| ID·상태 | `gemini-4-argon`, Stable, GA 2026-10-13. Cloud 전용 `gemini-4-argon-cyber-permissive`(Fairwind 승인, 기본 `HIGH`) | 모델 페이지, API 변경 로그, Cloud 가이드 |
| 입력·출력 | 텍스트·이미지·영상·음성·PDF → 텍스트. 이미지·음성 생성, Live API 미지원 | 모델 페이지 |
| 창·출력 한도 | 통합 1,048,576. Interactions `background=False`는 최대 65,536(넘기면 400). GenerateContent는 직접 비스트리밍 REST 요청당 32,768, 스트리밍 65,536, 최신 SDK 호출 기본 65,536(자동 이어 쓰기로 더 큰 전체 출력) | latest-model 두 판, Thinking, GenerateContent Long decode |
| 장문 출력 | Interactions: `background=True` + `max_output_tokens > 65536`. GenerateContent: SDK(Python 2.30.1+, JS 2.29.1+) 자동 이어 쓰기 또는 `continuation_token`. Cloud: GenerateContent v1beta1만, Interactions 미지원. OpenAI 호환 계층은 받지 못함 | latest-model, Cloud 가이드 |
| 사고 | `low`·`medium`(기본)·`high`. `minimal` 없음 | Thinking 표 |
| `thinking_budget` | Gemini API GenerateContent: "still works and maps to the nearest thinking_level, but it returns a warning" / Cloud: HTTP 400 | GenerateContent latest-model, Cloud 이행 문서 |
| 캐싱 | 명시 캐싱 미지원(GenerateContent는 오류). 암시 캐싱 95% 할인, 최소 Gemini API 4,096 / Cloud 6,144 | latest-model, Cloud 가이드 |
| sampling | 무시되고 사용 중단 경고. 제거 권고는 3.x에도 있었음 | AI Studio 가이드, 3.5 가이드 |
| 400 인자 | Cloud는 `frequency_penalty`·`presence_penalty`·`candidate_count`를 400으로 명시 | Cloud 가이드 |
| 공유 계약 | 사고 서명, 함수 결과 짝, 미리 채운 model 턴 금지, 미디어 해상도 표("Gemini 4 and Gemini 3 models"), 구조화 출력+도구(Preview) | 각 기능 문서 |
| 가격 | Standard 입력 $2·출력 $10·캐시 $0.10(11/30까지), 12/1부터 두 배. Batch·Flex 절반, Priority 1.8배. Developer API 무료 등급·AI Pro 플랜 제외 | Pricing |
| agy | 유료 Pro(체험판 제외)·Ultra·Enterprise, App·CLI·IDE 확장(구 IDE 제외). `agy models`(1.3.6)에 `-low`·`-medium`·`-high` 세 변형 | Antigravity 모델 표, 10/13 발표, 로컬 관측 |

## 2. 조사 중 바로잡은 것

- **"Argon 전용 공식 프롬프트 가이드가 없다"(Claude 1차)는 틀렸습니다.** AI Studio의 "Gemini 4 Argon: Developer Guide"(2026-10-13)에 운용 팁 다섯 개가 있습니다. Codex가 찾았습니다.
- **"`thinking_budget`은 400"(Claude 1차)은 Cloud 계약을 일반화한 것이었습니다.** Gemini API GenerateContent는 경고 후 변환합니다.
- **3.8 근거 링크**: dotfiles의 3.x 문서가 3.8 근거로 걸어 둔 `latest-model` 주소는 이제 Argon 문서입니다. 3.8 전용 주소(`whats-new-gemini-3.8`)로 바꿨습니다.
- **출처 충돌 처리**: Google 출시 글과 AI Studio 가이드는 Antigravity 이용자로 Ultra만 적지만, Antigravity 자체 발표와 모델 표는 유료 Pro 지원을 명시합니다(발표는 모두 10/13). 해당 서비스의 구체적인 조건을 따릅니다.
- **출력 한도 요약(최종 점검에서 Codex 지적)**: "동기 출력 최대 65,536, 초과 시 400"은 Interactions `background=False` 조건이었고, GenerateContent의 32,768은 직접 비스트리밍 REST에만 해당합니다. SDK 호출·전체 생성·개별 HTTP 요청을 나눠 쓰도록 고쳤습니다.

## 3. dotfiles 판단

| 대상 | 판단 |
|------|------|
| 새 문서 | Argon 풀 가이드 + `writing-prompts/references/gemini4-argon-patterns.md`. 3.x 파일에 덧붙이지 않은 이유는 API 계약 차이가 크고 전용 운용 권고가 있어서입니다 |
| 승계 규칙 | Argon 전용 권고와 공식 문서가 Gemini 4에 명시한 공통 계약을 우선하고, 나머지는 스킬 범용 원칙을 씁니다. Gemini 3 전용 처방은 자동 적용하지 않습니다(Codex 제안) |
| 3.7 Flash | 범위에 남기고 서비스별 상태를 적습니다. 보관 조건이 "공급자가 은퇴시킨 모델"인데 Cloud는 아직 제공하기 때문입니다. Cloud 종료일이 지나도 자동 보관하지 않고 그때 상태를 다시 확인합니다 |
| agy 상태줄 | 대표님 지적으로 확인한 결과, 유료 Pro는 Argon 전용 주간 버킷(`gemini-argon-wtu-weekly`, 5시간 한도 없음)이 따로 있었습니다(`agy -p "/usage"`는 할당량을 쓰지 않음). Argon 선택 시 이 버킷과, 하위 에이전트로 함께 쓰는 Flash의 `gemini` 버킷을 나란히 보이도록 고쳤고, 버킷이 없는 Ultra는 기존 `gemini` 버킷을 읽습니다 |
| `agy-live-check.sh` | 기존 검사 조건(`gemini-3.8-flash-low`)을 유지합니다. Argon으로 바꿀 필요는 확인되지 않았습니다 |
| 설치·권한 | 변경 없음 |

## 4. 미확인

- 지식 마감일, Gemini API에서 penalty 인자가 400인지, 구조화 출력 구 필드 호환성
- agy의 기본 변형·창 크기, 상태줄 페이로드에 Argon 버킷이 실제로 실리는지(키 이름은 `/usage`와 같다고 가정), 변형과 API `thinking_level`의 실제 대응, Argon이 서버 카탈로그만으로 배포됐는지
- Gemini 4 계열의 다음 모델 이름과 Pro·Flash 체계

## 5. 출처

수집은 2026-10-16 04:50~06:30 UTC입니다. 원문 텍스트 사본은 로컬 `.archive/2026-10-16_gemini4-argon-research/raw/`에 있습니다. 두 조사 보고서는 `.collab-loop/20261016-gemini4-argon/research_v1_claude.md`·`research_v1_codex.md`이고, 토론 메모도 같은 폴더에 있습니다(두 경로 모두 git 추적 대상이 아닙니다).

- Gemini API: [latest-model](https://ai.google.dev/gemini-api/docs/latest-model) · [GenerateContent판](https://ai.google.dev/gemini-api/docs/generate-content/latest-model) · [모델 페이지](https://ai.google.dev/gemini-api/docs/models/gemini-4-argon) · [Thinking](https://ai.google.dev/gemini-api/docs/thinking) · [Long decode](https://ai.google.dev/gemini-api/docs/long-decode) · [Long decode (GenerateContent)](https://ai.google.dev/gemini-api/docs/generate-content/long-decode) · [Pricing](https://ai.google.dev/gemini-api/docs/pricing) · [Changelog](https://ai.google.dev/gemini-api/docs/changelog) · [Deprecations](https://ai.google.dev/gemini-api/docs/deprecations) · [Media resolution](https://ai.google.dev/gemini-api/docs/media-resolution) · [Structured outputs (GenerateContent)](https://ai.google.dev/gemini-api/docs/generate-content/structured-output) · [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies) · [What's new in 3.8](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.8)
- AI Studio: [Gemini 4 Argon: Developer Guide](https://aistudio.google.com/learn/gemini-4-argon-developer-guide)
- Google Cloud: [개발자 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon) · [시작 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/start/get-started-with-gemini-4) · [이행 문서](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/migrate) · [모델 수명주기](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/model-versions)
- Google 블로그: [출시 글](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-argon/) · [9/30 첫 발표](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-4-argon/) · [Gemini 앱](https://blog.google/innovation-and-ai/products/gemini-app/gemini-4-argon-availability/)
- Antigravity: [10/13 발표](https://antigravity.google/blog/gemini-4-argon-in-google-antigravity) · [모델 표](https://antigravity.google/docs/models/) · [effort](https://antigravity.google/docs/cli/commands/effort/) · [요금제](https://antigravity.google/docs/plans/)
