# 세션 관리

> 대형 문서 처리, 토큰 제한 대응, 루프 중단/재개에 관한 가이드.

## 컨텍스트 관리

### 대형 문서 전략

대상 문서가 긴 경우(~5000단어 이상) 아래 전략을 순서대로 적용합니다.

1. **섹션 분할 루프**: 문서를 논리 단위(Introduction, Methods, Results 등)로 나누어 섹션별로 Mode 2→3 루프를 돌림. 각 섹션의 토론 상태표를 별도 파일로 저장.
2. **요약 packet**: 전체 문서를 보내지 않고, 핵심 주장 + 해당 섹션 발췌만 packet에 포함. 전체 맥락은 파일 경로로 참조.
3. **누적 토론 상태표 압축**: 라운드가 진행될수록 이전 토론 상태표를 요약본으로 압축. 전체 토론 상태표는 파일에 보존하고, packet에는 "미해결 항목"만 포함.

### Packet 크기 가이드라인

- packet 본문: **2000단어 이내** 권장
- 초과 시: 핵심 주장과 토론 포인트만 packet에, 나머지는 파일 경로 참조
- 상대 모델 응답도 Reply Contract 형식을 따르면 자연스럽게 간결해짐

### 라운드 누적 컨텍스트 압축 (Round 3+)

Round 3부터는 전체 히스토리를 그대로 붙이지 않고, 다음 기준으로 압축합니다. 전체 packet/reply 원본은 파일로 보존하고, 상대에게 보내는 packet에는 판단에 필요한 상태만 포함합니다.

| 보존 필수 | 요약 가능 |
|-----------|-----------|
| 미합의 쟁점의 양측 근거 | 합의 항목의 토론 과정 |
| 보류 항목과 검증 계획 | round 1~N-1 packet 본문 |
| 작업 목표 / 독자 / 종료 조건 | 직전 self-assessment |
| 최신 토론 상태표 | 외부 reference 목록 |

Round 2+ packet에서 미합의 쟁점을 전달할 때는 4열 근거 카드를 우선 사용합니다.

| 미합의 쟁점 | A측 주장+근거 | B측 주장+근거 | 이번 라운드 검증 방법 |
|-------------|---------------|---------------|----------------------|
| ... | 직전 reply 직접 인용 1문장 + 경로 | 직전 reply 직접 인용 1문장 + 경로 | 코드/데이터/문헌 확인 방법 |

각 측 셀은 최대 3문장으로 제한합니다. 미합의 쟁점이 5건을 초과하면 핵심 3~5건만 카드로 다루고, 나머지는 1줄 요약합니다.

## observer_log.md

`observer_log.md`는 토론 내용이 아니라 **라운드 운영 품질**을 기록하는 선택 산출물입니다. Codex 호스트 세션과 관찰자/테스트 모드에서는 필수로 작성하고, 일반 Claude 호스트 세션에서는 권장합니다. 생략하면 `decision_log.md` §7 메타에 사유를 1줄로 남깁니다.

기록 항목:
- 라운드 운영 품질: 최소 3라운드 준수, 4·5라운드 생략 사유, 종료 조건 확인
- 지침 전달 누락: packet 공통 블록, Reply Contract, 근거 카드 누락
- 대등성 훼손 사례: 한쪽 주장이 근거 없이 합의 처리된 순간
- Reply 이상 케이스와 복구 경로: empty reply, timeout, contract violation, fallback
- 호스트 자가승인 점검: host-origin 쟁점이 상대 동의 인용 없이 합의 처리됐는지

## decision_log.md 표준 템플릿

`decision_log.md`는 루프 종료(Mode 4)와 중단/재개 양쪽에서 사용하는 **단일 산출물**입니다. 아래 템플릿 하나를 따르고, 상황에 따라 일부 섹션이 빈 채로 남을 수 있습니다.

