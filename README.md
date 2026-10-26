# 🛠 dotfiles

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) · [Codex](https://github.com/openai/codex) · [Antigravity CLI](https://antigravity.google)(`agy`)의 전역 설정을 한 레포에서 관리한다. 한 번 설치하면 어떤 프로젝트에서든 같은 **규칙 · 에이전트 · 스킬 · 훅**이 적용된다.

**원칙**

- 확인 프롬프트 없이 자율 실행하고, 파국형 명령만 기계로 막는다.
- `rm`·`git push` 같은 위험 명령은 지침으로 통제한다. 사용자가 요청할 때만 쓴다.
- Claude 층이 정본이고, 다른 도구는 그것을 공유한다.

근거와 결정 기록은 [docs/DECISIONS.md](docs/DECISIONS.md), 버전별 변경은 [CHANGELOG.md](CHANGELOG.md)에 있다.

## 📦 설치

```bash
git clone https://github.com/mulgae-life/dotfiles.git ~/dotfiles
~/dotfiles/install.sh            # --dry-run 으로 미리 확인 가능
```

설치는 파일 성격에 따라 세 방식으로 나뉜다.

```
~/dotfiles ── install.sh ─┬─ 링크 ─ 지시 파일 · rules · agents · skills · hooks · 상태줄
                          │         → 레포에서 고치면 다음 세션부터 반영
                          ├─ 복사 ─ .claude/settings.json · .codex/config.toml
                          │         → 도구가 되쓰는 파일. 레포에서 고친 뒤 재설치
                          └─ 병합 ─ agy cli/settings.json (관리 키만)
                                    → 레포에서 고친 뒤 재설치
```

- 재설치하면 런타임에서 바꾼 모델·effort 같은 값은 레포 기본으로 돌아온다.
- `jq`가 없으면 자동 설치를 시도한다.
- 스킬 의존성도 함께 설치한다.
  - 사용자 권한: `visual-check`(Playwright·Chromium), `office-docs`(파이썬 가상환경·npm 패키지·나눔고딕)
  - 관리자 권한(LibreOffice·poppler): `sudo apt-get`을 시도하고, 실패하면 수동 명령을 안내한다.
  - 링크만 다시 걸 때는 `--skip-deps`.
- `install.sh`의 Antigravity IDE 설정 동기화는 macOS와 Windows(Git Bash로 실행할 때)에서만 한다.

### Windows (PowerShell · CMD, WSL 없이)

Claude 데스크톱 앱이나 Windows 터미널에서 쓰는 방법이다. 먼저 [Git for Windows](https://git-scm.com/downloads/win)를 설치해야 한다(`winget install --id Git.Git -e`).

```powershell
git clone https://github.com/mulgae-life/dotfiles.git "$HOME\dotfiles"
& "$HOME\dotfiles\install.cmd"          # -DryRun 으로 미리 확인 가능
```

CMD에서는 `"%USERPROFILE%\dotfiles\install.cmd"`로 실행하고, 탐색기에서 `install.cmd`를 더블클릭해도 된다. WSL 안에서는 위의 `install.sh`를 쓴다.

- 폴더(rules·agents·skills·hooks)는 정션(junction)으로 연결해 레포 변경이 바로 반영된다. 파일(`CLAUDE.md`·`AGENTS.md`·`GEMINI.md`·상태줄)은 Windows 심볼릭 링크에 개발자 모드나 관리자 권한이 필요해 복사하므로, `git pull` 뒤에 `install.cmd`를 다시 실행한다.
- 개발자 모드를 켜 둔다(설정 앱에서 "개발자용" 검색). `init-project` 스킬이 프로젝트 루트의 `CLAUDE.md`·`AGENTS.md`를 심볼릭 링크로 만드는데, 개발자 모드가 꺼져 있으면 링크를 만들 수 없다. 설치기는 Git Bash의 `ln -s`가 사본 대신 진짜 링크를 만들도록 사용자 환경 변수 `MSYS=winsymlinks:nativestrict`를 넣고, 개발자 모드가 켜져 있으면 git의 `core.symlinks`도 켠다.
- Claude의 훅과 상태줄은 Git Bash로 돈다. Codex 훅은 PowerShell용 명령(`command_windows`)을 따로 둔다. `jq`가 없으면 `winget`으로 설치를 시도한다.
- 데스크톱 앱에서 확인 없이 실행하려면 Settings → Claude Code의 "Allow bypass permissions mode"를 켠다. Team·Enterprise 플랜에서는 조직 정책이 이 설정을 정한다.
- agy는 Windows에서 PowerShell 명령을 전체 줄이 정확히 같을 때만 막아, deny 규칙이 사실상 동작하지 않는다(바이너리 분석 결과이며 실측 전). 상태줄도 `cmd /c`로 실행돼 레포 상태줄은 설치하지 않는다. 근거는 [.antigravity/README.md](.antigravity/README.md).
- 스킬 의존성 자동 설치와 Antigravity IDE 설정 동기화는 하지 않는다.

## ⚡ 자동으로 일어나는 것

| 기능 | 설명 |
|------|------|
| 규칙 자동 적용 | 코딩 스타일·보안·한국어 응답 등 7개 규칙이 매 세션 적용 |
| 무프롬프트 실행 | 확인 없이 실행. 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작 등)만 차단 |
| 에이전트 자동 위임 | 빌드 실패 → `build-resolver`, 보안 민감 코드 → `security-reviewer` |
| 데스크톱 알림 | 입력 대기·턴 완료 시 `notify-send` |
| 상태줄 | 입력창 아래에 프로젝트 · 모델 · effort · 컨텍스트 사용률 · 5시간/주간 한도를 세 도구 모두 표시 |
| compact 리마인더 | 컨텍스트 압축 뒤 "요약을 믿지 말고 파일을 다시 읽으라, 새 요청이 있으면 그것부터"를 주입 |

## 🎯 사용법

- **`시작`**이라고 치면 프로젝트 문서와 핵심 코드를 읽고 현재 상태를 요약한다.
- **`/init-project`** 는 새 프로젝트에 `agent-guide/`(GUIDE · PROJECT · SESSION) 3종을 만든다.
  - 루트 `CLAUDE.md`·`AGENTS.md`가 GUIDE 링크로 생긴다.
  - 그래서 세 도구 모두 전역 지침 뒤에 프로젝트 지침을 이어 읽는다.
- 나머지는 아래 스킬을 `/이름`(Codex는 `$이름`)으로 호출한다.

## ✏️ 페르소나 바꾸기

기본 설정은 사용자를 "대표님"으로 부르고 한국어 합쇼체로 답한다. 호칭·말투·역할을 바꾸려면 포크한 레포에서 아래 세 곳을 같은 내용으로 고친다. 지시 파일이 도구마다 따로 있어서, 한 곳만 고치면 다른 도구는 예전 말투로 답한다.

| 도구 | 파일 | 고칠 자리 |
|------|------|-----------|
| Claude Code | `.claude/rules/communication.md` | `## 페르소나` 절 |
| Codex | `.codex/config.toml` | `developer_instructions`의 `<identity>` 블록 |
| Antigravity CLI | `.antigravity/GEMINI.md` | `<identity>` 블록 |

- 반영 방식은 [설치](#-설치) 그림을 따른다. `config.toml`은 복사본이라 `~/.codex/`에서 직접 고치면 재설치할 때 덮어써진다.
- 응답 언어를 바꾸려면 다음도 함께 고친다.
  - `.claude/settings.json`의 `"language"`
  - 세 파일의 언어 절: `communication.md`의 `## 언어`, `config.toml`의 한국어 표현 항목, `GEMINI.md`의 `<language>`
- 호칭을 바꿨다면 `.claude/skills/cowork-set/`도 고친다. 스킬 본문과 tmux 메시지 머리말(`[대표님 지시]`)이 "대표님"을 전제로 쓰여 있다.

## ⚙️ 스킬 (26개, 세 도구 공용)

출처 열의 "이식"은 공식 저장소의 스킬을 가져온 것, "차용"은 일부 기준만 가져온 것이다. 둘 다 상류 갱신 대상이며 경로와 절차는 [docs/SKILL-SOURCES.md](docs/SKILL-SOURCES.md).

| 분류 | 스킬 | 용도 | 출처 |
|------|------|------|------|
| 프로젝트 | `/start` | 세션 시작 — 문서·핵심 코드 읽고 상태 요약 | 자체 |
| | `/brief` | 프로젝트 목적·기대 대비 진행 현황과 인사이트 브리핑 — 과정·실무 정보 제외 | 자체 |
| | `/init-project` | agent-guide 3종 생성 + 루트 진입 링크 | 자체 |
| | `/update-docs` | 작업 후 프로젝트 문서 갱신 | 자체 |
| | `/harness-evolve` | 세션 회고로 agent-guide 개선점 하나를 반영하고 다음 회고에서 효과 확인 | 자체 |
| | `/skill-creator` | 새 스킬 생성 가이드 | Anthropic 이식 |
| 코드 품질 | `/code-review` | 심각도 등급별 심층 리뷰 리포트 | Anthropic 차용 (오탐 기준만) |
| | `/work-verify` | 작업 후 빠른 점검 | 자체 |
| | `/work-plan` | Phase별 코드 예시 포함 작업 계획서 | 자체 |
| | `/code-simplifier` | 기능 보존 리팩토링 | Anthropic 이식·확장 |
| | `/feedback-analysis` | 사용자 피드백 분석·우선순위 | 자체 |
| 프론트엔드 | `/frontend-design` | 템플릿 티 안 나는 UI 디자인·코드 구현 | Anthropic 이식 |
| | `/stitch-design` | Google Stitch MCP로 UI 디자인 생성·편집, 코드↔디자인 변환 | Google 이식 |
| | `/hw-design` | 한화그룹 디자인 표준(토큰·폰트·로고) 배포 | 자체 |
| | `/hw-ppt` | 한화손해보험 톤 16:9 슬라이드 덱 | 자체 |
| | `/react-best-practices` | React/Next.js 성능 최적화 | Vercel 이식 |
| | `/web-design-guidelines` | 웹 인터페이스 가이드라인 리뷰 | Vercel 이식 |
| | `/visual-check` | Chromium 렌더링 스크린샷·진단으로 UI 결과를 눈으로 검증 | 자체 |
| 백엔드·데이터 | `/postgres-best-practices` | Postgres 스키마·마이그레이션·RLS·쿼리 모범 사례 | Supabase 이식 |
| | `/llm-api-guide` | OpenAI/Anthropic API 연동 | 자체 |
| | `/langchain-guide` | LangChain/LangGraph 에이전트·워크플로우 | 자체 |
| 문서 파일 | `/office-docs` | PDF·Word·PowerPoint·Excel 생성·읽기·편집, 검증·렌더링 검수 스크립트 포함 | Anthropic 이식 (4종 통합) |
| 프롬프트·협업 | `/writing-prompts` | LLM 프롬프트 작성 | 자체 |
| | `/reference-verification` | 논문·수식·벤치마크 인용 시 원문 검증 | 자체 |
| | `/recursive-discussion` | Claude↔Codex 왕복 토론으로 결과물 개선 | 자체 |
| | `/cowork-set` | Claude–Codex 협업 체계를 GUIDE에 세우고 tmux 상대 세션에 확인받음 (직접 호출 전용) | 자체 |

## 🧩 규칙 · 에이전트 · 훅

**규칙 7개** (`.claude/rules/`, 매 세션 자동 적용)

| 파일 | 역할 |
|------|------|
| `coding-style.md` | 코딩 스타일, 에러 처리, 리소스 관리 |
| `security.md` | 시크릿 관리, 입력 검증, 취약점 방지 |
| `architecture.md` | 파일 구조, 단일 역할, 의존성 방향 |
| `communication.md` | 페르소나, 한국어 응답, 변경 이유 설명, 용어 병기 |
| `context-management.md` | 계획 영속화, 부에이전트 공유 |
| `work-principles.md` | 정확성 우선, 위험 명령 통제, 산출물 정리 |
| `agents.md` | 에이전트 자동 위임 조건 |

**에이전트 4개** (`.claude/agents/`, 조건 충족 시 자동 위임)

| 에이전트 | 트리거 |
|----------|--------|
| `build-resolver` | 빌드·타입 에러 |
| `security-reviewer` | 인증·세션·토큰, 암호화, 시크릿 처리 코드 |
| `planner` | 아키텍처 결정이 필요하거나 요구가 불명확할 때, 계획 요청 시 |
| `verifier` | 사용자가 점검을 요청할 때만 |

**훅**

| 도구 | 이벤트 | 동작 |
|------|--------|------|
| Claude Code | PreToolUse(`mcp__.*`) | MCP 자동 승인 |
| | PostToolUseFailure(Bash) | 실패 대응 가이던스 |
| | Notification | 알림 |
| | SessionStart(compact) | 리마인더 |
| Codex | Stop | 알림 |
| | SessionStart(compact) | 리마인더 |
| Antigravity | — | 훅 없음. 알림은 내장 `notifications` |

## 🔧 도구별 구조

| | Claude Code | Codex | Antigravity CLI |
|---|---|---|---|
| 지시 파일 | `CLAUDE.md` + `rules/*.md` | `AGENTS.md` + `config.toml` | `GEMINI.md` |
| 설정 | `settings.json` (복사) | `config.toml` (복사) | `cli/settings.json` (관리 키 병합) |
| 권한 | `bypassPermissions` + deny 90건 (Bash 52 · PowerShell 38) | `approval_policy="never"` + Starlark 규칙 | `always-proceed` + deny 66건 |
| 스킬 | `.claude/skills/` | `~/.agents/skills` 링크 | `~/.gemini/config/skills` 링크 |
| 모델·effort | 기본값 추종(서브에이전트만 Opus 강제) | 기본값 추종 | 기본값 추종 |
| 상태줄 | `statusline-command.sh` | `[tui].status_line` 내장 항목 | `cli/statusline-command.sh` |
| 검증 버전 | 2.1.310 | 0.164.0 | `agy` 1.4.7 (IDE 층 미검증) |

## 📁 디렉토리 구조

```
dotfiles/
├── .claude/          CLAUDE.md · rules/ · agents/ · hooks/ · skills/ · settings.json · statusline-command.sh
├── .codex/           AGENTS.md · config.toml · rules/ (Starlark 차단 규칙) · hooks/ · skills → ../.claude/skills
├── .antigravity/     GEMINI.md · cli/settings.json · cli/statusline-command.sh · README.md (실측·병합 계약) · IDE용 settings·hooks (미검증)
├── scripts/          verify-policies.sh (정책 회귀) · agy-live-check.sh (agy 실측) · windows-live-check.cmd (Windows 차단 실측) · policy-cases.tsv · setup-apparmor.sh
├── docs/             DECISIONS.md(설계 원칙·결정 기록) · SKILL-SOURCES.md(스킬 출처·상류 갱신 절차)
├── reference/        프롬프트 가이드(Claude·OpenAI·Google·Qwen) · 모델 조사 원문(research/) · 디자인 원본
├── install.sh        Linux·macOS·WSL 설치기
└── install.cmd       Windows 네이티브 설치기 (CMD·PowerShell·더블클릭 공용)
```

정책을 고쳤으면 `bash scripts/verify-policies.sh`로 회귀를 확인한다(Codex 실제 엔진 30건 + agy 정적 17건). Windows에서는 `scripts\windows-live-check.cmd`가 세 도구를 실제 설정으로 돌려 차단을 확인한다. 모델을 호출하므로 쿼터를 쓰고, 시험 명령은 막히지 않아도 해가 없게 만들었다. 데스크톱 앱만 쓰는 PC에서는 앱에 들어 있는 `claude.exe`를 찾아 쓰는데, 이 실행 파일은 앱의 로그인을 물려받지 않으므로 처음 한 번 `claude.exe auth login`으로 로그인한다.
