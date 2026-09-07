# .antigravity/ — Google Antigravity 안전 정책

Claude Code / Codex CLI와 동일한 11 카테고리 안전 정책을 Antigravity에 통합합니다. Antigravity IDE와 Antigravity CLI(`agy`)가 대상입니다.

## 구조

```
.antigravity/
├── README.md                       # 이 문서
├── GEMINI.md                       # Antigravity 작업 지침 (전역, 정본) — ~/.gemini/GEMINI.md로 링크
├── AGENTS.md                       # 크로스툴 convention 진입점 → GEMINI.md 참조
├── settings.json                   # 워크스페이스 권한(allow/ask/deny) + agentSettings + hooks
├── hooks/
│   └── mcp-config-guard.sh         # .agent/mcp_config.json 백도어 차단
├── global_workflows/               # Antigravity IDE 글로벌 워크플로우 (링크 대상)
└── policies/                       # (예약) 추가 정책 문서
```

> `GEMINI.md`·`AGENTS.md`·`global_workflows/`는 Gemini CLI 층 은퇴(2026-09-07)로 `.gemini/`에서 이관됐습니다. `agy`가 `~/.gemini` 설정 트리를 그대로 물려받으므로 설치 경로는 그대로 둡니다.

## 검증 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| `permissions.{allow,ask,deny}` JSON 구조 | 🟢 **검증** | allow/ask/deny 3단 일치 (2026-07-13 2차 출처 교차) |
| 평가 순서 deny → ask → allow | 🟢 **검증** | 우선순위 Deny > Ask > Allow 일치 |
| `Bash(<pattern>)` 매처 문법 | 🔴 **오류** | 2026-07-13 검증: 실제 권한 매처는 `command(...)` 형태. 재작성 대상 |
| `Read()`/`Write()` action 지원 | 🔴 **오류** | 실제는 `read_file(...)`/`write_file(...)` 형태. 재작성 대상 |
| `hooks.before_tool_call` 이벤트명 | 🔴 **오류** | 실제 이벤트는 PreToolUse/PostToolUse이고 위치도 settings.json이 아닌 별도 hooks.json. 재작성 대상 |
| 훅 matcher 셸 도구명 | 🟢 **검증** | `run_command` — 2차 출처 2건 모두 일치(`run_shell_command` 아님) |
| 글로벌 hooks.json 경로 | 🟡 **미확정** | 출처 간 갈림: `~/.gemini/antigravity-cli/hooks.json`(Kanshi) vs `~/.gemini/config/hooks.json`(검색 요약). 워크스페이스 `<project>/.agents/hooks.json`은 출처 일치. 실설치 후 확정 |
| Antigravity Linux 지원 | 🟢 **검증** | Linux 공식 지원(.deb/.tar.gz/apt·rpm, glibc≥2.28). 과거 "IDE Linux 미지원" 기술은 오류였음 |
| Hook 입출력 JSON 포맷 | 🟡 **추정** | Claude Code PreToolUse 포맷 재사용 |
| `agentSettings.terminalExecutionPolicy` 키 명 | 🟡 **추정** | GUI 라벨 기준 추정. 실제 키는 설치 후 diff 필요 |
| CLI(`agy`) 설정 파일 경로 | 🟢 **검증** | `~/.gemini/antigravity-cli/settings.json` — 공식 문서(Permissions) |
| CLI 권한 문법 | 🟢 **검증** | `action(target)` 형식, 액션은 `read_file`·`write_file`·`read_url`·`execute_url`·`command`·`unsandboxed`·`mcp` 7종. 평가 우선순위 Deny > Ask > Allow |
| CLI 플러그인 구조 | 🟢 **검증** | `~/.gemini/antigravity-cli/plugins/<이름>/`에 `skills/`·`rules/`·`agents/`·`hooks.json` |
| 본 settings.json ↔ CLI 규격 정합 | 🔴 **불일치** | 현 파일은 Claude 문법(`Bash(...)`·`Read(...)`)이라 CLI에 그대로 쓸 수 없다. `agy` 설치·로그인 후 실측 기반으로 재작성 |

## 자동 설치 (수동 단계 없음)

`./install.sh` 한 번 실행으로 OS 감지 후 자동 적용:

