# Qwen 3.8 Prompting Guide

> **출처 (1차 공식)**:
> - [Qwen3.8 GitHub Repository | QwenLM](https://github.com/QwenLM/Qwen3.8)
> - [Qwen/Qwen3.8-27B Model Card | Hugging Face](https://huggingface.co/Qwen/Qwen3.8-27B)
> - [Qwen/Qwen3.8-2.4T-A95B Model Card | Hugging Face](https://huggingface.co/Qwen/Qwen3.8-2.4T-A95B)
> - [Qwen/Qwen3.8-Flash-Next Model Card | Hugging Face](https://huggingface.co/Qwen/Qwen3.8-Flash-Next)
> - [Qwen/Qwen3.8-27B tokenizer_config.json (chat template 원본)](https://huggingface.co/Qwen/Qwen3.8-27B/raw/main/tokenizer_config.json)
> - [Qwen3.8-Max: A New Bar for Coding and Cowork | Qwen Blog](https://qwen.ai/blog?id=qwen3.8) ([Alibaba Cloud 미러](https://www.alibabacloud.com/blog/qwen3-8-max-a-new-bar-for-coding-and-cowork_603421))
> - [Qwen3.8-Flash-Next: A New Architecture, Towards Ultimate Cost-Efficiency | Qwen Blog](https://qwen.ai/blog?id=qwen3.8-flash-next) ([Alibaba Cloud 미러](https://www.alibabacloud.com/blog/603501))
> - [Alibaba Unveils Qwen3.8-27B and Releases Weights of Qwen3.8 Flagship Model | Alibaba Cloud](https://www.alibabacloud.com/blog/alibaba-unveils-qwen3-8-27b-and-releases-weights-of-qwen3-8-flagship-model_603463)
> - [Qwen3.8-27B Practical Guide: Control Reasoning Depth and Extend Context to 1M Tokens | Alibaba Cloud](https://www.alibabacloud.com/blog/qwen3-8-27b-practical-guide-control-reasoning-depth-and-extend-context-to-1m-tokens_603509)
> - [QwenCloud — OpenAI chat API reference](https://docs.qwencloud.com/api-reference/chat/openai-chat) · [Thinking](https://docs.qwencloud.com/developer-guides/text-generation/thinking)
> - [Model Studio — qwen3.8-max](https://help.aliyun.com/en/model-studio/qwen3-8-max) · [qwen3.8-flash](https://help.aliyun.com/en/model-studio/qwen3-8-flash) · [Use deep thinking models via API](https://www.alibabacloud.com/help/en/model-studio/deep-thinking)
> - [vLLM Recipes — Qwen3.8-2.4T-A95B](https://recipes.vllm.ai/Qwen/Qwen3.8-2.4T-A95B) · [Qwen3.8-Flash-Next](https://recipes.vllm.ai/Qwen/Qwen3.8-Flash-Next)
> - [Qwen-Agent Framework | QwenLM](https://github.com/QwenLM/Qwen-Agent)
>
> **출처 (검증된 외부)**:
> - [Qwen 3.8 27B is excellent, but it defaults to wildly overthinking things | Simon Willison (2026-08-16)](https://simonwillison.net/2026/Aug/16/qwen-38-27b/)
> - [Qwen3.8 — How to Run Locally | Unsloth Documentation](https://unsloth.ai/docs/models/qwen3.8)
> - [ggml-org/Qwen3.8-27B-GGUF (llama.cpp 공식 변환)](https://huggingface.co/ggml-org/Qwen3.8-27B-GGUF)
> - [Ollama Library — qwen3.8](https://ollama.com/library/qwen3.8)
>
> **출처 (커뮤니티, 재현 가능성 표기)**:
> - [QwenLM/Qwen3.8 Issue #217 — chat template rejects reasoning_effort="high"](https://github.com/QwenLM/Qwen3.8/issues/217)
> - [Qwen/Qwen3.8-27B Discussions #97 · #113 — 과도한 thinking](https://huggingface.co/Qwen/Qwen3.8-27B/discussions/97)
> - [froggeric/Qwen-Fixed-Chat-Templates](https://huggingface.co/froggeric/Qwen-Fixed-Chat-Templates)
>
> **날짜**: 2026-09-11 (모든 URL 접근 일자)
> **이전 버전 비교**: Qwen 3.6 (마지막 오픈웨이트 세대). 그 사이의 Qwen 3.7(Max 2026-05, Plus 2026-06, 보도 기준)은 API 전용이라 오픈웨이트 마이그레이션 기준은 3.6이다. 3.6 가이드는 [`reference/archive/qwen-prompt-guide/qwen-3.6-prompt-guide.md`](../archive/qwen-prompt-guide/qwen-3.6-prompt-guide.md)

---

## 출처 신뢰 등급

본문 인용은 다음 라벨로 구분한다.

- **[공식]** — Alibaba/Qwen 팀 직접 발행 (GitHub, Qwen Blog, HuggingFace 모델 카드·chat template, Alibaba Cloud Blog, Model Studio·QwenCloud 문서, vLLM 공식 레시피)
- **[검증된 외부]** — Simon Willison, Unsloth, ggml-org, Ollama 등 재현 가능한 발견을 공개한 신뢰 가능한 분석가/조직
- **[커뮤니티]** — GitHub Issue, HuggingFace Discussion, 서드파티 템플릿. 재현 여부를 함께 표기

---

## ⚠️ 가장 먼저 알아야 할 것 (Qwen 3.6 → 3.8 핵심 변화)

Qwen 3.8은 Qwen 3.5 아키텍처 계보를 유지하면서 **Max급 플래그십(2.4T-A95B)을 처음 오픈웨이트로 공개**하고, **`reasoning_effort`로 추론 깊이를 3단계 제어**하며, **`preserve_thinking`을 기본 ON**으로 바꾼 세대다. Qwen 3.6 시스템 프롬프트는 그대로 동작하지만, chat template이 시스템 턴에 추론 지시문을 자동 주입하고, 허용되지 않는 `reasoning_effort` 값에는 예외를 던지며, 기본 설정이 매우 길게 생각하도록 되어 있어 **운영 설정을 손보지 않으면 응답 지연과 비용이 크게 늘어난다.**

> "Thinking mode is on by default and can be disabled per request; reasoning depth can be tuned with `reasoning_effort`, and reasoning context from historical messages is retained via `preserve_thinking`." [공식, QwenLM/Qwen3.8 README, 2026-09-11 접근]

> "Qwen3.8 brings a Qwen-Max-class model to open release. Built on the architectural foundation of Qwen3.5, Qwen3.8 delivers substantial gains across coding, professional work, research, and long-horizon agentic tasks." [공식, QwenLM/Qwen3.8 README]

### 한 페이지 변화 요약

| 항목 | Qwen 3.6 | Qwen 3.8 |
|------|----------|---------|
| 오픈웨이트 라인업 | 35B-A3B(MoE), 27B(dense) | **2.4T-A95B(MoE, Max급)**, **27B(dense)**, **Flash-Next(125B-A6B, Qwen4 아키텍처 프리뷰)** |
| API 라인업 | Plus, Max-Preview | **Max(8/3)**, **Max-0902(9/2 스냅샷)**, **Flash**, 27B 호스팅 |
| Thinking 토글 | `enable_thinking` | **동일** — 단 2.4T-A95B는 thinking 전용(끄면 template 예외) |
| `preserve_thinking` | 옵트인 (agentic 권장) | **기본 ON** (template·API 모두) |
| 추론 깊이 제어 | 없음 (sampling 프리셋으로 간접) | **`reasoning_effort` = `xhigh`(기본) / `medium` / `low`** — template이 시스템 턴에 지시문 주입, API는 토큰 예산으로 매핑 |
| Sampling 프리셋 | 모델별 `presence_penalty` 분기, 정밀 코딩용 temp 0.6 | **전 모델 단일 프리셋** (thinking `presence_penalty=0.0`, instruct 1.5). 코딩용 저온 프리셋은 카드에서 사라짐 |
| 출력 예산 권고 | 명시 없음 | **reasoning 262,144 / 최종 응답 131,072** |
| Tool-call 파서 | `qwen3` / `qwen3_coder` | **동일** (Flash-Next vLLM 레시피는 `qwen3_xml`) |
| Context | 262K native + YaRN 1M | **동일** (YaRN 설정값 명시: factor 4.0, mrope) |
| 라이선스 | Apache 2.0 | **27B만 Apache 2.0**. 2.4T-A95B는 Qwen3.8-Max 커스텀, Flash-Next는 Qwen Community License 1.0 |
| 멀티모달 | 27B·35B-A3B vision | **27B·Flash-Next vision**. 2.4T-A95B 오픈웨이트는 텍스트 전용(API `qwen3.8-max`는 이미지·영상 입력) |
| Ollama | 공식 등록 미확인 | **공식 라이브러리 `qwen3.8:27b` 등록** |
| Default system prompt | 없음 | 없음 — 단 thinking ON + `xhigh`/`low`면 template이 추론 지시문만 담은 시스템 턴을 만든다 (`medium`은 무주입) |

---

## 1. 개요

Qwen 3.8은 2026년 8월 Alibaba Qwen 팀이 출시한 LLM 패밀리. 기둥은 세 가지다.

1. **Max급 오픈웨이트** — Qwen3.8-2.4T-A95B는 "the first time that Qwen3.8 brings a Qwen-Max-class model to open release". [공식, Alibaba Cloud Blog 603463]
2. **추론 깊이 제어의 표준화** — `reasoning_effort` 3단계 + `preserve_thinking` 기본 ON. 3.6까지는 sampling 프리셋으로 간접 조절했다. [공식, HF 모델 카드]
3. **차세대 아키텍처 프리뷰** — Qwen3.8-Flash-Next는 "an early preview of the architecture used in Qwen4". GDN + QSA 하이브리드, Gated Residual, N-gram Embedding, Muon 최적화. [공식, Alibaba Cloud Blog 603501]

### 핵심 강점 (공식 권고 정리)

- 코딩·전문 업무·리서치·장기 agentic 작업 전반 향상. 27B가 "Qwen3.7-plus — an MoE model ten times its size"와 동급 주장 [공식, Alibaba Cloud Blog 603463]
- `reasoning_effort`로 정확도·속도·비용 균형을 요청 단위로 선택
- 262K native context, YaRN으로 1M (오픈웨이트 전 모델)
- Claude Code·Codex·Qwen Code·Qoder·OpenClaw 공식 설정 제공 [공식, Qwen Blog qwen3.8]
- 27B·Flash-Next는 이미지·영상 네이티브 이해 ("from STEM diagrams and documents to hour-scale videos") [공식, HF 27B 모델 카드]

### 명시적 프롬프팅·설정이 필요한 영역

- `reasoning_effort` 선택 — 기본 `xhigh`는 로컬 27B에서 과도하게 길게 생각한다 (§4.4, §15.1)
- `preserve_thinking` 유지 여부 — 기본 ON이라 멀티턴 컨텍스트와 과금이 빠르게 늘어난다
- 라이선스 — 2.4T-A95B·Flash-Next는 Apache가 아니다 (§2.4)
- 출력 예산 — reasoning 262,144 / 최종 131,072를 프레임워크 상한에 반영
- 시스템 프롬프트 — 디폴트 없음이지만 template이 추론 지시문을 앞에 붙인다는 점을 알고 작성 (§3.6)

---

## 2. 모델 변형

본 절은 **공식 출처에서 확인된 사양만** 기재한다.

| 모델 | 타입 | 총 / 활성 파라미터 | 컨텍스트 | 첫 공개 | 공개 형태 · 라이선스 | 비고 |
|------|------|-------------------|----------|--------|---------------------|------|
| **Qwen3.8-2.4T-A95B** | MoE (512 expert, 10 routed + 1 shared 활성) | 2.4T / 95B | 262,144 native, 1,010,000 YaRN | 2026-08-12 | 오픈웨이트 · **Qwen3.8-Max 커스텀 라이선스** | Max급 첫 오픈웨이트. **텍스트 전용**, thinking 전용 [공식, HF 모델 카드] |
| **Qwen3.8-27B** | Dense (causal LM + vision encoder) | 27B / 27B | 262,144 native, 1,000,000 YaRN | 2026-08-14 | 오픈웨이트 · **Apache 2.0** | 이미지·영상 입력. 하이브리드 thinking [공식, HF 모델 카드] |
| **Qwen3.8-Flash-Next** | MoE (512 expert, 10+1 활성) + N-gram Embedding 51B + MTP 4B | 125B / 6B | 262,144 native, 1,000,000 YaRN | 2026-08-26 | 오픈웨이트 · **Qwen Community License 1.0** | Qwen4 아키텍처 프리뷰. 이미지·영상 입력 [공식, HF 모델 카드 / Alibaba Cloud Blog 603501] |
| **Qwen3.8-Max** (`qwen3.8-max`) | API 전용 | 2.4T / 95B | **1,000,000** (입력 991,808 · 출력 131,072 · CoT 262,144) | 2026-08-03 | Model Studio / QwenCloud | 이미지·영상 입력, function calling, structured outputs, context cache. $2 / $6 per 1M [공식, Model Studio] |
| **Qwen3.8-Max-0902** (`qwen3.8-max-0902`) | API 전용 | 동일 | 동일 | 2026-09-02 | 동일 | 코딩·협업 에이전트·비전 후훈련 스냅샷. 별칭 `qwen3.8-max-2026-09-02` [공식, Model Studio] |
| **Qwen3.8-Flash** (`qwen3.8-flash`) | API 전용 | 비공개 | 1,000,000 (출력 131,072 · CoT 262,144) | 2026-08 | Model Studio / QwenCloud | Flash-Next 블로그가 "Model ID qwen3.8-flash"로 안내. $0.16 / $0.47 per 1M [공식, Alibaba Cloud Blog 603501 / Model Studio] |
| **Qwen3.8-27B 호스팅** (`qwen3.8-27b`) | API (오픈웨이트 호스팅) | 27B | 1,000,000 (출력 131,072 · CoT 262,144) | 2026-08 | QwenCloud | 이미지·영상 입력, 내장 도구 5종. $0.5 / $3 per 1M [공식, QwenCloud 모델 페이지] |

출시일은 GitHub README(8/12·8/14)와 Alibaba Cloud 블로그(둘 다 8/17)가 다르다. 본 가이드는 README를 따른다. Flash-Next는 HF·대부분의 보도가 8/26, Alibaba Cloud 미러 게시일이 8/27이다.

### 2.1 Qwen3.8-27B 아키텍처 상세 [공식, HF 모델 카드]

| 항목 | 값 |
|------|----|
| Hidden dimension | 5,120 |
| Layers | 64 |
| Layout | `16 × (3 × (Gated DeltaNet → FFN) → 1 × (Gated Attention → FFN))` |
| Gated Attention | 24 Q heads / 4 KV heads / head dim 256 |
| Type | Causal LM + Vision Encoder, 완전 dense |

Qwen3.6-27B와 골격이 같다. 로컬 운영 노하우(양자화 크기, KV cache)는 그대로 이전된다.

### 2.2 Qwen3.8-2.4T-A95B 아키텍처 상세 [공식, HF 모델 카드]

| 항목 | 값 |
|------|----|
| Hidden dimension | 8,192 |
| Layers | 92 |
| Layout | `23 × (3 × Gated DeltaNet → MoE / 1 × Gated Attention → MoE)` |
| MoE | 512 experts, 10 routed + 1 shared active |
| Gated DeltaNet | 128 V heads / 16 QK heads / head dim 128 |
| Gated Attention | 64 Q heads / 4 KV heads / head dim 256 |
| Vision | 없음 (텍스트 전용) |

> "Qwen3.8-2.4T-A95B is a text-only model that requires thinking mode for all interactions… thinking cannot be disabled." [공식, HF 모델 카드]

### 2.3 Qwen3.8-Flash-Next 아키텍처 상세 [공식, HF 모델 카드 / Alibaba Cloud Blog 603501]

| 항목 | 값 |
|------|----|
| Hidden dimension | 2,560 |
| Layers | 48 |
| Layout | `12 × (3 × Gated DeltaNet → MoE + 1 × QSA → MoE)` |
| MoE | 512 experts, 10 routed + 1 shared active |
| Gated DeltaNet | 48 V heads / 16 QK heads / head dim 128 |
| QSA | 24 Q heads / 2 KV heads / head dim 256 |
| 추가 파라미터 | N-gram Embedding 51B, MTP 모듈 4B |
| Type | Causal LM + Vision Encoder, 하이브리드 thinking (끌 수 있음) |

네 가지 아키텍처 변경 [공식, Alibaba Cloud Blog 603501]:
- **Attention** — "GDN + QSA hybrid architecture". Qwen Sparse Attention은 "compressed lightweight indexer to select important context"
- **Residual** — "Gated Residual (GR) widens the residual stream into 4 branches and controls reads and writes with a dynamic gate"
- **Embedding** — "N-gram Embedding looks up a table using local context to scale model capacity with very little extra computation"
- **Optimization** — "Muon optimizer refined around orthogonalization accuracy, division of labour between Muon and AdamW"

> "8.6× the Prefill throughput of Qwen3.7-Plus at 1M-token context" [공식, Alibaba Cloud Blog 603501]

### 2.4 라이선스 — 세 오픈웨이트가 서로 다르다

| 모델 | 라이선스 | 핵심 조건 |
|------|----------|-----------|
| Qwen3.8-27B | Apache 2.0 | 제한 없음 [공식, HF 모델 카드 front matter] |
| Qwen3.8-2.4T-A95B | Qwen3.8-Max 커스텀 | MAU 1억 또는 월 매출 2,000만 달러 초과 제품은 "model name must be prominently displayed on the user interface". Model-as-a-Service·AI Work Assistant 사업은 "shall obtain a separate license from Qwen" (내부 사용은 예외) [공식, HF LICENSE] |
| Qwen3.8-Flash-Next | Qwen Community License 1.0 | 위와 같은 MAU·매출 표기 조건, MaaS 별도 라이선스 조건 [공식, HF LICENSE] |

Alibaba Cloud 블로그(603463)는 2.4T-A95B도 Apache 2.0이라고 썼지만, HF 저장소의 LICENSE 파일과 모델 카드 메타데이터(`license: qwen3.8-max`)가 우선이다. 상용 배포 전 저장소의 LICENSE를 직접 읽을 것.

---

## 3. ChatML 템플릿 / 시스템 프롬프트 구조

Qwen 3.8은 Qwen 시리즈의 **ChatML 변종**을 그대로 쓴다. special token과 ID는 Qwen 3.6과 동일하다. [공식, tokenizer_config.json]

| Token ID | Content | 용도 |
|----------|---------|------|
| 248045 | `<\|im_start\|>` | 메시지 시작 |
| 248046 | `<\|im_end\|>` | 메시지 종료 |
| 248068 | `<think>` | 추론 블록 시작 |
| 248069 | `</think>` | 추론 블록 종료 |
| 248058 | `<tool_call>` | 함수 호출 시작 |
| 248059 | `</tool_call>` | 함수 호출 종료 |
| 248066 | `<tool_response>` | 툴 응답 시작 |
| 248067 | `</tool_response>` | 툴 응답 종료 |
| 248053 / 248054 | `<\|vision_start\|>` / `<\|vision_end\|>` | 비전 콘텐츠 경계 |
| 248056 / 248057 / 248076 | `<\|image_pad\|>` / `<\|video_pad\|>` / `<\|audio_pad\|>` | 멀티모달 placeholder |

### 3.1 기본 ChatML 포맷 (텍스트 전용)

```text
<|im_start|>system
Reasoning effort is set to xhigh. Please think carefully through the task, validate key assumptions, consider plausible alternatives, and prioritize correctness, consistency, and clarity in the final answer.

You are a helpful assistant.<|im_end|>
<|im_start|>user
Hi there!<|im_end|>
<|im_start|>assistant
<think>
... (모델이 생성하는 reasoning) ...
</think>

Hi! How can I help today?<|im_end|>
```

첫 줄의 추론 지시문은 사용자가 쓴 것이 아니라 **chat template이 자동으로 앞에 붙인 것**이다 (§3.6).

### 3.2 Default system prompt 정책

Qwen 3 시리즈의 "디폴트 시스템 프롬프트 없음" 정책은 유지된다. 단 thinking이 켜져 있고 `reasoning_effort`가 `xhigh` 또는 `low`이면, 시스템 메시지가 없어도 template이 **추론 지시문만 담은 `<|im_start|>system` 턴을 새로 만든다.** [공식, tokenizer_config.json chat_template] "시스템 프롬프트가 비어 있다"고 가정하고 설계하면 실제 프롬프트와 어긋난다.

### 3.3 Thinking 비활성 시 처리 — 모델별로 다르다

```jinja
{# Qwen3.8-27B / Flash-Next #}
{%- if enable_thinking is defined and enable_thinking is false %}
    {{- '<think>\n\n</think>\n\n' }}
{%- else %}
    {{- '<think>\n' }}
{%- endif %}
```

27B·Flash-Next는 3.6과 같이 빈 `<think></think>` 쌍을 삽입한다. **2.4T-A95B는 `enable_thinking=false`에 `raise_exception("Disabling thinking is not supported.")`를 던진다.** [공식, 양 모델 tokenizer_config.json] Model Studio 문서도 `qwen3.8-2.4t-a95b`를 "thinking-only mode"로 분류한다. [공식, Use deep thinking models via API]

### 3.4 멀티턴 history와 `preserve_thinking` 기본 ON

```jinja
{%- if preserve_thinking is undefined or preserve_thinking is true or loop.index0 > ns.last_query_index %}
    {{- '<|im_start|>' + message.role + '\n<think>\n' + reasoning_content + '\n</think>\n\n' + content }}
{%- else %}
    {{- '<|im_start|>' + message.role + '\n' + content }}
{%- endif %}
```

[공식, Qwen3.8-27B tokenizer_config.json]

- 3.6의 조건은 `preserve_thinking is defined and preserve_thinking is true`였다. 3.8은 **undefined도 true로 취급**하므로 옵션을 안 주면 모든 이전 assistant 턴의 `<think>` 블록이 그대로 들어간다.
- `reasoning_content`는 메시지의 전용 필드에서 읽는다. `content` 안의 `</think>`를 쪼개지 않는다. OpenAI 호환 클라이언트가 `reasoning_content`를 되돌려주지 않으면 보존은 무효다 (§4.3).
- `last_query_index`는 `<tool_response>`로 시작·종료하지 않는 마지막 **user** 턴이다. tool 턴은 기준을 옮기지 않는다.
- `reasoning_content`가 비어 있어도 `<think>\n\n</think>` 쌍이 그대로 찍힌다. Qwen 3.6 Issue #131이 지적한 "빈 history think 블록" 패턴은 3.8에서도 남아 있고, 기본값이 ON으로 바뀌어 영향 범위가 넓어졌다. [커뮤니티, QwenLM/Qwen3.6#131 — closed 상태이나 공식 응답·머지 확인 못함; froggeric 템플릿이 "Cured Empty Think Poisoning"으로 대응]

`last_query_index` 기준으로 이전 reasoning을 잘라내는 메커니즘은 Qwen 3부터 "rolling checkpoint"로 불려 온 것이다. [검증된 외부, Caleb Fahlgren / HF Blog "The 4 Things Qwen-3's Chat Template Teaches Us" 2025-04-30] 3.8은 `preserve_thinking` 기본값을 뒤집어 잘라내기를 옵트인으로 바꿨을 뿐 구조는 같다.

### 3.5 Tool call 렌더링 — XML 스타일 (`<function=…>` / `<parameter=…>`)

```jinja
{%- for args_name, args_value in tool_call.arguments|items %}
    {{- '<parameter=' + args_name + '>\n' }}
    {%- set args_value = args_value | string if args_value is string else args_value | tojson | safe %}
    {{- args_value }}
    {{- '\n</parameter>\n' }}
{%- endfor %}
```

[공식, Qwen3.8-27B tokenizer_config.json]

시스템 턴의 `<tools>` 블록에 다음 지시가 함께 들어간다:

> "If you choose to call a function ONLY reply in the following format with NO suffix:
> `<tool_call>` / `<function=example_function_name>` / `<parameter=example_parameter_1>` / `value_1` / `</parameter>` … `</function>` / `</tool_call>`" [공식, chat_template]

이 XML 스타일 포맷은 Qwen 3.6 template에서도 이미 같았다 (`Qwen3.6-27B` tokenizer_config.json 대조). 3.6 가이드 §14.3의 JSON 예시(`{"name": …, "arguments": …}`)는 부정확했으며 §14.3에서 바로잡는다. vLLM/SGLang의 `qwen3_coder` 파서가 이 포맷을 파싱한다.

### 3.6 `reasoning_effort` 지시문 주입

```jinja
{%- set resolved_reasoning_effort = reasoning_effort|default('xhigh') %}
{%- if resolved_reasoning_effort not in ('xhigh', 'medium', 'low') %}
    {{- raise_exception('Unexpected reasoning effort ' ~ reasoning_effort ~ '. Supported types are xhigh (default), medium, and low.') }}
{%- endif %}
{%- if resolved_reasoning_effort == 'xhigh' %}
    {%- set reasoning_instructions = 'Reasoning effort is set to xhigh. Please think carefully through the task, validate key assumptions, consider plausible alternatives, and prioritize correctness, consistency, and clarity in the final answer.' %}
{%- elif resolved_reasoning_effort == 'low' %}
    {%- set reasoning_instructions = 'Reasoning effort is set to low. Keep your thinking brief and focused, moving directly to the conclusion without unnecessary elaboration.' %}
{%- endif %}
```

[공식, Qwen3.8-27B · 2.4T-A95B tokenizer_config.json — 문자열은 원문, 구조는 정리]

- 지시문은 사용자 시스템 메시지 **앞**에 `\n\n`으로 이어 붙는다. 시스템 메시지가 없으면 시스템 턴을 새로 만든다.
- **`medium`은 아무 문장도 주입하지 않는다.** "medium = 지시문 없음"이 학습 기준선이다.
- `high`, `none`, `max` 등 다른 값은 **예외**다. vLLM의 Anthropic 호환 엔드포인트로 Claude Code를 붙이면 Claude Code 기본 effort `high`가 그대로 전달돼 HTTP 500이 난다. [커뮤니티, QwenLM/Qwen3.8#217 (2026-08-19, open) — 워크어라운드 `CLAUDE_CODE_EFFORT_LEVEL=medium`] 호스팅 API(QwenCloud)는 `high`/`max`를 `xhigh`로 별칭 처리하므로 이 문제가 없다 (§4.2).

---

## 4. Thinking 모드

### 4.1 세 파라미터 (오픈웨이트, chat template 기준)

```python
# 기본값과 동일 — 안 써도 이렇게 동작한다
extra_body={"chat_template_kwargs": {
    "enable_thinking": True,        # on by default
    "preserve_thinking": True,      # on by default
    "reasoning_effort": "xhigh",    # xhigh(default) / medium / low
}}

# 추론 깊이 낮추기 (지연·비용 절감)
extra_body={"chat_template_kwargs": {"reasoning_effort": "low"}}

# 이전 턴 reasoning 버리기 (컨텍스트 절약)
extra_body={"chat_template_kwargs": {"preserve_thinking": False}}

# thinking 완전 비활성 (instruct 모드) — 27B·Flash-Next만
extra_body={"chat_template_kwargs": {"enable_thinking": False}}
```

[공식, HF Qwen3.8-27B 모델 카드]

세 단계의 공식 정의 [공식, HF 모델 카드 / Alibaba Cloud 실전 가이드 603509]:
- `xhigh` (default): "for complex tasks that require thorough analysis"
- `medium`: "for balancing accuracy and speed"
- `low`: "for efficient reasoning that prioritizes speed and cost"

### 4.2 호스팅 API(QwenCloud / Model Studio)에서는 토큰 예산으로 매핑

| 파라미터 | 값 | 비고 |
|----------|----|------|
| `reasoning_effort` | `low` → 4,096 / `medium` → 16,384 / `xhigh` → 262,144 토큰 (기본 `xhigh`) | OpenAI 별칭: `max`·`high` → `xhigh`, `minimal` → `low`, `none` → `enable_thinking=False` |
| `thinking_budget` | 추론 토큰 상한. 기본은 "the model's maximum chain-of-thought length" (qwen3.8-max 262,144) | **`reasoning_effort`와 동시 지정 불가** — 에러 |
| `enable_thinking` | 하이브리드 모델 토글 | Python SDK는 `extra_body`, Node SDK는 최상위 파라미터 |
| `preserve_thinking` | `qwen3.8-max`·`-0902`는 **기본 true**, `qwen3.8-flash`는 지원(기본 false) | 되돌린 `reasoning_content`는 **입력 토큰으로 과금** |
| `max_completion_tokens` | CoT + 최종 응답 합계 상한 (권장) | `max_tokens`(deprecated)는 CoT를 제한하지 않음 |

[공식, QwenCloud OpenAI chat API reference / Model Studio deep-thinking 문서]

> "preserve_thinking defaults to true. You must send back all historical reasoning_content in the reasoning_content field. Do NOT concatenate reasoning_content into the content field." [공식, QwenCloud API reference — qwen3.8-max]

### 4.3 `preserve_thinking`이 실제로 동작하려면

1. 서버 응답의 `reasoning_content`를 클라이언트가 **버리지 않고** 다음 요청의 assistant 메시지에 같은 필드로 되돌려야 한다. 대부분의 OpenAI 호환 클라이언트는 이 필드를 모른다.
2. `content`에 `<think>…</think>`를 이어 붙이는 방식은 template이 인식하지 않는다 (§3.4).
3. Ollama의 OpenAI 호환 API는 `chat_template_kwargs`를 template에 전달하지 않는다는 보고가 있다. [커뮤니티, ollama/ollama#16240 (2026-05-20, Qwen 3.6 기준, open)] 3.8에서의 재현은 §16.

### 4.4 권장 사용처

| 시나리오 | 권장 | 근거 |
|----------|------|------|
| 복잡한 수학·리서치·장기 코딩 (호스팅 API) | Thinking ON, `xhigh` | 기본값이자 벤치마크 측정 조건 [공식] |
| 로컬 27B 대화·코딩 어시스턴트 | Thinking ON, **`low` 또는 `medium`** | 기본 `xhigh`는 SVG 하나에 21분·추론 22,276 토큰 [검증된 외부, Simon Willison] / `medium`으로 지연 −33% [커뮤니티, HF #113] |
| 도구 호출 위주 agentic 루프 | Thinking ON, `preserve_thinking` 유지, effort는 실측으로 결정 | "in multi-turn agentic tasks, lower effort doesn't always mean faster end-to-end. Faster per-turn responses may come with more failures and retries" [공식, Alibaba Cloud 실전 가이드 603509] |
| 단순 분류·짧은 응답·latency-critical | **Thinking OFF** (`enable_thinking=false`) | 토큰 절감. 2.4T-A95B는 불가 |
| 단발성 RAG QA | Thinking ON, `preserve_thinking=false` | 보존 이득 없음, 컨텍스트·과금 절약 |

### 4.5 컨텍스트·출력 길이 권고

> "Reasoning Content: Set the maximum output length to 262,144 tokens. Final Response: Set the maximum output length to 131,072 tokens." [공식, HF 27B · 2.4T · Flash-Next 모델 카드 Best Practices]

3.6 카드의 "at least 128K tokens" 문장은 3.8 카드에 없다. 대신 위 출력 예산이 명시되었고, 입출력 합계가 262K를 넘는 장기 작업은 YaRN을 켜라고 안내한다 (§6).

---

## 5. Tool Calling / Function Calling

공식 권장 프레임워크는 여전히 [Qwen-Agent](https://github.com/QwenLM/Qwen-Agent)이며, OpenAI 호환 API + vLLM/SGLang 파서로도 동작한다. [공식, GitHub README]

### 5.1 vLLM 권장 명령 (27B)

```bash
vllm serve Qwen/Qwen3.8-27B \
  --port 8000 \
  --tensor-parallel-size 4 \
  --max-model-len 262144 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

[공식, QwenLM/Qwen3.8 README]

### 5.2 SGLang 권장 명령 (27B) — CLI가 `sglang serve`로 바뀜

```bash
sglang serve --model-path Qwen/Qwen3.8-27B \
  --port 8000 --tp-size 4 \
  --context-length 262144 \
  --reasoning-parser qwen3 \
  --tool-call-parser qwen3_coder
```

[공식, QwenLM/Qwen3.8 README] — Flash-Next 모델 카드는 `python -m sglang.launch_server` 형태도 함께 쓴다.

### 5.3 파서 이름

- README·27B·2.4T: `--reasoning-parser qwen3 --tool-call-parser qwen3_coder` [공식]
- Flash-Next vLLM 레시피: `--tool-call-parser qwen3_xml` [공식, recipes.vllm.ai] — 같은 XML 포맷을 파싱하는 신형 파서. 27B·2.4T-A95B는 README 값, Flash-Next는 레시피 값을 따른다. 교차 사용 가능 여부는 실측하지 않았다.

### 5.4 Qwen-Agent + MCP 호출 패턴

```python
import os
from qwen_agent.agents import Assistant

llm_cfg = {
    'model': 'qwen3.8-max',
    'model_type': 'qwenvl_oai',
    'model_server': 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
    'api_key': os.getenv('DASHSCOPE_API_KEY'),
    'generate_cfg': {
        'use_raw_api': True,
        'extra_body': {
            'enable_thinking': True,
            'preserve_thinking': True,
            'reasoning_effort': 'medium',
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

구조는 Qwen 3.6 모델 카드의 공식 예제이고, 모델명·엔드포인트·`reasoning_effort`만 3.8 API 문서에 맞춰 바꿨다. Qwen-Agent README 자체는 본 가이드 작성 시점에 Qwen 3.8 예시를 싣지 않았다 (§16).

### 5.5 Tool 정의 베스트 프랙티스

- **JSON schema는 좁게**. optional 필드가 많을수록 long-context에서 실패율이 올라간다 [커뮤니티, llama.cpp #20164 — Qwen 3.5 기반 보고, 동일 파서 계열]
- 인자는 `<parameter=이름>` 블록으로 렌더링된다. 문자열은 그대로, 그 외는 JSON 직렬화 (§3.5). 코드·경로 같은 긴 문자열 인자는 이스케이프 부담이 없다.
- 병렬 함수 호출 지원 [공식, Qwen-Agent README]
- 시스템 프롬프트에 "call tools directly without asking permission for read-only inspection" 류의 명시적 권한 부여를 넣으면 도구 호출률이 올라간다 [공식, Qwen-Agent README Browser Assistant 예제]

---

## 6. Long Context

| 모델 | Native | YaRN 확장 |
|------|--------|----------|
| Qwen3.8-27B | 262,144 | 1,000,000 |
| Qwen3.8-2.4T-A95B | 262,144 | 1,010,000 |
| Qwen3.8-Flash-Next | 262,144 | 1,000,000 |
| Qwen3.8-Max / Flash / 27B 호스팅 (API) | **1,000,000** (입력 991,808) | — |

[공식, HF 모델 카드 + Model Studio]

### 6.1 YaRN 설정 (27B 기준)

`config.json`의 `text_config.rope_parameters`를 고치거나, 프레임워크 플래그로 덮어쓴다. [공식, HF 27B 모델 카드 / Alibaba Cloud 실전 가이드 603509]

```json
{
  "mrope_interleaved": true,
  "mrope_section": [11, 11, 10],
  "rope_type": "yarn",
  "rope_theta": 10000000,
  "partial_rotary_factor": 0.25,
  "factor": 4.0,
  "original_max_position_embeddings": 262144
}
```

```bash
# vLLM
VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 vllm serve Qwen/Qwen3.8-27B \
  --hf-overrides '{"text_config": {"rope_parameters": {"mrope_interleaved": true, "mrope_section": [11, 11, 10], "rope_type": "yarn", "rope_theta": 10000000, "partial_rotary_factor": 0.25, "factor": 4.0, "original_max_position_embeddings": 262144}}}' \
  --max-model-len 1000000

# SGLang
SGLANG_ALLOW_OVERWRITE_LONGER_CONTEXT_LEN=1 python -m sglang.launch_server --model-path Qwen/Qwen3.8-27B \
  --json-model-override-args '{"text_config": {"rope_parameters": {...}}}' \
  --context-length 1000000

# TokenSpeed
TOKENSPEED_ALLOW_OVERWRITE_LONGER_CONTEXT_LEN=1 tokenspeed serve Qwen/Qwen3.8-27B --max-model-len 1000000
```

### 6.2 권장 패턴

1. **필요할 때만 YaRN을 켠다.** "Open-source frameworks implement static YaRN — the scaling factor stays constant regardless of input length, which can hurt performance on shorter texts." [공식, Alibaba Cloud 실전 가이드 603509]
2. **factor는 실제 길이에 맞춘다.** "If your workloads usually sit around 524,288 tokens, set factor to 2.0 instead of 4.0." [공식, 같은 글]
3. **출력 예산을 먼저 확보한다.** reasoning 262,144 + 최종 131,072를 합치면 그것만으로 native 한도를 넘긴다. 장기 agentic 작업은 1M 설정이 전제다. [공식, HF 모델 카드]
4. **`preserve_thinking` 기본 ON은 컨텍스트를 빠르게 채운다.** 호스팅 API에서는 과금까지 붙는다 (§4.2).
5. **RAG 분할 호출**: Qwen-Agent RAG는 1M 컨텍스트에서 "outperform native long-context models on two challenging benchmarks"라고 자체 보고 [공식, Qwen-Agent README]

### 6.3 Flash-Next의 1M 컨텍스트

QSA 덕분에 "8.6× the Prefill throughput of Qwen3.7-Plus at 1M-token context"가 공식 주장이다. [공식, Alibaba Cloud Blog 603501] 단 vLLM 레시피 기준 YaRN 1M은 "requires explicit enablement"이며 N-gram Embedding은 pipeline parallel을 지원하지 않는다 (§12.5).

---

## 7. Agentic 능력

출시 메시지는 "coding and cowork"이다. [공식, Qwen Blog qwen3.8]

> 코딩: "taking a real, multi-day project from an empty folder all the way to a finished result, on its own" / 업무: "the messy, multi-step, tool-heavy tasks that fill the working day in nearly every profession" / 리서치: 논문을 재현한 뒤 "beats the paper's own approach, a +2.7-point gain on the competition-level math benchmark AIME24" / 비전: "a native feedback loop across planning, execution, verification, and iteration" [공식, Qwen Blog qwen3.8 — Alibaba Cloud 미러]

9월 2일 스냅샷 `qwen3.8-max-0902`는 같은 축을 더 밀었다: "Coding capability breaks new ground, handling more complex engineering-scale projects and long-horizon autonomous development. Collaborative agent performance is significantly enhanced, with greater composure in multi-tool orchestration and end-to-end task delivery." [공식, Model Studio qwen3.8-max] 3.6 블로그가 강조했던 3D 장면·게임·웹디자인 같은 프론트엔드 능력은 3.8 공식 자료에서 별도 절로 다루지 않는다.

### 7.1 공식 설정을 제공하는 코딩 하네스

**Claude Code, Codex, Qwen Code, Qoder, OpenClaw** [공식, Qwen Blog qwen3.8]. Anthropic 호환 엔드포인트는 `https://dashscope.aliyuncs.com/apps/anthropic`(중국 리전, 블로그 원문), OpenAI 호환은 `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`(국제 리전). [공식, Qwen Blog / QwenCloud 문서]

`qwen3.8-flash`도 "Fully compatible with both OpenAI and Anthropic API protocols, it integrates seamlessly with popular developer tools like Claude Code and Codex". [공식, Model Studio qwen3.8-flash]

27B 모델 카드의 코딩 벤치마크는 Claude Code 하네스로 측정됐다: "Evaluated with the Claude Code harness at temp=1.0, top_p=0.95, and a 256K context window." [공식, HF 27B 모델 카드] 공식 수치를 재현하려면 같은 하네스·sampling·컨텍스트를 맞춘다.

### 7.2 로컬 27B를 Claude Code에 붙일 때

vLLM Anthropic 호환 엔드포인트는 Claude Code의 `effort: "high"`를 template에 그대로 넘겨 500을 낸다. `CLAUDE_CODE_EFFORT_LEVEL=medium`으로 고정하거나, template에 `high → medium` 별칭을 추가한다. [커뮤니티, QwenLM/Qwen3.8#217] `xhigh`는 로컬에서 응답이 비는 사례가 보고돼 `medium`이 보수적 선택이다. [커뮤니티, 같은 이슈]

### 7.3 Agentic 시나리오 권고 (공식 정리)

1. `preserve_thinking` 유지 (기본값). 클라이언트가 `reasoning_content`를 되돌리는지 확인 (§4.3)
2. `reasoning_effort`는 턴당 속도가 아니라 **end-to-end 성공률**로 고른다 (§4.4)
3. `--tool-call-parser qwen3_coder` (Flash-Next는 레시피대로 `qwen3_xml`) 또는 Qwen-Agent
4. 출력 예산 reasoning 262,144 / 최종 131,072, 장기 작업은 YaRN 1M
5. Tool 정의는 nested 최소화, description 명시

---

## 8. 다국어 처리

Qwen 3.8 전용 언어 벤치·언어 수 발표는 본 가이드 작성 시점(2026-09-11) 공식 출처에서 확인하지 못했다 (§16). Qwen 3.5 이후의 "201 languages and dialects" 정책은 README 계보상 이어지는 것으로 보이나 3.8 문서가 직접 언급하지는 않는다.

### 한국어 사용 팁 (3.6 가이드에서 계승, 3.8 template 반영)

- 시스템 프롬프트는 영어로 써도 되지만 **응답 언어를 명시** (`Respond in Korean.`)
- thinking 트레이스의 언어는 모델이 고른다. 최종 답변 언어만 통제한다.
- template이 앞에 붙이는 추론 지시문은 영어다. 사용자 시스템 프롬프트가 한국어여도 충돌하지 않는다.

---

## 9. Reasoning Effort / Sampling 권장 파라미터

3.8은 **추론 깊이는 `reasoning_effort`로, 무작위성은 sampling 프리셋으로** 나눠 제어한다. sampling 프리셋은 세 오픈웨이트 모델이 동일하다. [공식, HF 27B · 2.4T · Flash-Next 모델 카드]

### 9.1 Thinking 모드

```
temperature = 1.0
top_p       = 0.95
top_k       = 20
min_p       = 0.0
presence_penalty   = 0.0
repetition_penalty = 1.0
```

3.6에서 갈렸던 모델별 `presence_penalty`(35B-A3B 1.5 / 27B 0.0)가 **0.0으로 통일**됐다. 반복이 심하면 "adjust the `presence_penalty` parameter between 0 and 2 to reduce endless repetition". [공식, HF 27B 모델 카드]

### 9.2 Instruct (Non-Thinking) 모드 — 27B·Flash-Next

```
temperature = 0.7
top_p       = 0.80
top_k       = 20
min_p       = 0.0
presence_penalty   = 1.5
repetition_penalty = 1.0
```

### 9.3 3.6의 "정밀 코딩 temp 0.6" 프리셋은 사라졌다

3.8 모델 카드는 코딩용 저온 프리셋을 따로 두지 않는다. 코딩 작업도 §9.1 그대로 두고, 깊이는 `reasoning_effort`로 조절한다. 3.6 운영 코드에 temp 0.6 분기가 있다면 근거가 없어졌으므로 실측으로 재판단한다. 3.6 가이드에 있던 "thinking을 끄고 추론을 시도할 때" 프리셋(Unsloth 출처)도 3.8 문서에는 없다. 추론이 필요하면 thinking을 켜고 `low`를 쓰는 것이 공식 경로다.

### 9.4 디폴트 출발점 권고

| 시나리오 | 모드 | `reasoning_effort` | sampling |
|----------|------|--------------------|----------|
| 호스팅 API 일반·코딩 | Thinking ON | `xhigh` (기본) | §9.1 |
| 로컬 27B 대화·코딩 | Thinking ON | `low`~`medium` | §9.1 |
| Agentic multi-step | Thinking ON + `preserve_thinking` | 실측 (§4.4) | §9.1 |
| 분류·latency-critical | Thinking OFF | — | §9.2 |

---

## 10. Instruction Tuning 관행

Qwen 3.8 오픈웨이트는 **instruct + reasoning 통합 모델**이다. Flash-Next는 Base 체크포인트의 벤치마크도 함께 발표됐다 ("with 6B activated parameters, Qwen3.8-Flash-Next-Base achieves the best result on 8 of the 14 benchmarks"). [공식, Alibaba Cloud Blog 603501] 27B·2.4T-A95B의 base 공개 여부는 §16.

### 권장 패턴

- **시스템 프롬프트는 Markdown 헤더 구조**가 공식 예시와 같다 (`# Goal`, `# Tools`, `# Style`). template도 `# Tools` 헤더로 도구 블록을 붙인다. XML 태그로 절을 나누는 것을 금지하는 공식 문구는 없지만, **`<think>`, `<tool_call>`, `<tool_response>`, `<function=…>`, `<parameter=…>`, `<tools>`는 template이 쓰는 이름**이라 커스텀 태그로 쓰지 않는다. 사용자 입력·긴 문서를 `<document>` 같은 태그로 감싸 경계를 주는 용도는 문제없다.
- **추론 지시문이 앞에 붙는다는 전제로 쓴다.** "천천히 생각하라" 류의 문장을 사용자 프롬프트에 또 넣으면 `xhigh` 지시문과 중복된다. 깊이는 `reasoning_effort`로만 조절한다.
- Thinking ON에서 few-shot은 **`<think>` 블록을 포함하지 말 것**. 예시는 user/assistant 최종 답변만.
- `medium`은 지시문이 없는 학습 기준선이다. 프롬프트 실험의 대조군으로 쓰기 좋다.
- 도구 사용 권한을 시스템 프롬프트에 명시하면 호출률이 올라간다 (§5.5).

---

## 11. 안전·정렬·운영 의무

본 가이드 작성 시점(2026-09-11) Qwen 3.8 전용 safety card / red-teaming 보고서는 공식 출처에서 확인하지 못했다 (§16).

### 운영 권고

- 시스템 프롬프트에 **불변 규칙(safety / honesty / privacy)**만 `ALWAYS`/`NEVER`로 작성. 형식·스타일에는 절대 규칙을 남용하지 말 것.
- `preserve_thinking` 기본 ON은 **reasoning trace를 누적 전송**한다. 민감 정보가 trace에 남으면 다음 턴 입력으로 되돌아가고 호스팅 API에서는 과금된다. 마스킹 정책이나 `preserve_thinking=false`를 설계에 포함.
- **라이선스 의무**: 2.4T-A95B·Flash-Next는 MAU 1억 / 월 매출 2,000만 달러 초과 시 모델명 UI 표기, MaaS·AI Work Assistant 사업은 별도 라이선스 (§2.4). 27B만 Apache 2.0.
- Tool execution은 외부 부수효과. Qwen-Agent의 code interpreter는 "basic sandbox isolation, but it should still be used with caution in production environments". [공식, Qwen-Agent README]

---

## 12. 로컬 배포 컨텍스트

[공식, HF 모델 카드 + QwenLM/Qwen3.8 README + vLLM 레시피 / 검증된 외부, Unsloth·ggml-org·Ollama]

### 12.1 vLLM (27B)

표준:
```bash
vllm serve Qwen/Qwen3.8-27B --port 8000 --tensor-parallel-size 4 \
  --max-model-len 262144 --reasoning-parser qwen3 \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder
```

MTP(Multi-Token Prediction) 투기적 디코딩 — 2.4T 레시피의 값:
```bash
  --speculative-config '{"method":"mtp","num_speculative_tokens":3}'
```

3.6의 `qwen3_next_mtp` 메서드명이 `mtp`로 바뀌었다. [공식, recipes.vllm.ai Qwen3.8-2.4T-A95B]

### 12.2 SGLang / Transformers / TokenSpeed

```bash
sglang serve --model-path Qwen/Qwen3.8-27B --port 8000 --tp-size 4 \
  --context-length 262144 --reasoning-parser qwen3 --tool-call-parser qwen3_coder

transformers serve Qwen/Qwen3.8-27B --port 8000 --continuous-batching

tokenspeed serve Qwen/Qwen3.8-27B --port 8000 --tensor-parallel-size 4 \
  --max-model-len 262144 --reasoning-parser qwen3 \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder
```

[공식, QwenLM/Qwen3.8 README] README는 TokenSpeed("a speed-of-light LLM inference engine")를 vLLM·SGLang과 같은 급의 공식 배포 경로로 안내한다. Unsloth 양자화 체크포인트는 lm_head가 FP8이라 SGLang 버전 제약이 있다. 문서의 v0.5.19 전후 문구가 서로 어긋나므로 최신 SGLang으로 실측한다. [검증된 외부, Unsloth]

### 12.3 llama.cpp / GGUF

- 공식 변환: `ggml-org/Qwen3.8-27B-GGUF` (Q4_0, Q4_K_M, Q8_0, BF16). Unsloth 동적 양자화 `unsloth/Qwen3.8-27B-GGUF`(UD-Q4_K_XL 등), `unsloth/Qwen3.8-2.4T-A95B-GGUF`(1~2-bit). [검증된 외부]
- `reasoning_effort`·`preserve_thinking`은 `--chat-template-kwargs '{"reasoning_effort":"medium"}'`로 전달. Windows PowerShell은 `"{\"reasoning_effort\":\"medium\"}"` 이스케이프. [검증된 외부, Unsloth]
- 커뮤니티는 `--reasoning-budget N`으로 추론 토큰 상한을 두는 방법도 쓴다. [커뮤니티, HF #97]
- MTP를 켜면 "prepare to have 1-2GB extra headroom". [검증된 외부, Unsloth]

### 12.4 Ollama / LM Studio

- **Ollama 공식 라이브러리에 `qwen3.8` 등록** — `qwen3.8:27b`(Q4_K_M 17~18 GB), `qwen3.8:27b-mlx`, 256K context, 이미지 입력. [검증된 외부, ollama.com/library/qwen3.8] 3.6 가이드 §16의 "Ollama 공식 등록 미확인"은 해소됐다.
- 단 Ollama OpenAI 호환 API가 `chat_template_kwargs`를 전달하는지는 3.6 기준 미해결 이슈가 있다 (§4.3, §16).
- LM Studio에서 Q4_K_M 17 GB로 15~30 tok/s, MTP(`--spec-type draft-mtp`)로 약 72% 향상. [검증된 외부, Simon Willison]

### 12.5 Flash-Next (vLLM 0.29.0+)

| 항목 | 값 |
|------|----|
| 체크포인트 | FP8 172.78 GiB, BF16 335.28 GiB |
| 하드웨어 | GB300 TP2~4, H200 ×8 TEP8, H100 ×4 TP4 + CPU 오프로드, MI355X ×4 |
| N-gram Embedding | H100(80 GB)은 `VLLM_PLE_CPU_OFFLOAD=1` 필수, 호스트 메모리 51 GB+ |
| 제약 | "Plain TP8 is incompatible with the FP8 checkpoint; use TEP8", N-gram Embedding은 pipeline parallel 미지원, XPU·TPU 미지원 |
| MTP | H100에서 "8-36% lower request throughput" — 기본 끄고 실측 후 결정 |

```bash
vllm serve Qwen/Qwen3.8-Flash-Next-FP8 --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.90 --max-num-seqs 256 --enable-prefix-caching \
  --no-enable-flashinfer-autotune --enable-auto-tool-choice \
  --tool-call-parser qwen3_xml --reasoning-parser qwen3
```

[공식, recipes.vllm.ai Qwen3.8-Flash-Next]

### 12.6 2.4T-A95B 하드웨어

| 변형 | 최소 GPU |
|------|----------|
| BF16 | 24 GPU |
| FP8 (`Qwen/Qwen3.8-2.4T-A95B-FP8`) | 16 GPU (GB300 4 tray, TP16, 2 노드) |
| NVFP4 W4A4 (`Inferact/Qwen3.8-2.4T-A95B-NVFP4`) | B300 ×8 (TP8) |
| MXFP4 | MI355X ×8 |

[공식, recipes.vllm.ai] Unsloth 동적 1-bit GGUF는 397~508 GB, 2-bit 657 GB. [검증된 외부]

### 12.7 양자화 / VRAM 가이드 (27B) [검증된 외부, Unsloth]

| 정밀도 | 크기 |
|--------|------|
| 1-bit | 7~8 GB |
| 2-bit | 9~11 GB |
| 3-bit | 12~14 GB |
| **4-bit** | **16~19 GB** |
| 6-bit | 23~26 GB |
| 8-bit | 31 GB |
| BF16 | 56 GB |

3.6 가이드의 "CUDA 13.2 회피" 경고는 3.8 Unsloth 문서에서 확인하지 못했다 (§16).

---

## 13. Qwen 3.6 → 3.8 마이그레이션 체크리스트

| 항목 | 변경 필요 여부 | 비고 |
|------|---------------|------|
| Chat template (ChatML, special token ID) | **불변** | 동일 |
| `enable_thinking` | **불변** — 단 2.4T-A95B는 false 불가 | template 예외 |
| `preserve_thinking` | **기본값 변경** (옵트인 → ON) | 끄려면 명시적으로 false. 클라이언트의 `reasoning_content` 왕복 확인 |
| `reasoning_effort` | **신규** | `xhigh`/`medium`/`low`만. `high`·`none`은 template 예외 (호스팅 API는 별칭 허용) |
| 시스템 턴 | **변경** | thinking ON이면 추론 지시문이 앞에 붙고, 시스템 메시지가 없어도 시스템 턴이 생김 |
| Sampling 프리셋 | **단순화** | `presence_penalty` 모델별 분기 삭제(thinking 0.0), 코딩용 temp 0.6 삭제 |
| 출력 예산 | **신규 권고** | reasoning 262,144 / 최종 131,072 |
| Tool-call 파서 | **불변** (`qwen3_coder`) | Flash-Next 레시피는 `qwen3_xml` |
| MTP 메서드명 | `qwen3_next_mtp` → **`mtp`** | vLLM `--speculative-config` |
| SGLang CLI | `python -m sglang.launch_server` → **`sglang serve`** (둘 다 동작) | README 기준 |
| Context | 동일 (262K + YaRN 1M) | YaRN 값 명시(factor 4.0, mrope) |
| 라이선스 | Apache 2.0 → **모델별 상이** | 2.4T-A95B·Flash-Next 상용 배포 전 LICENSE 확인 |
| 멀티모달 | 27B vision 유지 | 2.4T-A95B는 텍스트 전용 |
| Ollama | 미확인 → **공식 등록** | `qwen3.8:27b` |
| 하네스 | OpenClaw·Claude Code·Qwen Code → **+ Codex·Qoder** | 공식 설정 제공 |

### 마이그레이션 순서 (권장)

1. [ ] `reasoning_effort` 정책 결정 — 로컬 27B는 `low`/`medium`부터, 호스팅은 `xhigh` 기본 유지 후 실측
2. [ ] `preserve_thinking` 왕복 검증 — 클라이언트가 `reasoning_content`를 되돌리는지, 아니면 `false`로 끌지
3. [ ] Claude Code 등 하네스가 `high`를 보내면 `CLAUDE_CODE_EFFORT_LEVEL=medium` 또는 template 별칭
4. [ ] Sampling을 3.8 단일 프리셋으로 통일 (`presence_penalty` 분기·temp 0.6 제거)
5. [ ] `max_completion_tokens`·프레임워크 출력 상한을 262,144 / 131,072 기준으로 재설정
6. [ ] 2.4T-A95B·Flash-Next 채택 시 LICENSE 검토
7. [ ] vLLM MTP 설정을 `{"method":"mtp",…}`로 교체, Flash-Next는 `qwen3_xml` 파서
8. [ ] YaRN은 실제 길이가 262K를 넘을 때만, factor는 워크로드에 맞게

---

## 14. 치트시트

### 14.1 시스템 프롬프트 골격 (Agentic Coding)

```text
<|im_start|>system
Reasoning effort is set to xhigh. Please think carefully through the task, validate key assumptions, consider plausible alternatives, and prioritize correctness, consistency, and clarity in the final answer.

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

첫 문단은 template이 붙인 것이므로 **직접 쓰지 않는다.** `# Goal` 이하만 사용자 시스템 프롬프트다. `medium`이면 첫 문단이 없다.

### 14.2 API 호출 디폴트

```python
import os
from openai import OpenAI

# --- 로컬 (vLLM/SGLang/llama.cpp, OpenAI 호환) : chat_template_kwargs ---
local = OpenAI(base_url="http://localhost:8000/v1", api_key="EMPTY")

# 일반 (thinking ON, xhigh — 기본값과 동일)
resp = local.chat.completions.create(
    model="Qwen/Qwen3.8-27B", messages=messages,
    max_tokens=131072,
    temperature=1.0, top_p=0.95, presence_penalty=0.0,
    extra_body={"top_k": 20},
)

# 로컬 대화·코딩 (thinking ON, low)
resp = local.chat.completions.create(
    model="Qwen/Qwen3.8-27B", messages=messages, max_tokens=131072,
    temperature=1.0, top_p=0.95, presence_penalty=0.0,
    extra_body={"top_k": 20,
                "chat_template_kwargs": {"reasoning_effort": "low"}},
)

# Latency-critical (thinking OFF) — 2.4T-A95B 불가
resp = local.chat.completions.create(
    model="Qwen/Qwen3.8-27B", messages=messages, max_tokens=32768,
    temperature=0.7, top_p=0.8, presence_penalty=1.5,
    extra_body={"top_k": 20,
                "chat_template_kwargs": {"enable_thinking": False}},
)

# 단발 RAG (thinking ON, 이전 reasoning 버림)
resp = local.chat.completions.create(
    model="Qwen/Qwen3.8-27B", messages=messages, max_tokens=131072,
    temperature=1.0, top_p=0.95, presence_penalty=0.0,
    extra_body={"top_k": 20,
                "chat_template_kwargs": {"preserve_thinking": False}},
)

# --- 호스팅 (QwenCloud / Model Studio) : extra_body 최상위, 토큰 예산 매핑 ---
cloud = OpenAI(base_url="https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
               api_key=os.environ["DASHSCOPE_API_KEY"])

resp = cloud.chat.completions.create(
    model="qwen3.8-max",
    messages=messages,                 # 이전 assistant 메시지에 reasoning_content 포함해 되돌림
    max_completion_tokens=131072,      # CoT + 답변 합계
    extra_body={"enable_thinking": True,
                "reasoning_effort": "medium",   # thinking_budget과 동시 지정 금지
                "preserve_thinking": True},
    stream=True,
)
```

### 14.3 ChatML 직접 작성 예시 (tool 사용 1턴, 3.8 template 원문 포맷)

```text
<|im_start|>system
Reasoning effort is set to low. Keep your thinking brief and focused, moving directly to the conclusion without unnecessary elaboration.

You are a helpful coding assistant with filesystem tools.

# Tools

You have access to the following functions:

<tools>
{"type": "function", "function": {"name": "list_directory", "parameters": {"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]}}}
</tools>

If you choose to call a function ONLY reply in the following format with NO suffix:

<tool_call>
<function=example_function_name>
<parameter=example_parameter_1>
value_1
</parameter>
</function>
</tool_call><|im_end|>
<|im_start|>user
List files in /tmp.<|im_end|>
<|im_start|>assistant
<think>
The user wants a directory listing. I'll call the filesystem tool.
</think>

<tool_call>
<function=list_directory>
<parameter=path>
/tmp
</parameter>
</function>
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

3.6 가이드 §14.3은 `<tool_call>` 안에 JSON을 넣었으나, 3.5 이후 template의 실제 포맷은 위 XML 스타일이다.

---

## 15. 고수들의 노하우 (공식 실전 자료 + 검증된 외부 + 커뮤니티)

본 절은 **재현 가능한 발견** 위주다. 공식 자료라도 모델 카드 밖의 실전 권고는 여기에 둔다.

### 15.1 Simon Willison — "excellent, but it defaults to wildly overthinking" (2026-08-16)

> 펠리컨 SVG: "It took 21 minutes to generate, using 22,276 reasoning tokens to produce 3,223 tokens of output." reasoning을 끄면 137초에 3,715 토큰. "My strong recommendation: ignore that default. Run Qwen 3.8 27B on low or even no reasoning levels at first." [검증된 외부]

- Q4_K_M 17 GB, LM Studio·llama-server. 15~30 tok/s, MTP `--spec-type draft-mtp`로 약 72% 향상
- Pi 프레임워크로 코딩 에이전트 작업 성공, 사진 속 펠리컨 bounding box 좌표 정확
- 2.4T-A95B는 OpenRouter로 시험, 27B보다 우수한 애니메이션 SVG
- 결론: "A 17GB file can do all of this stuff on my home machines is a _miracle_" — 단 로컬 속도가 일상 사용의 병목

**실무 함의**: 로컬 27B의 `xhigh` 기본값은 벤치마크용이다. 대화형 용도는 `low`, 코딩 에이전트는 `medium`부터 시작한다.

### 15.2 Alibaba Cloud 실전 가이드 — 낮은 effort가 항상 빠르지 않다 (2026-08-28)

> "in multi-turn agentic tasks, lower effort doesn't always mean faster end-to-end. Faster per-turn responses may come with more failures and retries" [공식, 603509]

> "Open-source frameworks implement static YaRN — the scaling factor stays constant regardless of input length, which can hurt performance on shorter texts. Only enable YaRN when you actually need long contexts." [공식, 603509]

**실무 함의**: effort는 턴 지연이 아니라 작업 완료율·재시도 횟수로 평가한다. YaRN은 상시 켜두지 않는다.

### 15.3 Issue #217 — Claude Code의 `high`가 template 예외 (2026-08-19)

> "Unexpected reasoning effort high. Supported types are xhigh (default), medium, and low." [커뮤니티, QwenLM/Qwen3.8#217, open]

vLLM Anthropic 엔드포인트가 값을 검증 없이 template에 넘겨 500이 된다. 워크어라운드는 `CLAUDE_CODE_EFFORT_LEVEL=medium` 또는 template에 `high → medium` 별칭 추가. 호스팅 API는 `high → xhigh` 별칭을 공식 지원하므로 로컬 서빙에서만 발생한다.

### 15.4 HF Discussions #97·#113 — 과도한 thinking과 `medium` (2026-08)

- RTX 5090 Q4_K_M에서 `medium`으로 지연 −33%, 품질 손실 없음 (재현 1건) [커뮤니티, #113]
- 도구 호출 시나리오는 `low`가 다른 모델의 `high`에 해당한다는 경험담 [커뮤니티, #97]
- 일부 런타임에서 `enable_thinking: false`가 3.8에서 동작하지 않는다는 보고 — 환경 미기재, 재현 미확인 (§16)
- Qwen 팀 공식 응답 없음

### 15.5 Unsloth — 로컬 운영 (2026-08-19 갱신)

- 27B 4-bit 16~19 GB, MTP 사용 시 1~2 GB 여유 확보
- 2.4T-A95B 동적 1-bit 397~508 GB, 2-bit 657 GB — 단일 노드 CPU/RAM 오프로드 대상
- Unsloth FP8 lm_head 체크포인트는 SGLang 버전 제약 — 문서 문구가 상충하므로 최신 버전으로 실측 (§12.2)
- `reasoning_effort` 열거에 `none`을 포함 — 공식 template은 세 값만 허용하므로 Unsloth CLI가 `enable_thinking=false`로 변환하는 것으로 보이나 미확인 (§16)

### 15.6 vLLM 공식 레시피 — Flash-Next의 MTP는 역효과일 수 있다

> H100에서 MTP 활성 시 "8-36% lower request throughput" — "disable by default and verify on your hardware" [공식, recipes.vllm.ai Qwen3.8-Flash-Next]

**실무 함의**: 27B·2.4T에서 검증된 MTP 이득을 Flash-Next에 그대로 가정하지 않는다. N-gram Embedding 오프로드(`VLLM_PLE_CPU_OFFLOAD=1`)와 TEP8 요구도 Flash-Next 고유다.

### 15.7 froggeric — 수정 chat template (v22.5, 2026-09-03)

3.5/3.6/3.8 전 모델을 덮는 커뮤니티 템플릿. "Cured Empty Think Poisoning"(history 빈 think 제거), "Safe `medium` Default"(지시문 무주입 기본), tool 인자 dict/문자열 겸용 파싱, KV cache 적중을 위한 history 정렬. [커뮤니티] 공식 template의 §3.4·§3.6 문제를 우회하려는 경우 선택지이나, 학습 분포와의 차이는 자체 평가로 확인한다.

---

## 16. 확인되지 않은 영역 (정직한 한계)

본 가이드 작성 시점(2026-09-11) 1차/검증된 출처에서 **확인하지 못한 항목**. 추측으로 채우지 않는다.

1. **Qwen 3.8 기술 보고서** — arXiv에 Qwen3.8 명의 보고서 없음. 아키텍처 세부는 모델 카드·블로그가 전부.
2. **27B·2.4T-A95B의 base 체크포인트 공개 여부** — Flash-Next-Base 벤치만 발표.
3. **3.8 전용 다국어 벤치·언어 수** — 공식 발표 미확인.
4. **3.8 전용 safety / red-teaming 리포트** — 미확인.
5. **`qwen3.8-flash`(API)와 Flash-Next(오픈웨이트)의 동일성** — Flash-Next 블로그가 "Model ID qwen3.8-flash"로 안내하지만 Model Studio 모델 페이지는 관계를 언급하지 않는다. 컨텍스트도 API 1M vs 오픈웨이트 262K native로 다르다.
6. **`qwen3.8-max`(API)와 2.4T-A95B(오픈웨이트)의 동일성** — HF 인용 제목이 "Qwen3.8-Max"이고 Alibaba가 "weights of Qwen3.8 flagship model"이라 했지만, API는 이미지·영상 입력을 받고 오픈웨이트는 텍스트 전용이다. 비전 인코더 유무가 다르다고 보는 것이 안전하다.
7. **Ollama에서 `chat_template_kwargs`(`reasoning_effort`·`preserve_thinking`) 전달 여부** — 3.6 기준 미해결 이슈(#16240). 3.8 라이브러리 페이지는 두 파라미터를 소개하지만 API 경로 실측 없음.
8. **`enable_thinking=false`가 3.8에서 동작하지 않는다는 커뮤니티 보고** — 환경 미기재. 공식 template은 27B·Flash-Next에서 빈 think 블록을 삽입하도록 되어 있고, 2.4T-A95B만 예외를 던진다. 2.4T 보고가 섞였을 가능성.
9. **Unsloth의 `reasoning_effort=none`** — 공식 template 값이 아님. 변환 로직 미확인.
10. **Issue #131(빈 history think 블록)에 대한 Qwen 팀 입장** — closed이나 응답·머지 미확인, 3.8 template에 동일 패턴 잔존.
11. **3.6 Unsloth 문서의 로컬 경고(CUDA 13.2 gibberish, `--cache-type-k/-v bf16` KV cache 지정)의 3.8 적용 여부** — 3.8 Unsloth 문서에서 확인되지 않음. 증상이 재현되면 같은 조치를 먼저 시도한다.
12. **YaRN 1M의 실측 품질 곡선** — 공식은 static YaRN 주의만. needle-in-haystack 자체 평가 권장.
13. **출시일 불일치** — 27B 8/14(README·HF) vs 8/17(Alibaba Cloud 블로그).

---

## 17. Key Takeaways

Qwen 3.8은 다음일 때 최적 성능:

1. **`reasoning_effort`를 의식적으로 고른다** — 기본 `xhigh`는 호스팅·벤치마크용. 로컬 27B는 `low`/`medium`
2. **`preserve_thinking` 기본 ON**을 전제로 클라이언트가 `reasoning_content`를 되돌리는지 확인하고, 아니면 `false`
3. **`high`·`none`은 template 예외** — 하네스(Claude Code 등)의 effort 값을 `medium`으로 고정
4. **Sampling은 단일 프리셋** (thinking `presence_penalty=0.0`) — 3.6의 모델별 분기·코딩용 temp 0.6은 제거
5. **출력 예산 reasoning 262,144 / 최종 131,072**를 `max_completion_tokens`와 프레임워크 상한에 반영
6. **2.4T-A95B는 thinking 전용·텍스트 전용·커스텀 라이선스**, Flash-Next는 Qwen Community License. Apache 2.0은 27B뿐
7. **시스템 프롬프트는 Markdown 헤더**, template이 붙이는 추론 지시문과 겹치는 문장은 넣지 않는다
8. **Tool-call 포맷은 XML 스타일**(`<function=…>`), 파서는 `qwen3_coder`(Flash-Next는 `qwen3_xml`)
9. **YaRN은 필요할 때만**, factor는 실제 길이에 맞춘다
10. **Ollama 공식 등록**으로 로컬 진입이 쉬워졌지만, template 파라미터 전달은 실측 후 신뢰

**가장 높은 레버리지 변경**: `reasoning_effort` 정책, `preserve_thinking` 왕복 검증, 라이선스 확인.

---

## Sources

### 1차 공식
- [Qwen3.8 GitHub Repository](https://github.com/QwenLM/Qwen3.8)
- [Qwen/Qwen3.8-27B Model Card](https://huggingface.co/Qwen/Qwen3.8-27B) · [tokenizer_config.json](https://huggingface.co/Qwen/Qwen3.8-27B/raw/main/tokenizer_config.json)
- [Qwen/Qwen3.8-2.4T-A95B Model Card](https://huggingface.co/Qwen/Qwen3.8-2.4T-A95B) · [LICENSE](https://huggingface.co/Qwen/Qwen3.8-2.4T-A95B/raw/main/LICENSE) · [tokenizer_config.json](https://huggingface.co/Qwen/Qwen3.8-2.4T-A95B/raw/main/tokenizer_config.json)
- [Qwen/Qwen3.8-Flash-Next Model Card](https://huggingface.co/Qwen/Qwen3.8-Flash-Next) · [LICENSE](https://huggingface.co/Qwen/Qwen3.8-Flash-Next/raw/main/LICENSE)
- [Qwen3.8-Max: A New Bar for Coding and Cowork — Qwen Blog](https://qwen.ai/blog?id=qwen3.8) · [Alibaba Cloud 미러](https://www.alibabacloud.com/blog/qwen3-8-max-a-new-bar-for-coding-and-cowork_603421)
- [Qwen3.8-Flash-Next: A New Architecture, Towards Ultimate Cost-Efficiency — Qwen Blog](https://qwen.ai/blog?id=qwen3.8-flash-next) · [Alibaba Cloud 미러](https://www.alibabacloud.com/blog/603501)
- [Alibaba Unveils Qwen3.8-27B and Releases Weights of Qwen3.8 Flagship Model — Alibaba Cloud](https://www.alibabacloud.com/blog/alibaba-unveils-qwen3-8-27b-and-releases-weights-of-qwen3-8-flagship-model_603463)
- [Qwen3.8-27B Practical Guide: Control Reasoning Depth and Extend Context to 1M Tokens — Alibaba Cloud (2026-08-28)](https://www.alibabacloud.com/blog/qwen3-8-27b-practical-guide-control-reasoning-depth-and-extend-context-to-1m-tokens_603509)
- [QwenCloud — OpenAI chat API reference](https://docs.qwencloud.com/api-reference/chat/openai-chat) · [Thinking](https://docs.qwencloud.com/developer-guides/text-generation/thinking) · [qwen3.8-max 모델 페이지](https://www.qwencloud.com/models/qwen3.8-max) · [qwen3.8-27b 모델 페이지](https://www.qwencloud.com/models/qwen3.8-27b)
- [Model Studio — qwen3.8-max](https://help.aliyun.com/en/model-studio/qwen3-8-max) · [qwen3.8-flash](https://help.aliyun.com/en/model-studio/qwen3-8-flash) · [Use deep thinking models via API](https://www.alibabacloud.com/help/en/model-studio/deep-thinking)
- [vLLM Recipes — Qwen3.8-2.4T-A95B](https://recipes.vllm.ai/Qwen/Qwen3.8-2.4T-A95B) · [Qwen3.8-Flash-Next](https://recipes.vllm.ai/Qwen/Qwen3.8-Flash-Next)
- [Qwen-Agent Framework — QwenLM GitHub](https://github.com/QwenLM/Qwen-Agent)
- [Qwen/Qwen3.6-27B tokenizer_config.json (tool 포맷 대조용)](https://huggingface.co/Qwen/Qwen3.6-27B/raw/main/tokenizer_config.json)

### 검증된 외부
- [Qwen 3.8 27B is excellent, but it defaults to wildly overthinking things — Simon Willison (2026-08-16)](https://simonwillison.net/2026/Aug/16/qwen-38-27b/)
- [Qwen3.8 — How to Run Locally — Unsloth Documentation](https://unsloth.ai/docs/models/qwen3.8)
- [ggml-org/Qwen3.8-27B-GGUF](https://huggingface.co/ggml-org/Qwen3.8-27B-GGUF)
- [Ollama Library — qwen3.8](https://ollama.com/library/qwen3.8)
- [The 4 Things Qwen-3's Chat Template Teaches Us — Caleb Fahlgren / HF Blog (2025-04-30)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)

### 커뮤니티 (재현 가능성 표기됨)
- [QwenLM/Qwen3.8 Issue #217 — chat template rejects Claude Code's default reasoning_effort="high" (2026-08-19, open)](https://github.com/QwenLM/Qwen3.8/issues/217)
- [Qwen/Qwen3.8-27B Discussion #97 — A crazy thinking model](https://huggingface.co/Qwen/Qwen3.8-27B/discussions/97) · [#113 — This model cannot stop thinking](https://huggingface.co/Qwen/Qwen3.8-27B/discussions/113)
- [QwenLM/Qwen3.6 Issue #131 — empty historical think blocks (2026-04-09, closed)](https://github.com/QwenLM/Qwen3.6/issues/131)
- [ollama/ollama Issue #16240 — template parameters via OpenAI API (2026-05-20, open)](https://github.com/ollama/ollama/issues/16240)
- [froggeric/Qwen-Fixed-Chat-Templates (v22.5, 2026-09-03)](https://huggingface.co/froggeric/Qwen-Fixed-Chat-Templates)
- [ggml-org/llama.cpp Issue #20164 — Tool calling 실패 (Qwen 3.5 기반)](https://github.com/ggml-org/llama.cpp/issues/20164)
