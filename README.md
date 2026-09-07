# 🛠 dotfiles

AI 코딩 에이전트([Claude Code](https://docs.anthropic.com/en/docs/claude-code) / [Codex](https://github.com/openai/codex) / [Antigravity](https://antigravity.google))의 전역 설정을 관리하는 레포.

한 번 설치하면 어떤 프로젝트에서든 동일한 **규칙 · 에이전트 · 스킬 · 훅**이 자동 적용된다.

> **🎯 설계 원칙 — 자율성 우선, 최소 차단**: 모든 작업을 확인 프롬프트 없이 실행해 장기 작업이 중단되지 않게 한다(Claude Code는 ask 계층 전면 해제). 위험 명령(`rm` · `git push` · `sudo` 등)의 통제는 지침(rules)이 담당하고 — 자율 작업 중 사용 금지, 사용자 요청 시에만 — 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작, 크론탭 삭제)과 넓은 재귀 삭제 패턴(절대경로·`./` 하위 `rm -rf`)만 `permissions.deny`가 프롬프트 없이 차단한다. 차단 목록의 범위는 도구별로 다르다(아래 도구별 설정 구조 표 참조).

> **🔗 관리 원칙 — Claude 층이 정본, 완전히 공유되는 자산만 링크**: 스킬처럼 그대로 쓸 수 있는 자산은 다른 도구가 `.claude/`를 링크로 받고, 형식이나 내용이 도구마다 달라야 하는 규칙 본문(Codex `config.toml`·Antigravity `GEMINI.md`)은 직접 동기화한다. 일부만 맞는 자산을 링크하려고 정본 구조를 쪼개지 않는다.

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

설치 스크립트는 `~/dotfiles/` → `~/` 로 심볼릭 링크를 생성한다. 단, 도구가 런타임에 수정하는 파일(`.claude/settings.json`, `.codex/config.toml`)은 복사로 설치하여 레포 원본을 보호한다. 예외로 **Antigravity CLI(`agy`) settings는 관리 키만 병합**한다 — `agy`가 `model`·`trustedWorkspaces`·승인 캐시를 같은 파일에 되쓰기 때문이며, 레포의 `permissions` 3배열은 통째로 교체되고 나머지 키는 보존된다(`jq` 부재나 파싱 실패면 손대지 않고 오류만 낸다). Antigravity IDE 글로벌 settings도 deep merge하되 macOS·Windows에서만 일어난다. Linux는 경로가 미검증이라 건너뛰고 안내만 출력한다. 런타임 데이터(`projects/` 등)는 건드리지 않는다. `jq`가 없으면 자동 설치를 시도한다.

### 도구별 설정 구조

| | Claude Code | Codex | Antigravity |
|---|---|---|---|
| **지시 파일** | `CLAUDE.md` + `rules/*.md` | `AGENTS.md` + `config.toml` | `GEMINI.md` (`~/.gemini/config/`와 `~/.gemini/`에 설치) |
| **설정** | `settings.json` (복사) | `config.toml` (복사) | `cli/settings.json` (관리 키만 병합) |
| **권한** | `bypassPermissions` + deny 49건 + 지침 | `approval_policy="never"` + Starlark `rules/` | `toolPermission: always-proceed` + deny 66건(토큰 정확 일치) + 지침 |
| **에이전트** | `agents/*.md` | 없음 (수동) | Subagents (`/agents`) — 정의 0개 |
| **훅** | `PreToolUse`, `PostToolUseFailure`, `Notification`, `SessionStart` | `Stop`, `SessionStart` (v0.129+) | 없음 — 알림은 내장 `notifications`. `~/.gemini/config/hooks.json`이 로드됨을 실측(`PreToolUse`·`PostToolUse`·`PreInvocation`·`PostInvocation`·`Stop`) |
| **커스텀 명령** | `commands/*.md` (`/start`) + 스킬 | 없음 | Plugins (구 Extensions) |
| **기본 모델** | Claude Opus | 권장 기본 추종 (0.153.4부터 GPT-6 Astra, 미고정) | Gemini 3.8 Flash (High) 기본, 미고정 |
| **CLI 버전 (검증 기준)** | 2.1.258 | 0.153.4 | `agy` 1.1.27 (IDE 층은 미검증) |
| **스킬** | `.claude/skills/` | 심볼릭 링크 | 심볼릭 링크 (`~/.gemini/config/skills`) |

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
| MCP 자동승인 | PreToolUse (`mcp__.*`) | MCP 도구 호출을 프롬프트 없이 허용 — 의도된 정책 |
| `on-tool-failure.sh` | PostToolUseFailure (Bash) | 빌드/테스트/린트 실패 시 대응 가이던스 주입 |
| Notification | 알림 발생 시 | `notify-send`로 데스크톱 알림 |
| SessionStart (compact) | 컨텍스트 압축 직후 | 요약 불신·파일 재확인 리마인더를 `additionalContext`로 주입 — PostCompact는 `systemMessage`·stdout을 모델에 전달하지 않아 부적합 |

> Bash 자동승인 훅(`auto-approve-readonly.sh`)은 은퇴, `permissions.ask`도 전면 해제 — 504줄 텍스트 매칭이 따옴표 속 문구("rm 금지" 등)를 명령으로 오인하는 오탐이 누적됐고, ask 규칙도 bypass 모드에서 발동해(실측 확인) 자율 흐름을 끊었다. 이제 `defaultMode: bypassPermissions`로 전 명령 무프롬프트 실행이며, 위험 명령은 지침(work-principles)이 자율 사용을 금지하고 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작, 크론탭 삭제)과 넓은 재귀 삭제 패턴만 `permissions.deny` 49건이 차단한다 — 규칙의 `*`는 공백 포함 임의 문자열에 매칭되므로 `rm -rf /*`·`rm -rf ./*`는 절대경로·`./` 하위 `rm -rf` 전부에 걸린다(설계 의도는 파국형 차단이지만 구현은 이만큼 넓다). 훅 원본·회귀 케이스·기존 ask 목록(복원용)은 `.archive/2026-07-18_hook-retirement/`

