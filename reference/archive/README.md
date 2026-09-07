# 구세대 모델 자료 보관소

현역 기준에서 벗어난 모델 세대의 문서를 이력 보존 목적으로 모아 둔 곳입니다. 현행 스킬·규칙은 이 폴더를 참조하지 않습니다.

## 보관 기준

- **Claude**: 5 세대(Fable 5·Opus 5·Sonnet 5) 미만 전용 자료. Haiku 4.5는 현역 소형 모델이라 제외
- **GPT**: 5.6 미만 전용 자료. 5.6 자료는 GPT-6 가이드가 "프롬프트 계약 구조는 5.6 유효"로 참조하므로 현행 유지
- 연구 원문(`reference/research/`)은 조사 시점 기록이라 보관 대상이 아님

## 구성

원래 있던 폴더 구조를 그대로 유지합니다.

| 폴더 | 내용 |
|------|------|
| `openai-prompt-guide/` | GPT-4.1·5·5.1·5.2·5.4·5.5 프롬프팅 가이드, GPT-5 Prompt Optimizer, gpt-4o·o1·o3·GPT-5.2 시절 플랫폼 문서 스냅샷 7종 |
| `openai-api-guide/` | Reasoning models(GPT-5 초기), Using GPT-5.2, Using GPT-5.4 |
| `claude-prompt-guide/` | Claude 4.x Best Practices(영문·한국어), 응답 Prefilling(Claude 5·Sonnet 4.6+에서 400) |
| `skills/writing-prompts/` | `writing-prompts` 스킬에서 분리한 Claude 4.x 특화 기법, GPT-5.4·5.5 패턴, GPT-5 파라미터, Prefilling |

## 다시 꺼낼 때

해당 모델을 직접 다뤄야 할 때만 원래 위치로 되돌리고, 스킬 `SKILL.md`의 참조 목록과 상호 링크를 함께 복원합니다.
