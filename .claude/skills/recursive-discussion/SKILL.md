---
name: recursive-discussion
description: Claude와 Codex(GPT)가 대등한 지적 파트너로 왕복 토론하며 결과물을 끌어올리는 재귀 협업 루프. 논문·리포트·설계 문서·아이데이션 등 발산과 수렴이 모두 필요한 작업에 사용. "토론하면서", "비판적 피드백", "재귀 개선", "loop로 다듬어", "reviewer 관점", "티키타카" 등의 맥락에서 적극 트리거.
---

# Recursive Discussion

논문, 기술 리포트, 설계 문서, 아이데이션처럼
**발산과 수렴이 모두 중요한 작업**에 사용합니다.

"한 모델에게 외주"하는 것이 아니라,
**두 모델의 최대 지능을 부딪혀 결과물을 함께 끌어올리는 것**이 목적입니다.

## 핵심 원칙

- **Claude가 시작하고 Claude가 마무리**합니다. 이는 호스팅 환경이 아닌 **작문 역할** — 어느 CLI에서 실행하든, 초안 작성과 최종 통합은 Claude가 수행합니다.
- **Codex는 대등한 지적 파트너**입니다. 상하 관계 없이 분석·반론·검증으로 결과물을 함께 끌어올립니다.
- 두 모델의 주장 모두 자동 정답이 아닙니다. 가능한 경우 **코드, 데이터, 논문 원문, 실험 결과**로 검증합니다. 초기 아이데이션에서는 가정과 불확실성을 명시합니다.
- 기본 운영은 **5라운드 왕복 토론**입니다. 1라운드 = packet 전송 → 상대 응답 수신 → 판정. 핵심 쟁점이 모두 해소된 경우에만 조기 종료합니다.
- 장황한 초안보다, **논리적 구멍을 줄이고 근거를 강화하는 것**이 우선입니다.
- 이 스킬은 **Claude/Codex 어느 쪽에서든** 사용 가능합니다. 상대 CLI가 설치되어 있으면 실제 호출하고, 없으면 packet-only fallback.

## 진입점 판단

```
초안이 있는가?
├─ YES → Mode 2 (Packet) → Mode 3 → Mode 4 → Mode 5
├─ NO, 방향은 확정 → Mode 1 (Draft) → Mode 2 → ...
└─ NO, 아이디어 단계 → Mode 0 (Ideation) → Mode 1 → ...
```

> 아이데이션(Mode 0)은 `references/ideation.md` 참조.

**사용하지 않는 경우**: 단순 정보 전달 문서, 사실 확인만 필요한 짧은 메모, 1개 파일 소규모 수정.

## 역할 분리

| 역할 | 담당 | 책임 |
|------|------|------|
| 시작 / 초안 / 1차 서사 | Claude | 문제 정의, 초안 작성, 문장 흐름 구성 |
| 분석 / 반론 / 검증 | Codex | 구멍, 과장, 반례, 코드/데이터/문헌 정합성 점검 |
| 통합 / 최종본 | Claude | 토론 결과 반영, 구조 재정리, 최종 문장화 |
| 라운드 판정 | 오케스트레이터 | 판정표 작성, 다음 라운드 진행 여부 결정 |
| 최종 승인 | user | 종료본 수용/수정 요청/추가 루프 지시 |

핵심은 **Claude가 전개를 리드하고, Codex가 강하게 압박하며, Claude가 다시 통합**하는 구조입니다.
오케스트레이터(호스트 모델)가 라운드를 자율 진행하고, user는 최종본에 대해 승인합니다.

## Runtime / CLI Invocation

### Preflight Check

루프 시작 전 **상대 모델 CLI**가 설치되어 있는지 확인합니다.

```bash
# Claude 호스트 시
which codex && echo "codex OK" || echo "codex NOT FOUND"

# Codex 호스트 시
which claude && echo "claude OK" || echo "claude NOT FOUND"
```

상대 CLI가 없으면 §Fallback으로 전환합니다.

### Working Directory

토론 산출물은 `.collab-loop/`에 저장합니다.

```text
.collab-loop/
  YYYYMMDD-작업slug/
    packet_round1.md          # 호출자 → 응답자 요청
    reply_round1_{agent}.md   # 응답 (codex 또는 claude)
    packet_round2.md
    reply_round2_{agent}.md
    ...                       (최대 round5까지)
    decision_log.md
```

`{agent}`는 응답한 모델명 (`codex` 또는 `claude`)을 넣습니다.

### Packet Header

모든 packet 상단에 아래 메타데이터를 넣습니다. `from`, `to`, `type`은 호출 방향에 따라 변경합니다.

```text
---
from: {호출자}          # claude 또는 codex
to: {응답자}            # codex 또는 claude
round: 1
type: {요청 유형}       # critique / ideation-critique / draft-request / integration-request
instruction: respond-only, do-not-call-back
---
```

주요 type 값:
- `critique`: 초안에 대한 비판적 검토 요청 (→ Codex)
- `ideation-critique`: 아이디어 후보에 대한 비판적 검토 요청 (→ Codex)
- `draft-request`: 초안 작성 요청 (→ Claude)
- `integration-request`: 피드백 반영 통합 요청 (→ Claude)

