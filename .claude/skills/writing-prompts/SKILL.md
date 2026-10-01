---
name: writing-prompts
description: GPT/Claude/Gemini/Gemma/Qwen 프롬프트 파일 생성 및 개선. 대상 모델 ID와 API 방식을 먼저 확정해 그 모델의 문서만 적용합니다. OpenAI + Anthropic + Google + Alibaba 공식 가이드 기반. API 연동 코드는 범위 밖입니다.
when_to_use: "프롬프트 작성해줘, 톤 가이드 적용해줘, 시스템 프롬프트 만들어줘, AI 응답 품질 개선해줘 요청 시. LLM 프롬프트 작성, 챗봇 성격 설정, AI 응답 품질 개선이 필요한 모든 상황에서 사용."
---

# 프롬프트 작성 가이드 (OpenAI + Anthropic + Google + 오픈웨이트 통합)

OpenAI GPT, Anthropic Claude, Google Gemini 3.x·Gemma 4, Alibaba Qwen 3.8 공식 가이드 기반. **범용 원칙 우선, 모델별 최적화는 대상 모델이 확정됐을 때 그 모델 문서만**. 한국어 프로젝트 특화 규칙(격식체) 포함.

---

## 대상 모델 확정

프롬프트를 쓰기 전에 어느 모델의 어떤 API 경로에 들어갈 프롬프트인지 정한다.

1. **사용자가 지정한 대상 모델과 목적이 우선**한다. 기존 코드가 다른 모델을 쓰면 지정 모델 기준으로 쓰고 차이를 짚는다. 프롬프트 작성 요청이 코드의 실행 모델을 바꾸지는 않는다.
2. **지정이 없으면 편집 중인 호출 경로를 따라간다**: 호출 코드 → 설정 파일 → 환경변수 참조와 기본값. 무관한 예제나 보관 파일의 모델 ID는 채택하지 않는다. 시크릿 값은 출력하지 않는다.
3. **프롬프트에 영향을 주는 조건을 확인한다**: 대상 모델, 공급자 경로(직접 호출·호환 계층·클라우드), API 방식(예: Responses ↔ Chat Completions, Interactions ↔ GenerateContent), 사고 설정. 조건을 추론하거나 가정했을 때만 그 선택과 이유를 짧게 밝힌다.
4. **여러 모델이 섞이면 호출 경로마다 따로 다룬다.** 해소할 수 없는 모호함만 좁게 묻는다. 모델과 무관한 범용 프롬프트 요청에는 모델을 강제하지 않고 공통 원칙을 쓴다.
5. **ID는 정확히 맞춘다.** 정확한 별칭·스냅샷을 먼저 찾고, 넓은 접두어가 특수 모델(`-tts`, `-image`, `-customtools`, `-pro` 등)을 삼키지 않게 한다. 모르는 접미사를 떼어 내고 가까운 모델로 간주하지 않는다.
6. **패키지 이름은 공급자 증거가 아니다.** `openai` 라이브러리로 Gemini를 부를 수 있다(`base_url`이 Google 호환 계층). 이때 적용할 문서는 Gemini다.

**적용 범위**: 공통 원칙 + 대상 모델 문서의 해당 절 + 공식 문서가 승계를 확인한 절. 행동 보정 지시는 증상이 있고 근거가 있을 때만 넣는다.

**목록 밖 모델**: 이 스킬에 전용 문서가 없다고 밝히고, 사용자가 지정한 모델을 그대로 둔다. 공식 문서로 확인되는 그 모델의 계약과 공통 기법만 적용하고, 검증하지 않은 모델별 처방은 넣지 않는다. 후속 모델은 폐기·접근 제한·명시적 마이그레이션 요청이 있을 때만 찾아보며, 임의로 모델을 바꾸지 않는다.

