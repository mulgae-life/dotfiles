---
name: writing-prompts
description: GPT/Claude/Gemma/Qwen 프롬프트 파일 생성 및 개선. OpenAI + Anthropic + Google + Alibaba 공식 가이드 기반. API 연동 코드는 llm-api-guide 스킬 사용.
when_to_use: "프롬프트 작성해줘, 톤 가이드 적용해줘, 시스템 프롬프트 만들어줘, AI 응답 품질 개선해줘 요청 시. LLM 프롬프트 작성, 챗봇 성격 설정, AI 응답 품질 개선이 필요한 모든 상황에서 사용."
---

# 프롬프트 작성 가이드 (OpenAI + Anthropic + 오픈웨이트 통합)

OpenAI GPT, Anthropic Claude, Google Gemma 4, Alibaba Qwen 3.6 공식 가이드 기반. **범용 원칙 우선, 모델별 최적화는 보조**. 한국어 프로젝트 특화 규칙(격식체) 포함.

---

## Quick Start (5분 온보딩)

### 처음이라면?

1. **기본 템플릿** 복사 → [templates.md](references/templates.md)
2. **Few-shot 예시** 추가 → [few-shot.md](references/few-shot.md)
3. 필요 시 플랫폼 특화 기능 적용

---

## TL;DR

### 클로즈드 API (OpenAI / Anthropic)

| 항목 | 공통 | OpenAI (GPT) | Anthropic (Claude) |
|------|------|--------------|-------------------|
| **구조** | Identity → Instructions → Examples → Context | ✅ | ✅ |
| **어조** | 격식체 (습니다, 입니다, 하세요) | ✅ | ✅ |
| **Message Roles** | - | `developer` (최고) / `user` | `system` 파라미터 / `user` |
| **Examples** | 3-5개 권장 | Few-shot | Multishot (동일 개념) |
| **XML 태그** | ✅ 권장 | ✅ | ✅ |
| **특화 파라미터** | - | `reasoning_effort`, `verbosity`, `phase`, `image_detail` | - |
| **Prefilling** | - | ❌ | ✅ (JSON/캐릭터 강제) |
| **Long Context** | - | - | ✅ (문서 맨 위 → 30%↑) |
| **제약** | "~하지 마세요" 명시 | ✅ | ✅ |
| **모순 제거** | 충돌 지시 금지 | ✅ | ✅ |

### 오픈웨이트 (Google Gemma / Alibaba Qwen)

| 항목 | Google Gemma 4 | Alibaba Qwen 3.6 |
|------|---------------|------------------|
| **Chat template** | `<\|turn>...<turn\|>` (Gemma 3에서 완전 교체) | ChatML `<\|im_start\|>...<\|im_end\|>` (Qwen 3.5 동일) |
| **System role** | **신규 지원** (Gemma 3 워크어라운드 제거 필수) | 지원 (디폴트 system prompt 없음) |
| **Thinking** | `<\|think\|>` 토큰 + multi-turn strip 룰 | 디폴트 ON, `enable_thinking` / `preserve_thinking` (agentic) |
| **Tool calling** | `<\|"\|>` delimiter 공식 포맷 | `qwen3_coder` 파서, Qwen-Agent 권장 |
| **Sampling 권장** | `temp=1.0, top_p=0.95, top_k=64` (모든 사용처) | 모드별·작업별 프리셋 (모델별 `presence_penalty` 차이) |
| **Context** | 256K (대형) / 128K (Effective) | 262K native + YaRN으로 1M (오픈웨이트) |
| **Multimodal** | 모든 사이즈 vision + E2B/E4B는 audio | 27B / 35B-A3B 모두 vision encoder |
| **vLLM 필수 플래그** | `--reasoning-parser gemma4 --tool-call-parser gemma4` | `--reasoning-parser qwen3 --tool-call-parser qwen3_coder` |
| **라이선스** | Apache 2.0 (Gemma 3 Terms 제약 해소) | Apache 2.0 |

## 빠른 참조

### 1. 격식체 규칙 (한국어 특화)