### CLI Commands

세션 디렉토리는 첫 호출 시 생성합니다.

```bash
SESSION_DIR=".collab-loop/YYYYMMDD-작업slug"
mkdir -p "$SESSION_DIR"
```

#### Claude 호스트 → Codex 호출 (critique 요청)

```bash
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_codex.md"

codex exec \
  -s read-only \
  -o "$OUT" \
  - < "$PACKET"
```

- `-s read-only`: shell command를 읽기 전용으로 샌드박싱
- `-o "$OUT"`: 최종 응답만 파일로 저장 (진행 출력 제외)
- `- < "$PACKET"`: stdin으로 packet 전달

#### Codex 호스트 → Claude 호출 (초안/통합 요청)

```bash
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_claude.md"

claude -p \
  --output-format text \
  --tools "" \
  < "$PACKET" > "$OUT"
```

- `-p`: 비대화형 단발 응답
- `--tools ""`: 모든 도구 비활성화 (reply-only 보장)
- `--output-format text`: 순수 텍스트 출력
- `< "$PACKET"`: stdin으로 packet 전달

### Recursion Guard

각 round 종료 후, 오케스트레이터가 판정표를 작성하고 다음 round 진행 여부를 판단합니다. 상한은 **round 5**입니다.

**조기 종료 조건** (아래를 모두 만족할 때만 허용):
- 신규 핵심 쟁점이 없음
- 기존 쟁점에 대한 판정(수용/부분 수용/반박/보류)이 완료됨
- 다음 round가 결과물을 실질적으로 개선하지 못한다고 판단됨

**재호출 방지:**
- Codex 측: `-s read-only` 샌드박스가 shell command를 읽기 전용으로 제한하여 비파괴 실행을 보장합니다.
- Claude 측: `--tools ""`가 모든 도구를 비활성화하여 CLI 호출 자체를 차단합니다.
- 양측 공통: packet header의 `instruction: respond-only, do-not-call-back`이 프롬프트 수준 방어선입니다.

### Reply Contract

상대 모델 응답은 아래 형식을 요구합니다:

```text
[Summary]
- 한 줄 요약

[Findings]
- 핵심 지적 3~7개

[Disposition Hint]
- 유지 / 수정 / 삭제 권장

[Open Questions]
- 추가 검증 필요 항목
```

자유 산문으로 길게 쓰지 않게 합니다. 다음 round에서 바로 판정 가능한 형태로 받아야 합니다.

### Fallback (CLI 미설치 시)

1. packet 파일만 생성
2. `decision_log.md`에 `CLI unavailable` 기록
3. user에게 packet 전달 → 수동으로 상대 모델 응답 확보
4. 응답을 파일로 저장 → 다음 Mode로 진행

워크플로우 자체는 동일하게 유지합니다.

### 호스트별 실행 흐름

#### Claude 호스트

1. Claude가 초안 작성 (첫 라운드만)
2. Claude가 packet 작성 → `codex exec`로 critique 요청
3. Codex 응답 수신 → Claude가 판정표 작성 + 반론/통합
4. 조기 종료 조건 확인 → 미충족 시 2로 복귀
5. Claude가 최종 통합본 작성

#### Codex 호스트

1. Codex가 packet 작성 → `claude -p`로 초안 요청 (첫 라운드만)
2. Claude 응답 수신 → Codex가 critique 수행
3. Codex가 critique packet 작성 → `claude -p`로 반론/통합 요청
4. 조기 종료 조건 확인 → 미충족 시 2로 복귀
5. Claude의 마지막 출력이 최종본

> 어느 호스트든 2~4를 기본 5라운드 반복하며, 조기 종료 조건(§Recursion Guard)을 만족할 때만 종료합니다. Codex 호스트에서도 초안 작성과 최종 통합은 Claude가 수행합니다.

## 워크플로우

### Mode 1. Draft

1. **Claude가** 작업 목표를 1문장으로 정리합니다.
2. **Claude가** 산출물의 독자와 목적을 명확히 합니다.
3. **Claude가** 문서 구조를 먼저 잡습니다.
4. **Claude가** 초안을 작성합니다.
5. **Codex 검토를 위한 review packet**을 만듭니다 (→ Mode 2).

### Mode 2. Packet

상대 모델에 보낼 입력 묶음. type에 따라 필수 필드가 달라집니다.

**critique / ideation-critique** (→ Codex):
- **작업 목표**: 이 문서가 무엇을 달성하려 하는지
- **검토 대상**: 문서 전체 또는 특정 섹션
- **핵심 주장 3~5개**: Codex가 공격할 타깃
- **근거 경로**: 데이터/코드/문헌 파일 경로
- **중점 검토 포인트**: 과장, 논리 점프, 데이터 없는 추론 등