**Codex (v0.129+)**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `notify.sh` | Stop | 턴 완료 시 `notify-send` 알림 |
| `compact-reminder.sh` | SessionStart (compact) | 요약 불신·파일 재확인 리마인더를 `additionalContext`로 주입 — PostCompact의 `systemMessage`는 UI 경고 전용 |

> Codex는 훅 정의의 해시로 신뢰를 기록하므로 훅을 새로 만들거나 바꾸면 `/hooks`에서 검토·신뢰할 때까지 그 훅을 건너뛴다(시작 시 경고만 출력, 자동 확인창 없음).

> Codex 실패알림 훅(PostToolUse)은 제거됨 — PostToolUse는 비정상 종료한 Bash에도 발화하지만, payload(`tool_response`)가 exit code 없는 포맷된 출력 문자열이고 `PostToolUseFailure` 이벤트도 없어(0.142.5 + 0.144.1 `shell.rs`·`protocol.rs` 소스 재검증) 실패의 종료 상태를 범용적·신뢰성 있게 판정할 수 없다(출력 문자열에서 특정 오류 문구를 grep하는 것은 가능하나 일반적 실패 감지는 불가). Codex가 exit_code를 노출하면 `.archive/2026-07-02_codex-dead-hook/`에서 복원

> Codex PreToolUse는 의도적 미설정 — `approval_policy = "never"` + `.codex/rules/default.rules`(Starlark DSL)가 이미 통제

**Antigravity CLI (`agy` 1.1.27)**

