# Gemini 4 (Argon·Carbon) 프롬프트 패턴

대상 모델: `gemini-4-argon` · `gemini-4-carbon`. Cloud 전용 `-cyber-permissive` 변형은 별도 ID로 다룬다. 기존 링크를 유지하기 위해 파일명은 바꾸지 않는다.

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [1. 모델 계약](#1-모델-계약)
- [1.1 Carbon 차이 체크리스트](#11-carbon-차이-체크리스트)
- [2. 프롬프팅 권고](#2-프롬프팅-권고)
- [3. 사고 수준과 출력 한도](#3-사고-수준과-출력-한도)
- [4. 3.x와 공유하는 계약](#4-3x와-공유하는-계약)
- [참고](#참고)

> **적용 순서**: 모델별 계약 표 → Carbon 차이 체크리스트 → 두 모델 공통 본문. Argon 전용 성향은 따로 표시한다. [gemini3-patterns.md](gemini3-patterns.md)의 3.x 전용 처방은 자동 적용하지 않으며, 나머지는 이 스킬의 범용 원칙을 적용한다.
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`](../../../../reference/google-prompt-guide/gemini-4-argon-prompt-guide.md)

---

## 작성 체크리스트

- [ ] **ID·서비스·API 방식 확정**: `gemini-4-argon` 또는 `gemini-4-carbon`과 실제 서비스·API 경로를 확인한다. agy의 `-low`·`-medium`·`-high` 변형을 API 모델 ID로 쓰지 않는다
- [ ] **목표와 성공 조건을 먼저**: 장시간 실행 전에 측정 가능한 목표·성공 조건·이정표를 정한다. 시작 전에 경계 사례·성공 조건 질문과 도구 접근 확인을 하게 한다
- [ ] **검증 수단 제공**: 테스트·로그·스크린샷처럼 기존 검증 수단을 주고, 부족하면 재현 가능한 검사와 기준 결과를 마련한다. 잴 것이 아예 없으면 기준 측정부터 만들게 한다
- [ ] **되돌릴 수 없는 단계 앞 확인**: 끝까지 자율 실행하게 하되 비가역 단계에서는 멈춰 확인받게 한다
- [ ] **길이 목표에 기대지 않음**: 두 모델은 토큰 수·단어 수 같은 길이 목표를 따르지 않는다(공식 제한). 깊이는 `thinking_level`로 조절한다. 분량이 중요하면 항목 수·절 구성으로 잡아 보되 길이를 보장하는 공식 수단은 아니다
- [ ] **고정 내용은 앞에**: 암시 캐싱이 공통 접두부에 걸린다. 명시 캐싱(`cached_content`)은 없다
- [ ] **도구 직전 텍스트**: 도구 호출 앞에 구조 없는 텍스트를 두지 않고 지시는 `\n\n`으로 구분한다. 중간 메모는 `update`(`previous_step`·`plan`·`next_step`) 같은 전용 함수로
- [ ] **제거**: `temperature`·`top_p`·`top_k`·`candidate_count`, `thinking_budget`·`minimal`, 미리 채운 model 턴. Cloud면 `frequency_penalty`·`presence_penalty`도
- [ ] **Argon 응답 성향은 확인 후 반영**: 문체 지시를 잘 따르고 얼버무림·반복·상투어가 적다는 주장은 Argon 출시 자료에 한정한다. Carbon으로 확대하거나 문체 지시를 빼는 근거로 바로 쓰지 않는다

---

## 1. 모델 계약

| 항목 | Argon | Carbon |
|------|------|------|
| 안정 버전 ID·GA | `gemini-4-argon`, 2026-10-13 | `gemini-4-carbon`, 2026-11-10 |
| 기본 사고 수준 | `medium` | `medium` |
| Cloud 사이버 변형 | `gemini-4-argon-cyber-permissive`, 기본 `HIGH` | `gemini-4-carbon-cyber-permissive`, 기본 `HIGH` |
| 선택 기준 | 대부분의 고급 개발·지식 작업, 빠른 반복 | 깊은 탐색·추론·검증이 필요한 최고 난도 작업 |
| Developer API 일반 입력 / 출력 | 11-30까지 `$2 / $10`, 12-01부터 `$4 / $20` | 11-30까지 `$2 / $10`, 12-01부터 `$4 / $20` |
| 제공 경로 | 유료 Gemini API·AI Studio, Cloud, Antigravity | 유료 Gemini API·AI Studio, Cloud, Antigravity |
| Antigravity 자격 | 유료 Pro·일부 적격 기기 체험판, Ultra·적격 Enterprise | Ultra·적격 Enterprise; ADC는 프로젝트 접근 권한 필요 |

사이버 변형은 별도 승인 조건을 따른다. 아래 API 계약은 두 일반 모델 공통이며, 서비스별 차이는 그대로 구분한다.

| 항목 | 공통 계약 |
|------|------|
| 창 | 입력 + 사고 + 출력 통합 1,048,576 |
| 출력 한도 | 총 출력 예산 기본 65,536. 두 API의 전경 한 구간은 직접 비스트리밍 HTTP 32,768·스트리밍 65,536. 최신 SDK는 자동 이어 쓰기로 전체 결과를 합침. 최대 1,048,576 − 입력 토큰 |
| 사고 수준 | `low`·`medium`·`high` (기본 `medium`). `minimal` 없음 |
| `thinking_budget` | Gemini API GenerateContent: 가까운 수준으로 바뀌고 경고 / Cloud: 400 |
| 캐싱 | 암시 캐싱만, 적중 95% 할인. Gemini API·Cloud 모두 최소 4,096토큰. Cloud는 내구 캐싱 기본 |
| 입력·출력 | 텍스트·이미지·영상·음성·PDF → 텍스트. 이미지·음성 생성, Live API 미지원 |
| 도구 | 함수 호출·코드 실행·구조화 출력·검색·지도·URL·파일 검색. 컴퓨터 사용은 2026-10-30 GA |
| 캐시 읽기 | Developer API 일반 요율은 11-30까지 `$0.10`, 12-01부터 `$0.20`. 무료 API 등급 미지원. Cloud 가격은 별도 확인 |

### 1.1 Carbon 차이 체크리스트

- [ ] **Argon 기반의 같은 계열**: 요청 스키마는 유지한다. 공통 계약을 서로 다르게 복제하지 않는다
- [ ] **사고량·비용 재평가**: 복잡한 과제에서 Argon보다 사고·검증에 더 많은 토큰과 시간을 쓴다. 단가가 같다고 작업 비용이 같지는 않다
- [ ] **빠른 반복은 Argon 유지**: Carbon은 어려운 원인 분석·설계·감사·수학·과학 작업부터 평가한다
- [ ] **역할 분담은 선택지**: 필요하면 Carbon `medium`·`high`가 설계·조율·검증을, Argon·3.8 Flash가 독립적인 구현을 맡는다. `/swarm`은 미리보기이며 위임 의무가 아니다
- [ ] **추가 스킬·회고는 제안으로**: 공식 `gemini-frontend-design` 스킬과 회고 후 시각 설명을 검토하되, 기존 디자인 체계를 무시하거나 지침 파일을 자동 수정하지 않는다

---

## 2. 프롬프팅 권고

[공식, AI Studio의 Argon·Carbon 개발 가이드가 각각 제시한 다섯 운용 축]

1. **Align on intent before long runs** — 목표·이정표 합의, 질문 먼저, 사전 점검, 합의 후에는 턴마다 끼어들지 않고 끝까지 실행
2. **Give the model a way to verify its work** — 테스트·로그·스크린샷 같은 기존 신호를 주고, 부족하면 재현 가능한 검증 스크립트와 기준 점수로 변경마다 확인
3. **Use multimodal references** — 참조 이미지 1~2개나 `DESIGN.md`, 화면 녹화 + 음성 설명
4. **조율자와 구현 역할 분담** — Argon 가이드는 Argon + 3.8 Flash, Carbon 가이드는 Carbon + Argon·3.8 Flash를 제시. 독립적인 큰 작업에서 선택지로 검토
5. **지난 작업 회고** — 막힌 지점과 저장소 함정을 돌아보고 `AGENTS.md`·스킬 갱신을 제안하게 함

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
- `max_output_tokens`는 사고 + 함수 호출·응답 합계다. 대부분의 코딩은 기본 65,536부터 평가한다. 토큰을 줄이려면 사고 수준을 낮춘다
- Interactions 장문 출력은 `background=True`와 큰 출력 예산, 또는 전경 이어 쓰기다. 전경 자동 이어 쓰기는 Python 2.34.0+·JS 2.32.0+가 기본 지원하며 `background=False`에서도 64K 초과 결과를 합친다
- GenerateContent 자동 이어 쓰기는 Python 2.30.1+·JS 2.29.1+다. 직접 루프는 원래 요청과 `continuation_token`을 재전송하며 부분 출력을 입력에 붙이지 않는다
- Cloud 장문 출력은 두 API 모두 `v1beta1`에서 지원한다. OpenAI 호환 계층은 이어 쓰기를 지원하지 않는다
- 구간별 HTTP 시간 제한과 전체 호출 제한을 구분한다. 누적 입력 토큰으로 압축을 판단하지 않고, 이어 쓰기가 끝난 뒤 압축한다
- Carbon 학습 글의 전경 이어 쓰기 미제공 문장 대신 [현재 장문 출력 문서](https://aistudio.google.com/docs/long-decode)를 따른다

---

## 4. 3.x와 공유하는 계약

공식 문서가 Gemini 4와 3을 함께 명시했거나 두 모델 문서가 같은 요구를 다시 적은 항목만 [gemini3-patterns.md](gemini3-patterns.md)의 절을 따른다.

- 사고 서명·이력 보존 → §4 (두 모델의 GenerateContent 체크리스트)
- 함수 결과 짝(`id`·`name`·순서) → §5 (두 모델의 Cloud 가이드). 의존 관계 없는 조회까지 모두 직렬화하지 않는다
- 구조화 출력 + 내장 도구 → §5 (Gemini 4·3 계열, Preview). Developer API의 구 필드 호환성은 미확인
- 미디어 해상도 → §6 ("Gemini 4 and Gemini 3 models"). 영상의 에이전트형 처리는 별도 설정(`media_processing="agentic"`, 기본 `static`)

---

## 참고

- [Gemini 4 (Argon·Carbon) 전체 가이드](../../../../reference/google-prompt-guide/gemini-4-argon-prompt-guide.md)
- 새 기능: [Argon](https://aistudio.google.com/docs/whats-new-gemini-4-argon) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-argon?generate-content=true) · [Carbon](https://aistudio.google.com/docs/whats-new-gemini-4-carbon) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-carbon?generate-content=true)
- AI Studio 개발 가이드: [Argon](https://aistudio.google.com/learn/gemini-4-argon-developer-guide) · [Carbon](https://aistudio.google.com/learn/gemini-4-carbon-developer-guide)
- 모델 페이지: [Argon](https://aistudio.google.com/docs/models/gemini-4-argon) · [Carbon](https://aistudio.google.com/docs/models/gemini-4-carbon)
- [Long decode](https://aistudio.google.com/docs/long-decode) · [Thinking](https://aistudio.google.com/docs/thinking) · [Pricing](https://aistudio.google.com/docs/pricing)
- Cloud 개발 가이드: [Argon](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon) · [Carbon](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-carbon)
