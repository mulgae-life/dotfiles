# Runtime / CLI Invocation

> 디렉토리 구조, 호출 규약, 재귀 방어, Reply Contract 등 실행 세부사항.

---

## 호출 요건 (CLI 버전 무관)

이 스킬의 핵심 산출물은 **packet/reply 파일**이며, 그 자체는 어떤 CLI에도 의존하지 않습니다. 호스트가 상대 CLI를 호출할 때 충족해야 하는 **기능 요건**은 다음 4가지입니다:

| # | 요건 | 의미 |
|:-:|------|------|
| 1 | **비대화형 단발 응답** | 대화 루프에 진입하지 않고 1회 응답 후 종료 |
| 2 | **stdin 또는 파일 packet 입력** | packet 본문을 입력으로 받기 |
| 3 | **stdout/파일 텍스트 응답** | 응답을 `reply_round{N}_{agent}.md`로 저장 가능 |
| 4 | **재귀 호출 차단** | 호출된 CLI가 다시 다른 CLI를 호출하지 않음 |

이 4가지가 충족되면 **CLI 종류·버전이 무엇이든 토론 루프는 동작**합니다. 플래그 이름은 §Peer Adapter에서 매핑하며, 매핑이 실패해도 §Fallback으로 진행 가능합니다.

### 재귀 방어의 핵심 (best-effort 계층)

