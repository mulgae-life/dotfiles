---
name: writing-prompts
description: GPT/Claude 프롬프트 파일 생성 및 개선. OpenAI + Anthropic 공식 가이드 기반. API 연동 코드는 llm-api-guide 스킬 사용.
when_to_use: "프롬프트 작성해줘, 톤 가이드 적용해줘, 시스템 프롬프트 만들어줘, AI 응답 품질 개선해줘 요청 시. LLM 프롬프트 작성, 챗봇 성격 설정, AI 응답 품질 개선이 필요한 모든 상황에서 사용."
---

# 프롬프트 작성 가이드 (OpenAI + Anthropic 통합)

OpenAI GPT와 Anthropic Claude 공식 가이드 기반. **범용 원칙 우선, 모델별 최적화는 보조**. 한국어 프로젝트 특화 규칙(격식체) 포함.

---

## Quick Start (5분 온보딩)

### 처음이라면?

1. **기본 템플릿** 복사 → [templates.md](references/templates.md)
2. **Few-shot 예시** 추가 → [few-shot.md](references/few-shot.md)
3. 필요 시 플랫폼 특화 기능 적용

---

## TL;DR

| 항목 | 공통 | OpenAI (GPT) | Anthropic (Claude) |
|------|------|--------------|-------------------|
| **구조** | Identity → Instructions → Examples → Context | ✅ | ✅ |
| **어조** | 격식체 (습니다, 입니다, 하세요) | ✅ | ✅ |
| **Message Roles** | - | `developer` (최고) / `user` | `system` 파라미터 / `user` |
| **Examples** | 3-5개 권장 | Few-shot | Multishot (동일 개념) |
| **XML 태그** | ✅ 권장 | ✅ | ✅ |
| **특화 파라미터** | - | `reasoning_effort`, `verbosity`, `phase` | - |
| **Prefilling** | - | ❌ | ✅ (JSON/캐릭터 강제) |
| **Long Context** | - | - | ✅ (문서 맨 위 → 30%↑) |
| **제약** | "~하지 마세요" 명시 | ✅ | ✅ |
| **모순 제거** | 충돌 지시 금지 | ✅ | ✅ |

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
| OpenAI | Predicted Outputs, 구조화 출력 | `references/gpt5-params.md`, `references/gpt54-patterns.md` |
| Anthropic | Prefilling, 긴 컨텍스트 최적화 | `references/prefilling.md`, `references/long-context.md` |

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
- **[context-engineering.md](references/context-engineering.md)** ⭐ Context Engineering 개념과 실무 적용
- **[prompt-trends-2026.md](references/prompt-trends-2026.md)** 🆕 2026 프로덕션 전략, 자동 최적화 도구

### OpenAI (GPT) 특화

- **[message-roles.md](references/message-roles.md)** - developer/user 역할 상세
- **[gpt5-params.md](references/gpt5-params.md)** - GPT-5 API 파라미터 (`reasoning`, `verbosity` 코드 예시)
- **[gpt54-patterns.md](references/gpt54-patterns.md)** ⭐ GPT-5.4 프롬프트 패턴 (출력 계약, 도구 지속성, 검증 루프)
- **[optimization.md](references/optimization.md)** - GPT-5 최적화 팁

### Anthropic (Claude) 특화

- **[prefilling.md](references/prefilling.md)** ⭐ Prefilling (JSON/캐릭터 강제)
- **[long-context.md](references/long-context.md)** ⭐ Long Context 최적화 (30%↑)
- **[claude-4-specifics.md](references/claude-4-specifics.md)** ⭐ Claude 4.x 베스트 프랙티스

## 참고 자료

### OpenAI
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [GPT-5 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
- [GPT-5.4 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Prompt Optimizer](https://platform.openai.com/chat/edit?optimize=true) (사용자 직접 실행)

### Anthropic
- [Claude Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)
- [Claude 4.x Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)