| 모델 ID | 문서 | 볼 절 |
|---------|------|-------|
| `claude-opus-5-5` | [claude-5-specifics.md](references/claude-5-specifics.md) | 작성 체크리스트 + Opus 5 차이점 + Opus 5 → 5.5 델타 (델타가 바꾼 항목은 델타 우선) |
| `claude-fable-5-1` | claude-5-specifics.md | 본문 (5.1 기준) |
| `claude-sonnet-5-5` · `claude-sonnet-5` | claude-5-specifics.md | 작성 체크리스트 + Sonnet 5.5 · Sonnet 5 차이점 |
| `claude-opus-5` | claude-5-specifics.md | 작성 체크리스트 + Opus 5 차이점 |
| `claude-fable-5` | claude-5-specifics.md | 본문 (5.1 전용 항목 제외) |
| `claude-opus-4-8` · `claude-sonnet-4-6` · `claude-haiku-4-5` (`-20251001`) | [claude-4-specifics.md](references/claude-4-specifics.md) | 작성 체크리스트 + 공통 원칙 + 해당 모델 절 |
| `gpt-6-astra` · `gpt-6.1-sol` · `gpt-6-sol` · `gpt-6-luna` | [gpt6-patterns.md](references/gpt6-patterns.md) | 작성 체크리스트 + §0 모델별 계약 |
| `gpt-5.6-sol` · `gpt-5.6-terra` · `gpt-5.6-luna` · `gpt-5.6` | [gpt56-patterns.md](references/gpt56-patterns.md) | 작성 체크리스트 |
| `gpt-5.5` (`-2026-04-23`) | [gpt55-patterns.md](references/gpt55-patterns.md) | 작성 체크리스트 |
| `gemini-3.8-flash` · `gemini-3.7-flash` · `gemini-3.6-flash` · `gemini-3.5-flash-lite` · `gemini-3.1-flash-lite` · `gemini-3.1-pro-preview` | [gemini3-patterns.md](references/gemini3-patterns.md) | 작성 체크리스트 + §1 모델별 계약 |
| `google/gemma-4-{E2B\|E4B\|12B\|26B-A4B\|31B}-it` | [gemma4-patterns.md](references/gemma4-patterns.md) | §8 체크리스트 |
| `Qwen/Qwen3.8-27B` · `-2.4T-A95B` · `-Flash-Next`, `qwen3.8-max` · `-max-0902` · `-flash` · `-27b` | [qwen38-patterns.md](references/qwen38-patterns.md) | 작성 체크리스트 |

---

## Quick Start (5분 온보딩)

### 처음이라면?

