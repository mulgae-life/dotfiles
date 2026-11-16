# Gemini 3.6 Flash 계약과 메모 (보관)

> **보관 사유**: Gemini 4 Hydrogen을 Flash 계열의 최신 세대로 세면서 3.6 Flash가 현행 범위(최신·직전·전전 세대)를 벗어났습니다.
>
> **원래 위치**: 별도 파일이 아니라 [Gemini 3.x 가이드](../../google-prompt-guide/gemini-3-prompt-guide.md)와 `writing-prompts` 스킬의 3.x 패턴 요약 안에 있던 3.6 Flash 행과 문단입니다.
>
> **출처 (공식 1차)**: [3.6 Flash 모델 페이지](https://ai.google.dev/gemini-api/docs/models/gemini-3.6-flash) · [Thinking](https://ai.google.dev/gemini-api/docs/thinking) · [What's new in Gemini 3.8 Flash](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.8) · [OpenAI compatibility](https://ai.google.dev/gemini-api/docs/openai) · [Gemini deprecations](https://ai.google.dev/gemini-api/docs/deprecations) · [Cloud 모델 수명주기](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/model-versions)
>
> **날짜**: 계약 내용은 2026-10-01에 원문으로 확인했고, 제공 상태는 2026-11-16에 다시 확인했습니다.

3.x 공통 원칙(간결한 지시, sampling 제거, API 방식별 이력 처리, 함수 호출, 구조화 출력, 미디어 해상도)은 3.6 Flash에도 적용되며 현행 3.x 가이드에 있습니다. 아래는 3.6 Flash에만 해당하던 내용입니다.

## 모델 계약

| 항목 | 내용 |
|------|------|
| 모델 ID | `gemini-3.6-flash` |
| 상태 | Stable (2026-07-21 출시). Gemini API는 종료일 미발표, Cloud는 2026-11-19 종료 예정이고 권장 대체 모델은 `gemini-3.8-flash` |
| 입력·출력 | 입력 1,048,576 토큰, 출력 65,536 토큰. 텍스트·이미지·영상·음성·PDF 입력, 텍스트 출력. 함수 호출과 구조화 출력 지원 |
| 사고 수준 | `minimal`·`low`·`medium`·`high`, 기본 `medium` |
| 공식 포지션 | 3.8 가이드가 일상 작업 대안으로 명시("Alternatively, Gemini 3.6 Flash remains supported.") |

## 메모

- 3.8·3.7 Flash와 달리 `minimal`을 받습니다. 3.6용 설정을 3.7·3.8로 옮길 때 `minimal`을 `low`로 바꿉니다.
- `gemini-3.5-flash`는 Gemini API에서 2026-10-08에 폐기됐고, 요청은 3.6 Flash로 자동 연결됩니다.
- OpenAI 호환 계층의 `reasoning_effort` 대응표에는 3.6 Flash 열이 없습니다. 대응을 추측하지 않고 `extra_body`의 `google.thinking_config.thinking_level`로 보냅니다.
- 3.8 Flash로 옮길 때는 현행 3.x 가이드의 마이그레이션 체크리스트를 따릅니다.
