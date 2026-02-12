# dotfiles

Claude Code / Codex 전역 설정을 관리하는 레포.

여러 프로젝트, 여러 PC/서버에서 **동일한 AI 에이전트 설정**을 공유한다.

## 구조

```
dotfiles/
├── .claude/
│   ├── CLAUDE.md          # Claude Code 전역 진입점 (~/.claude/CLAUDE.md)
│   ├── rules/             # 코딩/보안/통신/에이전트 규칙 (4개)
│   ├── agents/            # 서브에이전트 정의 (4개)
│   ├── commands/          # 슬래시 커맨드 (/start)
│   └── skills/            # 재사용 스킬 (13개) ← 원본
├── .codex/
│   ├── AGENTS.md          # Codex 전역 지침 (~/.codex/AGENTS.md)
│   └── skills → ../.claude/skills   # 기존 호환
└── .agents/
    └── skills → ../.claude/skills   # 새 표준 경로 (Open Agent Skills)
```

## 전역 vs 프로젝트별

| 범위 | 파일 | 관리 위치 |
|------|------|----------|
| **전역** | `.claude/` (CLAUDE.md 포함), `.codex/` (AGENTS.md 포함) | 이 레포 (dotfiles) |
| **프로젝트별** | `agent-guide/GUIDE.md`, `PROJECT.md`, `SESSION.md` | 각 프로젝트 레포 |

## 설치

```bash
git clone https://github.com/mulgae-life/dotfiles.git ~/dotfiles
```
```bash
~/dotfiles/install.sh
```

`--dry-run` 옵션으로 변경 사항을 미리 확인할 수 있습니다:

```bash
~/dotfiles/install.sh --dry-run
```

스크립트가 생성하는 심볼릭 링크:

| 링크 | → 원본 | 용도 |
|------|--------|------|
| `~/.claude/CLAUDE.md` | `~/dotfiles/.claude/CLAUDE.md` | Claude Code 전역 지침 |
| `~/.claude/agents/` | `~/dotfiles/.claude/agents/` | 서브에이전트 정의 |
| `~/.claude/commands/` | `~/dotfiles/.claude/commands/` | 슬래시 커맨드 |
| `~/.claude/rules/` | `~/dotfiles/.claude/rules/` | 코딩/보안/통신 규칙 |
| `~/.claude/skills/` | `~/dotfiles/.claude/skills/` | 재사용 스킬 (원본) |
| `~/.codex/AGENTS.md` | `~/dotfiles/.codex/AGENTS.md` | Codex 전역 지침 |
| `~/.agents/skills/` | `~/.claude/skills/` | Open Agent Skills 표준 경로 |

Claude Code / Codex 런타임 데이터(`projects/`, `settings.json` 등)는 건드리지 않습니다.

### 새 프로젝트 초기화

프로젝트에서 기획 대화 후 `/init-project`을 실행하면 `agent-guide/` 3종 파일이 자동 생성된다.

## 포함된 스킬

| 스킬 | 용도 |
|------|------|
| code-review | 심각도 등급별 코드 리뷰 |
| code-simplifier | 코드 명확성/유지보수성 개선 |
| code-verify | 작업 후 점검 |
| feedback-analysis | 피드백 분석 |
| frontend-design | 프론트엔드 UI 제작 |
| init-project | 새 프로젝트 agent-guide 자동 생성 |
| llm-api-guide | OpenAI/Anthropic API 연동 |
| postgres-best-practices | Postgres 최적화 |
| react-best-practices | React/Next.js 성능 최적화 |
| skill-creator | 새 스킬 생성 가이드 |
| update-docs | 프로젝트 문서 업데이트 |
| web-design-guidelines | UI/UX 접근성 리뷰 |
| writing-prompts | LLM 프롬프트 작성 |
