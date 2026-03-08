---
name: writing-prompts
description: GPT/Claude 프롬프트 파일 생성 및 개선. OpenAI + Anthropic 공식 가이드 기반. 시스템 프롬프트 작성, 격식체 톤 가이드라인 적용, 플랫폼별 특화 기능 자동 적용. "프롬프트 작성해줘", "톤 가이드 적용해줘", "시스템 프롬프트 만들어줘", "AI 응답 품질 개선해줘" 등의 요청에 트리거. LLM 프롬프트를 작성하거나, 챗봇 성격을 설정하거나, AI 응답 품질을 개선하려는 모든 상황에서 이 스킬을 사용하세요. API 연동 코드는 llm-api-guide 스킬을 사용하세요.
---

# 프롬프트 작성 가이드 (OpenAI + Anthropic 통합)

OpenAI GPT와 Anthropic Claude 공식 가이드 기반. **범용 원칙 우선, 모델별 최적화는 보조**. 한국어 프로젝트 특화 규칙(격식체) 포함.

---

## Quick Start (5분 온보딩)

### 처음이라면?

1. **기본 템플릿** 복사 → [templates.md](references/templates.md)
2. **Few-shot 예시** 추가 → [few-shot.md](references/few-shot.md)
3. 필요 시 플랫폼 특화 기능 적용

### 학습 경로

```
[기초 - 범용]
few-shot → chain-of-thought → templates
    ↓
[플랫폼 이해]
platform-differences → reasoning-params
    ↓
[고급 - 범용]
security → self-correction → vision-prompting
    ↓
[모델 특화 - 선택]
OpenAI: optimization
Anthropic: prefilling, long-context
```

### 핵심 원칙

```
┌─────────────────────────────────────┐
│  범용 원칙 (모든 LLM 공통)          │  ← 메인
│  - Few-shot, CoT, XML 태그 등       │
├─────────────────────────────────────┤
│  모델별 팁 (선택적)                 │  ← 보조
│  - "Claude에서는 Prefilling 활용"   │
│  - "GPT-5에서는 reasoning_effort"   │
└─────────────────────────────────────┘
```

---

## TL;DR

| 항목 | 공통 | OpenAI (GPT) | Anthropic (Claude) |
|------|------|--------------|-------------------|
| **구조** | Identity → Instructions → Examples → Context | ✅ | ✅ |
| **어조** | 격식체 (습니다, 입니다, 하세요) | ✅ | ✅ |
| **Message Roles** | - | `developer` (최고) / `user` | `system` 파라미터 / `user` |
| **Examples** | 3-5개 권장 | Few-shot | Multishot (동일 개념) |
| **XML 태그** | ✅ 권장 | ✅ | ✅ |
| **특화 파라미터** | - | `reasoning_effort`, `verbosity` | - |
| **Prefilling** | - | ❌ | ✅ (JSON/캐릭터 강제) |
| **Long Context** | - | - | ✅ (문서 맨 위 → 30%↑) |
| **제약** | "~하지 마세요" 명시 | ✅ | ✅ |
| **모순 제거** | 충돌 지시 금지 | ✅ | ✅ |

## 빠른 참조

### 1. 프롬프트 구조 (공통)

```yaml
# Identity (정체성)
목적, 역할, 고수준 목표

# Instructions (지침)
규칙, 스타일, 출력 형식, 제약

# Examples (예시)
Few-shot learning 예시 3-5개

# Context (맥락)
외부 데이터, 참조 정보
```

**왜 이 순서?**
- Identity: 역할/목표 먼저 정의
- Instructions: 행동 규칙
- Examples: 기대 출력 명확화
- Context: 마지막 (프롬프트 캐싱 최적화)

### 2. 격식체 규칙 (한국어 특화)

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

### 3. XML 태그

| 태그 | 용도 |
|------|------|
| `<rules>` | 행동 규칙 |
| `<style>` | 대화 스타일 |
| `<output_format>` | 출력 형식 |
| `<constraints>` | 제약/금지 사항 |
| `<examples>` | 예시 |

### 4. 플랫폼별 특화 기능

#### OpenAI (GPT-5)

**파라미터**:
```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},  # 추론 깊이
    text={"verbosity": "low"},     # 응답 길이
    instructions="...",
    input="..."
)
```

#### Anthropic (Claude)

**Prefilling** (JSON 강제):
```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Extract as JSON"},
        {"role": "assistant", "content": "{"}  # Prefill
    ]
)
```

**Long Context** (문서 맨 위 배치 → 30%↑):
```xml
<documents>{{LONG_DOCS}}</documents>

위 문서를 분석하세요.
```

### 5. 모순 제거

```yaml
# ❌ 나쁜 예 (모순)
- 간결하게 답변하세요
- 상세하게 설명하세요

# ✅ 좋은 예 (명확)
- 핵심을 1-2문단으로 간결하게 답변하세요
- 필요한 경우에만 추가 설명을 제공하세요
```

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
- [ ] Few-shot 예시 3-5개
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

**OpenAI GPT-5**:
- [ ] reasoning_effort 설정 (작업 복잡도)
- [ ] verbosity 설정 (응답 길이)
- [ ] Message Roles (developer/user)

**Anthropic Claude**:
- [ ] Prefilling 활용 (JSON/형식 강제)
- [ ] Long context 문서 배치 (맨 위)

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

### OpenAI (GPT) 특화

- **[message-roles.md](references/message-roles.md)** - developer/user 역할 상세
- **[gpt5-params.md](references/gpt5-params.md)** - GPT-5 API 파라미터 (`reasoning`, `verbosity` 코드 예시)
- **[optimization.md](references/optimization.md)** - GPT-5 최적화 팁

### Anthropic (Claude) 특화

- **[prefilling.md](references/prefilling.md)** ⭐ Prefilling (JSON/캐릭터 강제)
- **[long-context.md](references/long-context.md)** ⭐ Long Context 최적화 (30%↑)
- **[claude-4-specifics.md](references/claude-4-specifics.md)** ⭐ Claude 4.x 베스트 프랙티스

## 프로젝트별 적용

### 사용 중인 플랫폼 확인

```
프로젝트 코드 확인:
- `import openai` 또는 `openai` 패키지? → OpenAI 섹션 적용
- `import anthropic` 또는 `anthropic` 패키지? → Anthropic 섹션 적용
- 둘 다? → 공통 섹션 + 각 API별 특화 기능
```

### 공통 기법 우선 적용

플랫폼에 관계없이 **공통 기법**(XML 태그, Examples, 명확한 지시, 모순 제거)을 먼저 적용하고, 필요 시 **특화 기능** 추가.

## 참고 자료

### OpenAI
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [GPT-5 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
- [Prompt Optimizer](https://platform.openai.com/chat/edit?optimize=true) (사용자 직접 실행)

### Anthropic
- [Claude Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)
- [Claude 4.x Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)
