# 🛠 dotfiles

AI 코딩 에이전트([Claude Code](https://docs.anthropic.com/en/docs/claude-code) / [Codex](https://github.com/openai/codex) / [Gemini CLI](https://github.com/google-gemini/gemini-cli) / [Antigravity](https://antigravity.google))의 전역 설정을 관리하는 레포.

한 번 설치하면 어떤 프로젝트에서든 동일한 **규칙 · 에이전트 · 스킬 · 훅**이 자동 적용된다.

> **🎯 설계 원칙 — 자율성 우선, 최소 차단**: 모든 작업을 확인 프롬프트 없이 실행해 장기 작업이 중단되지 않게 한다(Claude Code는 ask 계층 전면 해제). 위험 명령(`rm` · `git push` · `sudo` 등)의 통제는 지침(rules)이 담당하고 — 자율 작업 중 사용 금지, 사용자 요청 시에만 — 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작, 크론탭 삭제)과 넓은 재귀 삭제 패턴(절대경로·`./` 하위 `rm -rf`)만 `permissions.deny`가 프롬프트 없이 차단한다.

## 🔄 어떻게 동작하나?

```
설치 (심볼릭 링크 + 일부 복사)
  ↓
세션 시작 시 자동 로드
  ├── rules/         7개 규칙이 항상 적용 (코딩 스타일, 보안, 한국어 응답 등)
  ├── agents/        조건 충족 시 서브에이전트가 자동 위임 (빌드 에러, 보안 등)
  ├── hooks/         실패 가이던스, 알림, compact 리마인더
  ├── settings.json  권한, 언어, 모델 등 전역 설정 (복사)
  └── config.toml    Codex 모델, 커뮤니케이션 규칙 (복사)
  ↓
사용자가 필요할 때 호출
  └── skills/        /code-review, /writing-prompts 등 20개 전문 스킬
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

설치 스크립트는 `~/dotfiles/` → `~/` 로 심볼릭 링크를 생성한다. 단, 도구가 런타임에 수정하는 파일(`.claude/settings.json`, `.codex/config.toml`)은 복사로 설치하여 레포 원본을 보호한다. 예외로 **인증을 설정 파일에 인라인 저장하는 Gemini `settings.json`과 IDE 글로벌 settings(Antigravity)는 인증·외부 설정 보존을 위해 deep merge**한다(Claude는 인증이 `.credentials.json` 별도라 복사). 런타임 데이터(`projects/` 등)는 건드리지 않는다. `jq`가 없으면 자동 설치를 시도한다.

### 도구별 설정 구조

| | Claude Code | Codex | Gemini CLI | Antigravity |
|---|---|---|---|---|
| **지시 파일** | `CLAUDE.md` + `rules/*.md` | `AGENTS.md` + `config.toml` | `GEMINI.md` (인라인) | `AGENTS.md` + `GEMINI.md` (공유) |
| **설정** | `settings.json` (복사) | `config.toml` (복사) | `settings.json` (merge·인증 보존) | `.antigravity/settings.json` (워크스페이스) |
| **권한** | hooks + permissions | `approval_policy` + `rules/` | `policies/*.toml` (Policy Engine) | `permissions.{allow,ask,deny}` + hooks |
| **에이전트** | `agents/*.md` | 없음 (수동) | `agents/*.md` (YAML frontmatter) | Subagents (병렬 실행) |
| **훅** | `PreToolUse`, `PostToolUseFailure`, `Notification`, `SessionStart` | `Stop`, `SessionStart` (v0.129+) | `BeforeTool`, `Notification` 등 11종 | `PreToolUse`/`PostToolUse` — 별도 hooks.json (현 초안은 재작성 대상, `.antigravity/README.md` 검증 상태 참조) |
| **커스텀 명령** | 스킬로 대체 | 없음 | `commands/*.toml` | Plugins (구 Extensions) |
| **기본 모델** | Claude Opus | 권장 기본 추종 (0.153.4부터 GPT-6 Astra, 미고정) | Gemini 3.1 Pro | Gemini 3.1 Pro / 3 Flash |
| **CLI 버전 (검증 기준)** | 2.1.258 | 0.153.4 | 0.38.1 | IDE 2.1.x / `agy` |
| **스킬** | `.claude/skills/` | 심볼릭 링크 | 심볼릭 링크 | 심볼릭 링크 |

## 🚀 사용법

설치 후 별도 설정 없이 바로 사용할 수 있다.

### ⚡ 자동으로 일어나는 것

| 기능 | 설명 |
|------|------|
| 규칙 적용 | 코딩 스타일, 보안, 한국어 응답 등 `rules/` 규칙이 매 세션 자동 적용 |
| 명령어 자동 실행 | 전 명령 무프롬프트 실행(bypass) → 장기 작업이 중단 없이 진행. 위험 명령은 지침이 자율 사용을 금지하고 파국형 명령과 넓은 재귀 삭제 패턴(절대경로·`./` 하위 `rm -rf`)만 `deny` 차단 |
| 에이전트 위임 | 빌드 실패 → `build-resolver`, 보안 민감 코드 → `security-reviewer` 등 자동 위임 |
| 데스크톱 알림 | Claude가 입력 대기 중일 때 `notify-send`로 알림 |
| compact 리마인더 | 긴 세션에서 컨텍스트 압축 후 "요약을 사실로 단정하지 말고 관련 파일을 다시 읽으라"는 리마인더를 컨텍스트에 주입 |

### 🎯 사용자가 호출하는 것

| 명령 | 설명 |
|------|------|
| `시작` | 프로젝트 파악 후 현재 상태 요약 |
| `/init-project` | 새 프로젝트에 `agent-guide/` 3종 파일 자동 생성 |
| `/code-review` | 심층 코드 리뷰 리포트 |
| `/writing-prompts` | LLM 프롬프트 작성 |
| ... | 아래 스킬 목록 참고 |

## 🧩 구성요소

### 📏 Rules (7개) — 매 세션 자동 적용

| 파일 | 역할 |
|------|------|
| `coding-style.md` | 코딩 스타일, 에러 처리, 리소스 관리 |
| `security.md` | 시크릿 관리, 입력 검증, 취약점 방지 |
| `architecture.md` | 파일 구조, 단일 역할, 의존성 방향 |
| `communication.md` | 한국어 응답, 변경 이유 설명, 용어 병기, 이모지 활용 |
| `context-management.md` | 계획 영속화·부에이전트 공유 정책 (하네스 내장 동작 위의 로컬 정책만) |
| `work-principles.md` | 작업 원칙 (정확성 우선, 위험 명령 통제, 산출물 정리 등) |
| `agents.md` | 에이전트 자동 위임 조건과 우선순위 |

> 레퍼런스 검증 규칙은 상시 로드에서 온디맨드로 전환 — `/reference-verification` 스킬 참고 (work-principles에 호출 트리거 1줄 유지)

### 🤖 Agents (4개) — 조건 충족 시 자동 위임

| 에이전트 | 트리거 |
|----------|--------|
| `build-resolver` | 빌드/타입 에러 발생 시 |
| `security-reviewer` | 인증/인가, API, 시크릿 관련 코드 작성 시 |
| `planner` | 아키텍처 결정이 필요하거나 요구가 불명확한 작업, 사용자가 계획을 요청할 때 |
| `verifier` | 사용자가 점검을 요청할 때만 ("점검해줘/확인해줘") — 완료 보고 전 자동 위임 없음 |

### 🪝 Hooks — 이벤트 기반 자동 실행

**Claude Code**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `on-tool-failure.sh` | PostToolUseFailure (Bash) | 빌드/테스트/린트 실패 시 대응 가이던스 주입 |
| Notification | 알림 발생 시 | `notify-send`로 데스크톱 알림 |
| SessionStart (compact) | 컨텍스트 압축 직후 | 요약 불신·파일 재확인 리마인더를 `additionalContext`로 주입 — PostCompact는 `systemMessage`·stdout을 모델에 전달하지 않아 부적합 |

> Bash 자동승인 훅(`auto-approve-readonly.sh`)은 은퇴, `permissions.ask`도 전면 해제 — 497줄 텍스트 매칭이 따옴표 속 문구("rm 금지" 등)를 명령으로 오인하는 오탐이 누적됐고, ask 규칙도 bypass 모드에서 발동해(실측 확인) 자율 흐름을 끊었다. 이제 `defaultMode: bypassPermissions`로 전 명령 무프롬프트 실행이며, 위험 명령은 지침(work-principles)이 자율 사용을 금지하고 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작, 크론탭 삭제)과 넓은 재귀 삭제 패턴만 `permissions.deny` 49건이 차단한다 — 규칙의 `*`는 공백 포함 임의 문자열에 매칭되므로 `rm -rf /*`·`rm -rf ./*`는 절대경로·`./` 하위 `rm -rf` 전부에 걸린다(설계 의도는 파국형 차단이지만 구현은 이만큼 넓다). 훅 원본·회귀 케이스·기존 ask 목록(복원용)은 `.archive/2026-07-18_hook-retirement/`

**Codex (v0.129+)**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `notify.sh` | Stop | 턴 완료 시 `notify-send` 알림 |
| `compact-reminder.sh` | SessionStart (compact) | 요약 불신·파일 재확인 리마인더를 `additionalContext`로 주입 — PostCompact의 `systemMessage`는 UI 경고 전용 |

> Codex는 훅 정의의 해시로 신뢰를 기록하므로 훅을 새로 만들거나 바꾸면 `/hooks`에서 검토·신뢰할 때까지 그 훅을 건너뛴다(시작 시 경고만 출력, 자동 확인창 없음).

> Codex 실패알림 훅(PostToolUse)은 제거됨 — PostToolUse는 비정상 종료한 Bash에도 발화하지만, payload(`tool_response`)가 exit code 없는 포맷된 출력 문자열이고 `PostToolUseFailure` 이벤트도 없어(0.142.5 + 0.144.1 `shell.rs`·`protocol.rs` 소스 재검증) 실패의 종료 상태를 범용적·신뢰성 있게 판정할 수 없다(출력 문자열에서 특정 오류 문구를 grep하는 것은 가능하나 일반적 실패 감지는 불가). Codex가 exit_code를 노출하면 `.archive/2026-07-02_codex-dead-hook/`에서 복원

> Codex PreToolUse는 의도적 미설정 — `approval_policy = "never"` + `.codex/rules/default.rules`(Starlark DSL)가 이미 통제

### ⚙️ Skills (20개) — `/skill-name`으로 호출

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
| `/hw-design` | 한화그룹(Hanwha) 디자인 표준 DESIGN.md 배포 — Hanwha Orange + Navy 2색축 · 한화체 3w + 한화고딕 5w + IBM Plex 페어링 · 공식 트리서클 로고 번들 |
| `/hw-ppt` | 한화손해보험(Hanwha Insurance) PPT 디자인 시스템 — 16:9 1920×1080 · 9개 슬라이드 아키타입 · Density Zone 룰 · 한화체 .ttf 임베드 · Anthropic 공식 pptx 스킬과 협업 (.pptx 우선 + HTML 옵션) |
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
| `/reference-verification` | 논문 인용·수식→코드 구현·benchmark 비교 시 원문 검증 절차 (rules에서 온디맨드 스킬로 전환) |
| `/update-docs` | 프로젝트 문서 업데이트 |
| `/recursive-discussion` | Claude↔Codex 대등 토론으로 결과물 개선 — 라운드 정책(최소 3 / 권장 5 / 상한 10) + packet 공통 블록 + 토론 상태표 기반 판단 |

**프로젝트 관리**

| 스킬 | 용도 |
|------|------|
| `/start` | 세션 시작 시 프로젝트 파악/상태 요약 |
| `/init-project` | 새 프로젝트 agent-guide 자동 생성 |
| `/skill-creator` | 새 스킬 생성 가이드 |

> `/start`는 스킬이 아니라 커스텀 명령(`.claude/commands/start.md`)이다. 호출 방식이 같아 함께 표기하며, 20개 집계에는 포함하지 않는다.

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
│   ├── rules/                 # 규칙 (7개)
│   ├── agents/                # 서브에이전트 (4개)
│   ├── commands/              # 슬래시 커맨드
│   ├── hooks/                 # 이벤트 훅
│   ├── skills/                # 스킬 (20개)
│   ├── scratch/               # 임시 작업 파일 (gitignored, 보존물은 reference/로 승격)
│   ├── statusline-command.sh  # 상태줄 스크립트
│   └── settings.json          # 전역 설정
├── .mcp.json                    # MCP 서버 설정 (gitignored, API 키 포함)
├── .codex/
│   ├── AGENTS.md              # Codex 지침 (프로세스 · 에이전트 운영 · 스킬 · 비파괴 원칙)
│   ├── AGENTS.references.md   # 레퍼런스 검증 규칙 (논문/수식/benchmark)
│   ├── config.toml            # Codex 설정 (모델 · developer_instructions · 샌드박스 · 환경변수 정책 · 훅)
│   ├── rules/                 # 실행 정책 (위험 명령어 차단)
│   ├── hooks/                 # 이벤트 훅 (Stop / SessionStart)
│   └── skills → ../.claude/skills
├── .gemini/
│   ├── GEMINI.md              # Gemini CLI 지침 (전역, 정본)
│   ├── AGENTS.md              # 크로스툴 convention 진입점 (Antigravity·Cursor 등 → GEMINI.md 참조)
│   ├── settings.json          # Gemini CLI 설정 (모델, 훅)
│   ├── agents/                # 서브에이전트 (4개)
│   ├── commands/              # 커스텀 슬래시 명령
│   ├── hooks/                 # 이벤트 훅 (알림)
│   ├── global_workflows/      # Antigravity 글로벌 워크플로우 (링크 대상)
│   └── policies/              # 안전 정책 (명령 허용/차단)
├── .antigravity/              # Antigravity 안전 정책 (v1.5)
│   ├── README.md              # 검증 상태 + 4-tool 정합 매트릭스
│   ├── settings.json          # permissions(allow/ask/deny) + agentSettings + hooks
│   ├── policies/              # (예약) 정책 디렉토리
│   └── hooks/
│       └── mcp-config-guard.sh      # .agent/mcp_config.json 백도어 차단
├── scripts/                   # 유지보수 스크립트
│   ├── verify-policies.sh     # 2툴(Codex/Gemini) 정책 회귀 테스트 단일 실행기
│   ├── policy-cases.tsv       # 정책 케이스 테이블 (codex/gemini)
│   ├── gemini-policy-engine.mjs  # Gemini 정책 엔진 복제 러너 (0.38.1 소스 대조)
│   └── setup-apparmor.sh      # Codex bwrap용 AppArmor 프로필 설치 (1회 실행)
└── reference/                 # 레퍼런스 자료
    ├── Agent-Coding-Guide/    # 에이전트 코딩 가이드 (팀 교육용)
    ├── agent-teams-guide/
    ├── archive/               # 구세대 모델 자료 보관소 (Claude 5·GPT-5.6 미만 전용 문서)
    ├── awesome-design-md-survey/  # DESIGN.md 브랜드 사례 조사
    ├── claude-prompt-guide/
    ├── google-prompt-guide/
    ├── langchain-langgraph-guide/
    ├── openai-api-guide/
    ├── openai-prompt-guide/
    ├── qwen-prompt-guide/
    ├── research/              # 조사 원문 (Fable 5.1·GPT-6 Astra·GPT-5.6·프롬프트 트렌드 등)
    ├── skills-guide/
    ├── stitch-guide/          # Google Stitch MCP 참조 문서
    └── 참고디자인파일/           # 디자인 원본 (폰트·로고)
```

> **스킬 공유**: 설치 시 `~/.agents/skills → ~/.claude/skills` 로 통합된다. Codex·Gemini는 이 공용 경로로 스킬을 공유받으며, 도구별 개별 링크(`~/.gemini/skills` 등)는 만들지 않는다. Antigravity만 `~/.gemini/antigravity[-cli]/skills` 로 별도 연결한다.

## 📌 변경 이력

버전별 상세는 각 시점의 Git 이력에 있다. [GitHub Releases](https://github.com/mulgae-life/dotfiles/releases)는 별도 태그 체계(v1.x)로 일부 버전의 상세만 담는다.

| 버전 | 핵심 변경 |
|------|-----------|
| **v2.21** | Codex 설정 리뷰 재검토 반영 — 8건을 파일·Git 이력·공식 문서 원문·Codex 0.153.4 소스로 독립 판정(수용 5·부분 수용 2·기각 1). 압축 후 리마인더를 PostCompact에서 SessionStart(`compact`)의 `additionalContext`로 이전 — Claude 공식 문서가 PostCompact의 `systemMessage`·stdout 폐기를 명시하고 이번 세션 트랜스크립트에서도 로컬 명령 출력으로만 기록됨을 확인, Codex도 `compact.rs`가 `systemMessage`를 UI 경고로만 처리(스크립트 `compact-reminder.sh`로 개명, 규칙 재주입과 중복되는 문구 꼬리 삭제). config.toml `[agents]` 주석 정정(`max_depth`는 V2 무시·`job_max_runtime_seconds`는 no-op — `config_toml.rs` 소스 주석으로 확정, v2.19에서 결정한 "무효 가능성 기록"이 누락돼 있던 것을 이행. 키 삭제·개명은 계속 보류). `verify-policies.sh`에 인자 검증·실행 검사기 0개 실패·검사기 자체 오류 실패 처리(검사 없이 성공 종료하던 경로 3개 차단). default.rules 사유 문구를 forbidden의 실제 경로("사용자가 직접 실행")로 통일, AGENTS.md의 "ask 없음"을 "`prompt` 판정은 있으나 정책상 미사용"으로 정정. PostToolUseFailure 훅 timeout 5000초(단위가 초라 83분)→10초. deny 와일드카드가 절대경로·`./` 하위 재귀 삭제까지 매칭하는 실제 범위를 README·work-principles 문구에 반영(규칙 무변경). verifier.md·CLAUDE.md 경로를 `~/.claude/...`로 통일. 기각: verifier·security-reviewer 자동 수정 범위(초기 커밋부터 의도된 설계). Codex 2차 회신 반영: 검사기별 케이스 0건·케이스 파일 부재를 실패 처리, README 리마인더 설명 현행화, "파국형" 표현을 파국형 명령과 넓은 재귀 삭제 패턴으로 구분, Codex 훅 변경 시 `/hooks` 재신뢰 필요를 명시(문서 원문: 신뢰 전까지 건너뜀). Claude 쪽 `additionalContext` 주입은 수동 `/compact` 직후 실측 확인 |
| **v2.20** | 구세대 모델 자료 정리 — 유지 기준을 Claude 5 세대·GPT-5.6 이상으로 잡고(Haiku 4.5는 현역이라 유지), 그 미만 전용 문서 25개를 `reference/archive/`로 `git mv`(GPT-4.1~5.5 프롬프트 가이드 7종, gpt-4o·o1·GPT-5.2 시절 플랫폼 문서 스냅샷 7종, GPT-5 초기·5.2·5.4 API 정리 3종, Claude 4.x Best Practices 2종·Prefilling, `writing-prompts` 참조 5종). 유지 문서에서는 구세대 절을 삭제(Extended Thinking `budget_tokens`, Prefilling, GPT-5.4 `phase`, effort `none`에서만 되던 temperature 주석), 코드 예시 모델 ID를 `gpt-6-astra`·`claude-opus-5`로 통일(대표님 결정: Sonnet 예시 미사용. GPT-6·Claude 5 세대 모두 temperature 미지원이라 LangChain 예시는 temperature 제거, OpenAI는 `use_responses_api=True` 병기), 5.2/5.4 특화 절은 "내장 도구·에이전트 기능"으로 합쳐 GPT-6 모델 페이지의 지원 도구 목록으로 대체. 이동 파일의 상호 링크는 스킬에서는 제거, reference 가이드의 "이전 버전" 링크는 보관소 경로로 갱신. 연구 원문(`reference/research/`)과 이 이력 표는 시점 기록이라 손대지 않음 |
| **v2.19** | GPT-6 Astra(9/3 출시)·Codex 0.153.4 대응 — 서브에이전트 3개(공식·커뮤니티 / Codex 체인지로그·config 실측 / 레포 문구 인벤토리 96건) 병렬 조사 후 공식 원문 3건 직접 대조해 `research-gpt6.md`·`gpt-6-prompt-guide.md`(스니펫 원문)·`gpt6-patterns.md` 신설. 확정 사실: API 1.05M/128K·effort low~max 5단계(`none` 폐지)·`temperature` 등 제거·도구 호출 Responses 전용·272K 초과 요청 전체 2배 요율; Codex는 0.153.4부터 `model` 미설정 시 Astra 기본(컨테이너 실측), 창은 5.6과 같은 272K, `ultra`는 API 값이 아닌 자동 위임 모드로 켜면 하네스가 "명시 요청 없이 위임 금지" developer 지시를 무효화(`codex debug prompt-input` 실측). Codex 층 반영: config.toml 주석 현행화(Astra 기본·high는 상향 선택·ultra 단서), developer_instructions에 공식 가이드의 주도성("~해줄래"는 실행 지시로 간주·완주)과 테스트 범위 축소(가역적 변경에 구현 비추는 테스트 금지) 2줄, AGENTS.md의 계획·점검 트리거를 Claude 층 v2.16·v2.17과 정합(파일 3개+ 기준 삭제, 점검은 요청 시만 — 5.6 때 유지 근거였던 의도 이탈·허위 보고가 Astra 시스템 카드에서 18.8%→3.4%·1/4로 감소), Ultra 용어 분리. 스킬 층: effort 열거 6개 파일 8곳에 세대 분기, `writing-prompts`·`llm-api-guide`에 GPT-6 블록·특화 절 신설, 5.6은 이전 세대로 강등. 동작을 바꾸는 설정 키(`agents.*` 개명·`default_subagent_*`·`tools.update_plan`·`tui.auto_recap`)는 대표님 결정으로 보류(주석에만 기록). 부수: Codex Desktop remote app-server 구버전(0.145.0) 44일 잔류로 신형 캐시 파싱 실패 후 구형 목록을 덮어써 Astra가 피커에서 사라진 실사고 진단·복구. 2차 점검: Codex 층에 코딩·구조·보안 규칙이 전역에 없던 누락을 복원(`f956131`이 "developer_instructions와 중복"이라며 AGENTS.md에서 제거했으나 config에는 처음부터 없었음 — `<coding_rules>` 블록 신설, Claude rules 3종 압축 대응), AGENTS.md에서 0.153.4 바이너리에 없는 `spawn_agents_on_csv` 서술·설정값·중복 조항 삭제, config 주석의 이슈 번호·버전·인용 정리, `langchain-guide` 예시 7곳의 `gpt-5` + `temperature=0`(추론 모델 400)을 `gpt-6-astra` + `use_responses_api=True`로 정정(langchain-openai 소스 확인) |
| **v2.18** | 상용 스킬 6종 감사·반영 — 서브에이전트 3개 병렬 감사(API/프롬프트·작업·문서 스킬) 후 근거 확정분만 적용. `llm-api-guide`·`writing-prompts`는 Fable 5.1 미반영이 오류 수준(강제 `tool_choice` 예시가 5.1에서 400, 모델 표에 5.1 부재, 캐시 읽기 0.1배 낡음)이라 파괴적 변경 3건·베타 3종·폴백·effort 재측정을 반영하고, "자기검증 서브에이전트" 권장(v2.17과 충돌)·"verify your answer"류 지시·CoT 출력 지시·절차 열거 패턴에 "Claude 4.x·표준 모델 한정" 범위 표기. 근거 문서로 `reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md` 신설(스니펫 원문 축자). `work-plan`은 v2.16·v2.17 미반영 5곳(파일 3개+ 자동, verifier 고정 단계·완료 조건) 정합, `update-docs`는 Claude 5 세대에서 기본 제외된 Task 도구 호출 단계를 조건화, `work-verify` 번역투 카탈로그에 communication 명시 3패턴 보강, `init-project` GUIDE 템플릿에 `/start`의 교훈 검토 단계·GUIDE 갱신 시점 추가. 문서 스킬 2종의 `model: sonnet`(턴 한정 비용 라우팅, 7월 의도 설계)은 대표님 결정으로 `opus`로 변경 |
| **v2.17** | verifier 자동 위임 폐지 — Opus 5 프롬프팅 가이드 "Task scope and over-verification"("use a subagent to verify" 지시와 별도 검증 단계를 넣는 하네스 스캐폴딩 제거)와 Claude Code 모델 설정 문서의 Fable 요령("검증 리마인더 생략")을 원문 확인. v2.12가 트리거만 완화하고 남겨둔 자동 위임을 사용자 요청("점검해줘/확인해줘") 시에만으로 전환, 일반 흐름에서 제외, verifier.md description·위임 조건·비교표 정합. 완료 보고의 입증 기준(도구 출력)은 유지. Codex 층은 GPT-5.6 조사(의도 초과·허위 보고 → 검증 루프 필수)에 따라 미변경. 부수: 에이전트 정의 3개(verifier·security-reviewer·build-resolver)에 남아 있던 v2.10 은퇴 훅 "ask 발동 명령" 문단을 현행 work-principles 조항 기준으로 정정 |
| **v2.16** | Fable 5.1 출시(9/1) 대응 — 공식 자료·커뮤니티 후기를 서브에이전트 2개로 병렬 조사해 `research-fable51.md` 신설. rules 반영 3건: coding-style 최소 Diff에 "파일 전체 재작성 금지, 외과적 수정" 1줄(공식이 인정한 5.1 행동 변화), agents의 planner 트리거에서 파일 수 기준(3개+) 삭제 → 아키텍처 결정·요구 불명확·사용자 요청으로 한정(Fable 사용 요령 "경로는 모델이 계획, 큰 작업 통째로" + 하네스 자율 실행 + Opus 강제 서브에이전트 비용, planner.md description 동반 수정), context-management의 대량 출력 조항 삭제(하네스가 대량 도구 출력을 자동 파일 저장함을 실측). 진행 업데이트·병렬 호출·작업 완주 등 나머지 공식 처방은 하네스가 이미 주입하므로 중복 추가 안 함, 반서식 조항은 완화형이라 무변경. Codex·Gemini 층은 근거가 Claude 하네스 고유라 미변경. settings.json에 `remoteControlAtStartup: false`(Remote Control 자동 시작 해제)와 `CLAUDE_CODE_SUBAGENT_MODEL=opus` + `_FORCE=1`(서브에이전트 Opus 강제, 2.1.257+ 필요) 추가 — 5.1 출력 토큰 1.7배·구독 한도 소진 보고에 대응, 트랜스크립트 model 필드로 적용 실측. 도구 버전 현행화 Claude Code 2.1.250→2.1.258, Codex 0.150.1→0.152.1 체인지로그 대조 기능 변경 불요(`codex doctor`·execpolicy 회귀 20/20 정상) |
| **v2.15** | 도구 버전 현행화 — Claude Code 2.1.236→2.1.250, Codex 0.144.6→0.150.1 체인지로그를 dotfiles 설정·훅·권한 층과 대조해 기능 변경 불요 확인(Claude: 훅 stdout JSON 엄격화·와일드카드 allow 경고 모두 통과, Codex: `codex doctor`·execpolicy 실측 정상). 검증 기준 버전 표기 갱신, config.toml·rules의 낡은 주석 정정(`--full-auto` 제거 반영, 서브에이전트 모델 지정 공식 지원 반영). 로컬 전용 `settings.local.json`의 잔재 allow 42건 제거(레포 외) |
| **v2.14** | autocompact 임계값 고정 — settings.json에 `autoCompactWindow: 500000` 추가. 컨텍스트 500K 토큰 도달 시 자동 압축이 발동하도록 기본값(모델별 임계값)을 대체. `/autocompact`는 런타임본만 갱신하므로 레포본에 명시해 install.sh 재배포에도 유지 |
| **v2.13** | 스킬 층 전수 감사 — SKILL.md 20개를 rules 감량과 같은 3축으로 판정. 상시 노출층인 hw-design·hw-ppt description을 문단 수준에서 트리거·구분 정보만 남기고 압축, work-plan 작성 스타일을 code-review와 같은 완화 문구로 정렬(v2.9 개정 누락분), update-docs의 추상 플레이스홀더 표 삭제. references류(두꺼운 아티팩트)와 Anthropic·Vercel 원본 스킬은 처방에 부합해 무변경 |
| **v2.12** | 상시 로드 지침 감량 — Anthropic의 Claude 5 컨텍스트 엔지니어링 처방(시스템 프롬프트 80% 삭제, "지침의 저주")을 근거로 rules 전 조항을 3축(모델이 스스로 하는가/내장 기능과 중복인가/층간 충돌인가) 감사. reference-verification을 rules에서 온디맨드 스킬로 전환(상시 67줄→트리거 1줄), context-management를 내장 중복 제거 후 로컬 정책 3건으로 축소, CLAUDE.md 도구 힌트 표·security 예시 코드쌍·자기검증 지시 삭제, verifier 트리거·인수 프로토콜을 모델 중립 결과 기준으로 개정. 상시 로드 393→약 250줄 (원본은 `.archive/2026-08-13_rules-slimming/`) |
| **v2.11** | Claude Opus 5 조사·반영 — 서브에이전트 3개(공식 문서/Claude Code·SDK/커뮤니티) 병렬 조사로 `research-opus5.md` 신설, Opus 5 프롬프트 가이드 신설(검증 스캐폴딩 삭제·위임 상한·effort 역전·thinking 기본 켜짐), llm-api-guide에 Opus 5 주의사항 섹션·`fallbacks: "default"` 반영, writing-prompts `claude-5-specifics.md`를 Fable 5·Opus 5 공통 문서로 확장. 스킬 캐시 대비 실측 차이(web fetch 미지원, Sonnet 5 $2/$10 정가 확정) 정정 |
| **v2.10** | 확인 프롬프트 전면 해제 — Bash 자동승인 훅(497줄) 은퇴 + `permissions.ask` 81건 해제. 멀티라인 인용 오탐(따옴표 속 "rm 금지"를 명령 오인) 재현·수정 후, ask 규칙이 bypass 모드에서도 발동함을 실측 확인하고 두 ask 계층을 모두 제거. 위험 명령 통제는 지침 + `deny` 49건으로 일원화(권한변경 4건 해제, `systemctl`/`loginctl` 전원 조작·`crontab -r` 6건 보강), work-principles 훅 조항·`/tmp` 요령 4종 삭제 + PostCompact 리마인더를 요약 불신·파일 재확인 중심으로 개정 (복원 자료는 `.archive/2026-07-18_hook-retirement/`) |
| **v2.9** | Codex 스킬 재검토 2라운드(쟁점 52건) 전건 재현 판정·선별 수용 — skill-creator 하위 호출 격리(`--safe-mode`)·zip 심링크 차단·name 표준 정합, LLM API 병렬 도구 배칭(Anthropic·OpenAI)·thinking 호환 text 추출, token-audit 파이프 절단 수정, Stitch MCP 표기·경로 계약 정합·중첩 스킬 이름 충돌 해소 |
| **v2.8** | 한국어 문체 심층 조사(출처 21건, 주장 상위 25건 적대 검증) + 블라인드 실측 — 간결화 개정 기각, 스몰톡 해요체 허용·압축체(전보문) 금지·표준 용어 조항 3-tool 반영, style-check 정량 마커 증보 |
| **v2.7** | 최신 모델 프롬프팅 가이드 기준 지침 감량(에이전트 4종·Codex 설정) + scratch 임시 의미 복원 — 오버트리거 방지 |
| **v2.6** | 외부 코드 리뷰 9건 검증·선별 수용 — Gemini 정책 전면 소생, hook 혼합 대상 봉쇄, 정책 회귀 테스트 영속화(131케이스) |
| **v2.5** | `/tmp` 예외 케이스5 — `cd /tmp &&` 체인 위치 무관 일반화, 상대경로 축 완성(의도적 미확장 명문화) |
| **v2.4** | 문체 규칙 3-tool 정비(AI스러운 표현 차단) + 전역 rules 15% 감량 |
| **v2.3** | `&&` 끝 줄바꿈 라인 연속 정규화 — 멀티라인 체인 오탐 해소 |
| **v2.2** | 프로세스 종료 ask 해제(4-tool) + `/tmp` 예외 위치 무관 절대경로 확장(케이스4) |
| **v2.1** | `/tmp` 예외 선두 `&&` 체인 확장(케이스3) + 케이스2 확장 구멍 봉쇄 |
| **v2.0** | `gh api` 쓰기 누수 봉쇄(3-tool) + 실패알림 훅 수리·Codex 훅 제거 + Gemini `/tmp` 예외 |
| **v1.9** | 보안 hook `/tmp` 예외(경로 기반 정책) + CLI 검증버전 정합 |
| **v1.8** | hw-ppt PowerPoint 실측 좌표 확정 + 시그니처 ink 재페인트 |
| **v1.7** | 위험 명령 정밀 분류 + 셸 우회 차단 |
| **v1.6** | Opus 4.8 정합 + install.sh 파일별 정책 분리 + hw-ppt 스킬 신설 |
| **v1.5** | Antigravity 통합 — 4-tool 12 카테고리 정합, install.sh OS 감지 |
| **v1.4** | 위험 명령 차단 정합성 강화 — 3-tool 12 카테고리 ask 분기, 174건 검증 |
| **v1.3** | hw-design 헤더 시스템 + recursive-discussion 정합 + GPT-5.5 가이드 정합화 |
| **v1.2** | hw-design 스킬 신설 + `/work-plan` 콤팩트화 |
| **v1.1** | Gemini CLI 지원 추가 |
| **v1.0** | AI Agent Guidelines System 초기 릴리즈 |
