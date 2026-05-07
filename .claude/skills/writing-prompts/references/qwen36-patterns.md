# Qwen 3.6 프롬프트 패턴

## 목차
- [개요 (Qwen 3.5 → 3.6 핵심 변화)](#개요-qwen-35--36-핵심-변화)
- [1. ChatML 템플릿 + Special Tokens](#1-chatml-템플릿--special-tokens)
- [2. Thinking 모드 (디폴트 ON + `preserve_thinking`)](#2-thinking-모드-디폴트-on--preserve_thinking)
- [3. Tool Calling (`qwen3_coder` 파서, Qwen-Agent)](#3-tool-calling-qwen3_coder-파서-qwen-agent)
- [4. Long Context (262K + YaRN 1M)](#4-long-context-262k--yarn-1m)
- [5. Sampling 프리셋 (모드별·작업별)](#5-sampling-프리셋-모드별작업별)
- [6. Agentic 시나리오 핵심](#6-agentic-시나리오-핵심)
- [7. 배포 트랩 (CUDA, KV cache, third-party)](#7-배포-트랩-cuda-kv-cache-third-party)
- [8. Qwen 3.5 → 3.6 마이그레이션 체크리스트](#8-qwen-35--36-마이그레이션-체크리스트)
- [참고](#참고)

> Qwen 3.6은 Qwen 3.5의 hybrid Gated DeltaNet/Gated Attention 레시피를 유지하면서 **agentic coding**과 **multi-turn 추론 보존(`preserve_thinking`)**을 1순위로 재훈련된 세대다. **시스템 프롬프트는 거의 그대로 동작하지만, `preserve_thinking` API 파라미터·tool 파서 이름(`qwen3_coder`)·sampling 프리셋(모델별 차이)은 마이그레이션 시 반드시 업데이트.**
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/qwen-prompt-guide/qwen-3.6-prompt-guide.md`](../../../../reference/qwen-prompt-guide/qwen-3.6-prompt-guide.md)

---

## 개요 (Qwen 3.5 → 3.6 핵심 변화)

| 항목 | Qwen 3.5 | Qwen 3.6 |
|------|----------|---------|
| Thinking 모드 토글 | `enable_thinking` | **동일** + `preserve_thinking` 신설 |
| Multi-turn reasoning trace | 기본 폐기 | **`preserve_thinking=true` 시 모든 이전 턴 `<think>` 보존** (agentic 권장) |
| Tool-call 파서 | `qwen3` | **`qwen3_coder`** (vLLM/SGLang 권장값) |
| Reasoning 파서 | `qwen3` | **`qwen3` 동일** |
| Context | 모델별 (대개 256K) | **262,144 native + YaRN으로 1,010,000** (오픈웨이트) |
| Plus/Max API | Qwen3.5-Plus 등 | **Qwen3.6-Plus 1M 디폴트, Qwen3.6-Max-Preview 추가** |
| MoE 첫 오픈웨이트 | Qwen3.5-35B-A3B | **Qwen3.6-35B-A3B** (3B 활성, 256 expert) |
| Dense 첫 오픈웨이트 | Qwen3.5-27B | **Qwen3.6-27B** (완전 dense, 양자화 친화적) |
| Multimodal | 일부 모델 | **27B / 35B-A3B 모두 vision encoder 포함** |
| Default system prompt | 없음 | **없음** (정책 유지) |
| 라이선스 | Apache 2.0 | **Apache 2.0** (오픈웨이트) |

[공식, HuggingFace Qwen3.6 모델 카드 + Alibaba Cloud Blog]

---

## 1. ChatML 템플릿 + Special Tokens

Qwen 3.6은 Qwen 시리즈의 **ChatML 변종**을 그대로 사용한다. [공식, tokenizer_config.json]

| Token | 용도 |
|-------|------|
| `<\|im_start\|>` | 메시지 시작 |
| `<\|im_end\|>` | 메시지 종료 |
| `<think>` / `</think>` | 추론 블록 |
| `<tool_call>` / `</tool_call>` | 함수 호출 |
| `<tool_response>` / `</tool_response>` | 툴 응답 |
| `<\|vision_start\|>` / `<\|vision_end\|>` | 비전 콘텐츠 경계 |
| `<\|image_pad\|>` / `<\|video_pad\|>` / `<\|audio_pad\|>` | 멀티모달 placeholder |

### 1.1 기본 ChatML 포맷

```text
<|im_start|>system
You are a helpful assistant.<|im_end|>
<|im_start|>user
Hi there!<|im_end|>
<|im_start|>assistant
<think>
... (모델이 생성하는 reasoning) ...
</think>

Hi! How can I help today?<|im_end|>
```

### 1.2 Default System Prompt 정책

[검증된 외부, Caleb Fahlgren / HF Blog 2025-04-30]
> "Qwen-3 ships without a default system prompt, yet can still accurately identify its creator."

Qwen 3.5에서 도입된 정책이 Qwen 3.6에서도 유지. **시스템 프롬프트가 비어 있어도 동작하지만, 명시 권장.** 이전 Qwen 2.5의 "You are Qwen, created by Alibaba Cloud..." 식 디폴트 주입은 없다.

---

## 2. Thinking 모드 (디폴트 ON + `preserve_thinking`)

[공식, HF Qwen3.6-35B-A3B 모델 카드]
> "Qwen3.6 models operate in thinking mode by default, generating thinking content signified by `<think>\n...</think>\n\n` before producing the final responses."

### 2.1 활성/비활성 토글

```python
# 활성 (디폴트와 동일)
extra_body={"chat_template_kwargs": {"enable_thinking": True}}

# 비활성 (instruct 모드)
extra_body={"chat_template_kwargs": {"enable_thinking": False}}

# Multi-turn reasoning trace 보존 (agentic 권장)
extra_body={"chat_template_kwargs": {"preserve_thinking": True}}
```

### 2.2 권장 사용처

| 시나리오 | 권장 | 근거 |
|----------|------|------|
| 추론·수학·복잡한 코딩 | **Thinking ON** | 디폴트 학습 모드 [공식] |
| 단순 chat / 짧은 분류 / 응답 지연 민감 | **Thinking OFF** | 토큰 절감, 첫 토큰 지연 [검증된 외부, Unsloth] |
| Multi-turn agentic (코딩 에이전트, 멀티스텝 tool) | **Thinking ON + `preserve_thinking=true`** | [공식, Alibaba Cloud Blog] |
| 단발성 RAG QA | Thinking ON, `preserve_thinking` 불필요 | 토큰 비용 |

### 2.3 Context 길이 권고

[공식, HF 모델 카드]
> "We recommend you maintain a context length of at least 128K tokens to preserve thinking capabilities."

→ `max-model-len`을 128K 미만으로 설정하면 thinking 추론 품질 저하.

---

## 3. Tool Calling (`qwen3_coder` 파서, Qwen-Agent)

공식 권장 프레임워크는 **[Qwen-Agent](https://github.com/QwenLM/Qwen-Agent)**. OpenAI 호환 API + vLLM/SGLang 파서로도 정상 동작.

### 3.1 vLLM 권장 명령

```bash
vllm serve Qwen/Qwen3.6-35B-A3B \
  --port 8000 \
  --tensor-parallel-size 8 \
  --max-model-len 262144 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

[공식, HF 모델 카드 deployment 섹션]

→ 파서 이름이 Qwen 3.5의 `qwen3` → **`qwen3_coder`로 변경**됐다. 마이그레이션 시 필수 교체.

### 3.2 SGLang 권장 명령

```bash
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-35B-A3B \
  --port 8000 --tp-size 8 --mem-fraction-static 0.8 \
  --context-length 262144 \
  --reasoning-parser qwen3 \
  --tool-call-parser qwen3_coder
```

### 3.3 Qwen-Agent + MCP 패턴 (공식)

```python
from qwen_agent.agents import Assistant

llm_cfg = {
    'model': 'Qwen3.6-35B-A3B',
    'model_type': 'qwenvl_oai',
    'model_server': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'api_key': os.getenv('DASHSCOPE_API_KEY'),
    'generate_cfg': {
        'use_raw_api': True,
        'extra_body': {
            'enable_thinking': True,
            'preserve_thinking': True,
        },
    },
}

tools = [{'mcpServers': {
    "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
    }
}}]

bot = Assistant(llm=llm_cfg, function_list=tools)
```

### 3.4 Tool 정의 베스트 프랙티스

- **JSON schema는 가능한 한 좁게**. nested object는 `qwen3_coder` 파서가 지원하지만, optional 필드가 많을수록 long-context에서 실패율 증가 [커뮤니티, llama.cpp #20164]
- **병렬 함수 호출 디폴트 지원** [공식, Qwen-Agent README]
- `qwen3_coder` 파서는 코드 인자(`code`, `query`, `path` 등)의 따옴표 escape를 더 안정적으로 처리

---

## 4. Long Context (262K + YaRN 1M)

| 모델 | Native | YaRN 확장 |
|------|--------|----------|
| Qwen3.6-35B-A3B | 262,144 | ~1,010,000 |
| Qwen3.6-27B | 262,144 | ~1,010,000 |
| Qwen3.6-Plus (API) | **1,000,000 디폴트** | — |
| Qwen3.6-Max-Preview (API) | ~262,000 (output ~66K) | — |

### 4.1 권장 패턴

1. **128K 미만 truncate 금지** (thinking 보존 권고와 충돌)
2. **장문서 우선 배치**: Qwen-Agent의 RAG 솔루션은 1M 컨텍스트 native long-context를 능가한다고 자체 보고 — 외부 RAG에도 동일 패턴 권장 [공식]
3. **`preserve_thinking`은 토큰 비용 부담**: agentic multi-turn에서 보존 시 컨텍스트 빠르게 차오름. budget 모니터링 필수.

### 4.2 YaRN 확장 시 KV Cache

[검증된 외부, Unsloth Qwen3.6 가이드]
> gibberish 발생 시 context 길이가 너무 낮거나 KV cache 타입 명시 필요: `--cache-type-k bf16 --cache-type-v bf16`

---

## 5. Sampling 프리셋 (모드별·작업별)

[공식, HF Qwen3.6-35B-A3B / 27B 모델 카드]

OpenAI식 단일 `reasoning_effort`가 아닌 **모드별·작업별 sampling 프리셋**.

### 5.1 Thinking 모드 — 일반

```
temperature = 1.0
top_p       = 0.95
top_k       = 20
min_p       = 0.0
presence_penalty   = 1.5  # (35B-A3B 권장)
repetition_penalty = 1.0
```

> ⚠️ **모델별 차이**: Qwen3.6-27B는 thinking 일반에 `presence_penalty = 0.0`을 권장 (35B-A3B는 1.5). 두 모델을 동일 코드로 서빙 시 **`presence_penalty` 분기 필수**.

### 5.2 Thinking 모드 — 정밀 코딩 (WebDev 등)

```
temperature = 0.6
top_p       = 0.95
top_k       = 20
presence_penalty   = 0.0
repetition_penalty = 1.0
```

### 5.3 Instruct (Non-Thinking) 모드 — 일반

```
temperature = 0.7
top_p       = 0.80
top_k       = 20
presence_penalty   = 1.5
repetition_penalty = 1.0
```

### 5.4 Instruct 모드 — 추론 작업 (thinking 끄고 reasoning 시도)

```
temperature = 1.0
top_p       = 0.95
top_k       = 20
presence_penalty   = 1.5
```

[검증된 외부, Unsloth Qwen3.6 가이드]

---

## 6. Agentic 시나리오 핵심

> "Qwen3.6-Plus demonstrates strong practical engineering performance in code repair, terminal operations, and automated task execution... achieves top results in multiple challenging long-horizon planning tasks." [공식, Alibaba Cloud Blog "Qwen3.6-Plus: Towards Real-World Agents"]

### 6.1 공식 인증 코딩 어시스턴트 호환

> "can be seamlessly integrated with popular third-party coding assistants" — **OpenClaw, Qwen Code, Claude Code** 명시 호환 [공식]

### 6.2 Agentic 시스템 프롬프트 골격

```text
<|im_start|>system
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
<|im_end|>
```

### 6.3 핵심 4가지

1. `enable_thinking=true` + `preserve_thinking=true`
2. `--tool-call-parser qwen3_coder` (vLLM/SGLang) 또는 Qwen-Agent
3. Tool 정의는 nested 최소화, 명시적 description
4. 코딩 작업은 thinking + 코딩용 sampling (§5.2)

---

## 7. 배포 트랩 (CUDA, KV cache, third-party)

### 7.1 CUDA 13.2 회피

[검증된 외부, Unsloth] — Gemma 4와 동일하게 CUDA 13.2 런타임 GGUF 저품질 보고. 다른 버전으로 다운/업그레이드 권장.

### 7.2 Empty `<think>` 블록 prefix-cache 무효화

[커뮤니티, github.com/QwenLM/Qwen3.6 Issue #131]

`enable_thinking=false`도 빈 `<think></think>` 쌍이 의도적으로 삽입돼 (학습 분포 일관성 목적), 일부 추론 엔진에서 prefix cache를 무효화하는 케이스 보고. 재현 확인됨. 영향받는 경우 KV cache 정책 점검.

### 7.3 Ollama 공식 등록 미확인 (§16 빈칸)

본 가이드 작성 시점(2026-05-07)에 Ollama 공식 라이브러리에 Qwen 3.6 등록 여부 미확인. vLLM/SGLang/llama.cpp 우선 권장.

---

## 8. Qwen 3.5 → 3.6 마이그레이션 체크리스트

| 항목 | 변경 필요 | 비고 |
|------|----------|------|
| Chat template (ChatML) | **불변** | 동일 |
| `enable_thinking` API | **불변** | 동일 |
| `preserve_thinking` API | **신규** | agentic multi-turn에서 활성화 평가 |
| Tool-call 파서 | **`qwen3` → `qwen3_coder`** | vLLM/SGLang 모두 |
| Reasoning 파서 | **`qwen3` 동일** | 변경 없음 |
| Sampling 프리셋 | **재확인** | 모델별 `presence_penalty` 차이 (§5.1) |
| Context length | 256K → **262K native + 1M YaRN** | `max-model-len` 상향 검토 |
| 멀티모달 | 일부 → 전 모델 | vision encoder (27B/35B-A3B) |
| Coding agent 호환 | — → **OpenClaw / Claude Code / Qwen Code 인증** | 공식 통합 경로 |
| CUDA 환경 | — | **CUDA 13.2 회피** |

### 마이그레이션 순서

1. [ ] Tool-call 파서를 `qwen3_coder`로 교체
2. [ ] `preserve_thinking=true`를 agentic 시나리오에 활성화
3. [ ] Sampling을 모델별 공식 권장값으로 재설정 (특히 `presence_penalty`)
4. [ ] `max-model-len` 262144로 상향 (필요 시)
5. [ ] 시스템 프롬프트 명시도 점검 (디폴트 없음)
6. [ ] eval 후 `enable_thinking=false` 트래픽이 latency-민감인지 재검토
7. [ ] CUDA 13.2 사용 중이면 다른 버전으로 변경

---

## 참고

- [Qwen 3.6 풀 가이드 (한국어)](../../../../reference/qwen-prompt-guide/qwen-3.6-prompt-guide.md) — 17섹션 + 외부 노하우 + 빈칸
- [Qwen3.6 GitHub](https://github.com/QwenLM/Qwen3.6)
- [Qwen-Agent 공식 프레임워크](https://github.com/QwenLM/Qwen-Agent)
- [HuggingFace 모델 카드 (35B-A3B)](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [Qwen Blog](https://qwen.ai/blog?id=qwen3.6)
- [Alibaba Cloud Blog — Qwen3.6-Plus: Towards Real-World Agents](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
- [Caleb Fahlgren — The 4 Things Qwen-3's Chat Template Teaches Us (HF Blog)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
- [Simon Willison — Qwen3.6-27B 로컬 재현 (2026-04-22)](https://simonwillison.net/2026/Apr/22/qwen36-27b/)
- [Sebastian Raschka — LLM Architecture Gallery](https://sebastianraschka.com/llm-architecture-gallery/)
- [Unsloth Qwen3.6 가이드](https://unsloth.ai/docs/models/qwen3.6)