```markdown
---
session: YYYYMMDD-작업slug
status: closed | in-progress | deferred   # closed=정상 종료 / in-progress=중단 / deferred=10라운드 강제 종료
final_round: N
host: claude | codex
target_doc: path/to/doc_v2.md             # 토론 대상 문서 최종 경로 (해당 시)
---

## 1. 루프 요약
- 작업 목표: <1문장>
- 시작 ~ 종료: round 1 ~ round N
- 종료 사유: 정상 합의 / 사용자 중단 / 10라운드 도달 등

## 2. 변경된 핵심 내용
- 이번 루프에서 문서·결과물에 반영된 합의 항목 (불릿)

## 3. 토론 상태 최종표
| # | 쟁점 | 상태 | 조치 / 반영 결과 |
|---|------|------|------------------|
| 1 | ... | 합의(Agreed) | 본문 §X에 반영 |
| 2 | ... | 부분 합의(Partial) | 절충안 §Y에 반영 |
| 3 | ... | 보류(Deferred) | §4 검증 계획 참조 |

## 4. 보류(Deferred) 항목과 검증 계획
- 쟁점 / 양쪽 근거 요약 / 검증에 필요한 데이터·실험·문헌 / 책임자(있다면)

## 5. 남은 리스크
- 합의했더라도 추후 재검토가 필요한 항목 (사실 변경 가능성 등)

## 6. 다음 액션 (재개·후속 루프 시)
- 재개 시 첫 번째로 할 일
- 추가 루프 필요 여부와 그 이유
- latest_packet: 최신 packet 경로
- latest_reply: 최신 reply 경로
- resume_hint: 재개 시 바로 실행하거나 확인할 1줄 명령 또는 절차

## 7. 메타
- 필수: `rounds_used / round_limit`
- 필수: `fallback_entered: yes | no` (yes면 사유 포함)
- 필수: `adapter_mapping` — Preflight에서 작성한 §호출 요건 4가지 ↔ 현재 플래그 매핑
- 필수: `sandbox_applied: yes | no | best-effort` (미적용 시 사유 포함)
- 조건부 필수: `round4_5_skipped_reason` — 3라운드에서 종료했다면 미합의 0건·신규 핵심 쟁점 0건 확인 근거
- 필수: `observer_log: path | omitted` (omitted면 사유 포함)
- 선택: 라운드별 packet/reply 파일 목록
- 선택: 사용한 외부 레퍼런스·웹 검색 결과 요약
- 선택: `wall_clock_minutes`, `peer_invocations`, `reasoning_effort`
```

### 작성 규칙

- **status는 셋 중 하나**: `closed` (Mode 4 정상 종료) / `in-progress` (사용자 중단) / `deferred` (10라운드 강제 종료, runtime.md §Recursion Guard 참조)
- `closed`는 최소 3라운드 수행 후에만 사용합니다. `status: closed`와 `final_round < 3` 조합은 작성하지 않습니다. 라운드 1~2에서 합의된 것처럼 보여도 `status: in-progress`로 남기고 라운드 3에서 최종 반론·누락·과잉합의 여부를 점검합니다.
- 라운드 4·5는 강제가 아닙니다. 3라운드에서 종료한다면 `round4_5_skipped_reason`에 미합의 0건, 신규 핵심 쟁점 0건, host-origin 합의 처리 문제가 없음을 기록합니다.
- `deferred`는 라운드 10 도달 시 사용합니다. 라운드 3은 종료 목표가 아니며, 미합의 항목이 있으면 라운드 10까지 토론을 계속합니다.
- §1·§2·§3은 항상 채웁니다. §4는 보류 항목이 있을 때, §6은 status가 `closed`가 아닐 때 필수
- §6의 `latest_packet`, `latest_reply`, `resume_hint`는 중단/재개 또는 fallback 가능성이 있는 세션에서 필수입니다.
- §7의 필수 메타 항목은 모든 세션에서 기록합니다.
- 미합의(Disputed) 상태로 종료하지 않습니다. status가 `deferred`면 미합의 항목을 모두 보류로 전환한 뒤 §3에 기록

## 중단 & 재개

### 중단 시 절차

루프 중간에 세션을 종료해야 할 때, 위 템플릿에 따라 `decision_log.md`를 작성합니다 (`status: in-progress`). 핵심 필수 섹션:
- §1 (어디까지 진행했는지)
- §3 (현재까지의 토론 상태 — 미해결 쟁점 포함)
- §6 (재개 시 첫 액션, 최신 파일 경로)

### 재개 절차

1. `decision_log.md`에서 마지막 상태(§6) 확인
2. 최신 초안과 미해결 쟁점 파일을 읽기
3. 중단 시점의 Mode부터 재개 (새 라운드 번호를 이어서 사용)
4. 재개 첫 packet에 `resumed: true, previous_round: N` 메타데이터 추가
