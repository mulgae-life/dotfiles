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
    ...                       (최소 round3, 권장 기본 round5, 절대 상한 round10)
    observer_log.md           # 선택/조건부 — references/session-management.md §observer_log.md 참조
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

## Packet Body 공통 블록

상대 CLI는 이전 호출의 기억이나 이 스킬 본문을 갖고 있다고 가정하지 않습니다. 모든 packet 본문에는 아래 블록을 직접 포함합니다.

```text
## 운영 지침
- 당신은 상대 모델의 하위 검토자가 아니라 대등한 지적 파트너입니다.
- 문서 작업과 최종 문장화는 Claude가 담당하지만, 채택/기각 판단권은 Claude나 Codex(GPT) 어느 한쪽에 있지 않습니다.
- 판단은 근거와 토론 상태표로만 합니다.
- 이 packet에만 응답하고, 다른 CLI를 호출하지 마세요.

## 라운드 정책
- 현재 round: {N}
- 최소 3라운드, 권장 기본 5라운드, 절대 상한 10라운드입니다.
- 3라운드는 종료 목표가 아니라 조기 종료 방지선입니다.
- 미합의(Disputed) 항목이나 신규 핵심 쟁점이 남으면 다음 라운드로 넘기세요.

## 판단 기준
- 근거 우선순위: 실제 코드 > 실험 데이터/원시 산출물 > 논문 원문/1차 문헌 > 프로젝트 문서 > 토론 산출물.
- 각 쟁점은 합의(Agreed), 부분 합의(Partial), 미합의(Disputed), 보류(Deferred) 중 하나로 분류하세요.
- 근거가 부족하면 합의로 처리하지 말고 미합의 또는 보류로 남기세요.

## 이번 응답 임무
- {이번 호출에서 수행할 비판/재반론/초안/통합/최종 점검 임무}
```

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
| 호출 시간 상한 | `timeout 240s` (사용 가능 시 적용) |
| MCP 비활성화 | `--mcp-config '{"mcpServers":{}}' --strict-mcp-config` |

```bash
# 현재 시점 매핑 — Preflight에서 갱신
PACKET="$SESSION_DIR/packet_round1.md"
OUT="$SESSION_DIR/reply_round1_claude.md"

timeout 240s claude -p \
  --output-format text \
  --mcp-config '{"mcpServers":{}}' \
  --strict-mcp-config \
  < "$PACKET" > "$OUT"
```

> recursive-discussion의 기본 호출에서는 MCP를 비활성화합니다. 토론 루프의 핵심은
> packet 입력과 텍스트 reply이며, MCP 초기화는 지연·timeout 원인이 될 수 있습니다.
> 외부 레퍼런스가 필요하면 호스트가 웹 검색·파일 발췌를 수행해 packet에 동봉합니다.
> 상대 Claude가 MCP 도구를 직접 써야 하는 특수 세션에서만 위 `--mcp-config ...`
> `--strict-mcp-config`를 제거하고, 그 사유를 `decision_log.md` §7 메타에 기록합니다.

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

각 round 종료 후, 오케스트레이터가 토론 상태표를 작성하고 다음 round 진행 여부를 판단합니다. 토론 상태표는 특정 모델의 권한이 아니라 양쪽 근거를 기록하는 장부입니다. Claude가 문장화 담당이더라도 미합의 항목을 단독으로 합의 처리하지 않습니다.

**라운드 범위**: 최소 3라운드, 권장 기본 5라운드, 절대 상한 10라운드입니다. 3라운드는 조기 종료 방지선이지 종료 목표가 아닙니다.

**최소 라운드**: 라운드 1~2에서 쟁점이 모두 정리된 것처럼 보여도 정상 종료하지 않습니다. 라운드 3을 최종 반론·누락·과잉합의 점검 라운드로 사용합니다.

**합의 전 지속**: 라운드 3 이후에도 미합의(Disputed) 항목이나 신규 핵심 쟁점이 남아 있으면 **합의될 때까지 계속 토론**합니다. 같은 축에서 평행선이 길어지면 조기 종료하지 말고 전제·정의·검증 기준을 재정의한 packet으로 다음 라운드를 진행합니다.

**권장 점검 슬롯**: 라운드 4·5는 반례 점검과 외부 근거 보강을 위한 권장 슬롯입니다. 라운드 3 이후 미합의 0건과 신규 핵심 쟁점 0건이 양쪽에서 확인되면 라운드 4·5를 강제하지 않습니다.