훅은 쓰지 않는다. 알림은 내장 `notifications: true`가 담당하고, 압축 후 이벤트는 없다(`PreInvocation`은 매 모델 호출마다 실행돼 리마인더 용도로는 과하다). 권한은 `toolPermission: always-proceed`로 확인 프롬프트를 없애고, 파국형 66건만 `permissions.deny`가 차단한다 — deny는 토큰 단위 정확 일치·접두 매칭이며 글롭과 `regex:`는 동작하지 않아 Claude의 `rm -rf /home*`·`dd of=/dev/sd*` 같은 규칙은 옮길 수 없다(`dd`·`fdisk`·`parted`·`shred`는 지침 통제). 실측 근거와 병합 계약은 `.antigravity/README.md` 참조. IDE 층(`.antigravity/settings.json`)은 추정치 그대로다.

> Gemini CLI 층은 2026-09-07에 은퇴시켰다. Google이 2026-06-18부로 개인 계정(무료·AI Pro·AI Ultra) 요청 처리를 중단하고 Antigravity CLI(`agy`)로 통합했기 때문이다. 훅·정책·에이전트 원본과 회귀 케이스 62건은 `.archive/2026-09-07_gemini-cli-retirement/`

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
├── .antigravity/              # Antigravity 지침 + 안전 정책
│   ├── README.md              # CLI 실측·병합 계약·3-tool 정합 매트릭스
│   ├── GEMINI.md              # Antigravity 지침 (전역, 정본) → ~/.gemini/config/GEMINI.md
│   ├── cli/settings.json      # agy 관리 키 (always-proceed + deny 66건) → 병합 설치
│   ├── settings.json          # IDE 워크스페이스 설정 (추정치, 미검증)
│   ├── global_workflows/      # IDE 글로벌 워크플로우 (링크 대상)
│   ├── policies/              # (예약) 정책 디렉토리
│   └── hooks/
│       └── mcp-config-guard.sh      # IDE용 .agent/mcp_config.json 백도어 차단
├── scripts/                   # 유지보수 스크립트
│   ├── verify-policies.sh     # 정책 회귀 실행기 (Codex 실제 엔진 20건 + agy 설정 정적 검사 16건)
│   ├── policy-cases.tsv       # 정책 케이스 테이블 (codex 20건)
│   ├── agy-live-check.sh      # agy 실측 검사 (모델 호출 6회, 명시 실행 전용)
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

> **스킬 공유**: 설치 시 `~/.agents/skills → ~/.claude/skills` 로 통합된다. Codex는 이 공용 경로로 스킬을 공유받는다. Antigravity는 CLI용 `~/.gemini/config/skills`와 IDE용 `~/.gemini/antigravity/skills`로 별도 연결한다(`~/.gemini/antigravity-cli/skills`는 `agy`가 스스로 만드는 링크라 관리 제외).

## 📌 변경 이력

