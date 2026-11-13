# 변경 이력

버전마다 무엇이 바뀌었는지 적는다. 결정의 이유는 [docs/DECISIONS.md](docs/DECISIONS.md)에 있고, 공개 레포의 [릴리즈 노트](https://github.com/mulgae-life/dotfiles/releases)는 같은 버전 절의 내용이다.

## v2.71 — 협업 회신을 직접 신호로 알린다
- `cowork-set`의 `peer.sh`에 `signal`과 `listen`을 더했다. 파트너가 회신을 쓰고 신호를 남기면 중심의 수신기가 그 줄을 받는다. 중심이 Claude면 백그라운드 수신기가 끝나면서 Claude가 깨어난다.
- 신호는 대표님이 주로 대화하는 중심 쪽 대화창에 넣지 않고 신호 파일에 남긴다. 중심이 파트너에 알릴 때는 전처럼 입력창에 넣는다.
- 협업 절의 역할을 중심과 파트너로 적어 어느 도구든 중심이 될 수 있게 했다. 중심은 상대 화면을 지켜보며 기다리지 않고, 보낸 요청의 회신을 신호로 받는다.

## v2.70 — Claude Fable 5.2와 Gemini 4 Carbon 반영
- Fable 5.2 가이드를 새로 쓰고, 5.1에서 넘어올 때 깨지는 API 계약 네 가지와 행동 변화를 스킬에 반영했다. 기존 Claude 가이드의 이력 검사와 CMEK 서술도 현재 공식 문서에 맞췄다.
- Gemini 4 Carbon을 Argon 문서에 더하고, Cloud 캐시 최소 길이와 장문 출력 등 Argon의 낡은 서술을 고쳤다.
- 검증 버전을 Claude Code 2.1.322, Codex 0.167.2, agy 1.5.6으로 올렸다.

## v2.69 — 결정 기록과 변경 이력을 개조식으로 재작성
- `docs/DECISIONS.md`의 긴 문단을 소제목과 짧은 불릿으로 바꾸고, 지침·스킬 결정을 별도 절로 모았다.
- 이 문서를 버전별 절(제목 한 줄과 불릿)로 바꾸고, 측정 횟수나 조사 경위 같은 세부 사항은 뺐다.
- `scripts/publish-release.sh`가 새 형식에서 릴리즈 제목과 노트를 읽는다.

## v2.68 — 작업 레포와 공개 레포 분리
- 커밋 기록은 비공개 작업 레포에 두고, 공개 레포에는 릴리즈 시점의 파일만 올린다.
- 릴리즈는 `scripts/publish-release.sh`로 한다. 비공개 기록은 전송되지 않고, 작성자는 GitHub 대리 주소로 남는다.
- 설치 명령은 그대로다. 분리 전 사본도 원격 주소와 보존할 로컬 변경을 확인한 뒤 최신 공개 버전으로 맞출 수 있다.

## v2.67 — 서브에이전트 effort를 `high`로 고정
- Claude Code 2.1.317부터 메인과 모델이 다른 서브에이전트가 세션 effort를 이어받지 않아 medium에서 xhigh까지 갈렸다.
- PreToolUse(`Agent`) 훅이 호출 입력에 `effort: "high"`를 넣는다. effort를 직접 넘긴 호출과 fork는 건드리지 않는다.

## v2.66 — GPT-6.1 Terra 반영
- GPT-6 문서에 Terra를 더했다. `none`은 받지만 Chat Completions의 도구 호출은 막혀 있다.
- 같은 문서의 고속 모드, 캐싱, Codex 기본 창(500K) 서술을 바로잡았다.

## v2.65 — Windows 차단 실측 스크립트 추가
- `scripts/windows-live-check.cmd`가 그 PC의 실제 설정으로 도구를 돌려 위험 명령이 막히는지 확인한다.
- 모델의 답변이 아니라 도구의 기록과 시험 폴더가 남았는지로 판정한다.

## v2.64 — `writing-prompts`에 프롬프트 파일 문체 점검 추가
- 프롬프트 파일을 장황한 산문 대신 개조식으로 쓰고, 모델 행동을 바꾸지 않는 정보와 상투어를 빼게 했다.

## v2.63 — Windows 설치기를 `install.cmd` 한 파일로 통합
- 앞쪽 배치 부분이 PowerShell을 띄워 파일 전체를 실행한다.
- Git Bash의 `ln -s`가 링크 대신 사본을 만들던 문제를 `MSYS=winsymlinks:nativestrict`로 고쳤다.

## v2.62 — Windows 네이티브 설치기 추가
- WSL 없이 Claude 데스크톱 앱이나 Windows 터미널에서 세 도구를 설치한다.
- 줄바꿈을 `.gitattributes`로 LF로 고정했다.
- 차단 규칙과 지침에 Windows 항목(PowerShell, Git Bash `C:/` 경로)을 더했다. agy deny는 Windows에서 사실상 동작하지 않는다.

## v2.61 — `llm-api-guide` 에러 처리 예제 수정
- 예제가 부모 클래스 `APIError`에서 `status_code`를 읽어, 스트리밍 중 오류에서는 `AttributeError`가 원래 예외를 덮었다.
- `status_code`는 `APIStatusError` 분기에서만 읽도록 고쳤다.

## v2.60 — agy가 잘라 읽던 `writing-prompts` 본문 축소
- agy는 `SKILL.md` 본문의 앞 24,000바이트만 읽어, 끝의 참고 자료가 경고 없이 빠지고 있었다.
- 링크 목록을 `references/sources.md`로 옮기고, `verify-policies.sh`에 본문 크기 검사를 넣었다.

## v2.59 — Claude API `2026-10-21` 반영
- `llm-api-guide`에 API 버전과 SDK 절을 넣었다(SDK 메이저별 기본 날짜, 새 400 오류, Python 2.0·TypeScript 1.0 변경).
- 새 버전에서 400이 나는 sampling 서술을 버전별로 나눴고, 낡은 `Timeout` 예제를 고쳤다.
- Codex를 인라인 모드로 바꿔 tmux에서 마우스를 잡지 않게 했다.

## v2.58 — Gemini 4 Argon 반영
- 풀 가이드와 `writing-prompts` 패턴 요약을 새로 만들었다. 3.x 처방은 Argon에 그대로 옮기지 않는다.
- 같은 주에 바뀐 3.x 모델 상태(폐기, 자동 연결, 종료 일정)를 바로잡았다.
- agy 상태줄이 Argon을 고르면 별도 주간 쿼터도 보여 준다.

## v2.57 — `/brief` 분량과 문체 개정
- 같은 사실이 여러 절에 반복되던 것을 "한 사실은 한 곳에만"으로 정리하고, 상한을 60줄에서 40줄로 낮췄다.
- 문체를 음슴체 개조식(불릿 하나에 사실 하나)으로 바꿨다.

## v2.56 — Codex 스킬 목록에 `office-docs` 추가
- 처음 이식할 때부터 목록에서 빠져 있었다.

## v2.55 — 서브에이전트 영구 메모리 제거
- `verifier`·`security-reviewer`가 프로젝트마다 메모리 폴더를 만들었지만 쌓인 메모가 거의 없었다. 교훈은 자동 메모리가 맡는다.

## v2.54 — 협업 체계 세팅 스킬 `cowork-set` 추가
- 프로젝트 유형에 맞는 Claude·Codex 역할과 협업 관행(지시서 형식, 라운드 기록 등)을 GUIDE 협업 절로 기록한다.
- 상대 tmux 세션과 주고받는 기능은 `peer.sh`로 모았다.

## v2.53 — Haiku 5.5 반영
- 풀 가이드를 새로 만들고, `writing-prompts` 라우팅과 `llm-api-guide` 모델 표에 넣었다.
- Haiku 4.5 대비 파괴적 변경과 Sonnet 5.5 캐시 읽기 가격 인하를 반영했다.

## v2.52 — 도구 버전 현행화
- Claude Code·Codex·agy 변경 이력을 대조해 설정 변경이 필요 없음을 확인했다.
- agy가 같은 파일을 가리키는 지침 링크를 한 번만 읽게 바뀌어, 이중 주입 서술을 고쳤다.

## v2.51 — `harness-evolve` 스킬 추가
- 세션 기록을 회고해 프로젝트 `agent-guide`의 개선점 하나를 제안하고, 승인받으면 반영한다.
- 다음 회고에서 효과를 확인해 유지하거나 되돌린다. 전역 지침은 대상이 아니다.

## v2.50 — 스킬 템플릿 형식 정합
- `init-project`의 SESSION 이력 템플릿을 `update-docs` 형식에 맞췄다.
- `update-docs`의 우선순위 표기를 다른 스킬과 같이 P0부터로 통일했다.

## v2.49 — 허용 목록에서 `SendMessage` 삭제
- 스키마에 없는 도구 이름이라 편집기 경고가 떴고, bypass 모드라 동작에도 영향이 없다.

## v2.48 — `writing-prompts` 지원 범위 확대
- 계열별 최신·직전·전전 세대를 지원한다.
- 대상 모델 ID와 API 방식을 먼저 정하고, 그 모델 문서의 체크리스트만 적용한다.

## v2.47 — Opus 5.5 재조사와 GPT-6.1 Sol 반영
- 출력 전 거절의 범주별 과금, 6.1 Sol API 계약, Codex 기본값을 스킬과 가이드에 반영했다.
- Claude Code가 bypass 모드에서도 핵심 경로 `rm`에 확인창을 띄우게 되어, 지침의 "유일한 통제" 표현을 고쳤다.
- 사고 유도 지시 처방을 공급자별로 나눴다.

## v2.46 — 프롬프트 감사 후속 정리
- 스킬과 에이전트 사이에서 서로 어긋나던 서술 네 곳을 고쳤다.
- 재설치하면 bypass 진입 확인창이 다시 뜨던 문제를 `skipDangerousModePermissionPrompt`로 막았다.
- 파일 트리 사전 합의 기준을 "새 디렉토리나 모듈 구조를 정할 때"로 올렸다.

## v2.45 — Opus 5.5와 GPT-6 Sol 반영
- 스킬에 Opus 5.5 API 계약(thinking 끄기 불가, 강제 `tool_choice` 400, 기본 effort `medium` 등)과 GPT-6 제품군 차이를 넣었다.
- Opus 5.5 풀 가이드를 새로 만들고, Codex에서 효과가 없어진 `personality` 설정을 지웠다.
- `security-reviewer` 위임 범위와 규칙 우선순위의 불일치를 정리했다.

## v2.44 — `install.sh` 패키지 설치 실패 수정
- `apt-get update` 없이 설치해 새 환경에서 패키지를 찾지 못하던 문제를 고쳤다. update 실패는 경고로만 넘긴다.

## v2.43 — 계정 스킬 동기화 끄기와 `office-docs` 이식
- claude.ai 계정 스킬 동기화(`syncClaudeAiSkills`)를 껐다. 레포 링크 경로에 파일이 섞였고, 매 세션 스킬 설명이 프롬프트를 차지했다.
- 쓸모 있던 문서 스킬 4종(pdf·docx·pptx·xlsx)은 `office-docs` 한 스킬로 이식했다.
- `install.sh`가 스킬 의존성(`scripts/setup.sh`)도 설치한다(`--skip-deps`로 생략).

## v2.42 — autocompact 기준을 400K로 낮춤
- 장문 성능은 창 대비 비율이 아니라 절대 토큰 수를 따라 떨어진다. 300K는 압축이 잦아 요약 손실이 커서 400K로 절충했다.

## v2.41 — 도구 버전 현행화
- Claude Code·Codex 변경 이력을 대조해 설정 변경이 필요 없음을 확인했다.
- 스킬 frontmatter의 `model`·`effort`가 상류에서 고쳐져 실제로 적용되기 시작했다.

## v2.40 — compact 리마인더 개정
- 압축 직후의 새 요청(`/brief` 등)이 이전 작업 재개로 흡수되던 문제를 고쳤다. 압축 뒤 사용자 메시지가 이번 턴의 작업이다.

## v2.39 — `/brief` 재구성
- 판정 기준을 `PROJECT.md`의 현재 목표로 옮겼다.
- 형식을 목적, 진행 지도와 판정, 목표를 흔드는 것, 인사이트, 다음 순으로 바꾸고 실무 세부 정보는 뺐다.

## v2.38 — Codex 교훈 파일 운영 정비
- 경로를 `<프로젝트 루트>/.codex/lessons.md`로 못 박고, 세션 시작과 압축 뒤에 읽게 했다.
- Codex 공식 메모리는 쓰지 않는다(`features.memories = false`).

## v2.37 — `visual-check` 스킬 추가
- UI를 화면 폭별로 렌더링해 스크린샷과 진단(가로 넘침, 폰트, 깨진 이미지, 콘솔 오류)을 남긴다.

## v2.36 — Gemma 4 자료 현행화
- 초판 이후 공식 변경(5종 체제, chat template 개정, audio 배치 규칙 등)을 반영했다.
- 사라진 출처와 잘못 연결한 출처를 정리했다.

## v2.35 — Qwen 3.8 대응
- 풀 가이드와 패턴 파일을 3.8 기준으로 새로 쓰고, 3.6 자료는 `reference/archive/`로 옮겼다.
- 3.6 가이드의 tool call 예시 형식(JSON이 아니라 XML)을 바로잡았다.

## v2.34 — 이식 스킬 8개 상류 동기화
- 각 스킬을 상류 최신에 맞추고, 앞서 검증한 로컬 보완은 유지했다.
- 스킬 출처를 README와 `docs/SKILL-SOURCES.md`에 기록했다.

## v2.33 — 스킬 전수 점검
- 스킬은 서로 독립이라는 원칙으로, 다른 스킬을 가리키는 문구를 지웠다.
- 한화체 폰트를 `hw-ppt`에 넣어 `hw-design` 의존을 없앴다.

## v2.32 — `/brief` 스킬 추가
- 프로젝트 전용이던 브리핑 스킬을 어느 프로젝트에서나 쓰게 옮겼다.

## v2.31 — agy 전역 지침 이중 주입 수정
- 두 경로의 `GEMINI.md`가 모두 읽혀, 공식 경로(`~/.gemini/GEMINI.md`)만 남겼다.

## v2.30 — agy 상태줄 추가
- Claude Code와 같은 페이로드 구조라 상태줄 스크립트를 옮겨 왔다(컨텍스트, 쿼터, 모델, effort).

## v2.29 — 신모델 재점검과 문서 분리
- Fable 5.1·GPT-6 Astra·Gemini 3.8 기준으로 점검했고, Codex 추론 수준 고정을 풀었다.
- README를 사용법 중심으로 바꾸고, 설계 근거는 `docs/DECISIONS.md`로, 이력은 이 문서로 나눴다.

## v2.28 — Codex 점검 반영
- `/init-project`의 링크 단계를, `ln`이 막힌 도구(Codex)에서는 사용자에게 실행을 요청하도록 나눴다.

## v2.27 — `/start`가 핵심 코드도 읽음
- `PROJECT.md` 코드 지도를 따라 읽고, 지도가 없으면 진입점부터 탐색한다.

## v2.26 — `/init-project`가 루트 지침을 `GUIDE.md` 링크로 생성
- 루트 `CLAUDE.md`·`AGENTS.md`가 `GUIDE.md`를 가리켜, 세 도구가 같은 지침을 읽는다.
- `/start`를 커스텀 명령에서 공용 스킬로 옮겼다.

## v2.25 — agy 설정 병합 보강
- 새로 만들 때도 임시 파일을 검증한 뒤 교체하고, 링크는 마지막 교체 때만 일반 파일로 바꾼다.

## v2.24 — Antigravity 지침을 `GEMINI.md` 하나로 통합
- 공식 문서가 CLI와 IDE 모두 `GEMINI.md`를 전역 규칙으로 쓴다.
- 설정 병합의 백업·교체 실패를 설치 종료 코드에 반영했다.

## v2.23 — Antigravity CLI(`agy`) 관리 층 추가
- 전역 지침과 `cli/settings.json`(always-proceed와 파국형 deny)을 설치하고, 설정은 관리 키만 병합한다.
- deny 문법(토큰 정확 일치, 글롭·regex 무효)을 실측으로 확인했다.

## v2.22 — Gemini CLI 층 은퇴
- Google이 개인 계정 지원을 끊고 Antigravity CLI로 통합했다. 공유 자산은 `.antigravity/`로 옮겼다.

## v2.21 — compact 리마인더를 SessionStart로 이전
- PostCompact 출력은 모델에 전달되지 않는다.
- `verify-policies.sh`가 검사 없이 통과하던 경로를 막았다.

## v2.20 — 구세대 모델 자료 정리
- Claude 5·GPT-5.6 이전 문서를 `reference/archive/`로 옮기고, 예시 모델 ID를 최신으로 통일했다.

## v2.19 이전

| 버전 | 변경 |
|------|------|
| v2.19 | GPT-6 Astra 대응, Codex 층 지침을 Claude 층과 정합 |
| v2.18 | 상용 스킬 6종 감사(Fable 5.1 기준 API 예시·모델 표 수정) |
| v2.17 | verifier 자동 위임 폐지(사용자 요청 시에만) |
| v2.16 | Fable 5.1 대응, 서브에이전트 Opus 강제 |
| v2.15 | 도구 버전 현행화 |
| v2.14 | autocompact 임계값을 레포에 고정 |
| v2.13 | 스킬 설명(description) 압축 |
| v2.12 | 상시 로드 지침 감량(393→250줄) |
| v2.11 | Claude Opus 5 반영 |
| v2.10 | 확인 프롬프트 전면 해제(자동승인 훅 은퇴, ask 규칙 해제) |
| v2.9 | Codex 스킬 재검토 반영 |
| v2.8 | 한국어 문체 조사와 블라인드 실측 반영 |
| v2.7 | 최신 모델 가이드 기준 지침 감량 |
| v2.6 | 외부 코드 리뷰 반영, 정책 회귀 테스트 도입 |
| v2.5 | 보안 훅 `/tmp` 예외를 체인 위치와 무관하게 확장 |
| v2.4 | 문체 규칙 정비, 전역 규칙 15% 감량 |
| v2.3 | 멀티라인 `&&` 체인 오탐 수정 |
| v2.2 | 프로세스 종료 확인 해제, `/tmp` 예외 확장 |
| v2.1 | `/tmp` 예외를 `&&` 체인까지 확장 |
| v2.0 | `gh api` 쓰기 차단 보강, 실패알림 훅 정리 |
| v1.9 | 보안 훅 `/tmp` 예외 추가 |
| v1.8 | `hw-ppt` 좌표 확정 |
| v1.7 | 위험 명령 정밀 분류, 셸 우회 차단 |
| v1.6 | Opus 4.8 대응, 설치 파일별 정책 분리, `hw-ppt` 추가 |
| v1.5 | Antigravity 통합 |
| v1.4 | 위험 명령 차단 정합성 강화 |
| v1.3 | `hw-design` 헤더 시스템, 가이드 정합 |
| v1.2 | `hw-design` 스킬 추가 |
| v1.1 | Gemini CLI 지원 추가 |
| v1.0 | 첫 릴리즈 |