```yaml
# Instructions
<style>
- 반드시 격식체(~습니다, ~입니다, ~하세요)를 사용하세요
- 친절하고 전문적인 어조를 유지하세요
</style>

<constraints>
- 반말 또는 비격식체 사용 금지
- 비꼬는 표현이나 냉소적인 어조 사용 금지
</constraints>
```

**예시**:
```
❌ "이건 좋은 아이디어야"
✅ "이것은 좋은 아이디어입니다"
```

### 2. XML 태그

| 태그 | 용도 |
|------|------|
| `<rules>` | 행동 규칙 |
| `<style>` | 대화 스타일 |
| `<output_format>` | 출력 형식 |
| `<constraints>` | 제약/금지 사항 |
| `<examples>` | 예시 |

### 3. 플랫폼별 특화 기능

| 플랫폼 | 핵심 기능 | 상세 가이드 |
|--------|----------|------------|
| OpenAI | Outcome-first, 구조화 출력, Personality 분리 | `references/gpt5-params.md`, `references/gpt55-patterns.md` ⭐ (5.5), `references/gpt54-patterns.md` (5.4) |
| Anthropic | Prefilling, 긴 컨텍스트 최적화 | `references/prefilling.md`, `references/long-context.md` |
| Google Gemma 4 | `<\|turn>` 템플릿, `<\|think\|>` 토글, multi-turn thought strip, `<\|"\|>` delimiter | `references/gemma4-patterns.md` 🆕 |
| Alibaba Qwen 3.6 | ChatML, 디폴트 thinking + `preserve_thinking`, `qwen3_coder` 파서, 모드별 sampling | `references/qwen36-patterns.md` 🆕 |

## 기본 템플릿

```yaml
system_prompt: |
  # Identity
  당신은 [역할명]입니다.
  [목적 1-2문장]

  # Instructions
  <rules>
  - 반드시 격식체(~습니다, ~입니다)를 사용하세요
  - [규칙 1]
  - [규칙 2]
  </rules>

  <style>
  - 친절하고 전문적인 어조를 유지하세요
  </style>

  <output_format>
  [출력 형식 설명]
  </output_format>

  <constraints>
  - 반말 사용 금지
  - [제약 1]
  </constraints>

  # Examples
  <examples>
  <example id="1">
  <input>[입력]</input>
  <output>[출력]</output>
  </example>
  </examples>

  # Context
  [필요 시 외부 데이터]
```

## 체크리스트

프롬프트 작성/수정 시 확인:

### 필수 (범용)
- [ ] 구조: Identity → Instructions → Examples → Context
- [ ] 격식체 명시 (한국어 톤 가이드 참조)
- [ ] XML 태그 사용
- [ ] Few-shot 예시: Frontier 모델은 포맷 정렬용 0~2개, 소형 모델은 3-5개 → [few-shot.md](references/few-shot.md)
- [ ] 제약 명시 ("~하지 마세요")
- [ ] 모순 제거

### 보안 (민감한 작업)
- [ ] 사용자 입력 분리 (XML 태그로 경계)
- [ ] 출력 검증 로직 고려
- [ ] 시크릿 하드코딩 확인 → [security.md](references/security.md)

### 품질 향상 (복잡한 작업)
- [ ] Self-correction 체인 고려 → [self-correction.md](references/self-correction.md)
- [ ] 추론 깊이 적절히 설정 → [reasoning-params.md](references/reasoning-params.md)

### 플랫폼별 최적화 (선택)

**OpenAI GPT-5.5** (최신, 권장):
- [ ] **Outcome-first**: 절차가 아닌 목표·성공 기준·제약·중단 조건으로 정의
- [ ] **Personality + Collaboration Style 분리** (각 1-2문단 이내)
- [ ] `reasoning.effort`: `medium` 출발점, 많은 워크로드는 `low`도 충분
- [ ] `text.verbosity`: `low` 권장
- [ ] **Markdown 절제** (plain prose 기본, 헤더·불릿 sparingly)
- [ ] **Retrieval Budget** 명시 (도구 사용 시 stopping conditions)
- [ ] **Structured Outputs API**로 스키마 강제 (프롬프트 대신)
- [ ] **Tool Validation**: 출력 검증을 도구로 (테스트·린트·렌더링)
- [ ] 5.4에서 마이그레이션: **fresh baseline 재구성** (드롭인 금지)
- [ ] Message Roles (developer/user)

