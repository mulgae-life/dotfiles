# 호출 예시 및 Packet 샘플

## 호출 예시

**예시 1: 논문 섹션 초안**

```text
논문 results 섹션 초안 작성. recursive-discussion로 진행하고,
Claude가 먼저 초안을 쓰고, Codex가 검토할 discussion packet까지 만들어.
```

**예시 2: 리포트 결론 다듬기**

```text
이 리포트 결론 문단을 recursive-discussion 방식으로 다듬어.
Codex 반론이 오면 토론 상태표로 정리하고, 마지막은 Claude 문장으로 닫아.
```

**예시 3: 아이디어 검토**

```text
이 연구 아이디어를 recursive-discussion로 검토해.
Claude가 먼저 아이디어를 넓히고, Codex가 비판적으로 검증한 뒤, 양쪽이 토론하며 수렴해.
```

**예시 4: 아키텍처 설계 리뷰**

```text
이 마이크로서비스 분리안을 recursive-discussion로 검토해.
Claude가 설계를 정리하고, Codex가 장애 시나리오랑 운영 복잡도를 검증해.
```

**예시 5: 기술 제안서 다듬기**

```text
이 RFC를 recursive-discussion로 다듬어.
Claude가 먼저 구조를 잡고, Codex가 구현 복잡도랑 마이그레이션 리스크를 검증해.
```

**예시 6: 사업 기획서 검증**

```text
이 사업 기획서를 recursive-discussion로 검증해.
Claude가 서사를 잡고, Codex가 시장 가정과 재무 추정을 검증해.
```

## Discussion Packet 샘플

### 문서 검토용

```text
---
from: claude
to: codex
round: 1
type: critique
instruction: respond-only, do-not-call-back
---

검토 대상: 논문 결과 해석 섹션
목표: 제안 방법론의 강점/약점을 과장 없이 정리

핵심 주장:
1. 방법론 A가 수렴 차수에서 가장 우수하다.
2. 방법론 B가 정확도 일관성에서 더 안정적이다.
3. 방법론 A는 파라미터 민감도가 B보다 높다.

근거:
- data/experiments/comparison/
- results/table_3.csv
- [참고 논문 저자, 연도]

중점 검토:
- 과장된 결론 여부
- 데이터 없는 추론 여부
- 비교 대상 대비 우위 표현의 정당성

---
아래 형식으로 응답해 주세요:

[Summary]
- 한 줄 요약

[Findings]
- 핵심 지적 3~7개

[Disposition Hint]
- 유지 / 수정 / 삭제 권장

[Open Questions]
- 추가 검증 필요 항목
```

### 문서 검토용 (Round 2+, 후속 라운드)

```text
---
from: claude
to: codex
round: 2
type: critique
instruction: respond-only, do-not-call-back
---

검토 대상: 논문 결과 해석 섹션 (수정본 v2)
현재 문서: .collab-loop/20260314-results/results_v2.md

## 이전 라운드 토론 상태

| # | 쟁점 | 상태 | 조치 |
|---|------|------|------|
| 1 | 수렴 차수 우위 과장 | 합의 | v2에 톤 다운 반영 완료 |
| 2 | 비용 비교 근거 부족 | 미합의 | 이번 라운드 재논의 |
| 3 | 파라미터 민감도 서술 누락 | 합의 | v2에 추가 완료 |

## 미합의 쟁점 (#2) 양쪽 근거
- **A측(Claude)**: 실험 조건이 다르지만 상대적 비용 순위는 유효. table_3.csv의 비용 열 참조.
- **B측(Codex)**: 조건 차이가 비용에 직접 영향하므로 정량 비교 불가. 조건별 분리 실험 필요.

이번 라운드에서 #2에 대해 추가 논증 또는 절충안을 제시해 주세요.

---
아래 형식으로 응답해 주세요:

[Summary]
- 한 줄 요약

[Findings]
- 핵심 지적 3~7개

[Disposition Hint]
- 유지 / 수정 / 삭제 권장

[Open Questions]
- 추가 검증 필요 항목
```

### 아키텍처 설계 검토용

```text
---
from: claude
to: codex
round: 1
type: critique
instruction: respond-only, do-not-call-back
---

검토 대상: 주문 서비스 마이크로서비스 분리 설계안
목표: 운영 복잡도와 장애 시나리오를 과소평가하지 않았는지 검증

핵심 주장:
1. 주문/결제/재고를 독립 서비스로 분리하면 배포 속도가 3배 향상된다.
2. 이벤트 소싱으로 서비스 간 정합성을 보장할 수 있다.
3. 현재 모놀리스의 DB 병목이 분리의 주된 이유다.

근거:
- docs/architecture/current-bottlenecks.md
- monitoring/db-slow-queries-2026Q1.csv
- [Martin Fowler, Microservices Trade-Offs]

중점 검토:
- 분산 트랜잭션 복잡도를 과소평가했는지
- 이벤트 소싱의 운영 비용(이벤트 스토어, 리플레이)을 고려했는지
- 팀 규모 대비 서비스 수가 적절한지

---
아래 형식으로 응답해 주세요:

[Summary]
- 한 줄 요약

[Findings]
- 핵심 지적 3~7개

[Disposition Hint]
- 유지 / 수정 / 삭제 권장

[Open Questions]
- 추가 검증 필요 항목
```

### Claude 초안 요청용 (draft-request)

```text
---
from: codex
to: claude
round: 1
type: draft-request
instruction: respond-only, do-not-call-back
---

작업 목표: 논문 결과 해석 섹션 초안 작성
독자와 목적: 해당 분야 연구자 대상, 실험 결과의 의미를 과장 없이 전달
구조 힌트:
1. 주요 발견 요약
2. 기존 연구 대비 차별점
3. 한계와 향후 과제

근거:
- data/experiments/comparison/
- results/table_3.csv
- [참고 논문 저자, 연도]

---
초안을 작성해 주세요. 과장 없이, 데이터가 뒷받침하는 범위 내에서 서술해 주세요.
아래 형식으로 응답해 주세요:

[Draft]
- 요청된 초안 본문

[Self-Assessment]
- 약한 부분 2~3개 (다음 critique에서 집중 검토 대상)

[Assumptions]
- 전제한 가정 목록
```

### Claude 통합 요청용 (integration-request)

```text
---
from: codex
to: claude
round: 3
type: integration-request
instruction: respond-only, do-not-call-back
---

현재 초안: .collab-loop/20260314-results/reply_round2_claude.md

토론 상태표:
| # | 쟁점 | 상태 | 조치 |
|---|------|------|------|
| 1 | 결론이 데이터 범위를 초과 | 합의 | 표현 범위 축소 |
| 2 | 비교 대상 누락 | 부분 합의 | 각주로 한계 명시 |
| 3 | 방법론 우위 과장 | 합의 | 톤 다운 |

수정 지시:
- 1번과 3번은 즉시 반영
- 2번은 데이터가 없으므로 "비교 미수행"으로 명시

---
위 토론 상태표를 반영하여 통합본을 작성해 주세요.
아래 형식으로 응답해 주세요:

[Integrated Draft]
- 토론 상태표 반영 통합본

[Changes Applied]
- 반영한 항목과 변경 내용 요약

[Unresolved]
- 반영하지 못한 항목과 이유
```
