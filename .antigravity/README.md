# .antigravity/ — Google Antigravity 안전 정책

Claude Code / Codex CLI / Gemini CLI와 동일한 12 카테고리 안전 정책을 Antigravity에 통합합니다.

## 구조

```
.antigravity/
├── README.md                       # 이 문서
├── settings.json                   # 워크스페이스 권한(allow/ask/deny) + agentSettings + hooks
├── hooks/
│   ├── auto-approve-readonly.sh    # .claude/hooks/ 심볼릭 링크 (단일 소스)
│   └── mcp-config-guard.sh         # .agent/mcp_config.json 백도어 차단
└── policies/                       # (예약) 추가 정책 문서
```

## 검증 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| `permissions.{allow,ask,deny}` JSON 구조 | 🟢 **검증** | Claude Code와 동형 (secondary 소스) |
| `Bash(<pattern>)` 매처 문법 | 🟢 **검증** | 동일 |
| 평가 순서 deny → ask → allow | 🟢 **검증** | 동일 |
| `agentSettings.terminalExecutionPolicy` 키 명 | 🟡 **추정** | GUI 라벨 기준 추정. 실제 키는 설치 후 diff 필요 |
| `hooks.before_tool_call` 이벤트명 | 🟡 **추정** | secondary 소스 기준. 공식 docs SPA로 직접 확인 미완료 |
| Hook 입출력 JSON 포맷 | 🟡 **추정** | Claude Code PreToolUse 포맷 재사용 |
| `Read()`/`Write()` action 지원 | 🟡 **추정** | secondary 소스에서만 언급 |

## 실제 설치 후 검증 절차

1. macOS Antigravity IDE 설치:
   ```bash
   # agy CLI도 함께 설치 (Linux는 IDE 미지원, CLI만)
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   ```
2. 글로벌 settings.json 위치 확인:
   - macOS: `~/Library/Application Support/Antigravity/User/settings.json`
   - Windows: `%APPDATA%/Antigravity IDE/User/settings.json`
3. GUI에서 안전 토글 1개씩 변경 → `settings.json` diff 확인 → **정확한 키 이름 역공학**
4. 본 `.antigravity/settings.json`의 `_doc` 필드와 `agentSettings` 키 명을 실측 값으로 교체
5. `~/.antigravity/` (사용자 글로벌)에 본 디렉토리를 심볼릭 링크 (install.sh가 자동 처리)

## 알려진 보안 이슈 대응

| 이슈 | 출처 | 본 정책 대응 |
|------|------|---------------|
| `.agent/mcp_config.json` 영속 백도어 | Mindgard | `hooks/mcp-config-guard.sh`로 변경 시 ask 발동 |
| `webhook.site` 기본 Allowlist | agentpedia | `browserDomainDenylist`로 강제 차단 |
| Linux sandbox 미지원 (symlink 우회 가능) | MaanVader | OS-레벨 격리 불가 → 정책 의존도 100%, `permissions.deny`로 보완 |
| Turbo mode `chmod -R 777` 폭주 | agentpedia | `terminalExecutionPolicy: "off"` 강제 |
| 자격증명 탈취 (.env / SSH 키) | Embrace The Red | `permissions.deny`에 `Read(./.env)`, `Read(./**/id_rsa*)` 추가 |

## 4-tool 정합성

| 카테고리 | Claude Code | Codex CLI | Gemini CLI | Antigravity |
|----------|:----:|:----:|:----:|:----:|
| FILE_DELETE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| SYSTEM | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| GIT_WRITE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| GIT_STATE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| GH_CLI | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| DOCKER_DELETE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| INPLACE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| LINK_FORCE | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| PERMISSION | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| PROCESS | hook ask | Starlark forbidden | toml ask | hook ask + permissions.ask |
| SHELL_BYPASS | hook ask | (단일토큰 한계) | toml ask | hook ask |
| SCRIPT_INJECTION | hook ask | (단일토큰 한계) | toml ask | hook ask |

`.claude/hooks/auto-approve-readonly.sh`를 그대로 재사용하므로 12 카테고리 분류와 사유 메시지가 4-tool 전체에서 정확히 일치합니다.
