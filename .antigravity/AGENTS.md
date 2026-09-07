# AGENTS.md — 크로스툴 공용 지침 (Antigravity / Cursor 등)

> **이 저장소는 모든 AI 도구(Claude Code · Codex CLI · Antigravity)에 동일 규칙을 적용합니다.**
> 전체 규칙은 `GEMINI.md`를 정본으로 사용하세요. 이 파일은 AGENTS.md convention(Antigravity·Cursor 등이 우선 참조)에 맞춰 동일 내용을 노출하는 진입점입니다.

## 우선순위

1. `GEMINI.md` (이 파일과 동일 디렉토리) — 모든 항목의 정본
2. 프로젝트별 `<repo>/CLAUDE.md` · `<repo>/AGENTS.md` · `<repo>/agent-guide/*`

## Antigravity CLI (`agy`)

- 권한은 `toolPermission: always-proceed` — 모든 도구가 확인 프롬프트 없이 실행된다. 워크스페이스 밖 파일 접근도 막히지 않는다. 위험 명령의 통제는 `GEMINI.md` §위험 명령 지침이 담당하고, 파국형 명령만 `permissions.deny`가 차단한다
- MCP 서버 추가·변경(`~/.gemini/config/mcp_config.json`, `agy mcp add`)은 사용자가 명시적으로 요청할 때만
- 서브에이전트도 같은 지침을 따른다

## Antigravity IDE 전용 (설정 층 미검증)

- **Terminal Execution Policy**: `Turbo` 사용 금지 — `chmod -R 777` 폭주 사례 보고됨
- **Browser Allowlist**: `webhook.site` / `*.webhook.site` / `requestbin.com` 등 데이터 유출 채널 사용 금지 (기본값에 포함되어 있어 수동 제거 필요)
- **MCP Tool Approval**: `manual` 유지. 글로벌 `~/.gemini/antigravity/mcp_config.json`과 워크스페이스 `.agent/mcp_config.json` 변경 시 반드시 사용자 승인
