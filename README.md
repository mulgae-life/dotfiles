# 🛠 dotfiles

AI 코딩 에이전트([Claude Code](https://docs.anthropic.com/en/docs/claude-code) / [Codex](https://github.com/openai/codex) / [Gemini CLI](https://github.com/google-gemini/gemini-cli) / [Antigravity](https://antigravity.google))의 전역 설정을 관리하는 레포.

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
  └── skills/        /code-review, /writing-prompts 등 19개 전문 스킬
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
| **훅** | `PreToolUse`, `PostToolUseFailure`, `Notification`, `PostCompact` | `Stop`, `PostCompact` (v0.129+) | `BeforeTool`, `Notification` 등 11종 | `before_tool_call` (Claude hook 재사용) |
| **커스텀 명령** | 스킬로 대체 | 없음 | `commands/*.toml` | Plugins (구 Extensions) |
| **기본 모델** | Claude Opus | GPT-5.5 | Gemini 3.1 Pro | Gemini 3.1 Pro / 3 Flash |
| **CLI 버전 (검증 기준)** | 2.1.198 | 0.142.5 | 0.38.1 | IDE 2.1.x / `agy` |
| **스킬** | `.claude/skills/` | 심볼릭 링크 | 심볼릭 링크 | 심볼릭 링크 |

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

**Claude Code**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `auto-approve-readonly.sh` | PreToolUse (Bash) | 진짜 위험한 명령만 ask로 승인 요청, 안전 명령·`/tmp` 파일조작은 자동 승인 |
| `on-tool-failure.sh` | PostToolUseFailure (Bash) | 빌드/테스트/린트 실패 시 대응 가이던스 주입 |
| Notification | 알림 발생 시 | `notify-send`로 데스크톱 알림 |
| PostCompact | 컨텍스트 압축 후 | 핵심 규칙 리마인더 재주입 |

**Codex (v0.129+)**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| `notify.sh` | Stop | 턴 완료 시 `notify-send` 알림 |
| `post-compact-reminder.sh` | PostCompact (manual/auto) | 한국어 응답·변경 이유 리마인더 |

> Codex 실패알림 훅(PostToolUse)은 제거됨 — payload(`tool_response`)에 exit code가 없고 `PostToolUseFailure` 이벤트도 미지원(0.142.5 소스 검증)이라 실패 감지가 구조적으로 불가. Codex가 exit_code를 노출하면 `.archive/2026-07-02_codex-dead-hook/`에서 복원

> Codex PreToolUse는 의도적 미설정 — `approval_policy = "never"` + `.codex/rules/default.rules`(Starlark DSL)가 이미 통제

### ⚙️ Skills (19개) — `/skill-name`으로 호출

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
| `/update-docs` | 프로젝트 문서 업데이트 |
| `/recursive-discussion` | Claude↔Codex 대등 토론으로 결과물 개선 — 라운드 정책(최소 3 / 권장 5 / 상한 10) + packet 공통 블록 + 토론 상태표 기반 판단 |

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
│   ├── skills/                # 스킬 (19개)
│   ├── scratch/               # 연구 노트·대량 출력 저장
│   ├── statusline-command.sh  # 상태줄 스크립트
│   └── settings.json          # 전역 설정
├── .mcp.json                    # MCP 서버 설정 (gitignored, API 키 포함)
├── .codex/
│   ├── AGENTS.md              # Codex 지침 (프로세스 · 에이전트 운영 · 스킬 · 비파괴 원칙)
│   ├── AGENTS.references.md   # 레퍼런스 검증 규칙 (논문/수식/benchmark)
│   ├── config.toml            # Codex 설정 (모델 · developer_instructions · 샌드박스 · 환경변수 정책 · 훅)
│   ├── rules/                 # 실행 정책 (위험 명령어 차단)
│   ├── hooks/                 # 이벤트 훅 (Stop / PostCompact)
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
│       ├── auto-approve-readonly.sh → ../../.claude/hooks/auto-approve-readonly.sh
│       └── mcp-config-guard.sh      # .agent/mcp_config.json 백도어 차단
└── reference/                 # 레퍼런스 자료
    ├── Agent-Coding-Guide/    # 에이전트 코딩 가이드 (팀 교육용)
    ├── agent-teams-guide/
    ├── awesome-design-md-survey/  # DESIGN.md 브랜드 사례 조사
    ├── claude-prompt-guide/
    ├── google-prompt-guide/
    ├── langchain-langgraph-guide/
    ├── openai-api-guide/
    ├── openai-prompt-guide/
    ├── qwen-prompt-guide/
    ├── skills-guide/
    ├── stitch-guide/          # Google Stitch MCP 참조 문서
    └── 참고디자인파일/           # 디자인 원본 (폰트·로고)
```

> **스킬 공유**: 설치 시 `~/.agents/skills → ~/.claude/skills` 로 통합된다. Codex·Gemini는 이 공용 경로로 스킬을 공유받으며, 도구별 개별 링크(`~/.gemini/skills` 등)는 만들지 않는다. Antigravity만 `~/.gemini/antigravity[-cli]/skills` 로 별도 연결한다.

## 📌 변경 이력

상세 노트는 [GitHub Releases](https://github.com/mulgae-life/dotfiles/releases)에서 확인.

| 버전 | 핵심 변경 |
|------|-----------|
| **v2.1** | **`/tmp` 예외 선두 `&&` 체인 확장 (케이스3) + 케이스2 확장 구멍 봉쇄**: 실사용에서 `cd /tmp/... && rm ... && soffice ... ; pdfinfo \| grep` 같은 복합 체인이 "명령 전체 단위" 판정에 걸려 ask가 뜨던 것을 세그먼트 단위 판정으로 해소 — `cd`(리터럴 `/tmp` 경로)에 `&&`로 직결된 선두 구간은 cd 실패 시 단락·성공 시 cwd `/tmp` 고정이 보장되므로, 그 안의 파일조작 세그먼트(선행 세그먼트는 cwd 변경 불가한 검증된 파일조작·리터럴 `/tmp` cd만 허용)를 auto-allow. 탈출 벡터는 보수적 거부 유지: `..`·멀티라인·`$` 확장·리다이렉트·`;`/`\|`/단독 `&` 이후 세그먼트·eval/env 래퍼·동일 세그먼트 중복(위치 구분 불가) (29케이스 배터리 + 확장·공격 14종 + e2e 검증). + 기존 케이스2의 cd 대상 `$`/백틱 확장 허용 구멍(`cd /tmp/$DIR && rm` — 런타임 `DIR=..`로 탈출 가능) 봉쇄 + work-principles `/tmp` 예외 노트에 허용 형태 3종·작성 요령 정리 |
| **v2.0** | **`gh api` 쓰기 누수 봉쇄 (3-tool) + `PostToolUseFailure` 훅 수리 + Gemini `/tmp` 예외**: 전면 감사에서 발견된 `gh api` 쓰기 우회 3형(`--method` 롱폼, `-XDELETE` 결합형, `gh api <경로> -X` 위치변형)이 auto-allow로 새던 것을 Claude hook(`SKIP` 부분식 + 롱폼 `--method`/`--field`/`--raw-field`/`--input` 통합 패턴, 17케이스 실측) · Gemini `safety.toml`(토큰 시작 매칭, 32케이스 검증) · Antigravity ask 글롭 14종으로 봉쇄 — 읽기(`gh api` 조회·`--paginate`·`-H`·`--jq`)는 계속 자동 승인(오탐 0). Codex는 `gh api` 전체 forbidden이라 원래 면역. + `on-tool-failure.sh` 출력에 `hookSpecificOutput.hookEventName` 누락으로 가이던스가 조용히 미주입되던 것 수리(빌드 실패 유발 실측으로 발화 확인) + Gemini에 `/tmp` 한정 파일삭제(`rm`/`rmdir`/`unlink`) 자동 허용 규칙 추가(Claude v1.9 경로 기반 정책과 정합, 세그먼트 영숫자 시작 강제로 `..` 탈출·메타문자 체인 차단) + 문서 정합(훅 표 사실 오류 2건 — hook은 deny가 아닌 ask·`SessionStart`→`PostCompact`, scratch/플랜 지침 모순 해소, 디렉토리 트리 누락 보완, 검증버전 Claude `2.1.198`·Codex `0.142.5`) + **Codex 실패알림 훅 제거**(payload `tool_response`에 exit code 부재 + `PostToolUseFailure` 이벤트 미지원 — 0.142.5 소스 검증으로 작동 불가 확정, 스크립트는 `.archive/`에 보존) + Codex 실행정책 갭 3종 실측·문서화(`git -C/-c/--git-dir` 전역옵션 우회, `xargs rm`, `sed --in-place=.bak`) + `.pyc`/`.DS_Store` 추적 해제 |
| **v1.9** | **보안 hook `/tmp` 예외 (경로 기반 정책) + CLI 검증버전 정합**: `auto-approve-readonly.sh`에 "위험은 대상이 어디냐에서 온다" 정책 도입 — `/tmp` 하위 대상 파일조작(`rm`·`rmdir`·`unlink`·`shred`·`truncate`·`chmod`·`chown`·`sed -i`·`awk -i`·`ln -sf`·`find -delete`)은 ask 없이 자동 허용(임시 디렉토리=프로젝트 무관)하여 임시 작업·테스트 흐름이 안 끊기게 함. 우회 봉쇄: 화이트리스트(파일조작 명령 직접 시작 — `env`/`nohup`/`timeout`/`bash -c` 래퍼 차단) + 절대경로 전부 `/tmp/` + 메타문자/`..`/`/tmp` 접두어 공격(`/tmpfoo`) 차단 (65케이스 검증). 경로 무관 위험(`sudo`·`git`·`gh`·`docker`·`kill`·`echo\|bash`)은 `/tmp`여도 ask 유지 + work-principles `/tmp` 예외 노트·build-tool config(Claude Code 2.1.160) ask 항목 추가 + 검증버전 Claude Code `2.1.163`·Codex `0.137.0` 정합 |
| **v1.8** | **hw-ppt PowerPoint 실측 패치**: 헤더 시그니처 `hanwha-signature-ink.png` 신규(흰색 outline 텍스트를 ink `#1A1A1A`로 재페인트 → orange-tint `#FCE6D6` 헤더에서 "한화손보" 가시성 확보) + 헤더 strip height `56→80px` + 타이틀 밴드 좌표 실측 확정(밴드 시작 y `110→130`, 한글 타이틀 height `font_px×1.6`, 서브타이틀 y = title 박스 끝 `+24px`, 부제-본문 vertical gap `≥30px`) |
| **v1.7** | **위험 명령 정밀 분류 + 셸 우회 차단**: ask 1차 정밀 분류(Git 상태 변경 `checkout`/`switch`/`restore`/`stash`/`add`, in-place `sed -i`·`awk -i inplace`, 권한 `chmod`/`chown`, 프로세스 `kill`/`pkill`, 링크 강제 `ln -f`/`-sf`) + 2차 셸 우회 차단(`echo "rm"\|bash`·`curl url\|bash` 파이프 stripping 우회, `bash <(...)` process substitution, `find -delete` — 4건 갭 중 3건 차단, `source`는 allow 유지) + `cp`/`mv` allow 정정(되돌리기 쉬움) + curl 단독 다운로드 allow 유지 |
| **v1.6** | **Opus 4.8 정합 + hw-ppt 신설**: `.claude/settings.json` `effortLevel` 제거(Opus 4.8 기본 `high` 자동 추종 — v1.4 권한 커밋에서 `xhigh→medium`으로 비의도적 회귀했던 것 정정) + **install.sh `settings.json` 파일별 정책 분리**(deep merge가 키 삭제를 전파 못 해 좀비 잔존 → Claude는 `safe_copy`로 덮어쓰기, Gemini는 `security.auth` OAuth·`ide` 상태를 settings에 인라인 저장하므로 `safe_merge_json` 유지, Antigravity IDE 글로벌은 사용자 설정 보존 위해 merge) + README 설치방식 서술 정합 + Claude Code 검증버전 `2.1.156` / **hw-ppt 스킬 신설**: 한화손해보험 16:9 1920×1080 PPT 디자인 시스템(9개 슬라이드 아키타입·Density Zone 룰·한화체 `.ttf` 임베드·실측 헤더/타이틀 밴드 좌표·Anthropic 공식 pptx 스킬 협업) |
| **v1.5** | **Antigravity 통합 (수동 단계 0)**: `.antigravity/settings.json` 신설(permissions allow 179/ask 73/deny 53 + agentSettings + hooks) + `.claude/hooks/auto-approve-readonly.sh` 재사용으로 4-tool 12 카테고리 정합 + `.agent/mcp_config.json` 영속 백도어 차단 훅(`mcp-config-guard.sh`) + `webhook.site` 강제 denylist + `terminalExecutionPolicy: "off"` 강제 + `~/.gemini/AGENTS.md` 크로스툴 convention 진입점 + 19개 스킬 IDE/CLI 양쪽 연결 + **install.sh OS 감지**로 macOS `~/Library/Application Support/Antigravity/User/settings.json` · Windows `%APPDATA%/Antigravity IDE/User/settings.json` 자동 `safe_merge_json` (글로벌 settings → 모든 워크스페이스 자동 상속) |
| **v1.4** | 위험 명령 차단 정합성 강화: 12 카테고리 ask 사유 분기(Claude/Codex/Gemini 3-tool 정합) + `.claude/settings.json` 권한 재설계(deny 47 / ask 73 / allow 188, `defaultMode: "default"`) + 셸·인라인 스크립트 우회 차단 + `killall`·`sed --in-place` 보강 + 174건 직접 호출 검증(Claude hook 137 + Codex exec 37, 100% PASS) |
| **v1.3** | hw-design 브랜드 헤더 토큰화 + on-navy 로고 변형 PNG 3종(헤더/스플래시/모바일) + 결정 트리 / recursive-discussion CLI 버전 의존성 격리 + 권한 대칭성·라운드 정책·packet 공통 블록 강화 / GPT-5.5 가이드 정합화 + 한국어 응답 품질 강화 + `.archive` 산출물 정리 규칙 |
| **v1.2** | hw-design 스킬 신설 + `/work-plan` 콤팩트화 |
| **v1.1** | Gemini CLI 지원 추가 |
| **v1.0** | AI Agent Guidelines System 초기 릴리즈 |
