# 설계 원칙과 결정 기록

> README는 사용법만 담는다. 이 문서는 "왜 이렇게 했는가"와 실측 근거, 복원용 아카이브 위치를 담는다. 버전별 변경은 [CHANGELOG.md](../CHANGELOG.md).

## 1. 설계 원칙

**자율성 우선, 최소 차단.** 모든 작업을 확인 프롬프트 없이 실행해 장기 작업이 중단되지 않게 한다(Claude Code는 ask 계층 전면 해제). 위험 명령(`rm` · `git push` · `sudo` 등)의 통제는 지침(rules)이 담당하고 — 자율 작업 중 사용 금지, 사용자 요청 시에만 — 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작, 크론탭 삭제)과 넓은 재귀 삭제 패턴(절대경로·`./` 하위 `rm -rf`)만 `permissions.deny`가 프롬프트 없이 차단한다. 차단 목록의 범위는 도구별로 다르다(§3).

**auto 모드를 쓰지 않는 이유.** Claude Code는 2026-08-14부터 Pro/Max/Team의 기본 시작 모드가 auto(분류기 검토)다. 분류기는 CLAUDE.md 지침을 읽어 차단에 반영하지만, 3회 연속 또는 20회 누적 차단 시 승인 대기로 후퇴하고 이 임계값은 조정할 수 없다. 장기 작업이 중간에 멈추지 않아야 한다는 위 원칙과 맞지 않아 `bypassPermissions`를 유지한다. Codex의 Guardian auto-review도 `approval_policy="never"`에서는 검토 대상이 없어 같은 이유로 쓰지 않는다.

**Codex 공식 메모리를 쓰지 않는 이유.** `features.memories`는 세션을 백그라운드로 요약해 `~/.codex/memories/`에 쌓고 다음 세션에 자동 주입한다. 기본이 꺼짐이고 `false`로 의도를 명시해 둔다. 교훈은 프로젝트별 `.codex/lessons.md`가 담당하는데, 둘은 역할이 겹치면서 성질이 다르다. 메모리는 단위가 전역 하나여서 프로젝트가 섞이고, 내용을 모델이 골라 쓰므로 무엇이 남을지 통제할 수 없다. 추출과 통합이 모델 호출이라 사용량 한도를 소모하며, 잔여 25% 미만이면 생성이 멈춘다. 세션 중 에이전트는 읽기만 허용되어 피드백을 받은 자리에서 바로 적는 용도로도 쓸 수 없다. 공식 문서도 반드시 적용될 규칙은 `AGENTS.md`에 두고 메모리는 보조 회상 계층으로만 취급하라고 권한다. 대신 lessons에는 자동 주입이 없으므로 읽기를 지침이 지시한다 — `AGENTS.md`의 교훈 항목이 세션 첫 작업 전 읽기를, compact 리마인더 훅이 압축 후 재읽기를 담당한다.

**모델·추론 수준은 고정하지 않는다.** 세 도구 모두 설정에 모델과 effort를 두지 않고 기본값을 따른다. 세대가 바뀔 때 config가 낡지 않게 하기 위함이다. `/model`·`/effort`로 런타임에 고른 값은 재설치 때 레포 값으로 돌아간다. 예외는 Claude의 서브에이전트 Opus 강제(`CLAUDE_CODE_SUBAGENT_MODEL=opus` + `_FORCE=1`) — Fable 계열 서브에이전트 팬아웃이 구독 한도를 가장 빨리 소진하므로 비용 통제 목적으로 둔다.

**Claude 층이 정본, 완전히 공유되는 자산만 링크.** 스킬처럼 그대로 쓸 수 있는 자산은 다른 도구가 `.claude/`를 링크로 받고, 형식이나 내용이 도구마다 달라야 하는 규칙 본문(Codex `config.toml`·Antigravity `GEMINI.md`)은 직접 동기화한다. 일부만 맞는 자산을 링크하려고 정본 구조를 쪼개지 않는다.

## 2. 설치 방식 — 링크 · 복사 · 병합

`install.sh`는 `~/dotfiles/` → `~/`로 심볼릭 링크를 만든다. 단 도구가 런타임에 수정하는 파일은 링크하면 레포 원본이 오염되므로 방식을 나눈다.