**OpenAI GPT-5.4 이전**:
- [ ] reasoning_effort 설정 (작업 복잡도)
- [ ] verbosity 설정 (응답 길이)
- [ ] Message Roles (developer/user)

**Anthropic Claude**:
- [ ] Prefilling 활용 (JSON/형식 강제)
- [ ] Long context 문서 배치 (맨 위)

**Google Gemma 4** (오픈웨이트, 2026-04-02):
- [ ] **Chat template 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>` (Gemma 3에서 완전 교체)
- [ ] **System role 사용**: Gemma 3의 "user 턴에 system 우겨넣기" 워크어라운드 제거
- [ ] **Thinking 활성화**: 시스템 프롬프트 맨 앞에 `<|think|>` 토큰 추가
- [ ] **Multi-turn thought strip**: 직전 model 턴의 `<|channel>thought` 블록 제거 (단, 함수 호출 중에는 유지)
- [ ] **Multimodal placement**: image/audio를 text 앞에 배치
- [ ] **Visual token budget**: 70/140/280/560/1120 작업별 명시 (분류 70-140, OCR 1120)
- [ ] **Tool calling**: `<|"|>` delimiter 포맷 사용
- [ ] **공식 sampling**: `temperature=1.0, top_p=0.95, top_k=64` (OpenAI식 0.7 금지)
- [ ] **vLLM**: `--reasoning-parser gemma4 --tool-call-parser gemma4` 필수
- [ ] Audio 워크로드: E2B/E4B만 사용 (대형 2종 미지원)

**Alibaba Qwen 3.6** (오픈웨이트, 2026-04):
- [ ] **ChatML 템플릿**: `<|im_start|>role\n...\n<|im_end|>` (Qwen 3.5 동일)
- [ ] **디폴트 thinking ON** 인지: 단순 chat은 명시적으로 `enable_thinking=false`로 토큰 절감
- [ ] **`preserve_thinking=true`**: agentic multi-turn에서 활성화 (코딩 에이전트, 멀티스텝 tool 사용)
- [ ] **Tool 파서 교체**: Qwen 3.5의 `qwen3` → **`qwen3_coder`** (vLLM/SGLang)
- [ ] **Sampling 모드별 분리**: thinking 일반 (`temp=1.0, top_p=0.95, top_k=20`), 정밀 코딩 (`temp=0.6`), instruct (`temp=0.7, top_p=0.8`)
- [ ] **모델별 `presence_penalty` 분기**: 35B-A3B=1.5, 27B=0.0 (thinking 일반)
- [ ] **128K 미만 truncate 금지**: thinking 보존 권고 충족
- [ ] **Long context**: 262K native, YaRN으로 1M까지. Plus API는 1M 디폴트
- [ ] **공식 권장 프레임워크**: Qwen-Agent + MCP

### 추가 도구 (사용자 직접)
- OpenAI Prompt Optimizer: https://platform.openai.com/chat/edit?optimize=true

## 상세 가이드

### 플랫폼 비교

- **[platform-differences.md](references/platform-differences.md)** ⭐ 핵심 차이점 한눈에 비교

### 공통 기법 (범용)

- **[few-shot.md](references/few-shot.md)** - Few-shot/Multishot 예시 패턴
- **[chain-of-thought.md](references/chain-of-thought.md)** - CoT 프롬프팅 (단계별 추론)
- **[templates.md](references/templates.md)** - 실전 템플릿 + 한국어 톤 가이드 🆕
- **[tool-calling.md](references/tool-calling.md)** - Agentic Tool Calling 가이드
- **[reasoning-params.md](references/reasoning-params.md)** - 추론 깊이/응답 길이 제어 (범용 원칙 + 프롬프트 패턴) 🆕

### 고급 기법 (범용)

- **[security.md](references/security.md)** 🔴 Prompt Injection 방어, 입력/출력 검증 🆕
- **[self-correction.md](references/self-correction.md)** 🔴 자기수정 체인 (생성→검토→개선) 🆕
- **[vision-prompting.md](references/vision-prompting.md)** 🔴 이미지/차트 분석 프롬프트 🆕
- **[context-engineering.md](references/context-engineering.md)** ⭐ Context Engineering 개념과 실무 적용
- **[prompt-trends-2026.md](references/prompt-trends-2026.md)** 🆕 2026 프로덕션 전략, 자동 최적화 도구