**호스트 자가승인 방지**: 호스트가 자기 origin 쟁점(호스트가 해당 라운드에서 제안하거나 강하게 주장한 쟁점)을 합의(Agreed)로 올리려면 직전 상대 reply의 명시적 동의 인용을 토론 상태표에 붙입니다. 인용이 없으면 해당 항목은 자동으로 부분 합의(Partial)로 강등합니다. 부분 합의는 미합의(Disputed)가 아니므로 종료 조건의 "미합의 0건" 판단을 깨지 않습니다.

**Mode 4 drift 처리**: 최종본이 토론 상태표를 왜곡했거나 부분 합의를 완전 합의처럼 쓴 흔적이 있으면 종료하지 않습니다. 별도 `integration-audit` type을 만들지 않고, 다음 정식 라운드의 Round 2+ packet에 drift 쟁점으로 추가합니다.

**절대 상한**: **10라운드**. 미합의 항목이 남았어도 라운드 10에 도달하면 **강제 종료**합니다.
- 남은 모든 미합의(Disputed) 항목을 **보류(Deferred)로 일괄 전환**하고 양쪽 근거·검증 방법을 `decision_log.md`에 기록합니다.
- Mode 4로 진입하여 합의된 부분만 통합본에 반영합니다.

**종료 조건** (아래 중 하나):
- (정상 종료) 라운드 3 이상을 수행했고, 모든 쟁점이 합의(Agreed), 부분 합의(Partial), 또는 보류(Deferred) 상태이며, 미합의(Disputed) 항목 0건과 신규 핵심 쟁점 0건을 양쪽이 확인
- (강제 종료) 라운드 10 도달 — 남은 미합의 항목을 보류로 일괄 전환

> 라운드 3 도달은 종료 허가 조건 중 하나일 뿐입니다. 라운드 3에 무조건 종료하지 않습니다.

**재호출 방지** (§호출 요건 §재귀 방어의 핵심 참조):
- 양측 공통: packet header의 `instruction: respond-only, do-not-call-back`이 **프롬프트 수준의 방어선** (필수)
- 양측 공통: 비대화형 단발 호출 모드가 **호출 모드 수준의 방어선** (필수, §Peer Adapter 매핑 참조)
- 보조: 읽기 전용 샌드박스가 시스템 변경을 차단 (best-effort, 미지원 시 진행 가능)

> 도구(웹 검색, 파일 읽기 등)는 토론 품질을 위해 허용합니다. 재귀 방지와 도구 접근은 별개입니다.

## Reply Contract

유형별 응답 형식을 요구합니다. 자유 산문으로 길게 쓰지 않게 합니다.

모든 응답은 아래 원칙을 지킵니다:
- 상대 주장을 단순 수용하지 말고, 수용/반박/보류 이유를 근거와 함께 씁니다.
- 미합의 항목을 합의로 바꾸려면 새 근거 또는 명시적 절충안을 제시합니다.
- 라운드 3 전에는 `close`를 제안하지 않습니다.
- `evidence:`는 파일 경로, URL, 실험 산출물, 인용 가능한 packet/reply 근거를 허용합니다. 근거를 확보하지 못했으면 `evidence: 미확인`으로 표시합니다.
- 각 finding은 5줄 이내를 권장합니다.

### critique / ideation-critique 응답

```text
[Summary]
- 한 줄 요약

[Findings]
- 핵심 지적 3~7개
- 각 항목에 evidence: 파일/URL/데이터/논리 근거 1개 이상

[Counterarguments]
- 상대 주장 중 수용할 점 / 반박할 점 / 보류할 점

[Open Questions]
- 추가 검증 필요 항목

[Round Control]
- 현재 round에서 종료 가능한지 여부
- 남은 미합의 / 신규 핵심 쟁점
```

### draft-request 응답

```text
[Draft]
- 요청된 초안 본문

[Self-Assessment]
- 약한 부분 2~3개 (다음 critique에서 집중 검토 대상)

[Assumptions]
- 전제한 가정 목록

[Questions for Peer]
- 다음 critique에서 검증받아야 할 약점이나 쟁점
```

### integration-request 응답

```text
[Integrated Draft]
- 토론 상태표 기반 통합본

[Changes Applied]
- 합의된 항목의 반영 내용 요약

[Unresolved]
- 미합의(Disputed) 항목과 양쪽 근거 요약
- 각 항목에 evidence: 파일/URL/데이터/논리 근거 1개 이상 또는 evidence: 미확인

[Round Control]
- 현재 round에서 종료 가능한지 여부
- 다음 round가 필요하다면 집중할 쟁점
```

