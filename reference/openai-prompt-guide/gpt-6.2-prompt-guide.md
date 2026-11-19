# GPT-6.2 Prompting Guide (Astra·Sol)

> **출처**:
> - [Using GPT-6.2 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model/gpt-6.2-astra) (버전 고정 주소. 검증일에는 버전 없는 `guides/latest-model`·`guides/prompt-guidance`도 같은 페이지)
> - [Keep the prefix unchanged | OpenAI API](https://developers.openai.com/api/docs/guides/keep-prefix-unchanged)
> - 모델 카드: [gpt-6.2-astra](https://developers.openai.com/api/docs/models/gpt-6.2-astra) · [gpt-6.2-sol](https://developers.openai.com/api/docs/models/gpt-6.2-sol)
> - [Reasoning models](https://developers.openai.com/api/docs/guides/reasoning) · [Model selection](https://developers.openai.com/api/docs/guides/model-selection) · [Pricing](https://developers.openai.com/api/docs/pricing)
> - [Introducing GPT-6.2 Astra and Sol | OpenAI](https://openai.com/index/introducing-gpt-6-2-astra-sol/)
> - [GPT-6.2 Astra and Sol 시스템 카드](https://deploymentsafety.openai.com/gpt-6-2-astra-sol)
> - [Codex models | OpenAI](https://learn.chatgpt.com/docs/models)
>
> **검증일**: 2026-11-18
> **이전 버전**: [GPT-6 Prompting Guide](./gpt-6-prompt-guide.md) (6 Astra·6.1 Sol·6.1 Terra·6 Sol·Luna). 6.1 Terra와 6 Luna는 6.2 대응 모델이 없어 그 문서가 계속 현행입니다
> **조사 원문**: [research-gpt62.md](../research/research-gpt62.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (6 → 6.2)

GPT-6.2는 2026-11-17에 Astra와 Sol 두 모델로 나왔습니다. 6.2 Astra는 6 Astra의, 6.2 Sol은 6.1 Sol의 후속입니다. Terra와 Luna에는 6.2가 없어서 공식 대표 목록은 6.2 Astra·6.2 Sol·6.1 Terra·6 Luna입니다. 이 문서에서 "Astra"와 "Sol"은 6.2 모델을 가리키고, 이전 모델은 "6 Astra", "6.1 Sol"처럼 버전을 붙여 적습니다.

API 계약은 6 Astra·6.1 Sol과 거의 같습니다. `none` effort를 받지 않고, 도구 호출은 Responses API로 하며, 샘플링 파라미터를 받지 않습니다. 새로 챙길 곳은 하나입니다. 6.2부터 API는 대화 중간에 앞부분이 바뀌었거나 `safety_identifier`가 달라진 요청에서 해당 추론 항목(reasoning item)을 입력에서 뺍니다(§0.4). 대화 이력을 고쳐 쓰거나 요청마다 `tools`·`instructions`를 바꾸는 통합은 모델이 앞선 추론을 다시 하게 되어 품질이 떨어지고 토큰이 늘 수 있습니다.

프롬프트 쪽은 방향이 바뀐 곳이 있습니다. 6 Astra 가이드는 장황하고 서식이 많은 답, 질문하고 멈추는 성향, 과잉 테스트를 누르는 문장을 권했습니다. 6.2는 기본 문체가 간결해졌고, 테스트는 한 줄 지시로 줄었으며, 멈춤은 "다음 단계를 제안하고 확인을 기다리는" 모양으로 나타납니다. 그래서 6 Astra용 간결화 지시를 그대로 가져오면 6.2에서는 지나치게 짧아질 수 있습니다. 한편 시스템 카드의 두 가지 시험에서는 6.2가 막힌 일을 최종 보고에서 빠뜨린 비율이 이전 모델보다 높았습니다(§3.6). OpenAI는 간결함 훈련과 관련이 있을 수 있다고만 적었으므로 원인은 가설입니다. 이 문서는 간결함을 요구할 때 장애물과 한계를 알리라는 문장을 함께 두기를 권합니다.

### 한 페이지 변화 요약

| 항목 | 6 Astra · 6.1 Sol | 6.2 Astra · 6.2 Sol |
|------|-------------------|---------------------|
| 모델 ID | `gpt-6-astra` · `gpt-6.1-sol` | **`gpt-6.2-astra` · `gpt-6.2-sol`** |
| 가격 (1M당 입력 / 캐시 입력 / 출력) | $10 / $1 / $50 · $2 / $0.10 / $10 | **$8 / $0.40 / $40** · $2 / $0.10 / $10 |
| 지식 컷오프 | 2026-04-30 · 2026-04-30 | **2026-05-18 · 2026-06-01** |
| `reasoning.effort` | `low`~`max`, `none` 미지원 | `none` 거부 (허용 값 목록은 문서에 없음, §0.3) |
| 도구 호출, 샘플링 파라미터 | Responses 전용, `temperature`·`top_p`·`top_logprobs` 제거 | 같음 |
| 추론 항목이 입력에서 빠지는 조건 | 모델 계열 변경·하향, 조직·사용자 변경 | 여기에 **앞부분(prefix) 편집과 `safety_identifier` 변경**이 더해짐 |
| 기본 문체 | 자세하고 서식이 많음 → 산문 유도 | **간결하고 직접적** → "be concise" 계열 지시 재검토 |
| 멈추는 모양 | 질문을 던지고 멈춤 | **다음 단계를 제안하고 확인을 기다림** |
| 테스트 | 과잉 테스트 → 범위를 좁히는 지시 | 요청·저장소 규칙·특정 회귀가 있을 때만 새 테스트 |
| 새로 생긴 축 | — | **코딩 스타일, 프런트엔드 디자인** |
| 공식 가이드에서 빠진 축 | — | 지시 준수, 서브에이전트 위임 (§3.5) |
| Ultrafast | Standard의 6배 | **2027-02-28까지 3배**, 이후 6배 |

---

## 0. 모델과 API 계약

### 0.1 두 모델

| 항목 | 6.2 Astra | 6.2 Sol |
|------|-----------|---------|
| API ID | `gpt-6.2-astra` | `gpt-6.2-sol` |
| 모델 카드 소개 | "Our most capable model for your hardest projects, from start to finish." | "Our go-to model for everyday work, from coding to powering agents at scale." |
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000 | 같음 |
| 지식 컷오프 | 2026-05-18 | 2026-06-01 |
| 입력 모달리티 | 텍스트, 이미지 | 같음 |
| 입력 / 캐시 입력 / 30분 캐시 쓰기 / 출력 ($/1M, Standard) | $8 / $0.40 / $10 / $40 | $2 / $0.10 / $2.50 / $10 |
| 입력 272K 초과 요청 (요청 전체 적용) | $16 / $0.80 / $20 / $60 | $4 / $0.20 / $5 / $15 |

- 모델 목록은 두 모델을 이렇게 나눕니다. "use GPT-6.2 Astra, our flagship model for complex reasoning and coding. Choose GPT-6.2 Sol to balance intelligence and cost, or GPT-6 Luna for cost-sensitive, high-volume workloads."
- Astra는 6 Astra보다 입력·출력이 20%, 캐시 입력이 60% 쌉니다. Sol은 6.1 Sol 요율 그대로입니다. 두 모델 모두 캐시 입력이 입력의 5%입니다.
- 12시간 캐시 쓰기는 Astra $20, Sol $5입니다. Batch는 Standard의 50%, Fast 모드는 2배입니다. Ultrafast는 "3 times the Standard rate through February 28, 2027, and 6 times the Standard rate starting March 1, 2027 (Pacific time)"입니다.
- Flex 단가는 확인하지 못했습니다. 11월 17일 모델 릴리스 노트는 두 모델이 Flex를 지원한다고 적습니다("Both support Batch and Flex."). 그런데 Flex 가이드가 지원 목록으로 가리키는 가격표의 Flex 표에는 두 모델이 없고, 모델 카드도 Batch·Fast·Ultrafast만 적습니다. 이전 세대의 Flex 50%를 6.2에 그대로 적용하지 않습니다.
- 백그라운드 모드에 할인 완료 창이 공개 베타로 생겼습니다. `background: true`와 함께 `background_options.completion_window`를 `2h`로 두면 30%, `8h`로 두면 40% 할인이고, Standard 처리에서만 되며 스트리밍할 수 없습니다. 대상은 6.2 Astra·6.2 Sol·6.1 Terra·6 Luna입니다. 백그라운드 모드는 `store: false`나 ZDR에서도 응답 데이터를 일시 저장하므로("Background mode temporarily stores response data even when you set `store` to `false` or use Zero Data Retention."), 보존하지 않아야 하는 작업에는 따로 검토합니다.
- 긴 입력 할증은 이전 모델과 같습니다. 입력이 272K를 넘으면 초과분이 아니라 요청 전체에 입력·캐시 2배, 출력 1.5배가 붙습니다.
- 발표문은 두 모델이 같은 작업을 더 적은 출력 토큰으로 끝낸다는 점을 앞세웁니다("Both models deliver better results on demanding tasks with fewer output tokens"). 작업당 비용은 단가와 토큰 수를 함께 봐야 하므로 자기 작업으로 재서 비교합니다.
- Astra for Law는 별도 모델이 아니라 6.2 Astra에 법률 검색 색인과 지시문을 얹은 구성입니다.

### 0.2 모델 고르기

공식 모델 선택 가이드는 작업 유형 여섯 가지(3D·디자인, 소프트웨어 엔지니어링, 데이터 분석, 결과물 작성, 컴퓨터 사용, 연구 판단) 모두에서 적합도 순서를 6.2 Astra, 6.2 Sol, 6.1 Terra, Luna로 둡니다. 모델과 effort를 묶은 예시는 아래와 같고, 원칙은 "start with the lightest setting that meets your acceptance criteria"입니다.

| 조합 | 공식 예시 |
|------|-----------|
| 6.2 Sol · Medium | 기존 코드베이스의 버그 수정과 기능 추가, 검토받을 문서 초안 |
| 6.2 Sol · Extra high | 중간에 시험과 수정이 필요한 여러 단계 작업 |
| 6.2 Astra · Low | 분명한 지시서를 바로 쓸 수 있는 결과물로 다듬기 |
| 6.2 Astra · Medium | 복잡한 프로젝트를 계획하고 수행하며 새 정보에 맞춰 조정 |
| 6.2 Astra · Extra high | 트레이드오프를 따지고 가정을 시험해야 하는 열린 문제 |

### 0.3 API 계약

| 항목 | 6.2 Astra · 6.2 Sol |
|------|---------------------|
| `reasoning.effort` | "The API rejects requests that set reasoning effort to `none`." `minimal`을 쓰던 자리도 `low`로 옮깁니다. 6.2 모델 카드와 추론 가이드는 허용 값 전체 목록과 기본값을 싣지 않습니다. 공식 예시에는 `low`·`medium`·`xhigh`가 나옵니다. `low`·`medium`·`high`·`xhigh`·`max` 다섯 단계가 실제로 돈다는 근거는 ARC Prize가 6.2 두 모델을 다섯 단계 모두에서 측정한 결과와 Codex 카탈로그의 값입니다 |
| 도구 호출 | "GPT-6.2 Astra and GPT-6.2 Sol support Chat Completions, but tool calling requires Responses." |
| 받지 않는 파라미터 | Chat Completions: `temperature`, `top_p`, `logprobs`, `top_logprobs`. Responses: `temperature`, `top_p`, `top_logprobs`, 그리고 `include`의 `message.output_text.logprobs` |
| 프롬프트 캐싱 | `prompt_cache_options.ttl`(`"30m"` 또는 `"12h"`). GPT-5.5 이하에서 올 때만 `prompt_cache_retention`을 바꿉니다 |
| 엔드포인트 | Chat Completions, Responses, Batch |
| Responses 도구 | web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search |
| 데이터 레지던시 | "Both models support US and EU data residency with Standard, Fast, and Batch processing. Ultrafast supports US data residency only." |
| ZDR | 승인된 조직에서 지원. "With ZDR enabled, the Responses API treats `store` as `false`. For multi-turn work, pass the prior output items back in order, including encrypted reasoning items." |
| Multi-agent 베타 | 6.2 Astra·6.2 Sol·6.1 Sol·GPT-5.6 계열에서 지원. `multi_agent: {enabled: true}`와 헤더 `OpenAI-Beta: responses_multi_agent=v1`. 이 모드에서는 `/responses/compact`·`reasoning.summary`·`max_tool_calls`를 쓸 수 없고 `configuration_update`도 쓸 수 없습니다 |

6 Astra·6.1 Sol에서 옮길 때, 이력을 고치지 않는 단발 요청이고 두 세대가 함께 지원하는 옵션만 쓴다면 요청 형식에서 고칠 것은 모델 ID뿐입니다. 옵션이 다른 곳은 따로 확인합니다. 예를 들어 6.1 Sol의 Ultrafast는 EU 데이터 레지던시에서도 됐지만 6.2는 미국만 지원합니다. 6.1 Terra·6 Sol·Luna에서 옮길 때는 `none` 요청이 거절됩니다. 6 Sol·Luna에서는 `none`일 때만 되던 Chat Completions 함수 호출 경로도 사라집니다(6.1 Terra는 이미 Chat Completions에서 도구를 부를 수 없었습니다). [이전 가이드](./gpt-6-prompt-guide.md)의 계약 표와 견줍니다. `ultra`는 이번에도 API 값이 아니라 Codex·ChatGPT 선택기의 값입니다(§4).

### 0.4 추론 항목 제외와 접두사 유지 (신규)

> "Starting with GPT-6.2, the API will drop reasoning items when it detects mid-conversation changes to the conversation history (prefix edits), model downgrade, end user, or organization. When the model loses access to reasoning items, answer quality can decline and the model may use more tokens to repeat earlier work."

추론 가이드는 조건을 더 정확히 적습니다. 모델 계열을 바꾸거나 더 약한 모델로 내리거나 조직·사용자가 바뀔 때 추론 항목을 빼는 것은 이전부터 있던 장치이고("as one of our safeguards against distillation"), 6.2에서 두 가지가 더해졌습니다. 원문의 "drop"·"remove"는 API가 그 요청의 입력에서 추론 항목을 뺀다는 뜻이고, 저장된 응답을 없앤다는 뜻이 아닙니다. 응답의 `input_transformations`가 어떤 항목이 어떤 사유로 빠졌는지 알려 줍니다.

| 사유 | 6.2 이후 빠지는 경우 |
|------|------------------------|
| `prefix_mismatch` | 추론 항목보다 앞에 있는 내용을 끼워 넣거나 고침. 항목을 통째로 지우기만 하거나 뒤에 덧붙이는 것은 해당하지 않음 |
| `end_user_mismatch` | 항목을 만든 요청과 다시 쓰는 요청의 `safety_identifier`가 다름. 한쪽 요청에만 넣어도 해당하고, 양쪽에 같은 값을 넣거나 양쪽 다 빼면 통과 |

같은 계열 안에서 더 강한 모델로 올리는 것은 추론을 보존합니다("Moving to a more capable model within the same family preserves compatible reasoning if the other checks pass").

접두사와 식별자를 지켜도 이전 턴의 추론 항목이 빠지는 경우가 하나 더 있습니다. 모델이 현재 턴의 추론만 쓰면 이전 턴의 항목은 `turn_boundary` 사유로 빠지고, 지원 모델에서는 `reasoning.context`가 이를 정합니다. 추론 가이드의 `all_turns` 지원 목록은 6.1 Sol에서 끝나고 6.2는 적혀 있지 않으므로, 6.2에서는 `reasoning.context`를 생략하거나 `auto`로 두고 응답의 `reasoning.context`에 찍힌 실제 모드를 확인합니다.

접두사(prefix)는 어떤 추론 항목보다 앞에 놓인 대화 이력입니다. 도구 결과를 줄이거나, 개발자 메시지를 고쳐 쓰거나, 옛 턴을 요약으로 바꾸면 접두사가 바뀝니다. `tools`·`instructions`·`text.format` 같은 요청 파라미터를 바꿔도 마찬가지입니다. 공식 대응은 이력을 고치지 않고 뒤에 덧붙이는 통합입니다.

| 하려는 일 | 접두사를 지키는 방법 |
|-----------|----------------------|
| effort 변경 | 요청의 `reasoning.effort`는 그대로 두고 `configuration_update` 항목을 입력에 덧붙임 |
| 구조화 출력 스키마 변경 | `text.format`은 그대로 두고 `configuration_update` 항목으로 새 스키마를 덧붙임 |
| 도구 추가·제한 | `tools`는 그대로 두고 `additional_tools` 항목(`developer` 역할, 이후 요청에서 같은 자리에 재생)으로 추가, 제한은 `tool_choice`의 `allowed_tools` |
| 개발자 지시 갱신 | 원래 메시지를 고치지 않고 새 `developer` 메시지를 덧붙임. 한 턴짜리 지시는 그 메시지 바로 앞에 명시적 캐시 경계를 둠 |
| 압축 | OpenAI 압축(`/responses/compact`, `context_management`)은 접두사가 바뀌어도 뒤의 추론 항목을 지킴. 자체 압축은 압축 항목을 문맥 끝에 두거나 추론 항목 손실을 받아들임 |
| 지난 도구 출력·이미지 줄이기 | 나중에 줄이지 말고 처음 보낼 때 줄여 보냄 |

`configuration_update`에는 조건이 있습니다. 표준 단일 에이전트 Responses 요청에서만 쓰고, 입력 배열에서 다음 사용자 메시지 앞에 넣습니다("you can update reasoning effort and response format in standard, single-agent mode", "Add the following item before the next user message"). 이 항목이 들어 있는 이력은 독립 압축 엔드포인트 `/responses/compact`와 자동 잘라내기가 거부합니다. `context_management` 자동 압축은 최신 설정을 이어받습니다. 독립 압축을 쓰려면 [압축 가이드](https://developers.openai.com/api/docs/guides/compaction#continue-with-configuration-updates-and-tools)의 절차대로 갱신 항목을 빼고 압축한 뒤 설정과 도구를 다시 붙입니다.

진단 수단은 두 가지입니다. `prompt_cache_options.comparison_response_id`로 이전 응답과 비교해 캐시가 어긋난 첫 지점을 보고, 응답의 `input_transformations`로 API가 어떤 추론 항목을 왜 뺐는지 봅니다. 캐시 진단은 모델이 이전 추론 항목을 재사용했는지까지는 알려 주지 않습니다.

시스템 카드도 같은 배경을 적습니다. 암호화된 추론의 보호를 사용자·워크스페이스·조직·모델 계열 단위로 강화했다는 것입니다.

---

## 1. effort 선택

API 문서가 6.2의 `reasoning.effort`에 대해 못 박은 것은 `none` 거부뿐이고, 아래 표의 다섯 단계는 ARC Prize의 6.2 측정과 Codex 카탈로그에서 확인한 값입니다. 마이그레이션 절의 시작 권고는 "Start with `medium` for a new integration. If you currently use `none` or `minimal`, use `low` instead."입니다. 6 가이드의 "현재 값을 유지하라"는 문장은 6.2 가이드에 없습니다.

| 단계 | 사용처 |
|------|--------|
| `low` | `none`·`minimal`을 쓰던 자리의 출발점. 분명한 지시서를 다듬는 일(Astra · Low 예시) |
| `medium` | 새 통합의 출발점 |
| `high` | 여러 단계 작업의 마무리 점검까지 끌고 가야 할 때. 공식 문장은 "Higher reasoning effort can help it persist through the final checks on complex or long-running tasks." |
| `xhigh` | 시험과 수정이 반복되는 작업, 열린 문제(§0.2 예시) |
| `max` | 가장 어려운 문제만 |

시스템 카드는 같은 effort에서 6.2가 이전 모델보다 추론 토큰을 덜 쓴다고 적습니다("At comparable reasoning-effort settings, GPT-6.2 Astra and GPT-6.2 Sol generally used fewer reasoning tokens"). 이전 모델에서 맞춰 둔 effort를 그대로 옮기지 말고 한 번 다시 잽니다. Codex 선택기의 값과 기본값은 §4에 있습니다.

---

## 2. Migration: 6.2로 옮기기

1. [ ] `model`을 `gpt-6.2-astra` 또는 `gpt-6.2-sol`로 설정
2. [ ] effort — 새 통합은 `medium`에서 시작, `none`·`minimal`은 `low`로
3. [ ] 도구 호출은 Responses API로 (Chat Completions에서는 도구를 부를 수 없음)
4. [ ] `temperature`·`top_p`·`top_logprobs` 제거. Chat Completions는 `logprobs`도, Responses는 `include`의 `message.output_text.logprobs`도
5. [ ] GPT-5.5 이하에서 오면 `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. [ ] **접두사 감사** — 응답 사이에 `tools`·`instructions`·`text.format`·`reasoning.effort`를 바꾸는 곳, 지난 입력을 줄이거나 고쳐 쓰는 곳, 대화 도중 더 낮은 모델로 바꾸는 곳을 찾아 §0.4 방식으로 고침. `safety_identifier`는 한 대화의 모든 요청에 같은 값으로 넣거나 모두 뺌
7. [ ] ZDR을 쓰면 여러 턴 작업에서 이전 출력 항목을 암호화된 추론 항목까지 순서대로 다시 보냄
8. [ ] EU 데이터 레지던시에서는 Ultrafast를 쓸 수 없음 (Standard·Fast·Batch는 가능)
9. [ ] **프롬프트 재검토** — "be concise" 계열 지시, 6 Astra용 테스트 축소·산문 유도 스니펫이 6.2에서도 필요한지 확인(§3). API로 에이전트를 돌리면 막힌 일을 알리라는 문장을 넣음(§3.6)

1~5와 7~8은 공식 마이그레이션 절의 항목이고, 6과 9는 같은 페이지의 다른 절과 시스템 카드에서 가져온 항목입니다. 공식 문서는 코딩 에이전트에 [OpenAI Docs 스킬](https://github.com/openai/codex/tree/main/codex-rs/skills/src/assets/samples/openai-docs)을 붙여 옮기는 방법도 안내합니다.

---

## 3. 행동 축

공식 가이드는 스니펫을 "a starting point across the GPT-6.2 model family"로 제시하고, 관찰 대상을 "GPT-6.2 Astra and Sol"로 적습니다. 다만 네 축을 묶은 절의 제목은 "GPT-6.2 Astra behavior"입니다. 이전 가이드와 달리 Sol도 관찰 대상에 들었지만 Sol 전용 가이드는 없습니다. 사용법도 다릅니다. "If you recognize one in your own application, try the prompt in that section." 증상이 보일 때 그 절의 문장을 넣으라는 뜻이고, 전부 미리 넣으라는 뜻이 아닙니다. 코드 블록은 공식 페이지의 영문 원문입니다.

### 3.1 문체

> "The model's writing tends to be more concise and direct by default. When migrating, revisit instructions like "be concise" in your system prompt."

일상 업무의 협업 상대로 쓸 때:

```text
Write using terminology the user and sources use. Keep technical details and use domain-specific language when they make the explanation more precise. Use the active voice and keep closely related details together. Cover the key points up front, and avoid references that the reader can only make sense of later in the response. Give the user enough context to follow your reasoning.
```

사용자를 대신해 밖으로 나갈 글을 쓸 때:

```text
When drafting a message or any other material on behalf of the user to be sent to an external audience, consider who will read it and tailor the content to that intended audience. The intended audience likely does not have the same context as the user, so ensure that you provide the background information or reasoning required for the audience to understand the content. When reviewing or editing existing content, preserve the author's content and wording, and follow the user's instruction carefully for what edits they want.
```

긴 작업 뒤 최종 답변에 작업 중 약어가 섞일 때:

```text
Treat your final answer as the user's first look at your work, and not as a continuation of intermediate commentary. The final answer must always be fully self-contained: users should never need to read earlier commentary updates for context, since they are collapsed when the final answer is shown to the user.

Write the final answer and all other human-facing material anew for the intended reader. Do not copy or closely paraphrase your reasoning or adopt its writing style. Do not carry over working shorthand, jargon, or abbreviations from your reasoning, tool calls, or instructions to subagents and automations.
```

**해설**: 6 Astra 가이드의 문체 절은 장황함과 서식을 누르는 쪽이었고, 6.2는 정밀함과 독자 맥락을 채우는 쪽입니다. 6 Astra 가이드에 있던 피할 표현 목록 스니펫은 6.2 가이드에 없습니다. 시스템 카드의 준수 평가 과제에서 잰 응답 길이 중앙값도 6 Astra 836자에서 6.2 Astra 650자, 6.2 Sol 628자로 줄었습니다. 이전 세대용 프롬프트에 남은 분량 상한이나 "짧게" 지시는 6.2에서 필요한 근거와 단서까지 깎을 수 있으니, 지우거나 "무엇을 반드시 남길지"로 바꿔 씁니다.

**dotfiles 적용**: Codex 층 `developer_instructions`의 분량 기준치에는 상한보다 필수 사실·근거·리스크 보존이 우선이라는 단서가 붙어 있습니다. 세 번째 스니펫은 우리 `communication.md`의 "작업 중 만든 코드네임·축약 라벨을 설명 없이 쓰지 않기" 조항과 같은 문제를 겨냥합니다.

### 3.2 작업 완주

> "When the user's intent is unclear, the model may propose a next step and wait for confirmation. For longer tasks, give it room to make reasonable assumptions and keep working."

감독 없이 진행해도 되는 작업에는 끝낼 결과와 사용자가 정해야 할 결정을 적습니다.

```text
Avoid stopping to end the turn while the task is incomplete or if there is an authorized next step you can take, and instead take the next steps within task scope to progress the user's request. If your final response before ending the turn is a suggested next step, a plan, a request to the user for a routine decision, instructions for a task to execute, or similar handoff to the user, take these steps yourself to make progress towards what the user asked for. Make sure that you have authorization to do so, and flag any assumptions or decisions you make to the user.

Only stop to clarify with the user if there is significant change in task scope, you are concretely blocked, have a decision that the user needs to resolve, or before irreversible or destructive actions.
```

요청한 일을 다 했는지 스스로 확인하게 할 때:

```text
Bias towards action, and persist until you've completed the task the user asked for. Avoid stopping to end the turn while the task is incomplete or if there is an authorized next step you can take, and instead take the next steps within task scope to progress the user's request. Make sure that you have accounted for every part of the user's request, and persist until you've delivered a result that fully satisfies the user's goal. If a task requires sustained work, do all the necessary work until the intended outcome is completely fulfilled.

Progress autonomously towards the user's goal (e.g. creating isolated worktrees / checkouts if needed, resolving merge conflicts, creating draft PRs etc) unless they are clearly destructive or irreversible. Before ending a turn or calling your work complete, check that your work fully satisfies what the user asked for. If any steps remain or any part of the result still needs verification, follow through on this work before finishing.
```

세부가 불분명할 때 가정을 밝히고 계속하게 할 때:

```text
Make reasonable, reversible assumptions to carry work forward and state them if it progresses the task within scope. Do not second guess yourself, stop after describing what you could do, offer to do the work, or provide a partial answer unless there is no way you can proceed.
```

**해설**: 멈춰도 되는 경우는 네 가지로 좁혀졌습니다. 작업 범위가 크게 바뀔 때, 실제로 막혔을 때, 사용자가 정해야 할 결정이 있을 때, 되돌릴 수 없거나 파괴적인 행동 직전입니다. 첫 스니펫 원문에는 "you maketo the user"라는 오타가 있어 위에서는 띄어 적었습니다. 앱에 `request_user_input_async` 같은 비동기 질문 도구를 두면 모델이 질문을 던져 놓고 답과 무관한 일을 계속합니다("GPT-6.2 can ask the user for clarification and continue work that doesn't depend on the answer").

시스템 카드는 반대쪽 위험도 적습니다. 6.2는 확인되지 않은 세부를 사실처럼 다루는 일이 늘었습니다(§5). 가정을 세우고 계속하게 하는 문장을 넣을 때는 스니펫의 "state them", "flag any assumptions"를 빼지 않습니다.

**dotfiles 적용**: Codex 층 `developer_instructions`의 "~해줄래 → 실행 지시", "가장 합리적인 해석을 선택하고 가정을 1줄로 명시 후 진행" 줄이 같은 방향이라 그대로 둡니다. 위험 명령 목록은 스니펫의 "irreversible or destructive actions"에 해당합니다.

### 3.3 코딩 스타일

> "The model tends to write more efficient, high-quality code than its predecessors. Describe any project conventions that should guide how it writes or edits code."

```text
Above all, be thorough in producing high-quality, correct code that completely fulfills the user's task. Keep the code easy to read and verify that the user-requested outcome works as they intend. Follow these instructions when coding:

(a) Reuse existing logic in the user's repo when you can. You should reuse existing classes, methods, representations, and APIs in the codebase as long as they preserve correctness. Before consolidating or removing code, preserve the behavior its callers rely on unless the task requires changing it.
(b) Skip new tests unless requested, required by the repo, or needed to catch a specific regression existing tests would miss.
(c) Make sure that code is human readable. Do not use fewer lines, shorter variable names, minified formatting, or dense one-liners as substitutes for simplicity. Ensure that comments and variable names are readable and understandable to a human. Code-golfed expressions count as overly complex when they encode many branches, conditions, or hidden assumptions.
(d) Avoid unnecessary indirection and abstraction. Helper functions, utility functions, and class abstractions can add cognitive complexity even when they do not add branches.
```

**해설**: 프롬프트에 적을 것은 저장소의 관례입니다. 기존 로직을 언제 재사용할지, 변경 범위를 얼마나 좁힐지, 기존 테스트가 못 잡는 동작에 언제 테스트를 더할지입니다. (c)는 "단순하게"라는 지시가 줄 수 줄이기나 한 줄 압축으로 번지는 것을 막습니다. 테스트는 6 Astra 가이드의 두 문단짜리 범위 축소 스니펫이 (b) 한 줄로 바뀌었습니다.

**dotfiles 적용**: `coding-style.md`의 최소 Diff·단순성 조항, `architecture.md`의 기존 코드 재사용·과도한 사전 추상화 금지 조항이 (a)·(d)와 같은 내용입니다. Codex 층의 테스트 줄("가역적·저영향 변경에 구현을 그대로 비추는 테스트를 새로 쓰지 않고…")은 (b)와 방향이 같아 그대로 둡니다.

### 3.4 프런트엔드 디자인

> "If the interface needs a particular look, specify the imagery and typography it should use."

```text
When generating webpages or apps with a frontend user interface, follow these instructions:

- When choosing visuals, generally prefer realistic images from ImageGen or image search that suit the project's style and purpose. Use SVGs when the user specifically asks for them.
- Include a text element only when it provides information the user needs, helps them navigate or act, or fulfills an explicit content request. Remove decorative numbering, filler badges, redundant headings, and explanatory copy that merely restates what the surrounding interface already makes clear, while preserving necessary labels, instructions, and status feedback.
```

**해설**: 원하는 모습이 있으면 이미지 종류와 서체를 프롬프트에 적습니다. 말로 설명하기 어려운 부분은 디자인 도구의 참조 이미지를 주거나, 이미지 생성 도구를 열어 주고 참조 이미지를 만들게 한 뒤 그 이미지와 대조해 다듬게 합니다("ask the model to build the asset, render it, and refine it against the reference").

**dotfiles 적용**: `frontend-design` 스킬의 템플릿 기본값 회피, `visual-check` 스킬의 렌더링 후 확인과 같은 흐름입니다.

### 3.5 6 가이드에 있고 6.2 가이드에 없는 축

"Using GPT-6"의 다섯 축 가운데 지시 준수(스킬·`AGENTS.md` 감사, 사용자 지시 우선 스니펫)와 서브에이전트 위임 절은 6.2 가이드에 없습니다. 테스트 절은 §3.3의 (b)로 흡수됐습니다. 6.2에서 그 문제가 사라졌다고 밝힌 공식 문장은 없으므로, 필요 없다고 단정하지 않고 증상이 있을 때만 [이전 가이드](./gpt-6-prompt-guide.md)의 스니펫을 씁니다. 시스템 카드의 내부 Codex 재현 평가에서는 지시 위반 표시가 6.2 Astra 2.87%(6 Astra 1.96%), 6.2 Sol 4.66%(6.1 Sol 3.21%)로 오히려 늘었으므로, 지시 파일 사이의 모순을 걷어내는 감사는 6.2에서도 유효합니다.

### 3.6 막힌 일 보고

공식 프롬프팅 가이드에는 없고 시스템 카드와 발표문에 있는 축입니다.

> "in two tests, they were more likely to omit mentioning obstacles that blocked their work, such as a missing file or unavailable search tool. We added instructions in Codex that substantially reduce these omissions"

사용자가 고치라고 한 파일이 없거나 필요한 도구가 죽어 있을 때 최종 답변이 그 사실을 빠뜨리는 비율은 6.2 Astra 22.28%, 6.2 Sol 24.08%로 6 Astra 11.09%, 6.1 Sol 14.00%의 약 2.0배, 1.7배입니다. 검색 도구를 꺼 둔 시험에서도 6.2 Astra는 그 한계를 알리지 않은 비율이 23.00%로 6 Astra의 7.58%보다 높았고, 6.2 Sol도 9.33%로 6.1 Sol의 2.75%보다 높았습니다(Sol 수치는 그림에서 읽은 값). 카드가 밝히듯 이 시험들은 문제 행동을 끌어내도록 설계된 것이라 실제 사용에서의 빈도가 아닙니다("do not necessarily reflect the rate of misleading responses in production"). Codex 개발자 프롬프트를 넣으면 8.04%, 8.88%로 내려가지만, 시스템 카드는 "The Codex developer prompt used in these evaluations is not applied to direct API requests."라고 못 박습니다. OpenAI가 든 원인은 가설입니다("our efforts to make responses concise and avoid excessive caveats may be related to the model omitting important obstacles"). 짧게 쓰라는 지시 하나가 누락을 얼마나 늘리는지 잰 실험은 아닙니다.

API로 에이전트를 돌릴 때 막힌 일을 알리라는 문장을 넣는 것은 이 문서의 권고입니다. 시험에 쓰인 Codex 개발자 프롬프트의 문구는 공개되지 않았으므로 그대로 옮길 공식 스니펫이 없습니다. 그래서 최종 답변에 반드시 담을 항목으로 적습니다. 예를 들면 "요청한 일 가운데 하지 못한 것, 없던 파일이나 실패한 도구, 대신 택한 방법을 최종 답변에 적는다"입니다. Codex가 6.2에 주입하는 문구는 §4에 있습니다.

**dotfiles 적용**: Codex 층 `developer_instructions`의 두 줄이 이 축에 해당합니다. "차단 상황은 조기에 표면화. 더 나쁜 접근으로 조용히 갈아타지 마세요"와, 코드 수정 보고에서 끝내지 못한 일·검증하지 못한 부분·재량으로 정한 동작을 최종 답변에 적게 한 줄입니다.

---

## 4. Codex에서의 6.2

### 4.1 카탈로그와 요금

Codex 0.169.1이 번들 카탈로그에 두 모델을 넣고 기본 선택을 6.2 Sol로 바꿨습니다. 아래 카탈로그 값은 검증일에 받은 서버 카탈로그 기준입니다.

| 항목 | 6.2 Sol | 6.2 Astra |
|------|---------|-----------|
| 카탈로그 설명 | "Fast, go-to model for coding and everyday work." | "Our most capable model for complex coding and professional work." |
| 순서 | 1 | 2 |
| 기본 추론 수준 | `low` | `low` |
| 선택 가능한 수준 | `low`~`max`, `ultra` | 같음 |
| 기본 창 | 500,000 | 272,000 |
| 크레딧 (1M당 입력 / 캐시 입력 / 출력) | 50 / 2.5 / 250 | 200 / 10 / 1,000 |

- 6.1 Sol과 6 Astra는 카탈로그 설명이 "Previous generation model …"로 바뀌고 순서가 5, 6으로 내려갔습니다. 6.1 Terra가 3입니다.
- 시작 권고는 "For GPT-6.2 Astra or GPT-6.2 Sol, start with the effort your client selects and adjust it based on the task."입니다. ChatGPT Work의 새 대화는 개인 플랜에서 Sol·Light, Enterprise에서 Sol·Medium으로 시작합니다.
- 창은 `model_context_window`로 늘립니다. Codex 문서는 "each support a context window of up to 1 million tokens"라고 적고, 카탈로그의 최대값은 872,000입니다.
- 크레딧은 Astra가 6 Astra(250 / 25 / 1,250)보다 싸고 Sol은 6.1 Sol과 같습니다. 5시간당 메시지 수의 추정 범위는 Plus 기준 Astra 6~50, Sol 17~180으로 이전 모델(5~45, 15~160)보다 늘었고(고정 한도가 아닌 추정치), 발표문은 그 이유를 출력 토큰 감소로 설명합니다.
- Fast는 포함 사용량과 크레딧을 모두 2배로 씁니다(6.1·6 계열은 포함 사용량 2.5배). Ultrafast는 포함 사용량 6배이고 구매 크레딧은 2027-02-28까지 3배, 이후 6배입니다. Pro $200은 Sol에서만, Pro $500은 두 모델에서 Ultrafast를 씁니다. Enterprise·Edu는 적격 워크스페이스에서 관리자가 모델 접근과 Ultrafast 권한을 허용한 경우에 두 모델에서 씁니다.
- 제공 클라이언트는 Codex 앱과 CLI입니다. Codex 문서의 6.2 모델 카드에는 IDE 확장 항목이 없고, IDE 확장과 설정을 함께 쓸 때의 예시 모델은 `gpt-6.1-sol`입니다.
- `ultra`는 이번에도 요청에 `xhigh`로 실리고 적극 위임 힌트가 붙는 선택기 값입니다. 0.169.0과 0.169.1 사이에 변환 코드와 힌트 문구는 바뀌지 않았습니다.
- 오디오 입력은 출처마다 다릅니다. 0.169.1 번들 카탈로그의 6.2 Sol은 텍스트·이미지이고, 서버 카탈로그에는 오디오가 더해져 있습니다. API 모델 카드는 오디오를 지원하지 않는다고 적고, 고객지원 문서는 Work와 Codex에서 올린 음성의 전사를 제공하지 않는다고 적습니다. 그래서 오디오 입력을 쓸 수 있다고 적지 않습니다.

### 4.2 기본 지시문

6.2의 Codex 기본 지시문은 6.1 Sol·6 Astra 판을 거의 다시 썼습니다. 서버 카탈로그 기준으로 6.1 Sol 170줄이 6.2 Sol 201줄, 6.2 Astra 202줄이 됐습니다.

| 영역 | 6.1 Sol · 6 Astra 지시문 | 6.2 지시문 |
|------|--------------------------|------------|
| 맨 앞 절 | 권한을 물을 때의 기준 | **`# Completing the user's task`**. 끝날 때까지 계속하고 멈춰도 되는 경우를 한정 |
| 실행 요청 해석 | "can you...", "help me..."를 실행 요청으로 읽으라는 문단 | 문단 삭제. 다음 단계 제안·계획·일상적 결정 요청으로 끝내지 말고 직접 하라는 문장으로 대체 |
| 막힌 일 | 설명 문단을 끝에 두라는 문장 | 결함과 지시 없이 내린 결정을 최종 답변에 반드시 다시 적기, 막히면 남은 일과 막힌 지점 적기 |
| 테스트 | 불릿 두 개 (저영향 변경에 테스트를 쓰지 않기, 테스트 확대 조건) | Coding Style의 한 줄 "(c) Skip new tests unless requested, required by the repo, or needed to catch a specific regression existing tests would miss." |
| 코드 | 불릿 목록 | **`# Coding Style`** 절 (a)~(g). 기존 로직 재사용, 요청하지 않은 산출물 금지, 읽기 쉬운 코드, 불필요한 추상화 금지 |
| 프런트엔드 | 없음 | **`# Frontend Design Guidance`** 절과 글꼴 목록 |
| 문체 | 따뜻한 어조, 산문 기본, 피할 표현 목록 | "a clear communicator". 용어를 지어내지 않기, "X, not Y" 대조 표현 금지, 세미콜론 금지, 요청받지 않은 권고와 사전 단서 금지 |
| 기술 보고 | `## Technical communication`, PR 설명 작성 절 | 두 절 삭제 |

- **API 가이드의 스니펫과 이 지시문은 문장을 공유합니다.** 6.2 Astra 지시문의 첫 절은 §3.2의 첫 스니펫과 오타까지 같고, Coding Style과 Frontend 절도 같은 문장을 담습니다. 어느 쪽이 먼저 쓰였는지는 확인하지 못했습니다. 분량도 다릅니다. Coding Style은 API 가이드가 네 항목, Codex 지시문이 일곱 항목입니다. API로 Codex와 비슷한 행동을 내려면 §3의 스니펫이 출발점입니다.
- **막힌 일 보고에 해당하는 문장**은 아래 셋입니다. 시스템 카드는 누락을 줄인 Codex 개발자 프롬프트의 문구를 밝히지 않았으므로, 이 문장들이 그 조치라는 대응은 추정입니다.

```text
In your final answer back to the user, mention any relevant flaws in your work or any decisions you made without explicit guidance from the user, so that the user can verify your approach and work. Disclosure in commentary alone is not enough. You MUST repeat any such disclosures in the final answer.

If you are blocked and unable to make useful progress, you should state that clearly when you cannot do more useful work.

End early only if the user asks you to stop or no authorized step can advance the task. In that case, state what remains and the specific blocker.
```

- 6.2 Sol과 6.2 Astra의 지시문은 서로 다릅니다. 첫 절의 문장과 Apps·Plugins 절이 갈리고, 게임과 화면 복제를 다루는 문단은 Sol에만 있습니다. Astra는 확인 정책이 "Safety Floor" 구조로 새로 쓰였고, 자동 검토가 거절한 뒤의 행동도 "Continue with any materially safer alternative and complete unaffected work without asking for confirmation."으로 바뀌었습니다.
- 서버 카탈로그와 0.169.1 번들의 6.2 지시문은 다릅니다. 번들 판은 Sol과 Astra가 같고 `Completing the user's task` 절이 없습니다. Codex CLI 0.169.1에서 두 모델로 뽑은 프롬프트 입력(`codex debug prompt-input`)에는 서버 카탈로그 판의 문장이 들어 있었습니다.
- 카탈로그의 기본 지시문을 쓸 때 `personality = "none"`은 지시문에서 `# Personality` 절을 통째로 뺍니다(`base_instructions`를 따로 지정하면 그 값이 우선합니다). 6.2에서는 그 절 아래에 Writing style, Intermediate commentary, Final answer가 들어 있어서, 이 설정을 쓰면 위의 최종 답변 공개 문장까지 함께 빠집니다.

**dotfiles 적용**: `.codex/config.toml`은 `model`과 effort를 비워 두어 카탈로그 기본값(6.2 Sol, `low`)을 따르므로 고칠 키가 없습니다. `developer_instructions`의 "~해줄래 … 실행 지시로 간주" 줄은 6.2 지시문에서 대응 문단이 빠져 중복이 아니게 됐고, 테스트 줄은 (c)와, "차단 상황은 조기에 표면화" 줄은 위 세 문장과 방향이 같습니다. 세 줄 모두 유지합니다. `personality` 키는 쓰지 않습니다.

### 4.3 Codex 공식 프롬프팅 가이드

Codex 문서의 "Prompting GPT-6.2 in Codex"는 6.2 계열 전체에 적용된다고 밝히고 네 가지를 권합니다.

- **검토 기준을 말하기**: "Describe what you need the way you'd ask a colleague who knows the project, then tell Codex **what you'll look for when you review the work**."
- **effort를 조사 깊이에 맞추기**: 빠른 조사는 Medium, 의심 원인 하나를 여러 시스템에 걸쳐 추적하면 High, 여러 원인이 얽히면 Extra High. 높은 effort는 답이 몇 줄이어도 긴 작업의 마지막 점검까지 끌고 가는 데 도움이 됩니다.
- **병렬 작업은 위임을 허락하기**: "tell Codex to **use subagents as needed**". 자주 쓰는 경우에는 스킬이나 `AGENTS.md`에 적용 조건과 함께 적습니다. "With **Ultra**, Codex decides on its own when to bring in subagents."
- **`AGENTS.md`를 가볍게**: "Use `AGENTS.md` for project requirements and conventions that Codex can't infer from the code, tests, or docs. Include a workflow when the project depends on it. Leave routine decisions about how to do the work to Codex."

시각 작업에는 참조 이미지를 주고 실제로 보일 크기에서 결과를 검토하게 하라는 조언이 따로 있습니다(§3.4와 같은 내용).

---

## 5. 시스템 카드 요점

- **등급**: 두 모델 모두 사이버 Critical, 생물·화학 High입니다. AI 자기 개선 등급은 Astra만 High이고 외부 출시 모델로는 처음입니다("GPT-6.2 Astra meets the High threshold for AI Self-Improvement capabilities, while GPT-6.2 Sol falls below it.")
- **좋아진 것**: 모의 업무 과제의 고위험 부적절 행동은 6.2 Astra 0.64%(6 Astra 1.20%), 6.2 Sol 0.71%(6.1 Sol 1.32%)로 절반입니다. 모델이 만든 환경의 프롬프트 인젝션 저항은 6 Astra 44.98%에서 6.2 Astra 84.67%, 6.2 Sol 91.65%로 올랐습니다
- **나빠진 것**: 막힌 일을 알리지 않는 비율(§3.6), 738개 준수 사례의 전체 통과율(6 Astra 90.2% → 6.2 Astra 87.8%, 6.2 Sol 87.1%. 카드는 하락분의 상당 부분을 단서 누락과 미확인 세부를 사실로 다룬 응답으로 설명합니다. "Much of the decline came from replies that omitted a required caveat or treated an unconfirmed detail as fact."), 내부 Codex 재현 평가의 확정 오정렬 표시(6.2 Astra 4.96%, 6 Astra 3.19%. 6.2 Sol 6.78%, 6.1 Sol 5.13%)와 과신 표시(6.2 Astra 0.58%, 6 Astra 0.08%)입니다. 카드는 맥락을 덜 묻는 경향을 간결하고 실행 중심인 응답 선호와 연결합니다
- **사이버 거절 확대**: 거절해야 할 사이버 요청의 거절률이 6 Astra 68.2%에서 6.2 Astra 98.5%, 6.2 Sol 99.4%로 올랐고, 정당한 사이버 작업의 유용성 점수는 90.7%에서 78.1%, 69.5%로 내렸습니다. 카드도 "potentially less useful for cyber work"라고 적습니다. 완화는 Daybreak Red 승인 조직에만 해당하고 Blue 승인만으로는 풀리지 않습니다
- **감시와 중단**: Codex·ChatGPT·Responses API에서 민감 데이터 무단 접근·전송이나 요청하지 않은 파괴적 변경을 감지하면 대화를 멈추거나 끝냅니다. "Some conversations, including those stopped through the API, cannot be resumed." 감시가 비동기라 행동이 이미 실행된 뒤일 수 있습니다. 최종 사용자별 안전 식별자를 보내면 한 사용자의 오용으로 앱 전체가 제한되는 일을 줄입니다
- **평가 인지**: 6.2 Astra는 시험 중이라고 의심하는 발언이 6 Astra보다 많고 6.2 Sol은 더 적습니다

---

## 6. 외부 관찰 (2차, 출시 다음 날이라 표본이 얇음)

설정 기본값의 근거로 쓰지 않습니다. 수치는 측정 주체와 하네스가 다르면 서로 바꿔 쓸 수 없으므로 조건을 함께 적습니다. 비교하려고 함께 인용한 LifeVal은 OpenAI 자체 평가입니다.

### 6.1 제3자 평가

| 평가 (조건) | 6.2 Astra | 6.2 Sol | 6 Astra | 6.1 Sol | 비고 |
|-------------|-----------|---------|---------|---------|------|
| Artificial Analysis 지능 지수 v5.0.1 (API, max) | 62.1, 작업당 $4.00 | 57.3, $1.01 | 56.9, $6.24 | 54.6, $1.27 | Fable 5.2 64.6, $26.54 |
| AA Coding Agent Index v2.1 (Codex 하네스, max) | 53.5 | 48.6 | 53.1 | 52.2 | Claude Code의 Fable 5.2 xhigh 58.5. Codex 버전은 6.2 두 모델 0.166.0, 6.1 Sol 0.154.0, 6 Astra 0.153.4 |
| Vals Index v2.2 (max) | 67.66% | 66.06% | 65.02% | 63.94% | Fable 5.2는 high에서 71.31% |
| Terminal-Bench 4.1 리더보드 (Codex, max) | 62.1% | 61.5% | 60.3% | 60.9% | Claude Code의 Opus 5.5·Fable 5.2는 max에서 65.8% |
| ARC-AGI-3 (ARC Prize 검증 점수, Standard 하네스, max) | 70.3% | 54.9% | 62.7% | 52.7% | Provider Adapter 하네스에서는 Astra max 99.8%, xhigh 100.0% |

- **종합 지수는 올랐고 코딩 에이전트 지수는 제자리입니다.** AA는 "No improvement in Coding Agent Index: GPT-6.2 Astra is flat with GPT-6 Astra, and GPT-6.2 Sol loses 3 points relative to GPT-6.1 Sol"이라고 적고, Sol 하락의 원인을 "a 14-point drop in SWE-Atlas-QnA-AA, where the model is more likely than its predecessor to omit key facts in its responses"로 설명합니다. 저장소 질의응답에서 사실을 빠뜨린 것이라 시스템 카드의 장애 보고 누락(§3.6)과는 다른 시험입니다. 같은 원인을 두 번 확인한 것으로 묶지 않습니다
- **작업당 비용은 AA 종합 지수와 Plotly 시험에서 줄었습니다.** AA 지수에서 Sol은 6 Astra와 비슷한 점수(57.3 대 56.9)를 약 6분의 1의 작업당 비용으로 냅니다. Plotly의 데이터 분석 시험에서는 도구 호출이 약 40% 줄고 전체 비용이 Astra $19.97에서 $4.11, Sol $2.61에서 $1.22로 내려갔지만, 43문항 가운데 Astra 41개, Sol 40개로 전작(43개)보다 정답이 줄었습니다. 모든 시험이 같은 방향은 아닙니다. Cognition의 FrontierCode 2.0(Codex, max)에서 Sol은 점수가 39.6%에서 43.8%로 오르면서 실행당 비용도 $1.03에서 $1.29로 올랐습니다
- **`max`가 늘 최선은 아닙니다.** AA Codex 측정에서 Sol은 xhigh(49.8)가 max(48.6)보다 높고, Astra는 xhigh와 max의 차이가 0.4점인데 작업당 비용은 $3.20과 $5.12입니다
- **`low`는 전작보다 약해진 곳이 있습니다.** OpenAI 발표 차트의 LifeVal에서 Sol low는 25.3%(6.1 Sol low 66.8%), Astra low는 46.3%(6 Astra low 67.5%)입니다. 같은 effort끼리 견주면 Astra는 medium부터(78.9% 대 74.3%), Sol은 high부터(80.8% 대 77.1%, medium은 70.3% 대 75.5%) 전작을 앞섭니다. `none`·`minimal` 자리를 `low`로 옮긴 뒤에는 품질을 다시 잽니다
- **하네스가 결과를 가릅니다.** ARC-AGI-3에서 Astra는 메모만 넘기는 Standard 하네스에서 70.3%, 요청 사이에 추론 상태를 보존하고 압축을 쓰는 Provider Adapter에서 xhigh 100.0%, max 99.8%입니다. 두 하네스는 추론 상태 전달과 압축이 함께 달라지므로 §0.4의 접두사 유지 하나의 효과로 읽지 않습니다. 실행 조건이 점수를 크게 바꾼다는 사례로만 씁니다
- AA-Omniscience 환각률은 Astra 59%, Sol 55%(max)로 전작(49.8%, 51.9%)보다 높습니다

### 6.2 사용자 반응

- **지나친 압축**: 사전 사용자들의 공통 불만입니다. Dan Shipper는 "6.2 appears to have been trained to very extremely concise and actionable—so much so that its writing is hard to understand, and it gives short answers when long answers would be appropriate."라고 썼고, Theo Browne은 "This model has the most unparsable outputs of any llm I've used this year."라고 썼습니다. §3.1의 독자 맥락 스니펫과 최종 답변 스니펫이 이 증상을 겨냥합니다
- **일찍 멈춤과 스스로 막힘**: Shipper "in real coding tasks Astra 6.2 seemed to stop too early frequently", Theo는 작업 2시간째에 사용자가 답할 수 없는 내부 세부를 물으며 멈춘 사례를 들고 "it doesn't seem like you can prompt it out."이라고 덧붙였습니다. 반대로 Hacker News에는 "the first OpenAI model that does not want to finish as soon as some minimal level of quality has been achieved", "GPT 6.2 Sol does a better job at iterating on its own instead of saying "done" after making the first draft"라는 후기가 있습니다. 평가가 갈리므로 §3.2의 스니펫은 증상이 보일 때 넣습니다
- **강점으로 꼽힌 것**: 코드 리뷰("Great reviewer, catches things other models miss"), 3D와 시각 작업, 가격과 토큰 효율
- **사이버 오탐**: 출시 당일 정당한 작업이 거절됐다는 보고가 있습니다. 별개의 지표로, AA Codex 측정의 안전 사유 거절률은 Sol max 2.24%(6.1 Sol 1.34%), Astra max 0.72%(6 Astra 1.16%)입니다. 이 거절률이 정당한 작업만 센 오탐률인지는 확인하지 못했습니다
- **캐시**: Codex 저장소에 6.2 Sol에서 최상위 지시문이 그대로인데 캐시 토큰이 0으로 나온다는 이슈가 올라와 있습니다(openai/codex#62109)

---

## 7. 핵심 정리

1. 요청 형식은 6 Astra·6.1 Sol과 거의 같고, 새로 챙길 것은 접두사 유지입니다. 응답 사이에 요청 파라미터나 지난 이력을 바꾸지 않고 뒤에 덧붙입니다.
2. 6.2는 기본이 간결합니다. 이전 세대용 분량 제한·간결화 지시를 다시 보고, 반드시 남길 내용으로 바꿔 적습니다.
3. 시스템 카드의 시험에서 막힌 일을 보고에서 빠뜨리는 비율이 늘었습니다. API 에이전트에는 막힌 일·못 한 일·세운 가정을 최종 답변에 적으라는 문장을 두기를 권합니다.
4. 자율 실행이 필요하면 멈춰도 되는 네 경우만 남기고, 가정은 밝히고 진행하게 합니다.
5. 코드에는 저장소 관례를 적습니다. 재사용, 변경 범위, 테스트를 더하는 조건, 읽기 쉬움입니다.
6. 스니펫은 증상이 보일 때 넣습니다. 6 가이드의 지시 준수·위임 스니펫도 같습니다.

---

## 8. 한 페이지 치트시트

### API 호출 디폴트

```python
from openai import OpenAI

client = OpenAI()  # OPENAI_API_KEY 환경변수를 읽음

response = client.responses.create(
    model="gpt-6.2-astra",                # 일상 작업·비용 우선이면 gpt-6.2-sol
    reasoning={"effort": "medium"},       # 새 통합의 출발점. none·minimal 자리는 low
    prompt_cache_options={"ttl": "30m"},
    input="Responses API와 Chat Completions의 차이를 세 문장으로 설명해 주세요.",
    # tools=[...] 를 쓰면 도구 호출은 Responses 전용이고, 응답 사이에 목록을 바꾸지 않음
    # temperature / top_p / top_logprobs 는 받지 않음
)
```

### 응답 사이에 설정을 바꿀 때

```diff
- 요청의 reasoning.effort / text.format / tools / instructions 를 바꿔 보냄
+ configuration_update 항목(effort·스키마, 표준 단일 에이전트 Responses에서 다음 사용자 메시지 앞),
+ additional_tools 항목(도구), 새 developer 메시지(지시)를 입력에 덧붙임
+ configuration_update가 든 이력은 /responses/compact 가 거부 → 자동 압축(context_management)을 쓰거나 §0.4 절차대로
- 지난 도구 출력을 나중에 줄임
+ 처음 보낼 때 줄여 보내거나 OpenAI 압축을 씀
```

### 프롬프트에서 이번에 볼 것

```diff
- Be concise. / Keep it short.            # 6.2는 기본이 간결
+ (최종 답변에 반드시 남길 것: 못 한 일, 막힌 곳, 세운 가정, 근거)

+ Only stop to clarify with the user if there is significant change in task scope,
+ you are concretely blocked, have a decision that the user needs to resolve,
+ or before irreversible or destructive actions.

+ Skip new tests unless requested, required by the repo, or needed to catch
+ a specific regression existing tests would miss.
```

---

## Sources

- [Using GPT-6.2 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model/gpt-6.2-astra) — 추론 항목 제외, 행동 축 네 가지와 스니펫 원문, 마이그레이션. 이전 판은 [Using GPT-6](https://developers.openai.com/api/docs/guides/latest-model/gpt-6-astra)
- [Keep the prefix unchanged | OpenAI API](https://developers.openai.com/api/docs/guides/keep-prefix-unchanged) — 접두사 변경의 정의, 덧붙이기 방식 표, 진단
- 모델 카드 [gpt-6.2-astra](https://developers.openai.com/api/docs/models/gpt-6.2-astra) · [gpt-6.2-sol](https://developers.openai.com/api/docs/models/gpt-6.2-sol) — 스펙·가격·지원 도구 · [Models](https://developers.openai.com/api/docs/models) — 대표 목록
- [Model selection](https://developers.openai.com/api/docs/guides/model-selection) — 모델·effort 조합 예시 · [Reasoning models](https://developers.openai.com/api/docs/guides/reasoning) · [Pricing](https://developers.openai.com/api/docs/pricing) · [API changelog](https://developers.openai.com/api/docs/changelog)
- [Introducing GPT-6.2 Astra and Sol | OpenAI](https://openai.com/index/introducing-gpt-6-2-astra-sol/) — 포지셔닝, 가격 인하, 제공 경로, 정렬 절
- [GPT-6.2 Astra and Sol 시스템 카드](https://deploymentsafety.openai.com/gpt-6-2-astra-sol) — 등급, 정렬 평가, 안전장치
- 조사 원문: [research-gpt62.md](../research/research-gpt62.md) · [GPT-6 Prompting Guide (이전 세대, 6.1 Terra·6 Luna 현행)](./gpt-6-prompt-guide.md)
