# 변경 이력

버전별 상세는 각 시점의 Git 이력에 있다. [GitHub Releases](https://github.com/mulgae-life/dotfiles/releases)는 별도 태그 체계(v1.x)로 일부 버전의 상세만 담는다. 설계 결정의 근거는 [docs/DESIGN.md](docs/DESIGN.md).

| 버전 | 핵심 변경 |
|------|-----------|
| **v2.29** | 신모델(Fable 5.1·Astra·Gemini 3.8) 재점검 — 구조 변경 없음. Codex 추론 수준 고정 해제, agy 병합의 깨진 링크 선행 삭제 제거. README를 사용자용으로 재편하고 설계 근거는 `docs/DESIGN.md`, 이력은 `CHANGELOG.md`로 분리. `/update-docs` 이력 형식 초압축 |
| **v2.28** | Codex 점검 5건 반영 — `/init-project` 링크 단계를 `ln` 차단 도구(Codex)에서는 사용자 실행 요청으로 분기, 기존 파일 보존 분기와 완료 조건 정합, GUIDE 갱신 조건·교훈 경로·루트 기준 경로 일반화 |
| **v2.27** | `/start`가 문서에 더해 핵심 코드를 읽는다 — PROJECT.md 코드 지도(골격=항상·영역=다음 작업 관련) 기준, 없으면 진입점부터 탐색. 예산 3,000줄, 출력에 "코드 파악" 절 |
| **v2.26** | `/init-project`가 루트 `CLAUDE.md`·`AGENTS.md`를 `GUIDE.md` 링크로 생성 — 세 도구 링크 추종 실측. `/start`는 커스텀 명령에서 공용 스킬로 전환(Codex 층에 없던 세션 시작 절차 보강), `commands/` 설치 종료 |
| **v2.25** | `merge_agy_settings` 잔여 경로 정리 — 신규 생성도 임시 파일 검증 후 교체(쓰기 실패가 성공으로 보고되던 문제), 링크는 전환 없이 병합·검증 뒤 마지막 교체에서만 일반 파일로(검증 실패 시 링크 소실 문제), 링크는 내용이 같아도 교체. README 차단 범위 문구를 Claude 기준으로 한정. Codex 재점검 3건 반영 |
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
