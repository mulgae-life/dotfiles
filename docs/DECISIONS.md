# 설계 원칙과 결정 기록

> README는 사용법을, 이 문서는 "왜 이렇게 했는가"를 담는다. 버전별 변경은 [CHANGELOG.md](../CHANGELOG.md).

## 1. 설계 원칙

### 자율성 우선, 최소 차단

- 모든 작업을 확인 프롬프트 없이 실행한다. 장기 작업이 중간에 멈추지 않게 하기 위해서다(Claude Code는 ask 규칙을 모두 해제).
- 위험 명령(`rm`·`git push`·`sudo` 등)은 지침이 통제한다. 자율 작업 중에는 쓰지 않고, 사용자가 요청할 때만 쓴다.
- 기계 차단(`permissions.deny`)은 파국형 명령(루트·홈 삭제, 디스크 파괴, 전원 조작)과 넓은 재귀 삭제만 막는다. 범위는 도구마다 다르다(§3).
- Claude Code는 bypass 모드에서도 핵심 경로의 `rm`에 확인창을 띄우고, 2분간 응답이 없으면 거부한다. 거부 뒤에도 작업이 이어지므로 이 기본값을 그대로 둔다. 지침은 이 확인창에 기대지 말라고만 적는다.

### auto 모드를 쓰지 않는다

- Claude Code의 auto 모드는 차단이 3회 연속 또는 20회 누적되면 승인 대기로 바뀌고, 이 기준은 조정할 수 없다.
- 무중단 원칙과 맞지 않아 `bypassPermissions`를 유지한다.
- Codex의 Guardian auto-review도 `approval_policy = "never"`에서는 검토할 요청이 생기지 않아 쓰지 않는다.

### 메모리 기능을 쓰지 않는다

- **Codex 공식 메모리**(`features.memories = false`)
  - 전역에 하나뿐이라 프로젝트가 섞이고, 무엇을 남길지 모델이 정한다.
  - 백그라운드 모델 호출로 사용량을 쓰고, 세션 중에는 읽기만 된다.
  - 교훈은 프로젝트별 `.codex/lessons.md`가 맡는다. 자동으로 주입되지 않으므로 `AGENTS.md`가 세션 시작 때, compact 리마인더가 압축 뒤에 읽게 한다.
- **서브에이전트 영구 메모리**(`memory: project`)
  - 프로젝트마다 폴더를 만들었지만 쌓인 메모가 거의 없었고, 빈 폴더와 미추적 파일만 남겼다.
  - 교훈은 본 대화의 자동 메모리가 맡는다.

### 모델과 effort는 고정하지 않는다

- 세 도구 모두 기본값을 따른다. 세대가 바뀌어도 설정이 낡지 않게 하기 위해서다.
- 런타임에 고른 값(`/model`·`/effort`)은 재설치하면 레포 값으로 돌아간다.
- 예외는 Claude 서브에이전트의 두 설정이다.
  - 모델은 Opus로 강제한다(`CLAUDE_CODE_SUBAGENT_MODEL=opus` + `_FORCE=1`). Fable 계열은 구독 한도를 다른 Claude 모델보다 빨리 쓰고 주간 사용 상한도 따로 있어, 서브에이전트가 Fable을 상속하며 사용량이 늘어나는 것을 막기 위해서다.
  - effort는 `high`로 고정한다(§4의 훅). Claude Code 2.1.317부터 메인과 모델이 다른 서브에이전트는 세션 effort를 이어받지 않아 medium에서 xhigh까지 갈렸기 때문이다.

### Claude 층이 정본이다

- 그대로 공유할 수 있는 자산(스킬 등)은 다른 도구가 `.claude/`를 링크로 받는다.
- 도구마다 형식이 달라야 하는 규칙 본문(Codex `config.toml`, Antigravity `GEMINI.md`)은 직접 동기화한다.
- 일부만 맞는 자산을 링크하려고 정본 구조를 쪼개지 않는다.

### 공개 레포에는 릴리즈만 올린다

- 공개 레포는 커밋 메시지와 작성자 이메일까지 보이는데, GitHub에는 기록만 숨기는 설정이 없다.
- 커밋 기록은 비공개 작업 레포에 두고, 공개 레포에는 `scripts/publish-release.sh`가 릴리즈 시점의 파일을 커밋 하나로 올린다.
  - 새 커밋의 부모가 공개 레포의 직전 릴리즈라 비공개 기록은 전송되지 않는다.
  - 작성자는 GitHub 대리 주소(noreply)로 남는다.
