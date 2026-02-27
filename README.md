# dotfiles

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) / Codex / Antigravity 전역 설정을 관리하는 레포.

여러 프로젝트, 여러 PC/서버에서 **동일한 AI 에이전트 설정**을 공유한다.
한 번 설치하면 어떤 프로젝트에서든 동일한 규칙·에이전트·스킬이 자동 적용된다.

## 구조

```
dotfiles/
├── .claude/
│   ├── CLAUDE.md          # Claude Code 전역 진입점 (~/.claude/CLAUDE.md)
│   ├── rules/             # 코딩/보안/구조/통신/에이전트/컨텍스트 규칙 (6개)
│   ├── agents/            # 서브에이전트 정의 (4개)
│   ├── commands/          # 슬래시 커맨드 (/start)
│   └── skills/            # 재사용 스킬 (13개) ← 원본
├── .codex/
│   ├── AGENTS.md          # Codex 전역 지침 (~/.codex/AGENTS.md)
│   └── skills → ../.claude/skills   # 기존 호환
├── .gemini/
│   ├── GEMINI.md          # Antigravity 전역 지침 (~/.gemini/GEMINI.md)
│   └── global_workflows/  # Antigravity 전역 워크플로우
└── .agents/
    └── skills → ../.claude/skills   # 새 표준 경로 (Open Agent Skills)
```

### 구성요소

| 디렉토리 | 역할 | 로드 방식 |
|----------|------|----------|
| `rules/` | 코딩 스타일·보안·커뮤니케이션 등 **항상 적용되는 규칙** | `alwaysApply: true` — 매 세션 자동 로드 |
| `agents/` | 빌드 에러·보안 점검 등 **특정 상황에서 자동 위임**되는 서브에이전트 | 조건 충족 시 자동 위임 (`rules/agents.md`에 정의) |
| `skills/` | 코드 리뷰·프롬프트 작성 등 **슬래시 커맨드로 호출**하는 전문 가이드 | `/skill-name`으로 수동 호출 |
| `commands/` | 세션 시작 등 **사용자 정의 슬래시 커맨드** | `/command-name`으로 수동 호출 |

## 전역 vs 프로젝트별

| 범위 | 파일 | 관리 위치 |
|------|------|----------|
| **전역** | `.claude/`, `.codex/`, `.gemini/` | 이 레포 (dotfiles) |
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
| `~/.gemini/GEMINI.md` | `~/dotfiles/.gemini/GEMINI.md` | Antigravity 전역 지침 |
| `~/.gemini/antigravity/global_workflows` | `~/dotfiles/.gemini/global_workflows` | Antigravity 전역 워크플로우 |

Claude Code / Codex / Antigravity 런타임 데이터(`projects/`, `settings.json` 등)는 건드리지 않습니다.

## 사용법

설치 후 별도 설정 없이 바로 사용할 수 있다.

**세션 시작:** 프로젝트 디렉토리에서 Claude Code를 열고 `시작`이라고 입력하면 프로젝트 파악 후 현재 상태를 요약한다.

**자동 적용:** `rules/`의 규칙(코딩 스타일, 보안, 한국어 응답 등)은 모든 세션에 자동 적용된다.

**에이전트 위임:** 빌드 실패, 보안 민감 코드 등 특정 조건에서 서브에이전트가 자동으로 작업을 넘겨받는다.

**스킬 호출:** 심층 코드 리뷰(`/code-review`), 프롬프트 작성(`/writing-prompts`) 등 전문 작업은 슬래시 커맨드로 호출한다.

**새 프로젝트 초기화:** 프로젝트에서 기획 대화 후 `/init-project`을 실행하면 `agent-guide/` 3종 파일(`GUIDE.md`, `PROJECT.md`, `SESSION.md`)이 자동 생성된다.

## 포함된 스킬

| 스킬 | 호출 | 용도 |
|------|------|------|
| code-review | `/code-review` | 심각도 등급별 코드 리뷰 |
| code-simplifier | `/code-simplifier` | 코드 명확성/유지보수성 개선 |
| code-verify | `/code-verify` | 작업 후 점검 |
| feedback-analysis | `/feedback-analysis` | 피드백 분석 |
| frontend-design | `/frontend-design` | 프론트엔드 UI 제작 |
| init-project | `/init-project` | 새 프로젝트 agent-guide 자동 생성 |
| llm-api-guide | `/llm-api-guide` | OpenAI/Anthropic API 연동 |
| postgres-best-practices | `/postgres-best-practices` | Postgres 최적화 |
| react-best-practices | `/react-best-practices` | React/Next.js 성능 최적화 |
| skill-creator | `/skill-creator` | 새 스킬 생성 가이드 |
| update-docs | `/update-docs` | 프로젝트 문서 업데이트 |
| web-design-guidelines | `/web-design-guidelines` | UI/UX 접근성 리뷰 |
| writing-prompts | `/writing-prompts` | LLM 프롬프트 작성 |