### OpenAI (GPT) 특화

- **[message-roles.md](references/message-roles.md)** - developer/user 역할 상세
- **[gpt5-params.md](references/gpt5-params.md)** - GPT-5 API 파라미터 (`reasoning`, `verbosity` 코드 예시)
- **[gpt55-patterns.md](references/gpt55-patterns.md)** ⭐ GPT-5.5 프롬프트 패턴 (Outcome-first, Personality 분리, Retrieval Budget, Tool Validation, Markdown 절제) 🆕
- **[gpt54-patterns.md](references/gpt54-patterns.md)** GPT-5.4 프롬프트 패턴 (출력 계약, 도구 지속성, 검증 루프) — 5.5에서도 호환
- **[optimization.md](references/optimization.md)** - GPT-5 최적화 팁

### Anthropic (Claude) 특화

- **[prefilling.md](references/prefilling.md)** ⭐ Prefilling (JSON/캐릭터 강제)
- **[long-context.md](references/long-context.md)** ⭐ Long Context 최적화 (30%↑)
- **[claude-4-specifics.md](references/claude-4-specifics.md)** ⭐ Claude 4.x 베스트 프랙티스

### Google Gemma 특화 (오픈웨이트)

- **[gemma4-patterns.md](references/gemma4-patterns.md)** ⭐ Gemma 4 패턴 요약 — chat template 교체, `<|think|>` 토글, multi-turn strip, `<|"|>` tool delimiter, 공식 sampling, vLLM 플래그, Gemma 3 → 4 마이그레이션 🆕

### Alibaba Qwen 특화 (오픈웨이트)

- **[qwen36-patterns.md](references/qwen36-patterns.md)** ⭐ Qwen 3.6 패턴 요약 — ChatML, 디폴트 thinking + `preserve_thinking`, `qwen3_coder` 파서, 모드별 sampling, agentic 시스템 프롬프트, Qwen 3.5 → 3.6 마이그레이션 🆕

## 참고 자료

### OpenAI
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [GPT-5.5 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance/) ⭐ 최신 (2026-04)
- [Using GPT-5.5](https://developers.openai.com/api/docs/guides/latest-model)
- [Prompt Personalities (Cookbook)](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [GPT-5 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
- [GPT-5.4 Prompting Guide (이전)](https://developers.openai.com/api/docs/guides/prompt-guidance/?model=gpt-5.4)
- [Prompt Optimizer](https://platform.openai.com/chat/edit?optimize=true) (사용자 직접 실행)

### Anthropic
- [Claude Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)
- [Claude 4.x Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)

### Google Gemma 4 (2026-04-02)
- [Gemma 4 풀 가이드 (한국어)](../../../reference/google-prompt-guide/gemma-4-prompt-guide.md) ⭐ 16섹션 + 외부 노하우
- [Gemma 4 모델 카드 (공식)](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Prompt formatting (공식)](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling (공식)](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [HuggingFace Blog — Gemma 4](https://huggingface.co/blog/gemma4)
- [vLLM Gemma 4 Recipe](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [Simon Willison — Gemma 4 출시일 분석](https://simonwillison.net/2026/Apr/2/gemma-4/)

### Alibaba Qwen 3.6 (2026-04)
- [Qwen 3.6 풀 가이드 (한국어)](../../../reference/qwen-prompt-guide/qwen-3.6-prompt-guide.md) ⭐ 17섹션 + 외부 노하우
- [Qwen3.6 GitHub (공식)](https://github.com/QwenLM/Qwen3.6)
- [Qwen-Agent 프레임워크 (공식)](https://github.com/QwenLM/Qwen-Agent)
- [Qwen3.6-Plus: Towards Real-World Agents (Alibaba Cloud)](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
- [HuggingFace 모델 카드 (35B-A3B)](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [Caleb Fahlgren — Qwen 3 Chat Template 분석 (HF Blog)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
- [Simon Willison — Qwen3.6-27B 로컬 재현](https://simonwillison.net/2026/Apr/22/qwen36-27b/)
