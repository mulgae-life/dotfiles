# 🛠 dotfiles

AI 코딩 에이전트([Claude Code](https://docs.anthropic.com/en/docs/claude-code) / [Codex](https://github.com/openai/codex) / [Gemini CLI](https://github.com/google-gemini/gemini-cli))의 전역 설정을 관리하는 레포.

한 번 설치하면 어떤 프로젝트에서든 동일한 **규칙 · 에이전트 · 스킬 · 훅**이 자동 적용된다.

## 🔄 어떻게 동작하나?

```
설치 (심볼릭 링크 + 일부 복사)
  ↓
세션 시작 시 자동 로드
  ├── rules/         8개 규칙이 항상 적용 (코딩 스타일, 보안, 한국어 응답 등)
  ├── agents/        조건 충족 시 서브에이전트가 자동 위임 (빌드 에러, 보안 등)
  ├── hooks/         Bash 명령어 자동 승인, 알림, compact 리마인더
  ├── settings.json  권한, 언어, 모델 등 전역 설정 (복사)
  └── config.toml    Codex 모델, 커뮤니케이션 규칙 (복사)
  ↓
사용자가 필요할 때 호출
  └── skills/        /code-review, /writing-prompts 등 17개 전문 스킬
```

## 📦 설치

```bash
git clone https://github.com/mulgae-life/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`--dry-run`으로 변경 사항을 미리 확인할 수 있다:

```bash
~/dotfiles/install.sh --dry-run
```

설치 스크립트는 `~/dotfiles/` → `~/` 로 심볼릭 링크를 생성한다. 단, 도구가 런타임에 수정하는 파일(`settings.json`, `config.toml`)은 복사로 설치하여 레포 원본을 보호한다. 런타임 데이터(`projects/` 등)는 건드리지 않는다. `jq`가 없으면 자동 설치를 시도한다.

### 도구별 설정 구조

| | Claude Code | Codex | Gemini CLI |
|---|---|---|---|
| **지시 파일** | `CLAUDE.md` + `rules/*.md` | `AGENTS.md` + `config.toml` | `GEMINI.md` (인라인) |
| **설정** | `settings.json` (복사) | `config.toml` (복사) | `settings.json` (복사) |
| **권한** | hooks + permissions | `approval_policy` + `rules/` | `policies/*.toml` (Policy Engine) |
| **에이전트** | `agents/*.md` | 없음 (수동) | `agents/*.md` (YAML frontmatter) |
| **훅** | `PreToolUse`, `Notification` | 없음 | `BeforeTool`, `Notification` 등 11종 |
| **커스텀 명령** | 스킬로 대체 | 없음 | `commands/*.toml` |
| **기본 모델** | Claude Opus | GPT-5.4 | Gemini 3.1 Pro |
| **스킬** | `.claude/skills/` | 심볼릭 링크 | 심볼릭 링크 |

## 🚀 사용법

설치 후 별도 설정 없이 바로 사용할 수 있다.

### ⚡ 자동으로 일어나는 것

| 기능 | 설명 |
|------|------|
| 규칙 적용 | 코딩 스타일, 보안, 한국어 응답 등 `rules/` 규칙이 매 세션 자동 적용 |
| 명령어 자동 승인 | 위험한 명령(`rm`, `git push` 등)만 확인 요청, 나머지는 자동 승인 → 장기 작업이 중단 없이 진행 |
| 에이전트 위임 | 빌드 실패 → `build-resolver`, 보안 민감 코드 → `security-reviewer` 등 자동 위임 |
| 데스크톱 알림 | Claude가 입력 대기 중일 때 `notify-send`로 알림 |
| compact 리마인더 | 긴 세션에서 컨텍스트 압축 후 핵심 규칙(한국어, 변경 이유 설명 등) 자동 재주입 |

### 🎯 사용자가 호출하는 것

| 명령 | 설명 |
|------|------|
| `시작` | 프로젝트 파악 후 현재 상태 요약 |
| `/init-project` | 새 프로젝트에 `agent-guide/` 3종 파일 자동 생성 |
| `/code-review` | 심층 코드 리뷰 리포트 |
| `/writing-prompts` | LLM 프롬프트 작성 |
| ... | 아래 스킬 목록 참고 |

## 🧩 구성요소

### 📏 Rules (8개) — 매 세션 자동 적용

| 파일 | 역할 |
|------|------|
| `coding-style.md` | 코딩 스타일, 에러 처리, 리소스 관리 |
| `security.md` | 시크릿 관리, 입력 검증, 취약점 방지 |
| `architecture.md` | 파일 구조, 단일 역할, 의존성 방향 |
| `communication.md` | 한국어 응답, 변경 이유 설명, 용어 병기, 이모지 활용 |
| `context-management.md` | 컨텍스트 절약, 스크래치패드, 메모리 계층 |
| `work-principles.md` | 작업 원칙 (정확성 우선, 리소스 제약 추측 금지 등) |
| `agents.md` | 에이전트 자동 위임 조건과 우선순위 |
| `reference-verification.md` | 논문/레퍼런스 인용 시 원문 검증 의무화 |

### 🤖 Agents (4개) — 조건 충족 시 자동 위임

| 에이전트 | 트리거 |
|----------|--------|
| `build-resolver` | 빌드/타입 에러 발생 시 |
| `security-reviewer` | 인증/인가, API, 시크릿 관련 코드 작성 시 |
| `planner` | 파일 3개 이상 수정 예상되는 복잡한 작업 |
| `verifier` | 작업 완료 후 자동 점검 |

### 🪝 Hooks — 이벤트 기반 자동 실행

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `auto-approve-readonly.sh` | PreToolUse (Bash) | 위험 명령만 차단, 나머지 자동 승인 |
| Notification | 알림 발생 시 | `notify-send`로 데스크톱 알림 |
| SessionStart (compact) | 컨텍스트 압축 후 | 핵심 규칙 리마인더 재주입 |

### ⚙️ Skills (18개) — `/skill-name`으로 호출

**코드 품질**

| 스킬 | 용도 |
|------|------|
| `/code-review` | 심각도 등급별 심층 코드 리뷰 |
| `/work-verify` | 작업 후 빠른 점검 (코드/문서/리포트) |
| `/work-plan` | Phase별 코드 예시 포함 심층 작업 계획서 |
| `/code-simplifier` | 코드 명확성/유지보수성 개선 |
| `/feedback-analysis` | 사용자 피드백 분석 및 우선순위 정리 |

**프론트엔드**

| 스킬 | 용도 |
|------|------|
| `/frontend-design` | 코드 기반 프로덕션 UI 제작 |
| `/stitch-design` | Google Stitch MCP 기반 AI UI 디자인 (7개 서브스킬 포함) |
| `/react-best-practices` | React/Next.js 성능 최적화 |
| `/web-design-guidelines` | 웹 인터페이스 가이드라인 준수 리뷰 |

**백엔드/데이터**

| 스킬 | 용도 |
|------|------|
| `/postgres-best-practices` | Postgres 쿼리/스키마 최적화 |
| `/llm-api-guide` | OpenAI/Anthropic API 연동 |
| `/langchain-guide` | LangChain/LangGraph 에이전트/워크플로우 |

**프롬프트/문서/협업**

| 스킬 | 용도 |
|------|------|
| `/writing-prompts` | LLM 프롬프트 작성 |
| `/update-docs` | 프로젝트 문서 업데이트 |
| `/recursive-discussion` | Claude↔Codex 왕복 토론으로 결과물 개선 |

**프로젝트 관리**

| 스킬 | 용도 |
|------|------|
| `/start` | 세션 시작 시 프로젝트 파악/상태 요약 |
| `/init-project` | 새 프로젝트 agent-guide 자동 생성 |
| `/skill-creator` | 새 스킬 생성 가이드 |

## 🌐 전역 vs 프로젝트별

| 범위 | 내용 | 관리 위치 |
|------|------|----------|
| **전역** (이 레포) | rules, agents, skills, hooks, settings | `~/dotfiles/` → `~/` 심볼릭 링크 (일부 복사) |
| **프로젝트별** | `agent-guide/GUIDE.md`, `PROJECT.md`, `SESSION.md` | 각 프로젝트 레포 |

## 📁 디렉토리 구조

```
dotfiles/
├── .claude/
│   ├── CLAUDE.md              # 전역 진입점
│   ├── rules/                 # 규칙 (8개)
│   ├── agents/                # 서브에이전트 (4개)
│   ├── commands/              # 슬래시 커맨드
│   ├── hooks/                 # 이벤트 훅
│   ├── skills/                # 스킬 (18개)
│   └── settings.json          # 전역 설정
├── .mcp.json                    # MCP 서버 설정 (gitignored, API 키 포함)
├── .codex/
│   ├── AGENTS.md              # Codex 지침
│   ├── config.toml            # Codex 설정 (모델, 커뮤니케이션 규칙)
│   ├── rules/                 # 실행 정책 (위험 명령어 차단)
│   └── skills → ../.claude/skills
├── .gemini/
│   ├── GEMINI.md              # Gemini CLI 지침 (전역)
│   ├── settings.json          # Gemini CLI 설정 (모델, 훅)
│   ├── agents/                # 서브에이전트 (4개)
│   ├── commands/              # 커스텀 슬래시 명령
│   ├── hooks/                 # 이벤트 훅 (알림)
│   ├── policies/              # 안전 정책 (명령 허용/차단)
│   └── skills → ../.claude/skills
├── .agents/
│   └── skills → ../.claude/skills
└── reference/                 # 레퍼런스 자료
    ├── Agent-Coding-Guide/    # 에이전트 코딩 가이드 (팀 교육용)
    ├── agent-teams-guide/
    ├── claude-prompt-guide/
    ├── langchain-langgraph-guide/
    ├── openai-api-guide/
    ├── openai-prompt-guide/
    ├── skills-guide/
    └── stitch-guide/          # Google Stitch MCP 참조 문서
```