**draft-request** (→ Claude):
- **작업 목표**: 무엇을 작성해야 하는지
- **독자와 목적**: 누구를 위한 어떤 문서인지
- **구조 힌트**: 기대하는 섹션 구성 (있으면)
- **근거 경로**: 참고할 데이터/코드/문헌 파일 경로

**integration-request** (→ Claude):
- **현재 초안**: 수정 대상 문서 또는 경로
- **판정표**: 이번 round의 수용/반박 결과
- **수정 지시**: 무엇을 어떻게 반영할지

> packet 예시는 `references/examples.md` 참조.

packet 끝에 §Reply Contract 형식을 포함합니다. `.collab-loop/세션/packet_round{N}.md`에 저장한 뒤 CLI로 상대 모델을 호출합니다.

### Mode 3. Debate / Integration

상대 모델 응답을 받으면, 오케스트레이터가 항목별로 4분류 판정합니다:

- **critique 응답(Codex → 오케스트레이터)**: 판정표를 작성하고 수용/반박을 결정
- **draft/integration 응답(Claude → 오케스트레이터)**: 초안/통합본을 검토하고 critique를 생성

| 판정 | 의미 |
|------|------|
| **수용(Accept)** | 지적이 맞고 바로 반영 |
| **부분 수용(Partial)** | 문제의식은 맞지만 해법은 수정 |
| **반박(Reject)** | 근거상 틀림 또는 과도한 공격 |
| **보류(Defer)** | 추가 검증 필요 |

판정표 형식:

| # | 상대 피드백 요지 | 판정 | 근거 | 조치 |
|---|-----------------|------|------|------|
| 1 | 제안 방법론의 결론이 과장됨 | 수용 | 표 수치 재확인 | 톤 다운 |
| 2 | 비용 우위 단정 불가 | 반박 | 실험 조건 차이 | 표현 완화 |

이 단계의 핵심: **충돌 지점을 드러내고, 처리한 뒤 더 강한 버전으로 수렴**.

### Mode 4. Revision

판정표 기반으로 **작문 담당(Claude)**이 수정. 우선순위:

1. 사실 오류 수정
2. 논리 점프 제거
3. 과장 표현 완화
4. 구조/흐름 개선
5. 문장 다듬기

문체만 바꾸는 얕은 수정으로 끝내지 않습니다.

> 아이데이션 수정 우선순위는 `references/ideation.md` 참조.

**다음 라운드**: 조기 종료 조건(§Recursion Guard)을 만족하지 않으면, 수정본을 기반으로 Mode 2 → Mode 3 → Mode 4를 반복합니다. 각 round의 산출물은 `packet_round{N}.md`, `reply_round{N}_{agent}.md`로 저장합니다.

### Mode 5. Close

루프 종료 시 아래 3가지를 `decision_log.md`에 남깁니다:

- 이번 루프에서 바뀐 핵심 내용
- 아직 남은 리스크
- 추가 루프 필요 여부

종료본은 **Claude가 정리한 최종본**입니다.
기술 정합성이 민감한 경우, user 요청 시 Codex가 마지막 사실 점검을 한 번 더 수행할 수 있습니다.

## 판단 기준

근거 우선순위:

1. **실제 코드**
2. **실험 데이터 / 원시 산출물**
3. **논문 원문 / 1차 문헌**
4. 프로젝트 계획 문서
5. Claude와 Codex의 토론 산출물

Claude의 문장도 Codex의 분석도, 위 1~4와 충돌하면 수용하지 않습니다.
초기 아이데이션(Mode 0)에서는 검증 가능한 근거가 아직 없을 수 있으므로, 가정임을 명시하고 검증 계획을 함께 제시합니다.

## 산출물 형식

기본 출력 3단 구성:

**1. 현재 버전 요약** — 무엇을 주장하는 문서인지 / 이번 루프 목적

**2. 피드백 판정표** — 항목별 수용/부분 수용/반박/보류 + 근거 + 충돌 지점

**3. 수정 결과** — 실제 변경 내용 / 남은 리스크 / 다음 루프 필요 여부

> 문서 유형별 적용 포인트는 `references/document-types.md` 참조.
> 아이데이션 산출물 형식은 `references/ideation.md` 참조.

## 권장 운영 방식

- 큰 문서는 **섹션 단위**로 돌립니다 (Introduction → Methods → Results → Discussion).
- 아이데이션은 먼저 넓게 발산한 뒤, 두 번째 루프에서 빠르게 좁힙니다.
- 문서 작업과 아이데이션이 섞이면, **아이디어 수렴 후 문서화** 순서를 우선합니다.

## 금지 사항

- Codex가 최종 저자처럼 초안 전체를 다시 쓰는 구조로 바꾸지 않습니다.
- Claude 초안이나 Codex 반론을 **근거 검증 없이** 수용하지 않습니다.
- 루프를 **5라운드 초과** 반복하지 않습니다. 합의된 항목을 재논의하지 않습니다.
- 데이터가 없는 해석을 "그럴듯하다"는 이유로 결론에 넣지 않습니다.
- 아이데이션에서 멋있어 보이는 표현만 남기고 검증 계획 없이 끝내지 않습니다.
