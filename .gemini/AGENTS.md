# AGENTS.md — 크로스툴 공용 지침 (Antigravity / Cursor 등)

> **이 저장소는 모든 AI 도구(Claude Code · Codex CLI · Gemini CLI · Antigravity)에 동일 규칙을 적용합니다.**
> 전체 규칙은 `GEMINI.md`를 정본으로 사용하세요. 이 파일은 AGENTS.md convention(Antigravity·Cursor 등이 우선 참조)에 맞춰 동일 내용을 노출하는 진입점입니다.

## 우선순위

1. `GEMINI.md` (이 파일과 동일 디렉토리) — 모든 항목의 정본
2. `.claude/rules/*.md` (Claude Code 한정 보조 규칙)
3. 프로젝트별 `<repo>/CLAUDE.md` · `<repo>/agent-guide/*`

## Antigravity 전용 주의사항

- **Terminal Execution Policy**: `Off` 또는 `Auto` 사용. `Turbo`(YOLO) 절대 금지 — `chmod -R 777` 폭주 사례 보고됨
- **Non-Workspace File Access**: 비활성 유지. 워크스페이스 외부 파일 접근 시 사용자에게 명시 확인
- **Browser Allowlist**: `webhook.site` / `*.webhook.site` / `requestbin.com` 등 데이터 유출 채널 사용 금지 (기본값에 포함되어 있어 수동 제거 필요)
- **MCP Tool Approval**: `manual` 유지. 글로벌 `~/.gemini/antigravity/mcp_config.json`과 워크스페이스 `.agent/mcp_config.json` 변경 시 반드시 사용자 승인
- **Subagents**: 병렬 실행 시 동일한 안전 정책 적용. 서브에이전트가 위험 명령을 시도하면 `before_tool_call` 훅이 동일하게 차단

## 4-tool 안전 정책 요약

`GEMINI.md` §작업원칙 §금지명령 참조. 11 카테고리(FILE_DELETE / SYSTEM / GIT_WRITE / GIT_STATE / GH_CLI / DOCKER_DELETE / INPLACE / LINK_FORCE / PERMISSION / SHELL_BYPASS / SCRIPT_INJECTION) 모두 Antigravity의 `permissions`(대부분 `ask`, 파국적 명령만 `deny`) + `before_tool_call` 훅으로 강제됩니다 (`.antigravity/settings.json`).
