# Qwen 3.8 프롬프트 패턴

## 목차
- [개요 (Qwen 3.6 → 3.8 핵심 변화)](#개요-qwen-36--38-핵심-변화)
- [1. ChatML 템플릿 + Special Tokens](#1-chatml-템플릿--special-tokens)
- [2. Thinking 제어 (`reasoning_effort` + `preserve_thinking` 기본 ON)](#2-thinking-제어-reasoning_effort--preserve_thinking-기본-on)
- [3. Tool Calling (XML 포맷, `qwen3_coder` 파서)](#3-tool-calling-xml-포맷-qwen3_coder-파서)
- [4. Long Context (262K + YaRN 1M)](#4-long-context-262k--yarn-1m)
- [5. Sampling 프리셋 (단일화)](#5-sampling-프리셋-단일화)
- [6. Agentic 시나리오 핵심](#6-agentic-시나리오-핵심)
- [7. 배포 트랩 (effort 예외, 라이선스, Flash-Next)](#7-배포-트랩-effort-예외-라이선스-flash-next)
- [8. Qwen 3.6 → 3.8 마이그레이션 체크리스트](#8-qwen-36--38-마이그레이션-체크리스트)
- [참고](#참고)

> Qwen 3.8은 Qwen 3.5 아키텍처 계보를 유지하면서 **Max급 플래그십(2.4T-A95B)을 오픈웨이트로 공개**하고, **`reasoning_effort`(xhigh/medium/low)로 추론 깊이를 제어**하며, **`preserve_thinking`을 기본 ON**으로 바꾼 세대다. **시스템 프롬프트는 그대로 동작하지만, template이 추론 지시문을 자동 주입하고 허용되지 않는 effort 값에 예외를 던지며, 기본값이 매우 길게 생각하도록 되어 있어 운영 설정을 손보지 않으면 지연·비용이 크게 는다.**
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/qwen-prompt-guide/qwen-3.8-prompt-guide.md`](../../../../reference/qwen-prompt-guide/qwen-3.8-prompt-guide.md)

---

## 개요 (Qwen 3.6 → 3.8 핵심 변화)

| 항목 | Qwen 3.6 | Qwen 3.8 |
|------|----------|---------|
| 오픈웨이트 | 35B-A3B, 27B | **2.4T-A95B**(Max급), **27B**, **Flash-Next**(125B-A6B, Qwen4 아키텍처 프리뷰) |
| API | Plus, Max-Preview | **Max**, **Max-0902**, **Flash** |
| Thinking 토글 | `enable_thinking` | 동일 — **2.4T-A95B는 끌 수 없음**(template 예외) |
| `preserve_thinking` | 옵트인 | **기본 ON** |
| 추론 깊이 | sampling으로 간접 | **`reasoning_effort` = `xhigh`(기본) / `medium` / `low`** |
| Sampling | 모델별 `presence_penalty` 분기, 코딩용 temp 0.6 | **단일 프리셋** (thinking `presence_penalty=0.0`) |
| 출력 예산 | — | **reasoning 262,144 / 최종 131,072** |
| Tool 파서 | `qwen3` / `qwen3_coder` | 동일 (Flash-Next 레시피는 `qwen3_xml`) |
| 라이선스 | Apache 2.0 | **27B만 Apache 2.0**. 2.4T-A95B 커스텀, Flash-Next Qwen Community 1.0 |
| 멀티모달 | 27B·35B-A3B vision | 27B·Flash-Next vision. **2.4T-A95B는 텍스트 전용** |
| Ollama | 미확인 | **공식 `qwen3.8:27b`** |

[공식, HF 모델 카드 + QwenLM/Qwen3.8 README + Alibaba Cloud Blog]

---

## 1. ChatML 템플릿 + Special Tokens

Qwen 3.6과 토큰·ID 모두 동일. [공식, tokenizer_config.json]

| Token | 용도 |
|-------|------|
| `<\|im_start\|>` / `<\|im_end\|>` | 메시지 경계 |
| `<think>` / `</think>` | 추론 블록 |
| `<tool_call>` / `</tool_call>` | 함수 호출 |
| `<tool_response>` / `</tool_response>` | 툴 응답 |
| `<\|vision_start\|>` / `<\|vision_end\|>` / `<\|image_pad\|>` / `<\|video_pad\|>` | 멀티모달 |

### 1.1 기본 포맷 — 추론 지시문이 자동으로 앞에 붙는다

```text
<|im_start|>system
Reasoning effort is set to xhigh. Please think carefully through the task, validate key assumptions, consider plausible alternatives, and prioritize correctness, consistency, and clarity in the final answer.

You are a helpful assistant.<|im_end|>
<|im_start|>user
Hi there!<|im_end|>
<|im_start|>assistant
<think>
...
</think>

Hi! How can I help today?<|im_end|>
```

첫 문단은 사용자가 쓴 것이 아니라 **chat template이 주입**한 것이다. `low`는 "Keep your thinking brief and focused, moving directly to the conclusion without unnecessary elaboration." 문장, **`medium`은 아무것도 주입하지 않는다.** 시스템 메시지가 없어도 thinking ON이면 지시문만 담은 시스템 턴이 생긴다. [공식, chat_template]

### 1.2 Default System Prompt 정책

디폴트 시스템 프롬프트 없음(Qwen 3 시리즈 정책 유지). 단 `xhigh`·`low`에서는 위 1.1처럼 template이 지시문만 담은 시스템 턴을 만들므로 "비어 있다"고 가정하지 말 것.

### 1.3 커스텀 XML 태그 주의

시스템 프롬프트 구조는 **Markdown 헤더**(`# Goal`, `# Tools`, `# Style`)가 공식 예시와 같다. XML 태그로 절을 나누는 것을 막는 문구는 없지만 **`<think>`, `<tool_call>`, `<tool_response>`, `<tools>`, `<function=…>`, `<parameter=…>`는 template 예약어**라 커스텀 태그로 쓰지 않는다. 입력·문서 경계용 `<document>` 류는 무방.

---

## 2. Thinking 제어 (`reasoning_effort` + `preserve_thinking` 기본 ON)

### 2.1 오픈웨이트 (chat_template_kwargs)

```python
# 기본값과 동일
extra_body={"chat_template_kwargs": {
    "enable_thinking": True, "preserve_thinking": True, "reasoning_effort": "xhigh"}}

# 로컬 대화·코딩 — 깊이 낮추기
extra_body={"chat_template_kwargs": {"reasoning_effort": "low"}}

# 단발 RAG — 이전 reasoning 버림
extra_body={"chat_template_kwargs": {"preserve_thinking": False}}

# instruct 모드 — 27B·Flash-Next만 (2.4T-A95B는 "Disabling thinking is not supported.")
extra_body={"chat_template_kwargs": {"enable_thinking": False}}
```

[공식, HF Qwen3.8-27B 모델 카드 / tokenizer_config.json]

### 2.2 호스팅 API (QwenCloud / Model Studio) — 토큰 예산 매핑

| 파라미터 | 값 |
|----------|----|
| `reasoning_effort` | `low` 4,096 / `medium` 16,384 / `xhigh` 262,144 (기본). 별칭 `max`·`high`→`xhigh`, `minimal`→`low`, `none`→`enable_thinking=False` |
| `thinking_budget` | 추론 토큰 상한. **`reasoning_effort`와 동시 지정 불가** |
| `preserve_thinking` | `qwen3.8-max`·`-0902` 기본 true. 되돌린 `reasoning_content`는 **입력 토큰 과금** |
| `max_completion_tokens` | CoT + 답변 합계 (권장). `max_tokens`는 CoT 미제한 |

[공식, QwenCloud OpenAI chat API reference]

### 2.3 `preserve_thinking`이 실제로 동작하는 조건

1. 응답의 `reasoning_content`를 다음 요청 assistant 메시지에 **같은 필드로** 되돌린다. `content`에 `<think>`를 이어 붙이면 template이 인식하지 않는다.
2. 대부분의 OpenAI 호환 클라이언트는 이 필드를 버린다. 하네스별 실측 필수.
3. Ollama OpenAI API는 `chat_template_kwargs`를 전달하지 않는다는 3.6 기준 미해결 보고 [커뮤니티, ollama#16240]

### 2.4 권장 사용처

| 시나리오 | 권장 | 근거 |
|----------|------|------|
| 호스팅 API 복잡 추론·코딩 | ON, `xhigh` | 기본값·벤치 조건 [공식] |
| 로컬 27B 대화·코딩 | ON, **`low`~`medium`** | `xhigh`는 SVG 하나에 21분·추론 22,276 토큰 [검증된 외부, Simon Willison] |
| 도구 호출 agentic 루프 | ON + `preserve_thinking`, effort는 실측 | "lower effort doesn't always mean faster end-to-end… more failures and retries" [공식, Alibaba Cloud 실전 가이드] |
| 분류·latency-critical | **OFF** | 2.4T-A95B 불가 |
| 단발 RAG | ON, `preserve_thinking=false` | 컨텍스트·과금 절약 |

### 2.5 출력 예산

> reasoning 262,144 / 최종 응답 131,072 [공식, 세 모델 카드 Best Practices] — 합치면 native 262K를 넘으므로 장기 작업은 YaRN 1M 전제.

---

## 3. Tool Calling (XML 포맷, `qwen3_coder` 파서)

### 3.1 서빙 명령

```bash
# vLLM
vllm serve Qwen/Qwen3.8-27B --port 8000 --tensor-parallel-size 4 \
  --max-model-len 262144 --reasoning-parser qwen3 \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder

# SGLang (CLI가 sglang serve로 바뀜, 구형 launch_server도 동작)
sglang serve --model-path Qwen/Qwen3.8-27B --port 8000 --tp-size 4 \
  --context-length 262144 --reasoning-parser qwen3 --tool-call-parser qwen3_coder
```

[공식, QwenLM/Qwen3.8 README] Flash-Next vLLM 레시피는 `--tool-call-parser qwen3_xml`. [공식, recipes.vllm.ai]

### 3.2 호출 포맷은 XML 스타일

```text
<tool_call>
<function=list_directory>
<parameter=path>
/tmp
</parameter>
</function>
</tool_call>
```

3.5 이후 template이 계속 이 포맷이다. `<tool_call>` 안에 JSON을 넣는 것은 옛 Qwen3 포맷이므로 쓰지 않는다. 문자열 인자는 그대로, 그 외는 JSON 직렬화. [공식, chat_template]

### 3.3 Qwen-Agent + MCP

```python
llm_cfg = {
    'model': 'qwen3.8-max',
    'model_type': 'qwenvl_oai',
    'model_server': 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
    'api_key': os.getenv('DASHSCOPE_API_KEY'),
    'generate_cfg': {'use_raw_api': True,
                     'extra_body': {'enable_thinking': True,
                                    'preserve_thinking': True,
                                    'reasoning_effort': 'medium'}},
}
tools = [{'mcpServers': {"filesystem": {"command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]}}}]
bot = Assistant(llm=llm_cfg, function_list=tools)
```

구조는 Qwen 모델 카드의 공식 Qwen-Agent 예제, 모델·엔드포인트·effort는 3.8 API 문서 기준.

### 3.4 Tool 정의 베스트 프랙티스

- JSON schema는 좁게, optional 최소화 [커뮤니티, llama.cpp #20164]
- 병렬 호출 지원 [공식, Qwen-Agent]
- "call tools directly without asking permission for read-only inspection" 류 권한 부여 문장이 호출률을 올린다

---

## 4. Long Context (262K + YaRN 1M)

| 모델 | Native | 확장 |
|------|--------|------|
| 27B / Flash-Next | 262,144 | YaRN 1,000,000 |
| 2.4T-A95B | 262,144 | YaRN 1,010,000 |
| Max / Flash / 27B 호스팅 (API) | **1,000,000** | — |

### 4.1 YaRN은 필요할 때만, factor는 실제 길이에

```bash
VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 vllm serve Qwen/Qwen3.8-27B \
  --hf-overrides '{"text_config": {"rope_parameters": {"mrope_interleaved": true, "mrope_section": [11, 11, 10], "rope_type": "yarn", "rope_theta": 10000000, "partial_rotary_factor": 0.25, "factor": 4.0, "original_max_position_embeddings": 262144}}}' \
  --max-model-len 1000000
```

> "static YaRN — the scaling factor stays constant regardless of input length, which can hurt performance on shorter texts. Only enable YaRN when you actually need long contexts." / "If your workloads usually sit around 524,288 tokens, set factor to 2.0 instead of 4.0." [공식, Alibaba Cloud 실전 가이드]

### 4.2 `preserve_thinking` 기본 ON은 컨텍스트를 빠르게 채운다

호스팅 API는 과금까지 붙는다. 단발 작업은 끈다.

---

## 5. Sampling 프리셋 (단일화)

[공식, HF 27B · 2.4T · Flash-Next 모델 카드 — 세 모델 동일]

```
# Thinking
temperature=1.0  top_p=0.95  top_k=20  min_p=0.0  presence_penalty=0.0  repetition_penalty=1.0

# Instruct (27B·Flash-Next)
temperature=0.7  top_p=0.80  top_k=20  min_p=0.0  presence_penalty=1.5  repetition_penalty=1.0
```

- 3.6의 모델별 `presence_penalty`(1.5/0.0) 분기 → **0.0 통일**. 반복 시 0~2 사이에서 조정
- 3.6의 정밀 코딩 temp 0.6 프리셋 → **삭제**. 깊이는 `reasoning_effort`로

---

## 6. Agentic 시나리오 핵심

> "taking a real, multi-day project from an empty folder all the way to a finished result, on its own" [공식, Qwen Blog qwen3.8]

### 6.1 공식 설정을 제공하는 하네스

**Claude Code, Codex, Qwen Code, Qoder, OpenClaw** [공식, Qwen Blog]. Anthropic 호환 엔드포인트 `https://dashscope.aliyuncs.com/apps/anthropic`, OpenAI 호환 `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`.

### 6.2 시스템 프롬프트 골격

```text
You are a senior software engineer collaborating with the user.

# Goal
Resolve the user's request end-to-end within the current session.

# Tools
You have access to <list>. Call them whenever they materially improve
correctness or grounding. You do not need to ask permission for
read-only inspection.

# Style
- Be concise. Lead with the answer, then evidence.
- Show only the code that changed; do not re-print untouched files.
- If a step is blocked, surface the blocker explicitly.

# Reasoning policy
- Use your thinking trace to plan tool calls and verify outputs.
- Final answer to the user must be self-contained and not reference
  the thinking trace.
```

"천천히 생각하라" 류 문장은 넣지 않는다 — `xhigh` 지시문과 중복. 깊이는 `reasoning_effort`로만.

### 6.3 핵심 5가지

1. `preserve_thinking` 유지 + 클라이언트의 `reasoning_content` 왕복 확인
2. `reasoning_effort`는 턴 지연이 아니라 **end-to-end 완료율**로 선택
3. `--tool-call-parser qwen3_coder` (Flash-Next는 `qwen3_xml`) 또는 Qwen-Agent
4. 출력 예산 262,144 / 131,072, 장기 작업은 YaRN 1M
5. Tool 정의 nested 최소화

---

## 7. 배포 트랩 (effort 예외, 라이선스, Flash-Next)

### 7.1 `reasoning_effort` 예외 — Claude Code의 `high`

> "Unexpected reasoning effort high. Supported types are xhigh (default), medium, and low." [커뮤니티, QwenLM/Qwen3.8#217, open]

vLLM Anthropic 엔드포인트로 로컬 27B를 Claude Code에 붙이면 500. `CLAUDE_CODE_EFFORT_LEVEL=medium` 또는 template에 `high → medium` 별칭. 호스팅 API는 별칭을 공식 지원해 발생하지 않는다.

### 7.2 라이선스 — Apache 2.0은 27B뿐

| 모델 | 라이선스 |
|------|----------|
| 27B | Apache 2.0 |
| 2.4T-A95B | Qwen3.8-Max 커스텀 — MAU 1억 / 월 매출 2,000만 달러 초과 시 모델명 UI 표기, MaaS·AI Work Assistant 사업은 별도 라이선스 |
| Flash-Next | Qwen Community License 1.0 — 같은 조건 |

[공식, HF LICENSE] Alibaba Cloud 블로그의 "Apache 2.0" 서술보다 저장소 LICENSE가 우선.

### 7.3 빈 history `<think>` 블록

`preserve_thinking` 기본 ON이라 `reasoning_content`가 없는 이전 턴에도 `<think>\n\n</think>`가 찍힌다(3.6 Issue #131 패턴 잔존). prefix cache 적중률에 영향. [커뮤니티] 우회는 froggeric 수정 템플릿(v22.5) 등.

### 7.4 Flash-Next 고유

vLLM 0.29.0+, FP8 172.78 GiB. H100은 `VLLM_PLE_CPU_OFFLOAD=1`(N-gram Embedding 오프로드, 호스트 51 GB+), "Plain TP8 is incompatible with the FP8 checkpoint; use TEP8", MTP는 H100에서 "8-36% lower request throughput". [공식, recipes.vllm.ai]

### 7.5 MTP 메서드명

vLLM `--speculative-config '{"method":"mtp","num_speculative_tokens":3}'` — 3.6의 `qwen3_next_mtp`에서 변경. [공식, recipes.vllm.ai]

### 7.6 로컬 규모 [검증된 외부, Unsloth]

27B 4-bit 16~19 GB(MTP 시 +1~2 GB). 2.4T-A95B 동적 1-bit 397~508 GB. Ollama 공식 `qwen3.8:27b` 17~18 GB.

---

## 8. Qwen 3.6 → 3.8 마이그레이션 체크리스트

| 항목 | 변경 | 비고 |
|------|------|------|
| Chat template 토큰 | 불변 | |
| `enable_thinking` | 불변 — 2.4T-A95B는 false 불가 | |
| `preserve_thinking` | **기본 ON** | 끄려면 명시. `reasoning_content` 왕복 확인 |
| `reasoning_effort` | **신규** | `xhigh`/`medium`/`low`만. `high`·`none` 예외 |
| 시스템 턴 | **지시문 자동 주입** | 없어도 시스템 턴 생성 |
| Sampling | **단일 프리셋** | `presence_penalty` 분기·temp 0.6 삭제 |
| 출력 예산 | **신규** | 262,144 / 131,072 |
| Tool 파서 | 불변 | Flash-Next `qwen3_xml` |
| MTP | `qwen3_next_mtp` → `mtp` | |
| 라이선스 | **모델별 상이** | LICENSE 확인 |
| Ollama | **공식 등록** | template 파라미터 전달은 실측 |

### 마이그레이션 순서

1. [ ] `reasoning_effort` 정책 — 로컬 `low`/`medium`, 호스팅 `xhigh` 후 실측
2. [ ] `preserve_thinking` 왕복 검증 또는 `false`
3. [ ] 하네스 effort 값 `medium` 고정 (Claude Code 등)
4. [ ] Sampling 단일 프리셋으로 통일
5. [ ] `max_completion_tokens`·프레임워크 상한 재설정
6. [ ] 2.4T-A95B·Flash-Next 채택 시 LICENSE 검토
7. [ ] MTP `mtp`, Flash-Next `qwen3_xml`
8. [ ] YaRN은 262K 초과 시에만

---

## 참고

- [Qwen 3.8 풀 가이드 (한국어)](../../../../reference/qwen-prompt-guide/qwen-3.8-prompt-guide.md) — 17섹션 + 외부 노하우 + 미확인 영역
- [Qwen3.8 GitHub](https://github.com/QwenLM/Qwen3.8)
- [Qwen-Agent 공식 프레임워크](https://github.com/QwenLM/Qwen-Agent)
- [HuggingFace 모델 카드 (27B)](https://huggingface.co/Qwen/Qwen3.8-27B) · [2.4T-A95B](https://huggingface.co/Qwen/Qwen3.8-2.4T-A95B) · [Flash-Next](https://huggingface.co/Qwen/Qwen3.8-Flash-Next)
- [Qwen3.8-Max: A New Bar for Coding and Cowork (Alibaba Cloud 미러)](https://www.alibabacloud.com/blog/qwen3-8-max-a-new-bar-for-coding-and-cowork_603421)
- [Qwen3.8-Flash-Next: A New Architecture (Alibaba Cloud 미러)](https://www.alibabacloud.com/blog/603501)
- [Qwen3.8-27B Practical Guide (Alibaba Cloud)](https://www.alibabacloud.com/blog/qwen3-8-27b-practical-guide-control-reasoning-depth-and-extend-context-to-1m-tokens_603509)
- [QwenCloud OpenAI chat API reference](https://docs.qwencloud.com/api-reference/chat/openai-chat)
- [vLLM Recipes — Qwen3.8-Flash-Next](https://recipes.vllm.ai/Qwen/Qwen3.8-Flash-Next)
- [Simon Willison — Qwen 3.8 27B overthinking (2026-08-16)](https://simonwillison.net/2026/Aug/16/qwen-38-27b/)
- [Unsloth Qwen3.8 가이드](https://unsloth.ai/docs/models/qwen3.8)