## Reply 이상 케이스 처리

상대 CLI 호출이 성공해도 reply가 토론에 바로 쓸 수 없는 형태일 수 있습니다. 아래 케이스는 §Fallback 전에 먼저 처리합니다. 재호출이나 fallback 진입 사유는 `decision_log.md` §7 메타에 기록합니다.

| 케이스 | 감지 기준 | 1차 조치 | 2차 조치 |
|--------|----------|---------|---------|
| empty reply | reply 파일이 비어 있거나 Reply Contract 헤더가 없음 | 동일 packet 1회 재호출 | 사유 기록 후 packet-only fallback |
| contract violation | 필수 섹션 누락 또는 요청 type과 다른 형식 | 형식 보강 mini-packet 1회 | 사유 기록 후 보류(Deferred) |
| timeout | 호출 시간 상한 초과, 응답 미도달, 또는 reply 파일 0바이트 상태 장기 지속 | 동일 packet 1회 재호출 (Codex 호스트→Claude 호출은 MCP 비활성화 매핑 사용) | 누적 3회 시 fallback |
| non-zero exit | CLI exit code ≠ 0 | §Peer Adapter 매핑 재확인 | 매핑 정상이면 fallback |
| tool/reference unavailable | 상대가 검색·파일 접근 불가를 명시 | 호스트가 필요한 검색 결과·파일 발췌를 다음 packet에 동봉 | 그래도 차단 시 보류(Deferred) |

## Fallback (호환성 문제 처리)

§Peer Adapter의 매핑이 깨졌거나 §Reply 이상 케이스 처리에서 fallback 조건에 도달했을 때 **packet-only 모드로 전환**합니다.

1. packet 파일만 생성
2. `decision_log.md` §7 메타에 `peer adapter unavailable: {원인}` 기록
3. user에게 packet 전달 → 수동으로 상대 CLI에 입력 → 응답 확보
4. 응답을 `reply_round{N}_{agent}.md`로 저장 → 다음 Mode로 진행

토론 프로토콜(packet/reply 형식, 라운드 규칙, Reply Contract)은 동일하게 유지됩니다. 깨진 것은 **자동 호출 레이어**뿐이며, packet/reply 자체는 CLI에 무관합니다.

## 호스트별 실행 흐름

호스트가 누구든 **작문 담당(Claude)**과 **판단 기준(근거와 토론 상태표)**을 분리합니다. Claude는 초안과 최종본을 문장화하지만, Codex 반론을 근거 없이 기각하거나 미합의 항목을 임의로 반영하지 않습니다.

한 세션 내 호스트는 1명으로 고정합니다. 도중에 호스트를 전환해야 하면 새 세션 디렉토리를 열고 `decision_log.md`의 `host` 필드도 새로 기록합니다.

### Claude 호스트

1. Claude가 초안 작성 (첫 라운드만)
2. Claude가 packet 작성 → §Peer Adapter 매핑으로 Codex 호출 (critique 요청)
3. Codex 응답 수신 → Claude가 양쪽 근거를 토론 상태표에 기록하고, 합의된 항목만 반영
4. 종료 조건 확인 (라운드 3 이상 + 미합의 0건 + 신규 핵심 쟁점 0건, 또는 라운드 10 도달) → 미충족 시 2로 복귀
5. Claude가 토론 상태표 기준으로 최종 통합본 문장화

### Codex 호스트

1. Codex가 packet 작성 → §Peer Adapter 매핑으로 Claude 호출 (초안 요청, 첫 라운드만)
2. Claude 응답 수신 → Codex가 critique 수행
3. Codex가 critique packet 작성 → §Peer Adapter 매핑으로 Claude 호출 (반론/통합 요청)
4. 종료 조건 확인 (라운드 3 이상 + 미합의 0건 + 신규 핵심 쟁점 0건, 또는 라운드 10 도달) → 미충족 시 2로 복귀
5. Claude의 마지막 출력이 최종본이지만, 반영 범위는 토론 상태표의 합의/보류 판단을 따름

> 어느 호스트든 2~4를 최소 3라운드 수행하고, 이후 미합의 항목이 해소될 때까지 반복합니다 (권장 기본 5라운드, 필요 시 연장, 절대 상한 10라운드). Codex 호스트에서도 문서 작업과 최종 통합은 Claude가 수행합니다.
