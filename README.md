# 🛠 dotfiles

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) · [Codex](https://github.com/openai/codex) · [Antigravity CLI](https://antigravity.google)(`agy`)의 전역 설정을 한 레포에서 관리한다. 한 번 설치하면 어떤 프로젝트에서든 같은 **규칙 · 에이전트 · 스킬 · 훅**이 적용된다.

원칙은 셋이다. 확인 프롬프트 없이 자율 실행하되 파국형 명령만 기계로 막고, 위험 명령 통제는 지침이 맡으며, Claude 층을 정본으로 다른 도구가 공유한다. 근거와 결정 기록은 [docs/DECISIONS.md](docs/DECISIONS.md), 버전별 변경은 [CHANGELOG.md](CHANGELOG.md).

## 📦 설치

```bash
git clone https://github.com/mulgae-life/dotfiles.git ~/dotfiles
~/dotfiles/install.sh            # --dry-run 으로 미리 확인 가능
```

- 대부분은 `~/dotfiles/` → `~/` 심볼릭 링크다. 도구가 되쓰는 `settings.json`·`config.toml`은 복사, `agy` settings는 관리 키만 병합한다. 재설치하면 런타임에서 바꾼 모델·effort 같은 값은 레포 기본으로 돌아온다.
- `jq`가 없으면 자동 설치를 시도한다. Antigravity IDE 설정 동기화는 macOS·Windows만.

## ⚡ 자동으로 일어나는 것

| 기능 | 설명 |
|------|------|
| 규칙 자동 적용 | 코딩 스타일·보안·한국어 응답 등 7개 규칙이 매 세션 적용 |
| 무프롬프트 실행 | 확인 없이 실행. 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작 등)만 차단하고 `rm`·`git push`·`sudo` 같은 위험 명령은 사용자가 요청할 때만 쓰도록 지침으로 통제 |
| 에이전트 자동 위임 | 빌드 실패 → `build-resolver`, 보안 민감 코드 → `security-reviewer` |
| 데스크톱 알림 | 입력 대기·턴 완료 시 `notify-send` |
| compact 리마인더 | 컨텍스트 압축 뒤 "요약을 사실로 단정하지 말고 파일을 다시 읽으라"를 주입 |

## 🎯 사용법

- **`시작`** 이라고 치면 프로젝트 문서와 핵심 코드를 읽고 현재 상태를 요약한다.
- **`/init-project`** 로 새 프로젝트에 `agent-guide/`(GUIDE · PROJECT · SESSION) 3종을 만들면, 루트 `CLAUDE.md`·`AGENTS.md`가 GUIDE 링크로 생겨 세 도구가 전역 지침 뒤에 프로젝트 지침을 이어 읽는다.
- 나머지는 아래 스킬을 `/이름`(Codex는 `$이름`)으로 호출한다.

## ⚙️ 스킬 (21개, 세 도구 공용)

| 분류 | 스킬 | 용도 |
|------|------|------|
| 프로젝트 | `/start` | 세션 시작 — 문서·핵심 코드 읽고 상태 요약 |
| | `/init-project` | agent-guide 3종 생성 + 루트 진입 링크 |
| | `/update-docs` | 작업 후 프로젝트 문서 갱신 |
| | `/skill-creator` | 새 스킬 생성 가이드 |
| 코드 품질 | `/code-review` | 심각도 등급별 심층 리뷰 리포트 |
| | `/work-verify` | 작업 후 빠른 점검 |
| | `/work-plan` | Phase별 코드 예시 포함 작업 계획서 |
| | `/code-simplifier` | 기능 보존 리팩토링 |
| | `/feedback-analysis` | 사용자 피드백 분석·우선순위 |
| 프론트엔드 | `/frontend-design` | 코드 기반 프로덕션 UI 제작 |
| | `/stitch-design` | Google Stitch MCP 기반 AI UI 디자인 |
| | `/hw-design` | 한화그룹 디자인 표준(토큰·폰트·로고) 배포 |
| | `/hw-ppt` | 한화손해보험 톤 16:9 슬라이드 덱 |
| | `/react-best-practices` | React/Next.js 성능 최적화 |
| | `/web-design-guidelines` | 웹 인터페이스 가이드라인 리뷰 |
| 백엔드·데이터 | `/postgres-best-practices` | Postgres 쿼리·스키마 최적화 |
| | `/llm-api-guide` | OpenAI/Anthropic API 연동 |
| | `/langchain-guide` | LangChain/LangGraph 에이전트·워크플로우 |
| 프롬프트·협업 | `/writing-prompts` | LLM 프롬프트 작성 |
| | `/reference-verification` | 논문·수식·벤치마크 인용 시 원문 검증 |
| | `/recursive-discussion` | Claude↔Codex 왕복 토론으로 결과물 개선 |