| 방식 | 대상 | 이유 |
|------|------|------|
| 링크 | `CLAUDE.md`, `rules/`, `agents/`, `skills/`, `hooks/`, `AGENTS.md`, `GEMINI.md` 등 | 도구가 읽기만 한다 |
| 복사 | `.claude/settings.json`, `.codex/config.toml` | 도구가 되쓴다(`/model`·`/effort`, trust, 훅 신뢰 해시). 레포가 정본이므로 재설치가 런타임 조정값을 덮어쓴다 — Codex는 훅 신뢰 해시가 사라지면 시작 시 경고를 내고 `/hooks`에서 한 번 재승인하면 된다 |
| 병합 | `~/.gemini/antigravity-cli/settings.json` | `agy`가 `model`·`trustedWorkspaces`·승인 캐시를 같은 파일에 되쓴다. 레포의 관리 키(`permissions` 3배열은 통째 교체)만 적용하고 나머지 키는 보존. `jq` 부재·파싱 실패·검증 실패면 대상을 건드리지 않고 오류 + 종료 코드 1. 계약 상세는 [.antigravity/README.md](../.antigravity/README.md) |
| 병합(IDE) | Antigravity IDE 글로벌 settings | 런타임 필드를 보존하는 깊은 병합. macOS·Windows만 하고, Linux는 경로가 미검증이라 건너뛰고 안내만 출력한다 |

런타임 데이터(`projects/` 등)는 건드리지 않는다. `jq`가 없으면 자동 설치를 시도한다.

**스킬 공유 경로.** `~/.agents/skills → ~/.claude/skills`로 통합되고 Codex는 이 공용 경로로 받는다. Antigravity는 CLI용 `~/.gemini/config/skills`와 IDE용 `~/.gemini/antigravity/skills`로 따로 연결한다(`~/.gemini/antigravity-cli/skills`는 `agy`가 스스로 만드는 링크라 관리 제외). Gemini CLI 시절 `~/.gemini` 바로 아래 남은 링크(`agents`·`commands`·`policies`·`hooks`·`skills`·`AGENTS.md`)는 설치 때 정리한다.

**레포 안에서 작업할 때.** 레포의 `.claude/`·`.codex/`는 dotfiles 디렉토리에서 프로젝트 설정으로도 읽힌다. Claude는 같은 훅을 한 번만 실행하고 프로젝트 파일의 `bypassPermissions`는 무시한다. Codex는 상위 층 훅을 대체하지 않고 누적 로드하므로 이 레포 안에서는 알림·리마인더 훅이 두 층에서 등록된다. 설정을 바로 확인할 수 있는 이점이 있어 그대로 둔다.

## 3. 권한 통제 — 도구별 상세

| | Claude Code | Codex | Antigravity CLI |
|---|---|---|---|
| 모드 | `defaultMode: bypassPermissions` (사용자 settings에서만 유효 — 2.1.257부터 프로젝트 파일 값은 무시) | `approval_policy = "never"` + `sandbox_mode = "danger-full-access"` | `toolPermission: always-proceed`, `artifactReviewPolicy: always-proceed` |
| 기계 차단 | `permissions.deny` 49건 | Starlark `rules/default.rules` (`forbidden`) | `permissions.deny` 66건 |
| 차단 범위 | 파국형 + 넓은 재귀 삭제. 규칙의 `*`는 공백 포함 임의 문자열에 매칭되므로 `rm -rf /*`·`rm -rf ./*`는 절대경로·`./` 하위 `rm -rf` 전부에 걸린다(의도는 파국형이지만 구현은 이만큼 넓다) | 파일 삭제·Git 쓰기·`sudo`·`gh api`·`chmod`·`ln -sf`·`sed -i` 등 위험 명령 전반. 인자값·임의 위치 매칭은 불가(prefix_rule) | 파국형만. 토큰 단위 정확 일치·접두 매칭이며 글롭과 `regex:`는 동작하지 않아 `rm -rf /home*`·`dd of=/dev/sd*` 같은 규칙은 옮길 수 없다(`dd`·`fdisk`·`parted`·`shred`는 지침 통제) |
| 회귀 검증 | — (훅 은퇴로 케이스 아카이브) | `scripts/verify-policies.sh codex` — 실제 엔진 20건 | `scripts/verify-policies.sh agy` 정적 16건 + `scripts/agy-live-check.sh` 실측 6건 |

Codex 샌드박스를 끈 이유는 exec 샌드박스가 `/dev`를 tmpfs로 덮어 GPU 장치를 노출하지 않기 때문이다. 유일한 방어선이 Starlark 규칙이므로 `shell_environment_policy`로 시크릿 env 유출을 함께 막는다. Codex 훅 신뢰는 정의의 해시로 기록되며, 훅을 새로 만들거나 바꾸면 `/hooks`에서 검토·신뢰할 때까지 건너뛴다(시작 시 경고만, 자동 확인창 없음).

## 4. 훅 결정 기록