1. **기본 템플릿** 복사 → [templates.md](references/templates.md)
2. 필요하면 **예시** 추가 (개수는 대상 모델 문서와 과제별 평가로) → [few-shot.md](references/few-shot.md)
3. 대상 모델이 정해졌으면 그 모델 문서의 작성 체크리스트 적용 → [대상 모델 확정](#대상-모델-확정)

---

## TL;DR

### 클로즈드 API (OpenAI / Anthropic / Google)

| 항목 | 공통 | OpenAI (GPT) | Anthropic (Claude) | Google (Gemini 3.x) |
|------|------|--------------|-------------------|------|
| **구조** | 목표·성공 기준·형식·제약이 드러나게. 섹션 순서와 표기는 대상 모델 문서 기준 | Role → Personality → Goal → Success criteria → Constraints → Output → Stop rules (5.5 이후) | XML 태그로 구분, 긴 문서는 위 | 표기 하나로 일관, 긴 자료 앞·질문 끝 |
| **어조** | 제품 용도별 분기 (공식=격식체, 캐주얼=해요체) | ✅ | ✅ | ✅ |
| **Message Roles** | - | `developer` (최고) / `user` | `system` 파라미터 / `user` | `system_instruction` / `user`·`model` |
| **Examples** | 쓸지와 개수는 대상 모델 문서와 과제별 평가로 | 행동을 바꾸지 않는 예시는 줄임 | 공식 모범 사례는 다양한 예시 3~5개 | 공식 문서는 예시 포함 권장 |
| **특화 파라미터** | - | `reasoning.effort` (GPT-6 Astra·6.1 Sol: `none` 미지원, low~max / 6 Sol·Luna: none~max), `reasoning.mode`/`context` (5.6+), `verbosity`, 이미지 항목별 `detail` | `output_config.effort` (Haiku 4.5는 `budget_tokens`) | `thinking_level` (sampling 제거) |
| **Prefilling** | - | ❌ | ❌ (4.6 이후 400 → Structured Outputs, Haiku 4.5만 예외) | ❌ 새 프롬프트에서 쓰지 않음 (제거 권고는 3.8·Cloud 3.7 문서) |
| **Long Context** | - | - | ✅ (문서 맨 위 → 30%↑) | 긴 자료 앞, 질문 끝 |
| **제약** | "~하지 마세요" 명시 | ✅ | ✅ | ✅ |
| **모순 제거** | 충돌 지시 금지 | ✅ | ✅ | ✅ |

### 오픈웨이트 (Google Gemma / Alibaba Qwen)

| 항목 | Google Gemma 4 | Alibaba Qwen 3.8 |
|------|---------------|------------------|
| **Chat template** | `<\|turn>...<turn\|>` (Gemma 3에서 완전 교체) | ChatML `<\|im_start\|>...<\|im_end\|>` (Qwen 3.6 동일) |
| **System role** | **신규 지원** (Gemma 3 워크어라운드 제거 필수) | 지원 (디폴트 없음, 단 thinking ON이면 template이 추론 지시문을 앞에 주입) |
| **Thinking** | `<\|think\|>` 토큰 + multi-turn strip 룰. OFF여도 E2B/E4B 제외 전부 빈 블록 emit. tool call 턴 유지는 `preserve_thinking=True`(기본 false) | 디폴트 ON, `reasoning_effort` = `xhigh`(기본)/`medium`/`low`, `preserve_thinking` 기본 ON. 2.4T-A95B는 끌 수 없음 |
| **Tool calling** | `<\|"\|>` delimiter 공식 포맷, 병렬은 `tool_responses` 배열, 히스토리 `arguments`는 JSON 객체 | XML 스타일 `<function=…><parameter=…>`, `qwen3_coder` 파서, Qwen-Agent 권장 |
| **Sampling 권장** | `temp=1.0, top_p=0.95, top_k=64` (모든 사용처) | 단일 프리셋: thinking `temp=1.0, top_p=0.95, top_k=20, presence=0.0` / instruct `0.7, 0.8, 20, 1.5` |
| **Context** | 256K (12B·26B·31B) / 128K (E2B·E4B) | 262K native + YaRN 1M (오픈웨이트), API는 1M. 출력 예산 reasoning 262K / 최종 131K |
| **Multimodal** | 5종 모두 vision, audio는 E2B/E4B/12B. image는 text 앞, audio는 text 뒤 | 27B·Flash-Next vision. 2.4T-A95B는 텍스트 전용 |
| **vLLM 필수 플래그** | `--reasoning-parser gemma4 --tool-call-parser gemma4` (MTP는 `--speculative-config`) | `--reasoning-parser qwen3 --tool-call-parser qwen3_coder` (Flash-Next 레시피는 `qwen3_xml`) |
| **라이선스** | Apache 2.0 (Gemma 3 Terms 제약 해소, 드래프터·QAT 포함) | 27B만 Apache 2.0. 2.4T-A95B 커스텀, Flash-Next Qwen Community 1.0 |

## 빠른 참조

### 1. 어조 규칙 (한국어 특화)

제품 용도에 맞는 어조를 고릅니다. 격식체(~습니다)는 B2B·공공·공지 등 공식 응대의 기본값이고, 캐주얼 서비스는 친근한 존댓말(~요, ~해요)이 적합합니다. 용도별 톤 스펙트럼은 [templates.md](references/templates.md) 7장을 따르세요. 아래는 격식체 예시입니다.

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
| OpenAI | Outcome-first, 구조화 출력, Personality 분리, 주도성·테스트 범위·위임 명시·모델 선택(GPT-6), 티어 선택(5.6), 최소 프롬프트 기준선(5.5) | `references/gpt6-patterns.md` ⭐ (GPT-6 Astra·Sol·Luna), `references/gpt56-patterns.md` (5.6), `references/gpt55-patterns.md` (5.5) |
| Anthropic | De-prescribe(Claude 5 세대), 검증 지시 삭제·위임 상한(Opus 5), effort `medium` 시작(Opus 5.5), `between_tools`·작업 범위(Sonnet 5.5), 모델별 사고 방식(4.x), 긴 컨텍스트 최적화 | `references/claude-5-specifics.md` ⭐ (Opus 5.5·Fable 5.1·Sonnet 5.5·Opus 5·Fable 5·Sonnet 5), `references/claude-4-specifics.md` (Opus 4.8·Sonnet 4.6·Haiku 4.5), `references/long-context.md` |
| Google Gemini 3.x | 모델별 `thinking_level` 허용 값, sampling 제거, 사고 서명 보존, 함수 결과 짝 맞추기, 미디어 해상도 | `references/gemini3-patterns.md` |
| Google Gemma 4 | `<\|turn>` 템플릿, `<\|think\|>` 토글, multi-turn thought strip, `<\|"\|>` delimiter | `references/gemma4-patterns.md` |
| Alibaba Qwen 3.8 | ChatML, `reasoning_effort` 3단계 + `preserve_thinking` 기본 ON, XML tool 포맷·`qwen3_coder` 파서, 단일 sampling | `references/qwen38-patterns.md` |

## 기본 템플릿

모델과 무관한 출발점이다. 대상 모델 문서에 권장 구조가 있으면(예: GPT-5.5 이후의 Role → Goal → Success criteria → … → Stop rules) 그쪽을 따른다. 아래 어조는 공식 응대(격식체) 예시이고, 어조와 예시 절은 제품과 대상 모델에 맞게 바꾸거나 뺀다 → [1. 어조 규칙](#1-어조-규칙-한국어-특화).

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

### 필수 (모든 모델)
- [ ] 목표, 성공 기준, 출력 형식, 제약이 분명하다
- [ ] 서로 충돌하는 지시가 없다
- [ ] 대상 모델의 필수·금지 계약을 지켰다 (사고 설정, 제거된 파라미터, prefill 등 → 대상 모델 문서의 작성 체크리스트)
- [ ] 사용자 입력과 외부 데이터를 지시와 분리했다

### 선택 (대상 모델 문서와 과제에 맞춰)
- [ ] 구조 표기·섹션 순서·어조 (한국어 어조는 [templates.md](references/templates.md) 7장, 공식 응대는 격식체)
- [ ] 예시를 쓸지와 개수: 대상 모델 문서의 권고와 과제별 평가로 정한다 → [few-shot.md](references/few-shot.md)
- [ ] 수치 기준(예시 개수, sampling 값 등)은 근거가 있는 모델 문서의 값만 쓴다

### 보안 (민감한 작업)
- [ ] 사용자 입력 분리 (XML 태그 등 대상 모델에 맞는 구분자로 경계)
- [ ] 출력 검증 로직 고려
- [ ] 시크릿 하드코딩 확인 → [security.md](references/security.md)

### 품질 향상 (복잡한 작업)
- [ ] Self-correction 체인 고려 → [self-correction.md](references/self-correction.md)
- [ ] 추론 깊이 적절히 설정 → [reasoning-params.md](references/reasoning-params.md)

### 모델별 작성 체크리스트

[대상 모델 확정](#대상-모델-확정) 표에서 고른 문서의 "작성 체크리스트"를 적용한다(Gemma 4는 §8). 다른 모델의 체크리스트는 섞지 않는다.

### 추가 도구 (사용자 직접)
- OpenAI Prompt Optimizer: https://platform.openai.com/chat/edit?optimize=true

## 상세 가이드

### 플랫폼 비교

- **[platform-differences.md](references/platform-differences.md)** ⭐ 핵심 차이점 한눈에 비교

### 공통 기법 (범용)

- **[few-shot.md](references/few-shot.md)** - Few-shot/Multishot 예시 패턴
- **[chain-of-thought.md](references/chain-of-thought.md)** - CoT 프롬프팅 (단계별 추론)
- **[templates.md](references/templates.md)** - 실전 템플릿 + 한국어 톤 가이드
- **[reasoning-params.md](references/reasoning-params.md)** - 추론 깊이/응답 길이 제어 (범용 원칙 + 프롬프트 패턴)

### 고급 기법 (범용)

- **[security.md](references/security.md)** 🔴 Prompt Injection 방어, 입력/출력 검증
- **[self-correction.md](references/self-correction.md)** 🔴 자기수정 체인 (생성→검토→개선)
- **[vision-prompting.md](references/vision-prompting.md)** 🔴 이미지/차트 분석 프롬프트
- **[context-engineering.md](references/context-engineering.md)** ⭐ Context Engineering 개념과 실무 적용
- **[prompt-trends-2026.md](references/prompt-trends-2026.md)** 2026 프로덕션 전략, 자동 최적화 도구

### OpenAI (GPT) 특화

- **[message-roles.md](references/message-roles.md)** - developer/user 역할 상세
- **[tool-calling.md](references/tool-calling.md)** - Agentic Tool Calling 가이드 (패턴 출처는 OpenAI 가이드 — Claude 5 세대에는 그대로 적용 금지)
- **[gpt6-patterns.md](references/gpt6-patterns.md)** ⭐ GPT-6 프롬프트 패턴 (Astra 기준 주도성, 지시 파일 모순 감사, 테스트 범위 축소, 위임 명시, 모델별 effort 범위(Astra `none` 미지원, Sol·Luna 지원), 제거 파라미터, Sol·Luna 차이, 5.6 → 6 마이그레이션)
- **[gpt56-patterns.md](references/gpt56-patterns.md)** GPT-5.6 프롬프트 패턴 (티어 선택, 우선순위 지시, effort 재튜닝, pro mode·reasoning.context·PTC) — 계약 구조·신규 API 기능은 GPT-6에서도 유효
- **[gpt55-patterns.md](references/gpt55-patterns.md)** GPT-5.5 프롬프트 패턴 (outcome-first, 최소 프롬프트 기준선, personality·collaboration 분리, 검색 예산, `text.format` 구조화 출력, 이미지 `detail`, `phase`)
- **[optimization.md](references/optimization.md)** - GPT 프롬프트 최적화 팁 (모순 제거, 지시 계층, 출력 형식, 캐싱)

### Anthropic (Claude) 특화

- **[claude-5-specifics.md](references/claude-5-specifics.md)** ⭐ Claude 5 세대 (Opus 5.5·Fable 5.1·Sonnet 5.5·Opus 5·Fable 5·Sonnet 5) 베스트 프랙티스 — De-prescribe, 하드 제약, 권장 스니펫, Opus 5 차이점, Sonnet 5.5·5 차이점, Fable 5 → 5.1 델타, Opus 5 → 5.5 델타
- **[claude-4-specifics.md](references/claude-4-specifics.md)** Claude 4.x (Opus 4.8·Sonnet 4.6·Haiku 4.5) — 모델별 사고 방식·effort·sampling·prefill 계약, 4.x 공통 원칙
- **[long-context.md](references/long-context.md)** ⭐ Long Context 최적화 (30%↑)

### Google Gemini 특화

- **[gemini3-patterns.md](references/gemini3-patterns.md)** Gemini 3.x (3.8·3.7·3.6 Flash, 3.5·3.1 Flash-Lite, 3.1 Pro Preview) 패턴 요약 — 모델별 사고 수준, sampling 제거, Interactions·GenerateContent 계약, 함수 결과 계약, 미디어 해상도, OpenAI 호환 계층

### Google Gemma 특화 (오픈웨이트)

- **[gemma4-patterns.md](references/gemma4-patterns.md)** ⭐ Gemma 4 패턴 요약 — chat template 교체와 2026-07 개정 인자, `<|think|>` 토글, multi-turn strip, `<|"|>` tool delimiter·병렬 호출, 공식 sampling, vLLM 플래그, MTP·QAT, Gemma 3 → 4 마이그레이션

### Alibaba Qwen 특화 (오픈웨이트)

- **[qwen38-patterns.md](references/qwen38-patterns.md)** ⭐ Qwen 3.8 패턴 요약 — ChatML, `reasoning_effort` + `preserve_thinking` 기본 ON, XML tool 포맷·`qwen3_coder` 파서, 단일 sampling, 라이선스 차이, agentic 시스템 프롬프트, Qwen 3.6 → 3.8 마이그레이션

## 참고 자료

### OpenAI
- [GPT-6 풀 가이드 (한국어)](../../../reference/openai-prompt-guide/gpt-6-prompt-guide.md) ⭐ 최신 — Astra·6.1 Sol·6 Sol·Luna 제품군, 행동 축 5개 스니펫 원문·API 변경·Codex 적용 수록
- [Using GPT-6 — Prompt Guidance·Migration (공식)](https://developers.openai.com/api/docs/guides/latest-model) ⭐ 최신 — 제품군 공통 출발점, Astra에서 관찰된 행동 기준
- [GPT-6 Astra 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6-astra) · [GPT-6.1 Sol 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6.1-sol) · [GPT-6 Sol 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6-sol) · [GPT-6 Luna 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6-luna)
- [GPT-5.6 풀 가이드 (한국어)](../../../reference/openai-prompt-guide/gpt-5.6-prompt-guide.md) (이전 세대) — 티어·마이그레이션·신규 파라미터 수록
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [GPT-5.6 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6) (이전 세대)
- [Upgrading to GPT-5.6 Sol](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol) — 마이그레이션 공식 절차
- [Using GPT-5.6](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [GPT-5.5 풀 가이드 (한국어)](../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md) (전전 세대) · [Using GPT-5.5 (공식, 5.5 전용 원문)](https://developers.openai.com/api/docs/guides/latest-model/gpt-5.5.md)
- [Prompt Personalities (Cookbook)](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [Prompt Optimizer](https://platform.openai.com/chat/edit?optimize=true) (사용자 직접 실행)

### Anthropic
- [Opus 5.5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-opus-5-5-prompt-guide.md) ⭐ 최신 — effort `medium` 시작·thinking 끄기 전제 제거·실행 환경별 지시문
- [Fable 5.1 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md) — 행동 변화 대응 스니펫 원문 수록
- [Fable 5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-5-fable-prompt-guide.md) — 스니펫 원문 전체 수록
- [Opus 5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-opus-5-prompt-guide.md) — 스캐폴딩 삭제·위임 상한·effort 역전 (Opus 5.5 가이드가 출발점으로 인정)
- [Sonnet 5.5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-sonnet-5-5-prompt-guide.md) — API 파괴적 변경 5건·effort 재보정·`between_tools`·작업 범위 스니펫
- [Sonnet 5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-sonnet-5-prompt-guide.md) — Sonnet 4.6 대비 API 계약·문자 그대로의 지시 이행
- [Opus 4.8 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-opus-4-8-prompt-guide.md) — 사고 기본 꺼짐·코딩 `xhigh` 시작·서브에이전트 조절
- [Prompting Claude Opus 5.5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5) ⭐ 최신
- [Prompting Claude Fable 5.1 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)
- [Prompting Claude Sonnet 5.5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5)
- [Prompting Claude Fable 5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting Claude Opus 5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Prompting Claude Sonnet 5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5)
- [Prompting Claude Opus 4.8 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8)
- [Prompting best practices (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — 현역 모델 공통 기법 (Sonnet 4.6·Haiku 4.5는 전용 문서 없이 이 문서 기준)
- [Introducing Claude Fable 5 (공식)](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5)
- [Claude Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)

### Google Gemini 3.x
- [Gemini 3.x 풀 가이드 (한국어)](../../../reference/google-prompt-guide/gemini-3-prompt-guide.md) — 6개 모델 계약·API 방식별 차이·3.8 Flash 사용자 보고
- [Gemini 3.8 Flash — Latest model (공식)](https://ai.google.dev/gemini-api/docs/latest-model)
- [Prompt design strategies (공식)](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Thinking (공식)](https://ai.google.dev/gemini-api/docs/thinking)
- [OpenAI compatibility (공식)](https://ai.google.dev/gemini-api/docs/openai)

### Google Gemma 4
- [Gemma 4 풀 가이드 (한국어)](../../../reference/google-prompt-guide/gemma-4-prompt-guide.md) ⭐ 15섹션 + 외부 노하우
- [Gemma 4 모델 카드 (공식)](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Prompt formatting (공식)](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling (공식)](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [MTP 드래프터 (공식)](https://ai.google.dev/gemma/docs/mtp/mtp)
- [Gemma 4 Technical Report (arXiv)](https://arxiv.org/abs/2607.02770)
- [HuggingFace 모델 카드 (31B-it)](https://huggingface.co/google/gemma-4-31B-it)
- [HuggingFace Blog — Gemma 4](https://huggingface.co/blog/gemma4)
- [vLLM Gemma 4 Recipe](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [Simon Willison — Gemma 4 출시일 분석](https://simonwillison.net/2026/Apr/2/gemma-4/)

### Alibaba Qwen 3.8
- [Qwen 3.8 풀 가이드 (한국어)](../../../reference/qwen-prompt-guide/qwen-3.8-prompt-guide.md) ⭐ 17섹션 + 외부 노하우
- [Qwen3.8 GitHub (공식)](https://github.com/QwenLM/Qwen3.8)
- [Qwen-Agent 프레임워크 (공식)](https://github.com/QwenLM/Qwen-Agent)
- [Qwen3.8-Max: A New Bar for Coding and Cowork (Alibaba Cloud 미러)](https://www.alibabacloud.com/blog/qwen3-8-max-a-new-bar-for-coding-and-cowork_603421)
- [Qwen3.8-27B Practical Guide (Alibaba Cloud)](https://www.alibabacloud.com/blog/qwen3-8-27b-practical-guide-control-reasoning-depth-and-extend-context-to-1m-tokens_603509)
- [HuggingFace 모델 카드 (27B)](https://huggingface.co/Qwen/Qwen3.8-27B)
- [QwenCloud OpenAI chat API reference (공식)](https://docs.qwencloud.com/api-reference/chat/openai-chat)
- [Simon Willison — Qwen 3.8 27B overthinking 분석](https://simonwillison.net/2026/Aug/16/qwen-38-27b/)
- [Caleb Fahlgren — Qwen 3 Chat Template 분석 (HF Blog)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
