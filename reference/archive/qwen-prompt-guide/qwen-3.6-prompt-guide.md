# Qwen 3.6 Prompting Guide

> **출처 (1차 공식)**:
> - [Qwen3.6 GitHub Repository | QwenLM](https://github.com/QwenLM/Qwen3.6)
> - [Qwen/Qwen3.6-35B-A3B Model Card | Hugging Face](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
> - [Qwen/Qwen3.6-27B Model Card | Hugging Face](https://huggingface.co/Qwen/Qwen3.6-27B)
> - [Qwen3.6-35B-A3B: Agentic Coding Power, Now Open to All | Qwen Blog](https://qwen.ai/blog?id=qwen3.6-35b-a3b) ([Alibaba Cloud 미러](https://www.alibabacloud.com/blog/qwen3-6-35b-a3b-agentic-coding-power-now-open-to-all_603043))
> - [Qwen3.6-Plus: Towards Real-World Agents | Alibaba Cloud (2026-04)](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
> - [Qwen3.6-Max-Preview: Smarter, Sharper, Still Evolving | Qwen Blog](https://qwen.ai/blog?id=qwen3.6-max-preview)
> - [Qwen-Agent Framework | QwenLM](https://github.com/QwenLM/Qwen-Agent)
> - [Qwen/Qwen3.6-35B-A3B tokenizer_config.json (chat template 원본)](https://huggingface.co/Qwen/Qwen3.6-35B-A3B/raw/main/tokenizer_config.json)
>
> **출처 (검증된 외부)**:
> - [The 4 Things Qwen-3's Chat Template Teaches Us | Caleb Fahlgren · Hugging Face Blog](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
> - [Qwen3.6-27B: Flagship-Level Coding in a 27B Dense Model | Simon Willison (2026-04-22)](https://simonwillison.net/2026/Apr/22/qwen36-27b/)
> - [Qwen3.6 - How to Run Locally | Unsloth Documentation](https://unsloth.ai/docs/models/qwen3.6)
> - [LLM Architecture Gallery / A Dream of Spring for Open-Weight LLMs | Sebastian Raschka](https://magazine.sebastianraschka.com/p/a-dream-of-spring-for-open-weight)
>
> **날짜**: 2026-05-07 (모든 URL 접근 일자)
> **이전 버전 비교**: Qwen 3.5 (Qwen3.5-35B-A3B / Qwen3.5-27B / Qwen3.5-397B-A17B 등)

---

## 출처 신뢰 등급

본문 인용은 다음 라벨로 구분한다.

- **[공식]** — Alibaba/Qwen 팀 직접 발행 (GitHub, Qwen Blog, HuggingFace 모델 카드, Alibaba Cloud Blog)
- **[검증된 외부]** — Simon Willison, Sebastian Raschka, HuggingFace 공식 블로그, Unsloth 등 재현 가능한 발견을 공개한 신뢰 가능한 분석가/조직
- **[커뮤니티]** — GitHub Issue, Reddit, 개인 블로그. 재현 가능 여부 명시.

근거가 약한 일반론은 본문에서 제외하고 §16 "확인되지 않은 영역"에 솔직히 나열했다.

---

## ⚠️ 가장 먼저 알아야 할 것 (Qwen 3.5 → 3.6 핵심 변화)

Qwen 3.6은 Qwen 3.5의 하이브리드 Gated DeltaNet/Gated Attention 레시피를 유지하면서 **agentic coding**과 **multi-turn 추론 보존(`preserve_thinking`)**을 1순위 목표로 재훈련된 세대다. **기존 Qwen 3.5 시스템 프롬프트는 거의 그대로 동작하지만, `preserve_thinking` API 파라미터·`<think>` 블록 처리 정책·툴 콜 파서 이름이 바뀐 부분은 마이그레이션 시 반드시 업데이트해야 한다.**

> "Qwen3.6 models operate in thinking mode by default, generating thinking content signified by `<think>\n...</think>\n\n` before producing the final responses." [공식, HuggingFace Qwen3.6-35B-A3B 모델 카드, 2026-05-07 접근]

> "This release supports the `preserve_thinking` feature: preserving thinking content from all preceding turns in messages, which is recommended for agentic tasks." [공식, Alibaba Cloud Blog Qwen3.6-35B-A3B, 2026-05-07 접근]

### 한 페이지 변화 요약

| 항목 | Qwen 3.5 | Qwen 3.6 |
|------|----------|---------|
| Thinking 모드 토글 | `enable_thinking` (true/false) | **동일** + `preserve_thinking` 신설 |
| 멀티턴 reasoning trace | 기본 폐기 | **`preserve_thinking=true` 시 모든 이전 턴의 `<think>` 블록 보존** (agentic 권장) |
| Tool-call 파서 이름 | `qwen3` | **`qwen3_coder`** (vLLM/SGLang 권장값) |
| Reasoning 파서 | `qwen3` | **`qwen3` 동일** |
| Context 길이 | 모델별 상이 (대개 256K) | **262,144 native + YaRN으로 1,010,000까지 확장** (오픈웨이트 기준) |
| Plus/Max API | Qwen3.5-Plus 등 | **Qwen3.6-Plus 1M 컨텍스트 디폴트, Qwen3.6-Max-Preview 추가** |
| Agentic coding | 일반 SOTA 수준 | **Qwen3.6-Plus / Qwen3.6-Max-Preview가 6개 코딩 벤치 1위 주장** |
| MoE 패밀리 첫 오픈웨이트 | Qwen3.5-35B-A3B | **Qwen3.6-35B-A3B (3B 활성, 35B 총 파라미터, 256 expert)** |
| Dense 패밀리 첫 오픈웨이트 | Qwen3.5-27B | **Qwen3.6-27B (27B 완전 dense)** |
| 멀티모달 | 일부 모델 | **27B / 35B-A3B 모두 vision encoder 포함** |
| 라이선스 | Apache 2.0 (오픈웨이트) | **Apache 2.0 동일** |
| Default system prompt | 없음 (Qwen 3 시리즈 정책 유지) | **없음** [검증된 외부, Caleb Fahlgren / HF Blog] |

---

## 1. 개요

Qwen 3.6은 2026년 4월 Alibaba Qwen 팀이 출시한 LLM 패밀리. 동일 시기 출시된 모델들과 차별화되는 기둥은 세 가지다.

1. **Hybrid Gated DeltaNet + Gated Attention 아키텍처** — Qwen 3.5에서 도입된 선형 어텐션/소프트맥스 어텐션 혼합 구조를 그대로 사용. [공식, HF 모델 카드 / 검증된 외부, Sebastian Raschka LLM Architecture Gallery]
2. **Thinking Preservation** — `preserve_thinking` 파라미터로 멀티턴 reasoning trace를 보존. agentic 시나리오에 명시적으로 최적화. [공식, Alibaba Cloud Blog 2026-04]
3. **Agentic Coding 1위 주장** — Qwen3.6-Plus / Max-Preview가 6개 코딩 벤치 SOTA를 주장. [공식, Qwen Blog / 검증된 외부, Simon Willison 2026-04-22 로컬 재현]

### 핵심 강점 (공식 권고 정리)

- 디폴트 thinking 모드로 추론·수학·코딩에 최적화
- 멀티턴 agent 워크플로우에서 `preserve_thinking`으로 일관성 유지
- 262K native context (모든 오픈웨이트), YaRN으로 1M 확장
- `qwen3_coder` 파서로 nested object 인자 안정 처리 [공식, HF 모델 카드 deployment 섹션]
- Apache 2.0 (모든 오픈웨이트 모델)

### 명시적 프롬프팅이 필요한 영역

- Thinking ↔ non-thinking 모드 선택 (작업 종류별)
- `preserve_thinking` 활성화 정책 (agentic vs single-turn QA)
- Sampling 파라미터 (thinking과 non-thinking이 다름 — §9 참고)
- 시스템 프롬프트 작성 (디폴트 없음 → 명시 권장)
- Tool 정의의 JSON schema 정확성 (Qwen-Agent 권장)

---

## 2. 모델 변형

Qwen 3.6은 오픈웨이트와 API 전용으로 나뉜다. 본 절은 **공식 출처에서 확인된 사양만** 기재한다.

| 모델 | 타입 | 총 / 활성 파라미터 | 컨텍스트 | 첫 공개 | 공개 형태 | 비고 |
|------|------|-------------------|----------|--------|-----------|------|
| **Qwen3.6-35B-A3B** | MoE (256 expert, 8 routed + 1 shared 활성) | 35B / 3B | 262,144 native, ~1.01M YaRN 확장 | 2026-04-16 | 오픈웨이트 (Apache 2.0) | 첫 오픈웨이트 Qwen3.6, multimodal vision encoder 포함 [공식, HF 모델 카드] |
| **Qwen3.6-27B** | Dense (causal LM + vision encoder) | 27B / 27B | 262,144 native, ~1.01M YaRN 확장 | 2026-04-22 | 오픈웨이트 (Apache 2.0) | 모든 파라미터 매 토큰 활성. 양자화 친화적 [공식, HF 모델 카드 / 검증된 외부, Simon Willison] |
| **Qwen3.6-Plus** | API 전용 (구조 비공개) | 비공개 | **1M 디폴트** | 2026-04 | Alibaba Cloud Model Studio API | "drastically enhanced agentic coding"; 멀티모달, frontend/3D/게임 코딩 강조 [공식, Alibaba Cloud Blog] |
| **Qwen3.6-Max-Preview** | API 전용 (구조 비공개) | 비공개 | ~262K context, 출력 ~66K | 2026-04-20 | API (OpenAI/Anthropic 호환 모드) | 6개 주요 코딩 벤치 1위 주장 [공식, Qwen Blog · 검증된 외부, BuildFast/TokenMix 분석] |

### Qwen3.6-35B-A3B 아키텍처 상세 [공식, HF 모델 카드]

| 항목 | 값 |
|------|----|
| Hidden dimension | 2,048 |
| Layers | 40 |
| Layout | `10 × (3 × Gated DeltaNet → MoE) → 1 × (Gated Attention → MoE)` |
| Gated DeltaNet | 32 V heads / 16 QK heads / head dim 128 |
| Gated Attention | 16 Q heads / 2 KV heads / head dim 256 / RoPE dim 64 |
| MoE | 256 experts total, 8 routed + 1 shared active, expert intermediate dim 512 |
| Training | Multi-token prediction (MTP) 지원 (vLLM speculative config 가능) |
| Tokenizer | embedding/LM head 248,320 (padded) |

### Qwen3.6-27B 아키텍처 상세 [공식, HF 모델 카드]

| 항목 | 값 |
|------|----|
| Hidden dimension | 5,120 |
| Layers | 64 |
| Layout | `16 × (3 × (Gated DeltaNet → FFN) → 1 × (Gated Attention → FFN))` |
| Gated DeltaNet | 48 V heads / 16 QK heads / head dim 128 |
| Gated Attention | 24 Q heads / 4 KV heads / head dim 256 |
| Type | Causal LM + Vision Encoder, 완전 dense |

> "Qwen3.6 is a compact open-weight MoE that keeps the Qwen3.5 hybrid Gated DeltaNet/Gated Attention recipe while activating only about 3B parameters." [검증된 외부, Sebastian Raschka LLM Architecture Gallery, 2026-05-07 접근]

---

## 3. ChatML 템플릿 / 시스템 프롬프트 구조

Qwen 3.6은 Qwen 시리즈의 **ChatML 변종**을 그대로 사용한다. 토크나이저 설정 원본([HF tokenizer_config.json](https://huggingface.co/Qwen/Qwen3.6-35B-A3B/raw/main/tokenizer_config.json))에서 직접 추출한 special token은 다음과 같다. [공식]

| Token ID | Content | 용도 |
|----------|---------|------|
| 248045 | `<|im_start|>` | 메시지 시작 |
| 248046 | `<|im_end|>` | 메시지 종료 |
| 248068 | `<think>` | 추론 블록 시작 |
| 248069 | `</think>` | 추론 블록 종료 |
| 248058 | `<tool_call>` | 함수 호출 시작 |
| 248059 | `</tool_call>` | 함수 호출 종료 |
| 248066 | `<tool_response>` | 툴 응답 시작 |
| 248067 | `</tool_response>` | 툴 응답 종료 |
| — | `<|vision_start|>` / `<|vision_end|>` | 비전 콘텐츠 경계 |
| — | `<|image_pad|>` / `<|video_pad|>` / `<|audio_pad|>` | 멀티모달 placeholder |

### 3.1 기본 ChatML 포맷 (텍스트 전용)

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

### 3.2 Default system prompt 정책

> "Qwen-3 ships without a default system prompt, yet can still accurately identify its creator." [검증된 외부, Caleb Fahlgren / HF Blog "The 4 Things Qwen-3's Chat Template Teaches Us"]

Qwen 3.5에서 도입된 정책이 Qwen 3.6에서도 유지된다. **시스템 프롬프트가 비어 있어도 동작하지만, 명시 권장**. 이전 Qwen 2.5의 "You are Qwen, created by Alibaba Cloud..." 식 디폴트 주입은 없다.

### 3.3 Thinking 비활성 시 빈 think 블록 삽입 (의도된 설계)

```jinja
{# Qwen3 / Qwen3.6 #}
{%- if enable_thinking is defined and enable_thinking is false %}
    {{- '<think>\n\n</think>\n\n' }}
{%- endif %}
```

`enable_thinking=false`일 때도 빈 `<think></think>` 쌍을 삽입하는 것은 의도적이다. 모델이 학습 시 항상 이 토큰 패턴을 본다. [검증된 외부, Caleb Fahlgren / HF Blog 2025-04-30]

> ⚠️ **커뮤니티 발견 (재현 확인됨)**: 멀티턴 history에 reasoning이 없는 assistant 응답까지 빈 `<think></think>` 블록이 들어가서 prefix-cache가 무효화되는 사례가 보고됨. [커뮤니티, GitHub Issue QwenLM/Qwen3.6#131 by latent-variable, 2026-04-09 / Qwen 3.5-27B llama.cpp 환경에서 재현 확인] 워크어라운드: 템플릿 조건을 `loop.index0 > ns.last_query_index and reasoning_content`로 수정. 공식 패치 여부는 본 가이드 작성 시점(2026-05-07) 미확인 — §16 참고.

### 3.4 Rolling Checkpoint (멀티턴 reasoning 관리)

> "Qwen-3 uses a 'rolling checkpoint' system that intelligently preserves or prunes reasoning blocks during multi-step tool calls. Traverses the message list in reverse to find the latest user turn that wasn't a tool call. Keeps full `<think>` blocks for assistant replies after that index. Strips earlier reasoning to save tokens." [검증된 외부, Caleb Fahlgren / HF Blog]

Qwen 3.6은 이 동작을 그대로 유지하면서 `preserve_thinking=true` 옵션으로 **모든 이전 reasoning trace 보존**을 추가했다. agentic multi-step 워크플로우에서는 후자를 권장.

### 3.5 Tool Call 인자 직렬화

```jinja
{%- if tool_call.arguments is string %}
    {{- tool_call.arguments }}
{%- else %}
    {{- tool_call.arguments | tojson }}
{%- endif %}
```

이전 세대에서는 인자를 무조건 `| tojson`으로 흘려서 이중 이스케이프 위험이 있었다. Qwen 3 / 3.6은 타입을 먼저 검사한다. [검증된 외부, Caleb Fahlgren / HF Blog]

---

## 4. Thinking 모드

Qwen 3.6은 thinking 모드가 **기본 활성**이다.

> "Qwen3.6 models operate in thinking mode by default, generating thinking content signified by `<think>\n...</think>\n\n` before producing the final responses." [공식, HF 모델 카드]

### 4.1 활성/비활성 토글

```python
# 활성 (기본값과 동일)
extra_body={"chat_template_kwargs": {"enable_thinking": True}}

# 비활성 (instruct 모드)
extra_body={"chat_template_kwargs": {"enable_thinking": False}}

# 멀티턴 reasoning trace 보존 (agentic 권장)
extra_body={"chat_template_kwargs": {"preserve_thinking": True}}
```

[공식, HF 모델 카드 / 공식, Qwen-Agent README]

### 4.2 권장 사용처 (공식·검증된 외부 종합)

| 시나리오 | 권장 | 근거 |
|----------|------|------|
| 추론·수학·복잡한 코딩 | **Thinking ON** | 디폴트 학습 모드 [공식] |
| 단순 chat / 짧은 분류 / 응답 지연 민감 | **Thinking OFF** | 토큰 절감, 첫 토큰 지연 단축 [검증된 외부, Unsloth] |
| Multi-turn agentic (코딩 에이전트, 멀티스텝 tool 사용) | **Thinking ON + `preserve_thinking=true`** | 공식 권장 [공식, Alibaba Cloud Blog] |
| 단발성 RAG QA | Thinking ON, `preserve_thinking` 불필요 | 토큰 비용 차이 [검증된 외부, Unsloth] |

### 4.3 컨텍스트 길이 권고

> "We recommend you maintain a context length of at least 128K tokens to preserve thinking capabilities." [공식, HF Qwen3.6-35B-A3B 모델 카드]

`max-model-len`을 128K 미만으로 설정하면 thinking 모드의 추론 품질이 저하될 수 있다.

---

## 5. Tool Calling / Function Calling

Qwen 3.6의 툴 콜은 **공식 권장 프레임워크가 [Qwen-Agent](https://github.com/QwenLM/Qwen-Agent)** 다. [공식, GitHub README] 단, OpenAI 호환 API + vLLM/SGLang 파서로도 정상 동작한다.

### 5.1 vLLM 권장 명령

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

### 5.2 SGLang 권장 명령

```bash
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-35B-A3B \
  --port 8000 \
  --tp-size 8 \
  --mem-fraction-static 0.8 \
  --context-length 262144 \
  --reasoning-parser qwen3 \
  --tool-call-parser qwen3_coder
```

[공식, HF 모델 카드]

### 5.3 Qwen-Agent + MCP 호출 패턴 (공식 권장)

```python
import os
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

tools = [
    {'mcpServers': {
        "filesystem": {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
        }
    }}
]

bot = Assistant(llm=llm_cfg, function_list=tools)
messages = [{'role': 'user', 'content': 'Help me organize my desktop.'}]

for responses in bot.run(messages=messages):
    pass
```

[공식, HF Qwen3.6-35B-A3B 모델 카드]

### 5.4 Tool 정의 베스트 프랙티스

- **JSON schema는 가능한 한 좁게 정의**한다. nested object는 `qwen3_coder` 파서가 지원하지만, optional 필드가 많을수록 long-context에서 실패율이 올라간다 [커뮤니티, llama.cpp Issue #20164 — Qwen 3.5 기반 보고이지만 동일 파서 라인이라 Qwen 3.6에도 적용 가능, 2026-05-07 접근]
- 병렬 함수 호출 디폴트 지원 [공식, Qwen-Agent README]
- `qwen3_coder` 파서는 코드 인자(`code`, `query`, `path` 등)의 따옴표 escape를 더 안정적으로 처리

---

## 6. Long Context

| 모델 | Native | YaRN 확장 한계 |
|------|--------|---------------|
| Qwen3.6-35B-A3B | 262,144 | ~1,010,000 |
| Qwen3.6-27B | 262,144 | ~1,010,000 |
| Qwen3.6-Plus (API) | **1,000,000 디폴트** | — |
| Qwen3.6-Max-Preview (API) | ~262,000 | — (output ~66K) |

[공식, HF 모델 카드 + Alibaba Cloud Blog]

### 권장 패턴

1. **128K 미만으로 truncate 금지** (thinking 보존 권고와 충돌) [공식]
2. **장문서 우선 배치**: Qwen-Agent의 RAG 솔루션은 1M 컨텍스트에서 native long-context 모델을 능가한다고 자체 보고 — 외부 RAG 활용 시에도 이 패턴 권장 [공식, Qwen-Agent README]
3. **`preserve_thinking`은 토큰 비용**: agentic multi-turn에서 보존하면 컨텍스트가 빠르게 차오른다. budget 모니터링 필수.

### YaRN 확장 시 주의

> "If you're getting gibberish, your context length might be set too low" 또는 KV cache 타입을 명시: `--cache-type-k bf16 --cache-type-v bf16` [검증된 외부, Unsloth Qwen3.6 가이드]

---

## 7. Agentic 능력

Qwen 3.6의 출시 핵심 메시지는 "agentic coding" + "real-world agents"다.

> "Qwen3.6-Plus demonstrates strong practical engineering performance in code repair, terminal operations, and automated task execution... achieves top results in multiple challenging long-horizon planning tasks with leadership across tool-calling benchmarks." [공식, Alibaba Cloud Blog "Qwen3.6-Plus: Towards Real-World Agents"]

> "Qwen3.6-35B-A3B delivers outstanding agentic coding performance, surpassing its predecessor Qwen3.5-35B-A3B by a wide margin." [공식, Alibaba Cloud Blog]

### 공식 인증 코딩 어시스턴트 호환

> "can be seamlessly integrated with popular third-party coding assistants" — **OpenClaw, Qwen Code, Claude Code** 명시 호환 [공식, Alibaba Cloud Blog]

### Multimodal Agent Loop

> "from perception, to understanding, to reasoning, to task execution — supporting visual reasoning, visual coding, and video analysis." [공식, Qwen3.6-Plus Blog]

### Frontend Development

> "excellent frontend development capabilities including 3D scenes and games alongside web design." [공식]

### Agentic 시나리오 시스템 프롬프트 권고 (공식 정리)

본 가이드 §14 치트시트 참고. 핵심:
1. `enable_thinking=true` + `preserve_thinking=true`
2. `--tool-call-parser qwen3_coder` (vLLM/SGLang) 또는 Qwen-Agent
3. Tool 정의는 nested 최소화, 명시적 description
4. 코딩 작업은 thinking 모드 + 코딩용 sampling (§9.2)

---

## 8. 다국어 처리

> "Expanded support to 201 languages and dialects" [공식, Qwen3.6 GitHub README — Qwen3.5 시리즈에서 도입된 정책이 3.6 오픈웨이트에 계승]

Qwen 시리즈는 중국어 / 영어 / 한국어 / 일본어 / 동남아·중동·유럽 다언어에서 강세. 본 가이드 작성 시점(2026-05-07) 기준 **Qwen 3.6 전용 언어 벤치 공식 발표는 미확인** — Qwen 3.5의 "201 languages" 정책이 그대로 계승된다고 README가 시사하지만, 모델별 정확도 표는 §16 참고.

### 한국어 사용 팁 (공식 권장사항 기반)

- 시스템 프롬프트는 영어로 작성해도 무방하나, **응답 언어를 명시적으로 지정** (`Respond in Korean.`)
- thinking 트레이스는 모델이 자율적으로 언어 선택 — 영어/중국어가 섞일 수 있음. 최종 답변 언어만 통제.
- Qwen-Agent의 시스템 메시지 예시는 영어이지만 사용자 메시지는 다국어 OK [공식, Qwen-Agent README 예제]

---

## 9. Reasoning Effort / Sampling 권장 파라미터

Qwen 3.6은 OpenAI 식 단일 `reasoning_effort` 파라미터 대신 **모드별·작업 종류별 sampling 프리셋**을 권장한다. 공식 모델 카드 값을 그대로 인용한다. [공식, HF Qwen3.6-35B-A3B / Qwen3.6-27B 모델 카드]

### 9.1 Thinking 모드 — 일반 작업

```
temperature = 1.0
top_p       = 0.95
top_k       = 20
min_p       = 0.0
presence_penalty   = 1.5  # (35B-A3B 권장)
repetition_penalty = 1.0
```

> ⚠️ **모델별 차이**: Qwen3.6-27B 공식 모델 카드는 thinking 일반 작업에 `presence_penalty = 0.0`을 권장한다 (35B-A3B는 1.5). [공식, 양 모델 카드 비교] — 양 모델을 동일 코드로 서빙할 때는 `presence_penalty`를 분기시킬 것.

### 9.2 Thinking 모드 — 정밀 코딩 (WebDev 등)

```
temperature = 0.6
top_p       = 0.95
top_k       = 20
min_p       = 0.0
presence_penalty   = 0.0
repetition_penalty = 1.0
```

[공식, 양 모델 카드 동일]

### 9.3 Instruct (Non-Thinking) 모드 — 일반

```
temperature = 0.7
top_p       = 0.80
top_k       = 20
min_p       = 0.0
presence_penalty   = 1.5
repetition_penalty = 1.0
```

[공식, 양 모델 카드 동일]

### 9.4 Instruct 모드 — 추론 작업 (thinking 끄고 reasoning 시도)

```
temperature = 1.0
top_p       = 0.95
top_k       = 20
min_p       = 0.0
presence_penalty   = 1.5
repetition_penalty = 1.0
```

[검증된 외부, Unsloth Qwen3.6 가이드]

### 9.5 디폴트 출발점 권고

| 시나리오 | 모드 | 프리셋 |
|----------|------|--------|
| 일반 chat / QA | Thinking ON | §9.1 |
| 코딩 / SWE / WebDev | Thinking ON | §9.2 |
| 음성 응답 / 분류 / latency-critical | Thinking OFF | §9.3 |
| Agentic multi-step | Thinking ON + `preserve_thinking=true` | §9.1 또는 §9.2 |

---

## 10. Instruction Tuning 관행

Qwen 3.6 오픈웨이트는 **instruct + reasoning 통합 모델**이다. base 모델 별도 공개 여부는 본 가이드 작성 시점(2026-05-07) 공식 발표 미확인 — §16.

### 권장 패턴

- **System prompt 명시 권장** (디폴트 없음 — §3.2)
- Thinking ON 상태에서 few-shot은 **`<think>` 블록을 포함하지 말 것**: 모델이 자체 thinking을 학습한 패턴과 충돌 가능. few-shot 예시는 user/assistant 최종 답변만 포함.
- Tool 사용 학습된 모델이므로 "if you need a tool, call it directly without asking permission first" 같은 명시적 권한 부여를 시스템 프롬프트에 포함하면 도구 호출률이 올라감 [검증된 외부, Qwen-Agent README의 Browser Assistant 예제]

---

## 11. 안전·정렬

본 가이드 작성 시점(2026-05-07) Qwen 3.6 전용 safety card / red-teaming 보고서는 공식 출처에서 미확인. Qwen 3.5에서 강화된 정책이 계승된다고 README는 일반론으로 언급하지만, 구체 수치는 §16 참고.

### 운영 권고 (일반론)

- 시스템 프롬프트에 **불변 규칙 (safety / honesty / privacy)**만 `ALWAYS`/`NEVER`로 작성. 형식·스타일에는 절대 규칙을 남용하지 말 것.
- 멀티턴 agentic에서 `preserve_thinking=true`는 **사용자에게 보일 수 있는 reasoning trace를 누적**한다. 민감 정보 처리 시 reasoning trace 마스킹 정책을 별도 설계.
- Tool execution은 외부 부수효과 — Qwen-Agent의 `code_interpreter`는 isolated Docker 컨테이너 사용 [공식, Qwen-Agent README]. 자체 구현 시 동급 격리 권장.

---

## 12. 로컬 배포 컨텍스트

[공식, HF 모델 카드 + 검증된 외부, Unsloth]

### 12.1 vLLM (권장)

표준:
```bash
vllm serve Qwen/Qwen3.6-35B-A3B \
  --port 8000 --tensor-parallel-size 8 \
  --max-model-len 262144 --reasoning-parser qwen3
```

Multi-Token Prediction (MTP) 가속:
```bash
vllm serve Qwen/Qwen3.6-35B-A3B \
  --port 8000 --tensor-parallel-size 8 \
  --max-model-len 262144 --reasoning-parser qwen3 \
  --speculative-config '{"method":"qwen3_next_mtp","num_speculative_tokens":2}'
```

### 12.2 SGLang

```bash
python -m sglang.launch_server --model-path Qwen/Qwen3.6-35B-A3B \
  --port 8000 --tp-size 8 --mem-fraction-static 0.8 \
  --context-length 262144 --reasoning-parser qwen3
```

### 12.3 Hugging Face Transformers

```bash
pip install "transformers[serving]"
transformers serve Qwen/Qwen3.6-35B-A3B --port 8000 --continuous-batching
```

### 12.4 llama.cpp / GGUF

llama.cpp 공식 지원. `preserve_thinking`을 활성화하려면 `--chat-template-kwargs '{"preserve_thinking":true}'` 사용. [검증된 외부, Unsloth]

### 12.5 Ollama

> "Ollama is noted as incompatible." [검증된 외부, Unsloth Qwen3.6 가이드]

본 가이드 작성 시점(2026-05-07) 공식 Ollama 모델 등록은 미확인. 커뮤니티 GGUF (예: `unsloth/Qwen3.6-27B-GGUF`, `unsloth/Qwen3.6-35B-A3B-GGUF`) 가 있으나 chat template 호환 문제가 보고된 바 있어 §16 참고.

### 12.6 양자화 / VRAM 가이드 [검증된 외부, Unsloth]

| 모델 | 4-bit VRAM 가이드 |
|------|------------------|
| Qwen3.6-27B | ~18 GB |
| Qwen3.6-35B-A3B | ~23 GB |

> ⚠️ **알려진 환경 이슈**: "Do NOT use CUDA 13.2 as you may get gibberish outputs." [검증된 외부, Unsloth Qwen3.6 가이드 — 재현된 사례 다수]

---

## 13. Qwen 3.5 → 3.6 마이그레이션 체크리스트

| 항목 | 변경 필요 여부 | 비고 |
|------|---------------|------|
| Chat template (ChatML, `<|im_start|>` 등) | **불변** | 동일 |
| `enable_thinking` API 파라미터 | **불변** | 동일 |
| `preserve_thinking` API 파라미터 | **신규** | agentic multi-turn에서 활성화 평가 필수 |
| Tool-call 파서 이름 | **`qwen3` → `qwen3_coder`** | vLLM/SGLang 모두 |
| Reasoning 파서 이름 | **`qwen3` 동일** | 변경 없음 |
| Sampling 프리셋 | **재확인** | 모델별 `presence_penalty` 차이 (§9.1 주의) |
| Context length | 256K → **262K native + 1M YaRN** | `max-model-len` 상향 검토 |
| 멀티모달 입력 | 일부 → 전 모델 | vision encoder 포함 (27B/35B-A3B) |
| 시스템 프롬프트 디폴트 | 없음 → 없음 | 명시 권장 정책 유지 |
| Codingagent 호환 | — → **OpenClaw / Claude Code / Qwen Code 공식 인증** | 권장 통합 경로 |
| llama.cpp / GGUF | OK | `preserve_thinking` 옵션 사용 가능 |
| Ollama | 부분 지원 | Qwen 3.6 공식 등록 미확인 — §16 |
| CUDA 환경 | — | **CUDA 13.2 회피** (검증된 외부) |

### 마이그레이션 순서 (권장)

1. [ ] Tool-call 파서 인자를 `qwen3_coder`로 교체
2. [ ] `preserve_thinking=true`를 agentic 시나리오에 활성화
3. [ ] Sampling을 모델별 공식 권장값으로 재설정 (특히 `presence_penalty`)
4. [ ] `max-model-len` 262144로 상향 (필요 시)
5. [ ] 시스템 프롬프트의 명시도 점검 (디폴트 없음)
6. [ ] eval 후 `enable_thinking=false` 트래픽이 latency-민감인지 재검토
7. [ ] CUDA 13.2 사용 중이면 다른 버전으로 다운그레이드/업그레이드 (검증된 외부)

---

## 14. 치트시트

### 14.1 시스템 프롬프트 골격 (Agentic Coding, 공식 권장 정렬)

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

### 14.2 API 호출 디폴트 (OpenAI 호환)

```python
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8000/v1", api_key="EMPTY")

# 일반 chat (thinking ON 디폴트)
resp = client.chat.completions.create(
    model="Qwen/Qwen3.6-35B-A3B",
    messages=messages,
    max_tokens=81920,
    temperature=1.0, top_p=0.95, presence_penalty=1.5,
    extra_body={"top_k": 20},
)

# 정밀 코딩 (thinking ON, low-temp)
resp = client.chat.completions.create(
    model="Qwen/Qwen3.6-35B-A3B",
    messages=messages, max_tokens=81920,
    temperature=0.6, top_p=0.95, presence_penalty=0.0,
    extra_body={"top_k": 20},
)

# Latency-critical (thinking OFF)
resp = client.chat.completions.create(
    model="Qwen/Qwen3.6-35B-A3B",
    messages=messages, max_tokens=32768,
    temperature=0.7, top_p=0.8, presence_penalty=1.5,
    extra_body={"top_k": 20,
                "chat_template_kwargs": {"enable_thinking": False}},
)

# Agentic multi-turn (thinking ON + preserve)
resp = client.chat.completions.create(
    model="Qwen/Qwen3.6-35B-A3B",
    messages=messages, max_tokens=81920,
    temperature=1.0, top_p=0.95, presence_penalty=1.5,
    extra_body={"top_k": 20,
                "chat_template_kwargs": {"preserve_thinking": True}},
)
```

### 14.3 ChatML 직접 작성 예시 (tool 사용 1턴)

```text
<|im_start|>system
You are a helpful coding assistant with filesystem tools.<|im_end|>
<|im_start|>user
List files in /tmp.<|im_end|>
<|im_start|>assistant
<think>
The user wants a directory listing. I'll call the filesystem tool.
</think>

<tool_call>
{"name": "list_directory", "arguments": {"path": "/tmp"}}
</tool_call><|im_end|>
<|im_start|>user
<tool_response>
foo.txt
bar.log
</tool_response><|im_end|>
<|im_start|>assistant
<think>
Got two files. I'll summarize.
</think>

`/tmp` contains: `foo.txt`, `bar.log`.<|im_end|>
```

---

## 15. 고수들의 노하우 (검증된 외부 + 커뮤니티)

본 절은 **재현 가능한 발견** 위주. 인플루언서 가십이나 미검증 추측은 제외했다.

### 15.1 Simon Willison — 로컬 27B 양자화 재현 (2026-04-22)

> "Qwen3.6-27B is 55.6GB. Willison tested a quantized version at 16.8GB. Pelican on bicycle: 4,444 tokens generated in 2min 53s (25.57 tokens/s). The pelican output is _an outstanding result for a 16.8GB local model_, with appropriate visual elements like bicycle spokes, chain, and anatomically sensible details."
> [검증된 외부, Simon Willison Blog 2026-04-22]

**실무 함의**:
- 27B dense는 **양자화 친화적** (MoE보다 압축이 예측 가능, llama.cpp/SGLang/vLLM 통합 단순)
- 16.8 GB로 단일 로컬 GPU에 들어가면서 SVG 같은 정밀 출력에서 의미 있는 품질 — 데스크톱 코딩 어시스턴트로 실용 가능
- Simon은 본 게시물에서 thinking mode / tool calling 비교는 다루지 않았다 (재현 범위 한정 명시)

### 15.2 Caleb Fahlgren — Qwen 3 Chat Template 4가지 발견 (Hugging Face 공식 블로그)

> "Qwen-3 shows us that through the `chat_template` we can provide better flexibility, smarter context handling, and improved tool interaction." [검증된 외부, HF Blog 2025-04-30]

이 글은 Qwen 3 시리즈의 chat template을 처음 공개적으로 해부한 분석이며, **Qwen 3.6도 동일 템플릿 패턴을 계승**한다. 핵심 4가지:
1. `enable_thinking=false`도 빈 `<think></think>` 쌍을 의도적으로 삽입 — 학습 분포 일관성
2. Rolling checkpoint로 멀티턴 reasoning을 자동 prune
3. Tool 인자 직렬화 시 string/dict 타입 분기로 이중 escape 방지
4. Default system prompt 없음 — 모델 robustness가 충분

### 15.3 Sebastian Raschka — Hybrid Architecture 계보 정리

> "Qwen3.6 is a compact open-weight MoE that keeps the Qwen3.5 hybrid Gated DeltaNet/Gated Attention recipe while activating only about 3B parameters. The model uses 256 experts with 8 routed plus 1 shared expert active inside a 40-layer hybrid stack." [검증된 외부, Sebastian Raschka LLM Architecture Gallery, 2026-05-07 접근]

**실무 함의**: Qwen 3.6은 **"신규 아키텍처가 아니라 Qwen 3.5 레시피의 정제판"**이다. 따라서 Qwen 3.5 기반 운영 노하우(KV cache, parallel decoding, MoE routing tuning)가 거의 그대로 이전된다.

### 15.4 Unsloth — 로컬 운영 함정 (재현 다수)

> "Do NOT use CUDA 13.2 as you may get gibberish outputs."
> "If you're getting gibberish, your context length might be set too low" 또는 `--cache-type-k bf16 --cache-type-v bf16` 명시.
> [검증된 외부, Unsloth Qwen3.6 가이드, 2026-05-07 접근]

**실무 함의**: 로컬 배포 시 가장 흔한 두 가지 사일런트 실패는 (a) CUDA 13.2 환경 (b) max-model-len 과소 설정이다. 두 가지를 먼저 점검할 것.

### 15.5 GitHub Issue #131 — Empty Think 블록 prefix-cache 무효화

> "These empty historical `<think>` blocks change the serialized prompt without adding any useful information. Impact: prefix-cache reuse degradation, avoidable cache misses in multi-turn discussions." [커뮤니티, github.com/QwenLM/Qwen3.6 Issue #131 by latent-variable, 2026-04-09 / Qwen 3.5-27B llama.cpp 환경에서 재현 확인]

**워크어라운드** (재현됨):
```jinja
{# from #}
{%- if loop.index0 > ns.last_query_index %}
{# to #}
{%- if loop.index0 > ns.last_query_index and reasoning_content %}
```

본 가이드 작성 시점(2026-05-07) 공식 패치 머지 여부 미확인 — Issue 본문에서는 closed 상태로 표시되었으나 Qwen 팀 공식 응답 내용은 공개 자료에서 확인하지 못함. §16 참고.

### 15.6 Qwen-Agent 공식 RAG 주장

> "Qwen-Agent has demonstrated capability in 1M-token contexts and reportedly outperform native long-context models on two challenging benchmarks." [공식, Qwen-Agent README]

**실무 함의**: Qwen 3.6의 1M 컨텍스트(Plus) 또는 YaRN 1M 확장(오픈웨이트)을 활용할 때, **단일 거대 컨텍스트 호출보다 Qwen-Agent의 RAG 분할 호출이 더 좋은 결과**를 낼 수 있다는 공식 자체 보고. 자체 RAG 시스템과 비교 평가 권장.

---

## 16. 확인되지 않은 영역 (정직한 한계)

본 가이드 작성 시점(2026-05-07) 1차/검증된 출처에서 **확인하지 못한 항목**을 명시한다. 추측으로 채우지 않는다.

1. **Qwen3.6-Plus / Max-Preview의 정확한 파라미터 수, 활성 파라미터, 아키텍처 종류** — Alibaba가 비공개. "drastically enhanced agentic coding" 같은 정성 메시지만 공식.
2. **Qwen 3.6 base 모델 (post-training 이전) 공개 여부** — 공식 README에서 "오픈웨이트 = post-trained" 라고만 명시. base 모델 별도 공개 계획 미확인.
3. **Qwen 3.6 전용 다국어 벤치 수치** — Qwen 3.5의 "201 languages" 정책은 README가 시사하지만, Qwen 3.6 한국어/일본어 정확도 표는 본 가이드 작성 시점 공식 발표 미확인.
4. **Qwen 3.6 전용 safety / red-teaming 리포트** — Qwen 시리즈 일반 정책 외에 3.6 전용 safety card 미확인.
5. **Qwen3.6-Max-Preview의 정확한 출력 토큰 한계** — 2차 분석가들은 ~66K로 보고하지만 Qwen 공식 페이지가 본 가이드 fetch 시점에 JS 렌더링으로 본문이 비어 직접 인용 불가. 1차 인용 보강 필요 시 [Qwen Blog Max-Preview](https://qwen.ai/blog?id=qwen3.6-max-preview) 직접 방문 권장.
6. **GitHub Issue #131의 Qwen 팀 공식 응답·머지 상태** — Issue가 closed로 표시되었으나, 공식 응답 본문은 공개 자료에서 확인하지 못함. 워크어라운드 적용 시 본인 환경에서 재검증 권장.
7. **Ollama 공식 모델 등록 여부** — Unsloth는 "incompatible"이라 명시. 본 가이드 작성 시점 ollama.com에 Qwen 3.6 공식 모델 등록 확인 못함. 커뮤니티 GGUF는 chat template 호환 이슈 보고가 산발적 (Qwen 3.5 패턴이 Qwen 3.6에도 재현될 가능성 — 별도 검증 필요).
8. **YaRN 1M 컨텍스트의 실측 품질** — 공식 카드는 "extensible up to 1,010,000 tokens"라고만 명시하며 품질 저하 곡선은 미공개. 실사용 시 needle-in-haystack 자체 평가 권장.

---

## 17. Key Takeaways

Qwen 3.6은 다음일 때 최적 성능:

1. **Thinking 모드 ON이 디폴트**, 단순 chat/latency 작업만 OFF
2. **Agentic multi-turn은 `preserve_thinking=true`** (공식 권장)
3. **Sampling은 모드별·작업별 공식 프리셋** 사용 (모델별 `presence_penalty` 차이 주의)
4. **Tool-call 파서는 `qwen3_coder`** (vLLM/SGLang 모두), Reasoning 파서는 `qwen3`
5. **Native 262K context, YaRN 1M까지 확장** — 단 thinking 보존을 위해 128K 미만 회피
6. **System prompt는 명시 권장** (디폴트 없음)
7. **Qwen-Agent + MCP가 공식 권장 agentic 경로**
8. **Qwen 3.5에서 마이그레이션은 거의 드롭인** — 단 `preserve_thinking` 도입과 tool 파서 이름 변경만 챙기면 됨
9. **27B dense는 양자화·로컬 친화**, 35B-A3B MoE는 vRAM 효율적 추론
10. **CUDA 13.2 회피, `max-model-len` 충분히 부여** (로컬 사일런트 실패 1순위)

**가장 높은 레버리지 변경**: `preserve_thinking` 도입, tool 파서 이름 교체, sampling 프리셋 모델별 분기.

---

## Sources

### 1차 공식
- [Qwen3.6 GitHub Repository](https://github.com/QwenLM/Qwen3.6)
- [Qwen/Qwen3.6-35B-A3B Model Card](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [Qwen/Qwen3.6-27B Model Card](https://huggingface.co/Qwen/Qwen3.6-27B)
- [Qwen/Qwen3.6-35B-A3B tokenizer_config.json](https://huggingface.co/Qwen/Qwen3.6-35B-A3B/raw/main/tokenizer_config.json)
- [Qwen3.6-35B-A3B: Agentic Coding Power, Now Open to All — Qwen Blog](https://qwen.ai/blog?id=qwen3.6-35b-a3b)
- [Qwen3.6-35B-A3B: Agentic Coding Power — Alibaba Cloud Mirror](https://www.alibabacloud.com/blog/qwen3-6-35b-a3b-agentic-coding-power-now-open-to-all_603043)
- [Qwen3.6-Plus: Towards Real-World Agents — Alibaba Cloud (2026-04)](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
- [Qwen3.6-Max-Preview: Smarter, Sharper, Still Evolving — Qwen Blog](https://qwen.ai/blog?id=qwen3.6-max-preview)
- [Qwen-Agent Framework — QwenLM GitHub](https://github.com/QwenLM/Qwen-Agent)

### 검증된 외부
- [The 4 Things Qwen-3's Chat Template Teaches Us — Caleb Fahlgren / HF Blog (2025-04-30)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
- [Qwen3.6-27B: Flagship-Level Coding in a 27B Dense Model — Simon Willison (2026-04-22)](https://simonwillison.net/2026/Apr/22/qwen36-27b/)
- [Qwen3.6 — How to Run Locally — Unsloth Documentation](https://unsloth.ai/docs/models/qwen3.6)
- [LLM Architecture Gallery — Sebastian Raschka](https://sebastianraschka.com/llm-architecture-gallery/)
- [A Dream of Spring for Open-Weight LLMs — Sebastian Raschka (2026-02)](https://magazine.sebastianraschka.com/p/a-dream-of-spring-for-open-weight)

### 커뮤니티 (재현 가능성 표기됨)
- [QwenLM/Qwen3.6 Issue #131 — chat template empty think blocks (2026-04-09)](https://github.com/QwenLM/Qwen3.6/issues/131)
- [ggml-org/llama.cpp Issue #20164 — Tool calling 실패 (Qwen 3.5 기반, Qwen 3.6 동일 파서)](https://github.com/ggml-org/llama.cpp/issues/20164)