| 도구 | 결정 | 이유 |
|------|------|------|
| Claude | Bash 자동승인 훅(`auto-approve-readonly.sh`) 은퇴, `permissions.ask` 전면 해제 (v2.10) | 504줄 텍스트 매칭이 따옴표 속 문구("rm 금지" 등)를 명령으로 오인하는 오탐이 누적됐고, ask 규칙은 bypass 모드에서도 발동해(실측) 자율 흐름을 끊었다. 원본·회귀 케이스·기존 ask 목록은 `.archive/2026-07-18_hook-retirement/` |
| Claude | MCP 자동승인 훅(PreToolUse `mcp__.*`) 유지 | 의도된 정책 — 보안 리뷰에서 취약점으로 다루지 않는다 |
| Claude·Codex | compact 리마인더를 PostCompact가 아니라 SessionStart(`compact`)에 둠 (v2.21) | PostCompact는 `systemMessage`·stdout을 모델에 전달하지 않는다(Codex는 `compact.rs`에서 UI 경고 전용 확인) |
| Codex | 실패알림 훅(PostToolUse) 제거 (v2.0) | payload(`tool_response`)가 exit code 없는 포맷 문자열이고 `PostToolUseFailure` 이벤트도 없어(0.142.5·0.144.1 `shell.rs`·`protocol.rs` 확인) 실패를 일반적으로 판정할 수 없다. Codex가 exit_code를 노출하면 `.archive/2026-07-02_codex-dead-hook/`에서 복원 |
| Codex | PreToolUse 의도적 미설정 | `approval_policy = "never"` + Starlark가 이미 통제 |
| Antigravity | 훅 미사용 | 알림은 내장 `notifications: true`. 압축 후 이벤트가 없고 `PreInvocation`은 매 모델 호출마다 실행돼 리마인더 용도로 과하다. `~/.gemini/config/hooks.json`이 로드됨은 실측(`PreToolUse`·`PostToolUse`·`PreInvocation`·`PostInvocation`·`Stop`) |

## 5. 도구별 세부 사항

| | Claude Code | Codex | Antigravity |
|---|---|---|---|
| 커스텀 명령 | 스킬(`/이름`) — `commands/*.md`는 사용하지 않음 | 스킬(`$이름`·`/skills`) + `~/.codex/prompts/*.md`(`/prompts:이름`, 미사용) | 스킬(`/이름`, 헤드리스 `-p "/이름 …"`도 확장) |
| 에이전트 | `agents/*.md` 4개 | 없음 — AGENTS.md의 역할 트리거로 절차형 대응 | Subagents(`/agents`) — 정의 0개 |
| 지시 파일 설치 경로 | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/GEMINI.md`(CLI·IDE 공식 경로 하나. `config/GEMINI.md`까지 두면 이중 주입) |
| IDE 층 | — | — | `.antigravity/settings.json`·`hooks/mcp-config-guard.sh`는 추정치, 미검증 |
| 약관 | — | — | Antigravity 로그인 자격증명을 타사 클라이언트에서 재사용하는 접근은 공식 FAQ의 제한 대상. 공식 `agy` CLI를 다른 에이전트가 호출하는 구성의 적용 범위는 미확인 |

레퍼런스 검증 규칙은 상시 로드에서 온디맨드 스킬(`/reference-verification`)로 전환했고, work-principles에 호출 트리거 1줄만 남겼다(v2.12).

## 6. 은퇴·아카이브

| 항목 | 시점 | 위치 |
|------|------|------|
| Gemini CLI 층 | 2026-09-07 — Google이 2026-06-18부로 개인 계정 요청 처리를 중단하고 Antigravity CLI로 통합 | `.archive/2026-09-07_gemini-cli-retirement/` (훅·정책·에이전트 원본, 회귀 케이스 62건) |
| Claude Bash 자동승인 훅 + ask 81건 | 2026-07-18 | `.archive/2026-07-18_hook-retirement/` |
| Codex PostToolUse 실패알림 훅 | 2026-07-02 | `.archive/2026-07-02_codex-dead-hook/` |
| `/start` 커스텀 명령 → 공용 스킬 | 2026-09-07 | `.archive/2026-09-07_start-to-skill/` |
| 상시 로드 지침 감량 원본(393→250줄) | 2026-08-13 | `.archive/2026-08-13_rules-slimming/` |
| 구세대 모델 자료(Claude 5·GPT-5.6 미만) | v2.20 | `reference/archive/` |

모델·도구 조사 원문은 `reference/research/`(Opus 5·Fable 5.1·GPT-6 Astra·컨텍스트 엔지니어링·한국어 문체 등).