- 기록을 한 커밋으로 합쳐 강제 푸시하는 방법은 옛 커밋이 해시로 계속 열려 쓰지 않았다.
- 로컬 작업 폴더는 `~/dotfiles` 하나다. 원격 `origin`은 비공개 레포를, `public`은 공개 레포를 가리킨다.

## 2. 설치 방식 — 링크 · 복사 · 병합

`install.sh`는 `~/dotfiles/`에서 `~/`로 심볼릭 링크를 만든다. 도구가 런타임에 되쓰는 파일은 링크하면 레포 원본이 오염되므로 방식을 나눈다.

| 방식 | 대상 | 이유 |
|------|------|------|
| 링크 | `CLAUDE.md`, `rules/`, `agents/`, `skills/`, `hooks/`, `AGENTS.md`, `GEMINI.md` 등 | 도구가 읽기만 한다 |
| 복사 | `.claude/settings.json`, `.codex/config.toml` | 도구가 되쓴다(`/model`·`/effort`, 신뢰 폴더, 훅 신뢰 해시). 레포가 정본이라 재설치가 런타임 값을 덮어쓴다. Codex는 훅 신뢰가 풀리면 `/hooks`에서 한 번 다시 승인한다 |
| 병합 | `~/.gemini/antigravity-cli/settings.json` | `agy`가 모델·신뢰 폴더·승인 캐시를 같은 파일에 되쓴다. 레포의 관리 키만 적용하고 나머지는 보존한다. 실패하면 파일을 건드리지 않고 종료 코드 1로 끝난다. 상세는 [.antigravity/README.md](../.antigravity/README.md) |
| 병합(IDE) | Antigravity IDE 전역 settings | 런타임 필드를 보존하는 깊은 병합. macOS·Windows만 하고, Linux는 경로를 확인하지 못해 안내만 출력한다 |

- 런타임 데이터(`projects/` 등)는 건드리지 않는다. `jq`가 없으면 자동 설치를 시도한다.
- 스킬 공유 경로
  - Codex는 `~/.agents/skills → ~/.claude/skills`로 받는다.
  - Antigravity는 CLI용 `~/.gemini/config/skills`와 IDE용 `~/.gemini/antigravity/skills`로 따로 연결한다. `~/.gemini/antigravity-cli/skills`는 `agy`가 스스로 만드는 링크라 관리하지 않는다.
  - 은퇴한 Gemini CLI가 `~/.gemini` 바로 아래 남긴 링크는 설치 때 정리한다.

### Windows 네이티브 설치 (`install.cmd`)

WSL 없이 Claude 데스크톱 앱이나 Windows 터미널을 쓰는 경우를 위해, `install.sh`와 같은 대상에 같은 규칙으로 설치한다. 다른 점은 다음과 같다.

- **연결 방식**: 폴더는 정션(junction)으로 연결하고 파일은 복사한다. 파일 심볼릭 링크는 개발자 모드나 관리자 권한이 필요하기 때문이다. 설치기가 만든 사본은 해시를 `.install-state.json`에 남겨, 다음 설치 때 백업 없이 덮어쓴다.
- **Git for Windows 필수**: 훅과 상태줄이 Git Bash로 돌아야 한다. Git Bash가 없으면 Claude Code가 훅을 PowerShell로 돌려 `.sh` 훅이 깨진다.
- **줄바꿈 LF 고정**: Windows 기본값(`core.autocrlf=true`)은 `.sh`를 CRLF로 바꿔 실행을 막고 `SKILL.md` 크기도 바꾸므로 `.gitattributes`로 LF를 고정한다.
- **설치기 한 파일**: 앞쪽 ASCII 배치 부분이 PowerShell을 띄워 파일 전체를 UTF-8로 실행한다. `.ps1`만 두면 실행 정책에 막히고, 파일이 둘이면 무엇을 실행할지 헷갈린다. cmd.exe가 읽는 배치 부분은 ASCII로만 쓰고, 파일은 BOM 없이 저장한다.
- **진짜 링크 강제**: Git Bash의 `ln -s`는 개발자 모드에서도 기본이 사본이라, `init-project`의 루트 `CLAUDE.md`·`AGENTS.md`가 `GUIDE.md`와 어긋난다. 그래서 사용자 환경 변수 `MSYS=winsymlinks:nativestrict`를 넣는다. git의 `core.symlinks`는 개발자 모드일 때만 켠다. 링크를 만들 수 없는데 켜 두면 클론이 실패한다.
- **Codex 훅**: Windows에서는 훅이 PowerShell로 돌아 `command_windows`에 대체 명령을 둔다. 한글이 깨지지 않게 비ASCII 문자는 `\uXXXX`로 내보낸다.
- **상태줄 `jq`**: Git Bash의 `jq.exe`는 줄 끝을 CRLF로 내므로 `-b`를 붙인다.
- **agy**: Windows에서는 상태줄을 `cmd /c`로 돌려 레포 `statusLine`을 빼고 병합한다. `~/.antigravity`는 Windows에서 구버전 Antigravity의 확장 폴더라 연결하지 않는다.
- **하지 않는 것**: 스킬 의존성 설치(Linux 가상환경 경로를 전제), Antigravity IDE 층, Gemini CLI 잔여 링크 정리.

