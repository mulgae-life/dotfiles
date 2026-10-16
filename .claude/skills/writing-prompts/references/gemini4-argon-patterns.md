# Gemini 4 Argon 프롬프트 패턴

대상 모델: `gemini-4-argon` (Cloud 전용 `gemini-4-argon-cyber-permissive`는 별도 ID로 다룬다)

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [1. 모델 계약](#1-모델-계약)
- [2. 프롬프팅 권고](#2-프롬프팅-권고)
- [3. 사고 수준과 출력 한도](#3-사고-수준과-출력-한도)
- [4. 3.x와 공유하는 계약](#4-3x와-공유하는-계약)
- [참고](#참고)

> **적용 순서**: Argon 전용 권고와, 공식 문서가 Gemini 4에도 적용한다고 명시한 공통 계약을 우선한다. 나머지는 이 스킬의 범용 원칙을 적용한다. [gemini3-patterns.md](gemini3-patterns.md)의 3.x 전용 처방은 자동 적용하지 않으며, 참고할 때에는 적용 근거와 검증 필요 여부를 구분한다.
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`](../../../../reference/google-prompt-guide/gemini-4-argon-prompt-guide.md)

---

## 작성 체크리스트

- [ ] **ID·서비스·API 방식 확정**: API 모델 ID는 `gemini-4-argon` 하나다. agy의 `gemini-4-argon-low`·`-medium`·`-high`는 CLI 노력 수준 변형이라 API에 쓰지 않는다. Gemini API와 Cloud, Interactions와 GenerateContent의 계약이 다르므로 대상 코드의 경로를 먼저 본다
- [ ] **목표와 성공 조건을 먼저**: 장시간 실행 전에 측정 가능한 목표·성공 조건·이정표를 정한다. 시작 전에 경계 사례·성공 조건 질문과 도구 접근 확인을 하게 한다
- [ ] **검증 수단 제공**: 테스트·로그·스크린샷처럼 기존 검증 수단을 주고, 부족하면 재현 가능한 검사와 기준 결과를 마련한다. 잴 것이 아예 없으면 기준 측정부터 만들게 한다
- [ ] **되돌릴 수 없는 단계 앞 확인**: 끝까지 자율 실행하게 하되 비가역 단계에서는 멈춰 확인받게 한다
- [ ] **길이 목표에 기대지 않음**: Argon은 토큰 수·단어 수 같은 길이 목표를 따르지 않는다(공식 제한). 깊이는 `thinking_level`로 조절한다. 분량이 중요하면 출력 형식(항목 수, 절 구성)으로 잡아 보되, 이는 이 문서의 활용 제안이고 길이를 보장하는 공식 수단이 아니다
- [ ] **고정 내용은 앞에**: 암시 캐싱이 공통 접두부에 걸린다. 명시 캐싱(`cached_content`)은 없다
- [ ] **도구 직전 텍스트**: 도구 호출 앞에 구조 없는 텍스트를 두지 않고 지시는 `\n\n`으로 구분한다. 중간 메모는 `update`(`previous_step`·`plan`·`next_step`) 같은 전용 함수로
- [ ] **제거**: `temperature`·`top_p`·`top_k`·`candidate_count`, `thinking_budget`·`minimal`, 미리 채운 model 턴. Cloud면 `frequency_penalty`·`presence_penalty`도
- [ ] **응답 성향은 확인 후 반영**: "문체 지시를 더 잘 따르고 얼버무림·반복·상투어가 적다"는 Google 주장이다. 이를 근거로 문체 지시를 빼기 전에 과제별로 확인한다

---

## 1. 모델 계약

| 항목 | 내용 |
|------|------|
| 상태 | Stable, 2026-10-13 GA |
| 창 | 입력 + 사고 + 출력 통합 1,048,576 |
| 출력 한도 | Interactions `background=False`는 최대 65,536(넘기면 400). GenerateContent 직접 비스트리밍 REST는 요청당 32,768, 스트리밍 65,536. 최신 SDK 호출은 기본 65,536이고 자동 이어 쓰기로 더 큰 전체 출력을 돌려줌 |
| 사고 수준 | `low`·`medium`·`high` (기본 `medium`). `minimal` 없음 |
| `thinking_budget` | Gemini API GenerateContent: 가까운 수준으로 바뀌고 경고 / Cloud: 400 |
| 캐싱 | 암시 캐싱만, 적중 95% 할인. 최소 길이 Gemini API 4,096 / Cloud 6,144 |
| 입력·출력 | 텍스트·이미지·영상·음성·PDF → 텍스트. 이미지·음성 생성, Live API 미지원 |
| 가격 (Standard) | 입력 $2·출력 $10 (2026-11-30까지), 12-01부터 $4·$20. Developer API 무료 등급·AI Pro 플랜 제외 |

---

## 2. 프롬프팅 권고

[공식, AI Studio "Gemini 4 Argon: Developer Guide" · 5 practical tips]

1. **Align on intent before long runs** — 목표·이정표 합의, 질문 먼저, 사전 점검, 합의 후에는 턴마다 끼어들지 않고 끝까지 실행
2. **Give the model a way to verify its work** — 테스트·로그·스크린샷 같은 기존 신호를 주고, 부족하면 재현 가능한 검증 스크립트와 기준 점수로 변경마다 확인
3. **Use multimodal references** — 참조 이미지 1~2개나 `DESIGN.md`, 화면 녹화 + 음성 설명
4. **Use Argon as an orchestrator** — 복잡하고 독립적으로 나눌 수 있는 작업에서 Argon이 분해·설계·리뷰를 맡고 범위가 분명한 병렬 작업은 3.8 Flash 하위 에이전트에 맡기는 분업을 선택지로 검토. 위임 의무는 아님
5. **Have Argon reflect on past work** — 막힌 지점과 저장소 함정을 돌아보고 `AGENTS.md`·스킬 갱신을 제안하게 함

권고 예시 원문(검증 수단 제공):

```text
First, write a headless Chrome script that crawls every route in src/routes/, inspects the live DOM and accessibility tree, and logs all violations to record our baseline score. ... Re-run your script after each change to verify that each single fix resolves the entire cluster with zero regressions. Keep going until all routes pass with zero violations.
```

---

## 3. 사고 수준과 출력 한도

| 레벨 | 용도 |
|------|------|
| `low` | 분류·라우팅·추출, 가벼운 분석·글쓰기, 비용 민감 작업 |
| `medium` | 대부분의 작업, 복잡한 코드·에이전트 작업 권장 |
| `high` | 다중 파일 원인 분석, 취약점 패치, 어려운 수학·과학, 초기 설계. 장문 출력과 함께 |

- 세 수준을 모두 평가하고 품질 기준을 넘는 가장 낮은 수준을 고른다
- `max_output_tokens`는 사고 + 응답 합계다. 32K 미만이면 32,768 이상으로 올리고, 토큰을 줄이려면 사고 수준을 낮춘다
- 장문 출력: Interactions는 `background=True` + `max_output_tokens > 65536`(한도를 안 주면 64K에서 멈춤), GenerateContent는 최신 SDK 자동 이어 쓰기 또는 `continuation_token` 루프, Cloud는 GenerateContent v1beta1만. OpenAI 호환 계층은 장문 출력을 받지 못한다
- 어려운 프롬프트는 몇 분 걸린다. 타임아웃 15~20분 이상 또는 백그라운드 실행

---

## 4. 3.x와 공유하는 계약

공식 문서가 Gemini 4와 3을 함께 명시했거나 Argon 문서가 같은 요구를 다시 적은 항목만 [gemini3-patterns.md](gemini3-patterns.md)의 절을 따른다.

- 사고 서명·이력 보존 → §4 (Argon GenerateContent 체크리스트 "Preserve thought signatures")
- 함수 결과 짝(`id`·`name`·순서) → §5 (Cloud Argon 관례)
- 구조화 출력 + 내장 도구 → §5 ("Gemini 4 and Gemini 3 series models", Preview). 구 필드 호환성은 미확인
- 미디어 해상도 → §6 ("Gemini 4 and Gemini 3 models"). 영상의 에이전트형 처리는 별도 설정(`media_processing="agentic"`, 기본 `static`)

---

## 참고

- [Gemini 4 Argon 풀 가이드 (한국어)](../../../../reference/google-prompt-guide/gemini-4-argon-prompt-guide.md)
- [What's new in Gemini 4 Argon (공식)](https://ai.google.dev/gemini-api/docs/latest-model) · [GenerateContent판](https://ai.google.dev/gemini-api/docs/generate-content/latest-model)
- [Gemini 4 Argon: Developer Guide (AI Studio)](https://aistudio.google.com/learn/gemini-4-argon-developer-guide)
- [Gemini 4 Argon 모델 페이지 (공식)](https://ai.google.dev/gemini-api/docs/models/gemini-4-argon)
- [Long decode (공식)](https://ai.google.dev/gemini-api/docs/long-decode) · [Thinking (공식)](https://ai.google.dev/gemini-api/docs/thinking)
- [Developer's guide to Gemini 4 Argon (Google Cloud)](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon)
