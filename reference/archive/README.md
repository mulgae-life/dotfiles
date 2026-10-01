# 구세대 모델 자료 보관소

현역 기준에서 벗어난 모델 세대의 문서를 이력 보존 목적으로 모아 둔 곳입니다. 현행 스킬·규칙은 이 폴더를 참조하지 않습니다.

## 보관 기준

계열별로 최신·직전·전전 세대만 현행으로 두고, 그보다 오래된 세대 전용 자료를 보관합니다. 공급자가 은퇴시킨 모델은 이 범위 안이어도 보관 대상입니다. 새 모델이 나오면 가장 오래된 세대를 이곳으로 옮깁니다.

| 계열 | 현행 |
|------|------|
| Claude Opus | 5.5 · 5 · 4.8 |
| Claude Sonnet | 5.5 · 5 · 4.6 |
| Claude Fable | 5.1 · 5 |
| Claude Haiku | 4.5 |
| GPT | 6 (Astra·6.1 Sol·6 Sol·Luna) · 5.6 · 5.5 |
| Gemini | Flash 3.8 · 3.7 · 3.6, Flash-Lite 3.5 · 3.1, Pro 3.1 Preview |
| Gemma | 4 (최신 세대만) |
| Qwen | 3.8 (최신 세대만. 3.7은 API 전용이라 오픈웨이트 계보는 3.6 → 3.8) |

연구 원문(`reference/research/`)은 조사 시점 기록이라 보관 대상이 아닙니다.

## 구성

원래 있던 폴더 구조를 그대로 유지합니다.

| 폴더 | 내용 |
|------|------|
| `openai-prompt-guide/` | GPT-4.1·5·5.1·5.2·5.4 프롬프팅 가이드, GPT-5 Prompt Optimizer, gpt-4o·o1·o3·GPT-5.2 시절 플랫폼 문서 스냅샷 7종 |
| `openai-api-guide/` | Reasoning models(GPT-5 초기), Using GPT-5.2, Using GPT-5.4 |
| `claude-prompt-guide/` | Claude 4.x Best Practices(영문·한국어, Sonnet 4.5·Opus 4.5 시절), 응답 Prefilling(Claude 4.6 이후 모델에서 400) |
| `qwen-prompt-guide/` | Qwen 3.6 프롬프팅 풀 가이드 (§14.3의 tool call JSON 예시는 부정확 — 실제 template은 3.5부터 XML 스타일) |
| `skills/writing-prompts/` | `writing-prompts` 스킬에서 분리한 GPT-5.4 패턴, GPT-5 파라미터, Prefilling, Qwen 3.6 패턴 |

## 다시 꺼낼 때

해당 모델을 직접 다뤄야 할 때만 원래 위치로 되돌리고, 스킬 `SKILL.md`의 참조 목록과 상호 링크를 함께 복원합니다. 되돌린 파일의 API 예시와 상대 링크는 현재 공식 문서와 새 위치 기준으로 다시 확인합니다.