## 🧩 규칙 · 에이전트 · 훅

**규칙 7개** (`.claude/rules/`, 매 세션 자동 적용)

| 파일 | 역할 |
|------|------|
| `coding-style.md` | 코딩 스타일, 에러 처리, 리소스 관리 |
| `security.md` | 시크릿 관리, 입력 검증, 취약점 방지 |
| `architecture.md` | 파일 구조, 단일 역할, 의존성 방향 |
| `communication.md` | 한국어 응답, 변경 이유 설명, 용어 병기 |
| `context-management.md` | 계획 영속화, 부에이전트 공유 |
| `work-principles.md` | 정확성 우선, 위험 명령 통제, 산출물 정리 |
| `agents.md` | 에이전트 자동 위임 조건 |

**에이전트 4개** (`.claude/agents/`, 조건 충족 시 자동 위임)

| 에이전트 | 트리거 |
|----------|--------|
| `build-resolver` | 빌드·타입 에러 |
| `security-reviewer` | 인증·인가, API, 시크릿 코드 |
| `planner` | 아키텍처 결정이 필요하거나 요구가 불명확할 때, 계획 요청 시 |
| `verifier` | 사용자가 점검을 요청할 때만 |

**훅**

| 도구 | 이벤트 → 동작 |
|------|--------------|
| Claude Code | PreToolUse(`mcp__.*`) → MCP 자동 승인 · PostToolUseFailure(Bash) → 실패 대응 가이던스 · Notification → 알림 · SessionStart(compact) → 리마인더 |
| Codex | Stop → 알림 · SessionStart(compact) → 리마인더 |
| Antigravity | 훅 없음 — 알림은 내장 `notifications` |

## 🔧 도구별 구조

| | Claude Code | Codex | Antigravity CLI |
|---|---|---|---|
| 지시 파일 | `CLAUDE.md` + `rules/*.md` | `AGENTS.md` + `config.toml` | `GEMINI.md` |
| 설정 | `settings.json` (복사) | `config.toml` (복사) | `cli/settings.json` (관리 키 병합) |
| 권한 | `bypassPermissions` + deny 49건 | `approval_policy="never"` + Starlark 규칙 | `always-proceed` + deny 66건 |
| 스킬 | `.claude/skills/` | `~/.agents/skills` 링크 | `~/.gemini/config/skills` 링크 |
| 모델·effort | 기본값 추종(서브에이전트만 Opus 강제) | 기본값 추종 | 기본값 추종 |
| 검증 버전 | 2.1.258 | 0.153.4 | `agy` 1.1.27 (IDE 층 미검증) |

## 📁 디렉토리 구조

```
dotfiles/
├── .claude/          CLAUDE.md · rules/ · agents/ · hooks/ · skills/ · settings.json · statusline-command.sh
├── .codex/           AGENTS.md · config.toml · rules/ (Starlark 차단 규칙) · hooks/ · skills → ../.claude/skills
├── .antigravity/     GEMINI.md · cli/settings.json · README.md (실측·병합 계약) · IDE용 settings·hooks (미검증)
├── scripts/          verify-policies.sh (정책 회귀) · agy-live-check.sh (agy 실측) · policy-cases.tsv · setup-apparmor.sh
├── docs/DECISIONS.md 설계 원칙·결정 기록·아카이브 위치
├── reference/        프롬프트 가이드(Claude·OpenAI·Google·Qwen) · 모델 조사 원문(research/) · 디자인 원본
└── install.sh
```

정책을 고쳤으면 `bash scripts/verify-policies.sh`로 회귀를 확인한다(Codex 실제 엔진 20건 + agy 정적 16건).