| OS | 자동 동기화 경로 | 방식 |
|----|-----------------|------|
| macOS | `~/Library/Application Support/Antigravity/User/settings.json` | `safe_merge_json` (jq deep merge, 런타임 필드 보존) |
| Windows | `%APPDATA%/Antigravity IDE/User/settings.json` | 동일 |
| Linux | IDE는 공식 지원되나 settings 동기화 경로(추정 `~/.config/Antigravity/User/settings.json`) 미검증 → 현재 `~/.antigravity`, `~/.gemini/antigravity-cli/skills` (agy CLI 참조)만 활성화 | symlink |

글로벌 User settings에 `permissions`를 두면 모든 워크스페이스에 자동 상속(VS Code 패턴).
워크스페이스별 `.antigravity/settings.json` 복사 불필요.

## 키 이름 검증 (선택적, 사후)

본 settings.json의 `agentSettings.*` 키 명은 GUI 라벨 기반 추정입니다. 실제 IDE 토글과
정확히 매칭되는지 검증하려면:

1. Antigravity 설치 후 GUI에서 안전 토글 1개씩 변경
2. `~/Library/Application Support/Antigravity/User/settings.json` diff 확인
3. 본 `.antigravity/settings.json`의 `agentSettings` 키 명을 실측 값으로 교체 후 commit

> 키 이름이 틀려도 IDE는 silent ignore하므로 위험은 없음. `permissions`만 정확히 작동하면 권한 정책은 보장됨.

## 알려진 보안 이슈 대응

| 이슈 | 출처 | 본 정책 대응 |
|------|------|---------------|
| `.agent/mcp_config.json` 영속 백도어 | Mindgard | `hooks/mcp-config-guard.sh`로 변경 시 ask 발동 |
| `webhook.site` 기본 Allowlist | agentpedia | `browserDomainDenylist`로 강제 차단 |
| Linux sandbox 미지원 (symlink 우회 가능) | MaanVader | OS-레벨 격리 불가 → 정책 의존도 100%, `permissions.deny`로 보완 |
| Turbo mode `chmod -R 777` 폭주 | agentpedia | `terminalExecutionPolicy: "off"` 강제 |
| 자격증명 탈취 (.env / SSH 키) | Embrace The Red | `permissions.deny`에 `Read(./.env)`, `Read(./**/id_rsa*)` 추가 |

## 3-tool 정합성

| 카테고리 | Claude Code | Codex CLI | Antigravity |
|----------|:----:|:----:|:----:|
| FILE_DELETE | 지침 (+deny 파국형) | Starlark forbidden | permissions.ask |
| SYSTEM | 지침 (+deny 파국형) | Starlark forbidden | permissions.ask |
| GIT_WRITE | 지침 (rules) | Starlark forbidden | permissions.ask |
| GIT_STATE | allow | Starlark forbidden | permissions.ask |
| GH_CLI | 지침 (rules) | Starlark forbidden | permissions.ask |
| DOCKER_DELETE | 지침 (rules) | Starlark forbidden | permissions.ask |
| INPLACE | 지침 (rules) | Starlark forbidden | permissions.ask |
| LINK_FORCE | 지침 (rules) | Starlark forbidden | permissions.ask |
| PERMISSION | 지침 (rules) | Starlark forbidden | permissions.ask |
| SHELL_BYPASS | 지침 (rules) | (단일토큰 한계) | 지침 (rules) |
| SCRIPT_INJECTION | 지침 (rules) | (단일토큰 한계) | 지침 (rules) |

> Gemini CLI 열은 2026-09-07 은퇴로 제거했다. 정책 원본과 회귀 케이스 62건은 `.archive/2026-09-07_gemini-cli-retirement/`에 있다.

Bash 자동승인 훅(`auto-approve-readonly.sh`)은 은퇴했고 Claude Code는 `permissions.ask`도 전면 해제 — 확인 프롬프트 없이 지침(work-principles)이 위험 명령의 자율 사용을 금지하고, 파국형만 `permissions.deny`가 차단한다. Antigravity는 자체 settings의 ask/deny 규칙을 유지한다. 훅 원본·기존 ask 목록은 `.archive/2026-07-18_hook-retirement/` 참조. (PROCESS는 v2.2에서 allow로 해제 — 재시작 가능한 조작)