버전별 상세는 각 시점의 Git 이력에 있다. [GitHub Releases](https://github.com/mulgae-life/dotfiles/releases)는 별도 태그 체계(v1.x)로 일부 버전의 상세만 담는다.

| 버전 | 핵심 변경 |
|------|-----------|
| **v2.24** | Antigravity 지침을 `GEMINI.md` 하나로 통합 — 공식 문서가 CLI·IDE 모두 `GEMINI.md`를 전역 규칙으로 명시하고 `AGENTS.md`는 대체 이름일 뿐이라 진입점 파일을 없앰. 우선순위를 사용자 현재 요청 1순위로 Codex 층과 정합. `merge_agy_settings`의 백업·교체 실패를 명시 처리하고 설치 종료 코드에 반영, 링크 대상 병합. Codex 정적 점검 4건 반영 |
| **v2.23** | Antigravity CLI(`agy` 1.1.27) 관리 층 신설 — 전역 지침을 `~/.gemini/config/`로, `cli/settings.json`(always-proceed + 파국형 deny 66건)을 관리 키만 병합하는 `merge_agy_settings`로 설치. deny 문법(토큰 정확 일치, 글롭·regex 무효)·전역 규칙 경로·훅 로드를 실측. 정적 검사 16건 + 실측 스크립트. Codex와 토론해 확정 |
| **v2.22** | Gemini CLI 층 은퇴 — Google이 2026-06-18부로 개인 계정 지원을 끊고 Antigravity CLI(`agy`)로 통합. 공유 자산(`GEMINI.md`·`AGENTS.md`·워크플로우)은 `.antigravity/`로 이관, 나머지와 회귀 케이스 62건은 아카이브. 3-tool 체계로 정리 |
| **v2.21** | 압축 리마인더를 PostCompact → SessionStart(`compact`)로 이전(Claude·Codex 모두 PostCompact 출력이 모델에 안 닿음). Codex 리뷰 8건 판정, `verify-policies.sh` 무검사 통과 경로 차단, 문서 정합 점검으로 Gemini 층 드리프트 정정 |
| **v2.20** | 구세대 모델 자료 정리 — 컷오프를 Claude 5·GPT-5.6으로 잡고 미만 문서 25개를 `reference/archive/`로 이동, 코드 예시 모델 ID를 `claude-opus-5`·`gpt-6-astra`로 통일하고 temperature 제거 |
| **v2.19** | GPT-6 Astra·Codex 0.153.4 대응 — 조사 문서 3종 신설, Codex 층 지침을 Claude v2.16·v2.17과 정합, 스킬의 effort 열거에 세대 분기. Codex 층에 없던 코딩·구조·보안 규칙 복원 |
| **v2.18** | 상용 스킬 6종 감사·반영 — Fable 5.1 미반영으로 오류가 된 API 예시·모델 표·캐시 단가를 고치고, 자기검증 권장 등 v2.17과 충돌하는 지시에 세대 범위를 표기. Fable 5.1 프롬프트 가이드 신설 |
| **v2.17** | verifier 자동 위임 폐지 — Opus 5 가이드의 과잉 검증 절을 근거로 사용자 요청 시에만 위임하도록 전환. 완료 보고의 입증은 작업 중 도구 출력으로 유지 |
| **v2.16** | Fable 5.1 대응 — 조사 문서 신설, coding-style에 외과적 수정 조항 추가, planner 트리거에서 파일 수 기준 삭제, 서브에이전트 Opus 강제 |
| **v2.15** | 도구 버전 현행화 — Claude Code·Codex 체인지로그를 설정 층과 대조해 기능 변경 불요 확인, 낡은 주석 정정 |
| **v2.14** | autocompact 임계값을 `autoCompactWindow: 500000`으로 레포에 고정 (런타임 명령은 재배포 시 사라짐) |
| **v2.13** | 스킬 층 전수 감사 — SKILL.md 20개를 rules 감량과 같은 기준으로 판정해 상시 노출되는 description을 압축 |
| **v2.12** | 상시 로드 지침 감량 393→250줄 — Claude 5 컨텍스트 엔지니어링 처방을 근거로 모델이 스스로 하거나 내장 기능과 겹치는 조항을 걷어냄 (원본은 `.archive/2026-08-13_rules-slimming/`) |
| **v2.11** | Claude Opus 5 조사·반영 — 조사 문서와 프롬프트 가이드 신설, 스킬의 모델 정보를 실측 기준으로 정정 |
| **v2.10** | 확인 프롬프트 전면 해제 — 자동승인 훅(504줄) 은퇴 + `ask` 81건 해제. 위험 명령 통제를 지침 + `deny` 49건으로 일원화 (복원 자료는 `.archive/2026-07-18_hook-retirement/`) |
| **v2.9** | Codex 스킬 재검토 2라운드(쟁점 52건) 전건 재현 판정·선별 수용 — 스킬 격리·병렬 도구 배칭·경로 계약 정합 |
| **v2.8** | 한국어 문체 심층 조사 + 블라인드 실측 — 간결화 개정 기각, 스몰톡 해요체 허용·압축체 금지·표준 용어 조항 반영 |
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