| 계층 | 방어 수단 | 필수 여부 |
|------|----------|:--------:|
| **프롬프트** | packet header `instruction: respond-only, do-not-call-back` | ✅ 필수 |
| **호출 모드** | 비대화형 단발 응답 (요건 #1) | ✅ 필수 |
| **샌드박스** | 읽기 전용 모드 (`-s read-only` 등) | ⭕ best-effort |

읽기 전용 샌드박스는 **있으면 적용, 없으면 진행**합니다. 미적용 시 `decision_log.md` §7 메타에 "샌드박스 미적용"을 기록하면 됩니다. 재귀 방어의 본질은 packet header + 단발 호출 두 축입니다.

---

## Preflight Check

루프 시작 전, **상대 CLI의 `--help` 출력을 1회 읽어 §호출 요건 4가지에 대응하는 현재 플래그 매핑을 작성**합니다. 이 매핑은 세션 동안 캐시하여 재사용합니다.

```bash
# Claude 호스트 시
codex exec --help > /tmp/codex_help.txt

# Codex 호스트 시
claude --help > /tmp/claude_help.txt
```

호스트 모델은 위 출력을 읽고 §Peer Adapter의 매핑 표를 **현재 시점 충족 수단으로 갱신**합니다. 4가지 요건 중 하나라도 충족 수단을 찾지 못하면 §Fallback으로 전환합니다 (참고: ④ 재귀 호출 차단은 플래그가 아니라 packet header + 단발 호출 조합으로 충족).

> CLI 자체는 항상 설치되어 있다는 전제이므로 존재 여부 검사는 생략합니다.

## Working Directory

토론 산출물은 `.collab-loop/`에 저장합니다.

```text
.collab-loop/
  YYYYMMDD-작업slug/
    packet_round1.md          # 호출자 → 응답자 요청
    reply_round1_{agent}.md   # 응답 (codex 또는 claude)
    packet_round2.md
    reply_round2_{agent}.md
    ...                       (기본 5라운드, 절대 상한 round10)
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

## Peer Adapter

> 🔒 **이 섹션이 이 스킬의 유일한 버전 의존 지점입니다.** claude/codex CLI의 플래그가 바뀌면 **여기서만** 매핑을 갱신하세요. SKILL.md 본문, `## 호출 요건`, `## Recursion Guard`, `## Reply Contract`, `## Fallback` 등 다른 섹션은 CLI 버전과 무관합니다.
>
> Preflight에서 `--help`를 읽고 매핑이 깨졌다고 판단되면 아래 표를 현재 시점 플래그로 업데이트하거나, 매핑 자체가 불가능하면 §Fallback으로 전환하세요.

세션 디렉토리는 첫 호출 시 생성합니다.

```bash
SESSION_DIR=".collab-loop/YYYYMMDD-작업slug"
mkdir -p "$SESSION_DIR"
```

### Claude 호스트 → Codex 호출 (critique 요청)

**필수 4요건 → 현재 플래그 매핑** (Preflight에서 `codex exec --help`로 재검증):

| # | 호출 요건 | 충족 수단 (현재 시점 예시) |
|:-:|----------|----------------------------|
| ① | 비대화형 단발 응답 | `codex exec` (대화형 진입 없음) |
| ② | stdin packet 입력 | `- < "$PACKET"` |
| ③ | 파일 응답 저장 | `-o "$OUT"` |
| ④ | 재귀 호출 차단 | packet header `instruction: respond-only, do-not-call-back` + ①의 단발 호출 모드 (별도 플래그 불필요, 프롬프트+호출 모드 조합) |

**best-effort (있으면 적용, 없으면 진행)**:

| 항목 | 충족 수단 (현재 시점 예시) |
|------|----------------------------|
| 비파괴 실행 (샌드박스) | `-s read-only` |

```bash
# 현재 시점 매핑 — Preflight에서 갱신
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_codex.md"

codex exec \
  -s read-only \
  -o "$OUT" \
  - < "$PACKET"
```

### Codex 호스트 → Claude 호출 (초안/통합 요청)

**필수 4요건 → 현재 플래그 매핑** (Preflight에서 `claude --help`로 재검증):

| # | 호출 요건 | 충족 수단 (현재 시점 예시) |
|:-:|----------|----------------------------|
| ① | 비대화형 단발 응답 | `-p` |
| ② | stdin packet 입력 | `< "$PACKET"` |
| ③ | 파일 응답 저장 | `> "$OUT"` (셸 리다이렉트) + `--output-format text`로 순수 텍스트 응답 |
| ④ | 재귀 호출 차단 | packet header `instruction: respond-only, do-not-call-back` + ①의 단발 호출 모드 (별도 플래그 불필요, 프롬프트+호출 모드 조합) |

**best-effort (있으면 적용, 없으면 진행)**:

| 항목 | 충족 수단 |
|------|----------|
| 비파괴 실행 (샌드박스) | Claude Code는 별도 read-only 모드 매핑 없음 (현재 시점). 미적용 시 `decision_log.md` §7 메타에 사유 기록 |

```bash
# 현재 시점 매핑 — Preflight에서 갱신
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_claude.md"

claude -p \
  --output-format text \
  < "$PACKET" > "$OUT"
```

> 도구 제한은 기본적으로 사용하지 않습니다. Claude가 웹 검색, 파일 읽기 등으로
> 레퍼런스를 확보할 수 있어야 토론 품질이 높아집니다. 재귀 호출 방지는 packet header의
> `instruction: respond-only, do-not-call-back`과 단발 모드로 충분합니다.

### 대형 문서 전달

기본은 packet에 파일 경로를 명시하고 상대 모델이 직접 읽게 합니다.
상대 모델이 경로 기반 읽기를 안정적으로 수행하지 못할 때,
보조 수단으로 stdin concatenate로 문서를 함께 전달합니다.

아래 예시는 **Claude 호스트 → Codex 호출 매핑(위 첫 번째 표)을 그대로 사용하면서 stdin에 `cat`으로 packet+document를 결합**한 형태입니다. 호스트 방향이 반대이거나 어댑터가 갱신되었으면 위 매핑 표의 현재 시점 플래그로 치환하세요.

```bash
# Claude 호스트 → Codex 호출 시 대형 문서 동봉 (현재 시점 매핑 — Preflight에서 갱신)
cat "$PACKET" "$DOCUMENT" | codex exec -s read-only -o "$OUT" -
```

> 대형 문서 분할 전략은 `session-management.md` 참조.

## Recursion Guard

각 round 종료 후, 오케스트레이터가 토론 상태표를 작성하고 다음 round 진행 여부를 판단합니다.

**기본 라운드**: 5라운드. 미합의(Disputed) 항목이 남아 있으면 **합의될 때까지 연장**합니다. 시간이 걸려도 충분히 토론하는 것이 우선입니다.

**절대 상한**: **10라운드**. 미합의 항목이 남았어도 라운드 10에 도달하면 **강제 종료**합니다.
- 남은 모든 미합의(Disputed) 항목을 **보류(Deferred)로 일괄 전환**하고 양쪽 근거·검증 방법을 `decision_log.md`에 기록합니다.
- Mode 4로 진입하여 합의된 부분만 통합본에 반영합니다.
- 같은 축에서 5라운드 이상 평행선이 유지되면 라운드 10까지 가지 말고 조기에 보류 처리하는 것을 권장합니다 (전제·정의가 어긋났을 가능성이 높습니다).

**종료 조건** (아래 중 하나):
- (정상 종료) 모든 쟁점이 합의(Agreed), 부분 합의(Partial), 또는 보류(Deferred) 상태이고 미합의(Disputed) 항목이 0건이며 신규 핵심 쟁점이 없음
- (강제 종료) 라운드 10 도달 — 남은 미합의 항목을 보류로 일괄 전환

**재호출 방지** (§호출 요건 §재귀 방어의 핵심 참조):
- 양측 공통: packet header의 `instruction: respond-only, do-not-call-back`이 **프롬프트 수준의 방어선** (필수)
- 양측 공통: 비대화형 단발 호출 모드가 **호출 모드 수준의 방어선** (필수, §Peer Adapter 매핑 참조)
- 보조: 읽기 전용 샌드박스가 시스템 변경을 차단 (best-effort, 미지원 시 진행 가능)

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

## Fallback (호환성 문제 처리)

§Peer Adapter의 매핑이 깨졌을 때(예: `--help`에서 §호출 요건 4가지를 충족하는 플래그를 찾지 못함, 호출이 비-0 종료 코드로 3회 연속 실패) **packet-only 모드로 전환**합니다.

1. packet 파일만 생성
2. `decision_log.md` §7 메타에 `peer adapter unavailable: {원인}` 기록
3. user에게 packet 전달 → 수동으로 상대 CLI에 입력 → 응답 확보
4. 응답을 `reply_round{N}_{agent}.md`로 저장 → 다음 Mode로 진행

토론 프로토콜(packet/reply 형식, 라운드 규칙, Reply Contract)은 동일하게 유지됩니다. 깨진 것은 **자동 호출 레이어**뿐이며, packet/reply 자체는 CLI에 무관합니다.

## 호스트별 실행 흐름

### Claude 호스트

1. Claude가 초안 작성 (첫 라운드만)
2. Claude가 packet 작성 → §Peer Adapter 매핑으로 Codex 호출 (critique 요청)
3. Codex 응답 수신 → Claude가 토론 상태표 작성 + 근거 기반 반론/통합
4. 종료 조건 확인 (미합의 0건 또는 라운드 10 도달) → 미충족 시 2로 복귀
5. Claude가 최종 통합본 작성

### Codex 호스트

1. Codex가 packet 작성 → §Peer Adapter 매핑으로 Claude 호출 (초안 요청, 첫 라운드만)
2. Claude 응답 수신 → Codex가 critique 수행
3. Codex가 critique packet 작성 → §Peer Adapter 매핑으로 Claude 호출 (반론/통합 요청)
4. 종료 조건 확인 (미합의 0건 또는 라운드 10 도달) → 미충족 시 2로 복귀
5. Claude의 마지막 출력이 최종본

> 어느 호스트든 2~4를 미합의 항목이 해소될 때까지 반복합니다 (기본 5라운드, 필요 시 연장, 절대 상한 10라운드). Codex 호스트에서도 초안 작성과 최종 통합은 Claude가 수행합니다.
