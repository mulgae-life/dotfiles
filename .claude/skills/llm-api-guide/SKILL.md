---
name: llm-api-guide
description: LLM API(OpenAI, Anthropic) 연동 코드 구현 가이드. 프롬프트 내용 작성은 writing-prompts 스킬 사용.
when_to_use: "OpenAI API 연동해줘, Claude API 사용해줘, LLM 호출 코드 작성해줘 요청 시. SDK 초기화, 스트리밍, tool calling, 에러 핸들링 등 LLM API 코드 구현 시 반드시 참조."
---

# LLM API 개발 가이드

LLM API(OpenAI, Anthropic) 연동 **코드** 구현 가이드.
프롬프트 **내용** 작성은 `writing-prompts` 스킬 참조.

---

## Quick Start

### 역할 분리

| 스킬 | 역할 | 주요 질문 |
|------|------|-----------|
| `llm-api-guide` | API **코드** 구현 | "어떤 API 사용?", "파라미터는?" |
| `writing-prompts` | 프롬프트 **내용** 작성 | "어떤 톤?", "구조는?" |

### API 선택 가이드

```
OpenAI
├── Responses API (권장) ← Reasoning 모델, Tool Calling, CoT 유지
└── Chat Completions API ← 레거시, 단순 대화

Anthropic
└── Messages API ← 유일한 선택
```

---

## TL;DR

| 항목 | OpenAI (Responses API) | Anthropic (Messages API) |
|------|------------------------|--------------------------|
| **엔드포인트** | `/v1/responses` | `/v1/messages` |
| **Instructions** | `instructions` 파라미터 또는 `developer` role | `system` 파라미터 |
| **입력** | `input` (문자열 또는 메시지 배열) | `messages` 배열 |
| **Reasoning** | `reasoning: {effort}` (5.5: `medium` 권장 출발점, 많은 워크로드는 `low`도 충분 / 5.4 이전: 작업 형태별 매트릭스) | 모델 자체 기능 (extended thinking) |
| **스트리밍** | `stream: true` | `stream: True` |
| **대화 유지** | `previous_response_id` | 직접 메시지 이력 관리 |

---

## 구현 패턴 참조

| 주제 | 핵심 원칙 | 상세 가이드 |
|------|----------|------------|
| 클라이언트 초기화 | 앱 수명주기로 관리, 요청마다 생성 금지 | `references/common-patterns.md` |
| Message Roles | system/user/assistant 역할 분리, 우선순위 준수 | 각 API references |
| Reasoning | OpenAI: `reasoning.effort`, Anthropic: extended thinking `budget_tokens` | 각 API references |
| 스트리밍 | SSE 기반, 청크 조립 + 에러 핸들링 | `references/common-patterns.md` |
| 에러 핸들링 | 타입별 분기 + 지수 백오프 재시도 | `references/common-patterns.md` |
| 대화 이력 | OpenAI: `previous_response_id`, Anthropic: 수동 메시지 배열 관리 | 각 API references |
| Tool Calling | 함수 스키마 정의 + 호출 결과 전달 루프 | 각 API references |
| 출력 검증 | Pydantic/구조화 출력으로 LLM 응답 파싱 | `references/common-patterns.md` |
| 프롬프트 캐싱 | 정적 prefix + 동적 suffix 배치 | `references/common-patterns.md` |

---

## 체크리스트

### 필수

- [ ] 클라이언트 초기화: 앱 수명주기로 관리 (요청마다 생성 금지)
- [ ] API 키: 환경변수 사용 (하드코딩 금지)
- [ ] 에러 핸들링: RateLimitError, APIError 처리
- [ ] 타임아웃 설정

### 권장

- [ ] 스트리밍: 긴 응답은 스트리밍 사용
- [ ] Reasoning effort: 작업 복잡도에 맞게 설정
- [ ] 대화 이력: `previous_response_id` (OpenAI) 또는 수동 관리 (Anthropic)

### 프롬프트 작성

- [ ] 프롬프트 내용 작성은 `writing-prompts` 스킬 참조

---

## 상세 가이드

- **[openai-responses-api.md](references/openai-responses-api.md)** - OpenAI Responses API 상세
- **[anthropic-messages-api.md](references/anthropic-messages-api.md)** - Anthropic Messages API 상세
- **[common-patterns.md](references/common-patterns.md)** - 공통 패턴 (초기화, 에러, 스트리밍, SSE)

---

## 참고 자료

### OpenAI

- [Responses API Reference](https://platform.openai.com/docs/api-reference/responses)
- [Reasoning Models Guide](https://platform.openai.com/docs/guides/reasoning)
- [Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)
- [GPT-5.5 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance/) ⭐ 최신 (2026-04)
- [Using GPT-5.5](https://developers.openai.com/api/docs/guides/latest-model)
- [GPT-5.4 Prompting Guide (이전)](https://developers.openai.com/api/docs/guides/prompt-guidance/?model=gpt-5.4)

### Anthropic

- [Messages API Reference](https://docs.anthropic.com/en/api/messages)
- [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)
- [Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