### 레포 안에서 작업할 때

- 레포의 `.claude/`·`.codex/`는 이 폴더에서 프로젝트 설정으로도 읽힌다.
- Claude는 같은 훅을 한 번만 돌리고, 프로젝트 파일의 `bypassPermissions`는 무시한다.
- Codex는 층마다 훅을 누적해, 이 레포에서는 알림과 리마인더가 두 번 등록된다. 설정을 바로 확인할 수 있어 그대로 둔다.

## 3. 권한 통제 — 도구별 상세

| | Claude Code | Codex | Antigravity CLI |
|---|---|---|---|
| 모드 | `defaultMode: bypassPermissions` | `approval_policy = "never"` + `sandbox_mode = "danger-full-access"` | `toolPermission`·`artifactReviewPolicy`: `always-proceed` |
| 기계 차단 | `permissions.deny` 90건 (Bash 52 · PowerShell 38) | Starlark `rules/default.rules` (`forbidden`) | `permissions.deny` 66건 |
| 차단 범위 | 파국형 + 넓은 재귀 삭제 | 위험 명령 전반(삭제, Git 쓰기, `sudo`, `chmod` 등) | 파국형만 |
| 회귀 검증 | 실제 엔진 44건 + Windows 실기기 21건 | `scripts/verify-policies.sh codex` 30건 | `scripts/verify-policies.sh agy` 17건 + `scripts/agy-live-check.sh` 6건 |

### Claude Code

