# Runtime / CLI Invocation

> 디렉토리 구조, CLI 명령어, 재귀 방어, Reply Contract 등 실행 세부사항.

## Preflight Check

루프 시작 전 **상대 모델 CLI**가 설치되어 있는지 확인합니다.

```bash
# Claude 호스트 시
which codex && echo "codex OK" || echo "codex NOT FOUND"

# Codex 호스트 시
which claude && echo "claude OK" || echo "claude NOT FOUND"
```

상대 CLI가 없으면 §Fallback으로 전환합니다.

## Working Directory

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

> **대상 문서 버전 관리**: `.collab-loop/`는 토론 산출물(packet/reply/log)을 저장합니다.
> 토론 대상 문서 자체는 원래 위치에서 `_v1`, `_v2` 접미사로 버전을 관리합니다.
> - v1: Mode 1 초안 또는 루프 진입 시점의 원본
> - v2+: 라운드 수정 반영본 (라운드마다 새 버전을 만들 필요는 없고, 수정 규모에 따라 판단)
> - 최종본 경로는 decision_log.md에 기록합니다.

## Packet Header

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

## CLI Commands

세션 디렉토리는 첫 호출 시 생성합니다.

```bash
SESSION_DIR=".collab-loop/YYYYMMDD-작업slug"
mkdir -p "$SESSION_DIR"
```

### Claude 호스트 → Codex 호출 (critique 요청)

| 요건 | 이유 | 현재 플래그 (v0.114 기준) |
|------|------|--------------------------|
| 읽기 전용 샌드박스 | 비파괴 실행 보장 | `-s read-only` |
| 응답만 파일 저장 | 진행 출력 제외 | `-o "$OUT"` |
| stdin 입력 | packet 전달 | `- < "$PACKET"` |

```bash
# 참고: 현재 버전 기준 전체 명령어
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_codex.md"

codex exec \
  -s read-only \
  -o "$OUT" \
  - < "$PACKET"
```

> 버전별 플래그가 다를 수 있습니다. `codex exec --help`로 확인 후 적용하세요.

### Codex 호스트 → Claude 호출 (초안/통합 요청)

| 요건 | 이유 | 현재 플래그 (Claude Code 1.x 기준) |
|------|------|----------------------------------|
| 비대화형 단발 응답 | 루프 내 자동화 | `-p` |
| 순수 텍스트 출력 | 후처리 용이 | `--output-format text` |
| stdin 입력 | packet 전달 | `< "$PACKET"` |

```bash
# 참고: 현재 버전 기준 전체 명령어
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_claude.md"

claude -p \
  --output-format text \
  < "$PACKET" > "$OUT"
```

> 도구 제한(`--tools ""`)은 기본적으로 사용하지 않습니다. Claude가 웹 검색, 파일 읽기 등으로
> 레퍼런스를 확보할 수 있어야 토론 품질이 높아집니다. 재귀 호출 방지는 packet header의
> `instruction: respond-only, do-not-call-back`과 `-p` 단발 모드로 충분합니다.

> 버전별 플래그가 다를 수 있습니다. `claude --help`로 확인 후 적용하세요.

### 대형 문서 전달

기본은 packet에 파일 경로를 명시하고 상대 모델이 직접 읽게 합니다.
상대 모델이 경로 기반 읽기를 안정적으로 수행하지 못할 때,
fallback으로 stdin concatenate로 문서를 함께 전달합니다.

```bash
cat "$PACKET" "$DOCUMENT" | codex exec -s read-only -o "$OUT" -
```

> 대형 문서 분할 전략은 `session-management.md` 참조.

## Recursion Guard

각 round 종료 후, 오케스트레이터가 토론 상태표를 작성하고 다음 round 진행 여부를 판단합니다.

**기본 라운드**: 5라운드. 미합의(Disputed) 항목이 남아 있으면 **합의될 때까지 연장**합니다. 시간이 걸려도 충분히 토론하는 것이 우선입니다.

**종료 조건** (아래를 모두 만족할 때):
- 모든 쟁점이 합의(Agreed), 부분 합의(Partial), 또는 보류(Deferred) 상태
- 미합의(Disputed) 항목이 0건
- 신규 핵심 쟁점이 없음

**재호출 방지:**
- Codex 측: `-s read-only` 샌드박스가 shell command를 읽기 전용으로 제한하여 비파괴 실행을 보장합니다.
- Claude 측: `-p` 단발 모드가 대화형 루프를 차단합니다.
- 양측 공통: packet header의 `instruction: respond-only, do-not-call-back`이 프롬프트 수준 방어선입니다.

> 도구(웹 검색, 파일 읽기 등)는 토론 품질을 위해 허용합니다. 재귀 방지와 도구 접근은 별개입니다.

## Reply Contract

유형별 응답 형식을 요구합니다. 자유 산문으로 길게 쓰지 않게 합니다.

### critique / ideation-critique 응답

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

### draft-request 응답

```text
[Draft]
- 요청된 초안 본문

[Self-Assessment]
- 약한 부분 2~3개 (다음 critique에서 집중 검토 대상)

[Assumptions]
- 전제한 가정 목록
```

### integration-request 응답

```text
[Integrated Draft]
- 토론 상태표 기반 통합본

[Changes Applied]
- 합의된 항목의 반영 내용 요약

[Unresolved]
- 미합의(Disputed) 항목과 양쪽 근거 요약
```

## Fallback (CLI 미설치 시)

1. packet 파일만 생성
2. `decision_log.md`에 `CLI unavailable` 기록
3. user에게 packet 전달 → 수동으로 상대 모델 응답 확보
4. 응답을 파일로 저장 → 다음 Mode로 진행

워크플로우 자체는 동일하게 유지합니다.

## 호스트별 실행 흐름

### Claude 호스트

1. Claude가 초안 작성 (첫 라운드만)
2. Claude가 packet 작성 → `codex exec`로 critique 요청
3. Codex 응답 수신 → Claude가 토론 상태표 작성 + 근거 기반 반론/통합
4. 종료 조건 확인 (미합의 0건) → 미충족 시 2로 복귀
5. Claude가 최종 통합본 작성

### Codex 호스트

1. Codex가 packet 작성 → `claude -p`로 초안 요청 (첫 라운드만)
2. Claude 응답 수신 → Codex가 critique 수행
3. Codex가 critique packet 작성 → `claude -p`로 반론/통합 요청
4. 종료 조건 확인 (미합의 0건) → 미충족 시 2로 복귀
5. Claude의 마지막 출력이 최종본

> 어느 호스트든 2~4를 미합의 항목이 해소될 때까지 반복합니다 (기본 5라운드, 필요 시 연장). Codex 호스트에서도 초안 작성과 최종 통합은 Claude가 수행합니다.