- `bypassPermissions`와 진입 확인창 생략(`skipDangerousModePermissionPrompt`)은 사용자 settings에서만 읽힌다. 그래서 레포의 settings.json에 두고 설치 때 복사한다.
- 규칙의 `*`는 공백을 포함한 임의 문자열에 맞는다. 그래서 `rm -rf /*`·`rm -rf ./*`는 절대경로와 `./` 아래의 `rm -rf` 전부를 막는다.
- PowerShell 규칙은 같은 범위를 옮긴 것이다. `Remove-Item`의 경로와 `-Recurse` 순서마다 규칙을 둔다. `.`·`..` 경로는 `release..old` 같은 일반 이름이 걸리지 않게 공백 경계를 지킨다.
- 규칙 문자열을 쓸 때 주의할 점
  - 역슬래시는 두 번 해석된다. JSON의 `\\`가 `\` 하나가 되고, `\*`는 문자 그대로의 별표다. 그래서 `C:\`·`.\` 뒤 와일드카드는 JSON에 역슬래시 8개를 쓴다.
  - 끝이 `:*`인 규칙은 옛 접두 문법으로 읽혀 `C:*` 같은 형태는 쓸 수 없다.
- Git Bash의 `C:/` 경로 `rm -rf`도 막는다.
- 회귀 검증은 두 가지로 했다. Linux에서는 PowerShell 도구를 켜고 `dontAsk` 모드로 44건(차단 33, 대조군 11)을, Windows 실기기에서는 `scripts\windows-live-check.cmd`로 21건을 확인했다.

### Codex

- 차단 규칙은 명령 앞부분만 맞추는 `prefix_rule`이라, 인자값이나 임의 위치는 맞추지 못한다.
- Windows에서는 PowerShell 스크립트를 명령 단위로 나눠 대조하므로 `Remove-Item` 계열과 전원·디스크 cmdlet을 더했다. 첫 토큰은 철자 그대로 대조해 정식 표기, 소문자, `.exe` 표기를 함께 둔다. 그 밖의 대소문자 조합은 막지 못한다.
- 샌드박스를 끈 이유는 exec 샌드박스가 `/dev`를 덮어 GPU 장치가 보이지 않기 때문이다. 대신 `shell_environment_policy`로 시크릿 환경 변수 유출을 막는다.
- 훅 신뢰는 정의의 해시로 기록된다. 새로 만들거나 바꾼 훅은 `/hooks`에서 신뢰할 때까지 건너뛴다.

### Antigravity CLI

- deny는 토큰 단위 정확 일치와 접두 매칭만 된다. 글롭과 `regex:`가 동작하지 않아 `rm -rf /home*` 같은 규칙은 옮길 수 없다. `dd`·`fdisk`·`parted`·`shred`는 지침으로 통제한다.
- Windows에서는 PowerShell 명령을 줄 전체 정확 일치로만 판정해 deny가 사실상 동작하지 않는다(바이너리 분석 기준, 실측 전).

## 4. 훅 결정 기록

| 도구 | 결정 | 이유 |
|------|------|------|
| Claude | Bash 자동승인 훅 은퇴, `permissions.ask` 전면 해제 (v2.10) | 텍스트 매칭이 따옴표 속 문구를 명령으로 오인하는 오탐이 쌓였고, ask 규칙은 bypass 모드에서도 떠서 작업 흐름을 끊었다 |
| Claude | MCP 자동승인 훅(PreToolUse `mcp__.*`) 유지 | 의도된 정책이다. 보안 리뷰에서 취약점으로 다루지 않는다 |
| Claude | 서브에이전트 effort 훅(PreToolUse `Agent`) 추가 (v2.67) | 서브에이전트에만 적용되는 effort 설정이 없다. 세션 effort 설정은 메인 대화까지 묶고, 에이전트 정의의 `effort`는 내장 에이전트에 닿지 않는다. effort를 직접 넘긴 호출과 fork는 건드리지 않는다. 워크플로 에이전트와 에이전트 팀은 실측하지 않았다 |
| Claude·Codex | compact 리마인더를 SessionStart(`compact`)에 둠 (v2.21) | PostCompact 출력은 모델에 전달되지 않는다 |
| Claude·Codex | 리마인더가 이전 작업 재개를 재촉하지 않음 (v2.40) | 압축 직후의 새 요청이 이전 작업 재개로 흡수된 사례가 있었다. 새 메시지가 있으면 그것이 이번 턴의 작업임을 못 박는다 |
| Codex | 실패알림 훅(PostToolUse) 제거 (v2.0) | payload에 exit code가 없고 실패 전용 이벤트도 없어 실패를 판정할 수 없다 |
| Codex | PreToolUse 의도적 미설정 | `approval_policy = "never"`와 Starlark 규칙이 이미 통제한다 |
| Antigravity | 훅 미사용 | 알림은 내장 기능(`notifications: true`)을 쓴다. 압축 후 이벤트가 없고, 모델 호출마다 도는 이벤트는 리마인더 용도로 과하다 |

## 5. 도구별 세부 사항

| | Claude Code | Codex | Antigravity |
|---|---|---|---|
| 커스텀 명령 | 스킬(`/이름`) | 스킬(`$이름`·`/skills`) | 스킬(`/이름`, 헤드리스 `-p "/이름 …"`도 가능) |
| 에이전트 | `agents/*.md` 4개 | 없음(`AGENTS.md`의 역할 트리거로 대응) | 정의 없음 |
| 지시 파일 경로 | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/GEMINI.md` |
| IDE 층 | — | — | `.antigravity/settings.json`·`hooks/` 추정치, 미검증 |

- **agy 스킬 본문 한도**: `SKILL.md` 본문의 앞 24,000바이트만 읽는다. `verify-policies.sh`가 정적 검사로 막고, 영문 원문을 유지하는 이식 스킬 `skill-creator`만 예외로 둔다. 이 스킬에서 잘리는 뒷부분은 Claude 전용 기능 설명과, 앞에서 이미 언급한 참고 파일 목록이다.
- **agy 지시 파일**: `~/.gemini/config/GEMINI.md`는 비공식 경로라 쓰지 않는다. 다른 파일을 두면 두 번 주입된다.
- **약관**: Antigravity 로그인 자격 증명을 타사 클라이언트에서 재사용하는 것은 공식 FAQ의 제한 대상이다. 공식 `agy`를 다른 에이전트가 호출하는 구성에 적용되는지는 확인하지 못했다.

## 6. 지침·스킬 결정

### 레퍼런스 검증은 필요할 때 부르는 스킬로 둔다 (v2.12)

- 상시 로드 규칙에서 `/reference-verification` 스킬로 옮기고, `work-principles`에는 호출 조건 한 줄만 남겼다.

### 규칙끼리 기준이 겹치면 담당을 나눈다 (v2.45)

- `security-reviewer`의 자동 위임 범위는 `rules/agents.md` 표(인증, 암호화, 시크릿)가 정한다. 취약점 발견 뒤의 대응은 `rules/security.md`가 맡는다.
- 충돌할 때 코드 품질은 프로젝트 문서가 먼저이고(`coding-style.md`), 파일 배치는 기존 구조가 먼저다(`architecture.md`). 두 순서를 통일하지 않고, `coding-style.md`가 구조 판단을 `architecture.md`에 넘긴다.

### 멈춤을 줄이자는 제안은 필요한 곳만 받는다 (v2.46)

- 파일 트리 사전 합의만 "파일 2개 이상"에서 "새 디렉토리나 모듈 구조를 정할 때"로 올렸다. 파일 2개는 거의 모든 작업에 해당하고, 구조 이탈은 `architecture.md`가 이미 막는다.
- 질문, 계획 저장, 재현 테스트, 토론 최소 라운드의 기준은 그대로 둔다. 각각 조건이 이미 있거나, 과잉 합의를 막는 핵심 장치다.

### `writing-prompts`는 계열별 최근 세 세대를 지원한다 (v2.48)

- 계열은 Claude(Opus, Sonnet, Fable, Haiku), GPT, Gemini(Argon·Carbon, Flash, Flash-Lite, Pro)로 나눈다. 공급자가 은퇴시킨 모델은 뺀다. Gemma와 Qwen은 최신 세대만 둔다.
- 대상 모델 ID와 API 방식을 먼저 확정한다. 패키지 이름으로 공급자를 추정하지 않는다. `openai` 라이브러리로 Gemini를 부를 수도 있기 때문이다.
- 목록 밖 모델은 다른 모델로 바꾸지 않고, 공식 계약과 공통 기법만 적용한다.
- 예시 개수 같은 수치는 범용 체크리스트에 두지 않고, 근거가 있는 모델 문서에만 둔다.

### 협업 회신은 직접 신호로 알린다 (v2.71)

- 파트너가 회신을 쓰면 신호를 남기고, 중심은 그 신호를 받아 회신을 읽는다. 중심이 상대 화면을 주기적으로 읽으며 기다리던 방식을 대신한다.
- 신호는 중심 대화창에 넣지 않는다. 대표님이 주로 쓰는 곳이라, 글을 넣으면 사용자 입력처럼 남고 대표님이 쓰던 글과 섞일 수 있다. 신호 파일에 붙이고 수신기가 그 줄을 출력한다.
- 이 규칙은 도구가 아니라 역할에 붙는다. 중심이 Claude면 백그라운드 수신기가 끝나며 Claude를 깨운다. 중심이 Codex면 요청을 보낸 턴 안에서 수신기가 끝나기를 기다린다. 유휴 상태의 Codex를 신호로 깨우는 방법은 찾지 못했다.
- 수신기가 꺼져 있으면 신호는 파일에 남아 다음 수신기가 읽는다. 입력창으로 대신 보내지 않는다.
- 중심은 파트너 입력창에 직접 넣는다. 작업 중인 쪽에는 닿지 않으므로, 파트너는 답이 필요한 질문을 신호로 남긴 뒤 턴을 끝낸다.

## 7. 은퇴·아카이브

`.archive/`는 레포에 올리지 않는 로컬 보관소다.

| 항목 | 시점 | 위치 |
|------|------|------|
| Gemini CLI 층 (개인 계정 지원 종료) | 2026-09-07 | `.archive/2026-09-07_gemini-cli-retirement/` |
| Claude Bash 자동승인 훅과 ask 규칙 81건 | 2026-07-18 | `.archive/2026-07-18_hook-retirement/` |
| Codex PostToolUse 실패알림 훅 | 2026-07-02 | `.archive/2026-07-02_codex-dead-hook/` |
| `/start` 커스텀 명령 (공용 스킬로 전환) | 2026-09-07 | `.archive/2026-09-07_start-to-skill/` |
| 상시 로드 지침 감량 전 원본 (393→250줄) | 2026-08-13 | `.archive/2026-08-13_rules-slimming/` |
| 지원 범위 밖 모델 자료 | v2.20, v2.48 | `reference/archive/` |

모델·도구 조사 원문은 `reference/research/`에 있다.
