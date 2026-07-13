# Codex 작업 지침 (전역)

## 우선순위

1. 사용자의 현재 요청 (신규 지시가 이전 지시와 충돌하면 신규 우선; 충돌 없는 이전 지시는 유지)
2. 저장소의 실제 코드/구조/테스트 결과
3. 이 문서의 지침

> 응답 형식·범위 규율·코딩 스타일·언어 규칙·작업 사고(outcome-first)·협업 스타일·도구 사용·검증은 `~/.codex/config.toml`의 `developer_instructions`에 정의되어 있다. 이 문서는 **에이전트 운영·스킬 카탈로그·레퍼런스 검증·비파괴 원칙**에 집중한다.

---

## 에이전트 운영 (Codex 절차형 대응)

Codex는 서브에이전트와 Ultra를 지원하지만, 이 레포는 역할 트리거만으로 자동 위임하지 않는다. 기본은 직접 수행이며, 사용자 요청 또는 적용되는 프로젝트·스킬 지시가 위임을 요구할 때만 서브에이전트를 사용한다.

### 역할별 트리거

| 순위 | 역할 | 트리거 | 절차 |
|------|------|-------|------|
| 1 | **빌드 해결** | 빌드 실패 (`npm run build`, `tsc` 에러) | 최우선, 최소 변경으로 해결 |
| 2 | **보안 점검** | auth/login/session/token, 암호화, 시크릿 처리 | OWASP Top 10 기반 점검 |
| 3 | **계획 수립** | 파일 3개+ 수정, 아키텍처 결정 필요 | 계획 먼저 → 사용자 논의 → 확정 |
| 4 | **작업 점검** | 작업 완료 후, "점검해줘/확인해줘" | 기본 점검 수행 |

일반 흐름: 계획 수립 → 사용자 논의 → 구현 → 작업 점검 → (보안·빌드 에러 시) 해당 역할 수행.

### 직접 처리 (역할 분리 불필요)

- 단순 질문/설명
- 1-2줄 간단 수정
- 사용자가 "직접 해줘" 명시적 요청
- 파일 1-2개만 수정

### 멀티 에이전트 활용

`config.toml`의 `[features] multi_agent = true` 활성. `[agents]` `max_threads = 12` (로컬 코어 수 기준).

- 정형 문구: *"Spawn one agent per point, wait for all of them, and summarize the result for each point."*
- 배치 처리: `spawn_agents_on_csv`로 CSV 기반 일괄 작업
- 명시적 요청해야 스폰 (Claude와 달리 자동 위임 없음)
- 서브에이전트는 각각 모델·도구 작업을 수행하므로 단일 에이전트보다 토큰을 더 사용한다. 독립적인 읽기·탐색·테스트·요약부터 적용하고, 병렬 쓰기는 충돌·조정 비용이 이득보다 작을 때만 사용한다.
- 필요한 최소 인원만 생성하고 모든 결과를 기다린 뒤 한 번 종합한다. 대부분의 작업에는 Max·Ultra가 필요하지 않다.

### 복잡 작업 착수 프로토콜

파일 3개+ 수정 시 작업 착수 전 아래 항목을 명시:

| 항목 | 설명 |
|------|------|
| **task** | 수행할 작업 (1문장) |
| **context_files** | 관련 파일 경로 목록 |
| **constraints** | 제약 조건 (변경 범위, API 호환성 등) |
| **success_criteria** | 검증 기준 (테스트 통과, 수치 목표, 비교 기준 등) |
| **stop_rules** | 중단 조건 (시도 횟수, 진전 없음 시점, 가설 재구성 트리거) |

> 코드 수정 시점의 outcome 사고(goal·success_criteria·stop_rules)는 `developer_instructions` `<process>` 참조.

### 행동 원칙

- **Starlark `forbidden` 명령은 시도 자체 금지**: 아래 명령은 `.codex/rules/default.rules`에서 `forbidden`으로 설정되어 **사용자 명시 요청 여부와 무관하게 차단**됩니다 (Codex Starlark는 ask 메커니즘이 없음). 자율 작업 중에는 절대 시도하지 말고, 사용자가 요청한 경우에는 **사용자에게 직접 실행을 부탁드린다고 안내**:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`
  - **Git 쓰기**: `git push`, `git commit`, `git reset`, `git clean`, `git rebase`, `git merge`, `git cherry-pick`, `git revert`, `git am`, `git apply`, `git rm`, `git branch -d/-D`, `git tag -d/-f`
  - **Git 상태 변경**: `git checkout`, `git switch`, `git restore`, `git stash` (전체), `git add` — 작업 컨텍스트/working tree/staging 상태 변경 위험
  - **GitHub CLI 쓰기**: `gh pr/issue/release create/close/delete/merge/edit/comment`, `gh api` (전체), `gh auth login/logout`
  - **시스템**: `reboot`, `shutdown`, `poweroff`, `halt`, `sudo`, `dd`, `mkfs`, `fdisk`, `parted`
  - **파일 수정/링크 강제/권한**: `ln` (전체 차단, -f/-sf 위험), `chmod`, `chown`, `sed -i` / `awk -i inplace` / `gawk -i inplace` (표준 옵션 위치만 매칭) — Edit 도구 우회·보안 상태 변경
  - **Docker 삭제**: `docker rm/rmi`, `docker compose down/rm`
  - (참고: `cp`/`mv`/`>`/`>>`/`tee`는 경로 변경·복사·명령 결과 저장으로 일상 패턴이라 allow)

> **Codex Starlark 한계 (갭 인정)**: `prefix_rule`은 단어 prefix 매칭만 지원하므로 다음 패턴은 정책으로 차단 불가 → 사용자 명시 요청 시에도 시도 자체 금지:
> - `sed -i` / `awk -i inplace` 옵션 순서가 바뀐 케이스 (예: `sed -e 'pattern' -i file`, `awk -f prog.awk -i inplace file`) — 표준 위치(`sed -i ...`, `awk/gawk -i inplace ...`)는 룰로 차단됨. `sed --in-place=.bak`(값 결합 토큰)도 미매칭
> - **git 전역옵션 경유**: `git -C <경로> push`, `git -c <키=값> commit`, `git --git-dir=<경로> push` 등 — prefix_rule은 `["git", "push"]` 토큰 순서만 매칭하므로 전역옵션이 끼면 미차단 (실측 확인). 읽기(`git -C <경로> status`)까지 막지 않기 위해 룰 추가 안 함 → 쓰기 하위명령은 전역옵션 형태로도 시도 금지
> - `xargs rm` / `ls | xargs rm` (rm이 첫 토큰이 아니어서 미매칭)
> - `echo "..." | bash` / `curl ... | bash` (파이프로 셸에 전달 — 따옴표 stripping 우회)
> - `bash <(...)` (process substitution — 셸 명령 우회)
> - `find ... -delete` (rm 없이 동일 효과)
> - **인라인 스크립트 우회**: `python -c "import os; os.system('rm ...')"`, `python -c "import shutil; shutil.rmtree(...)"`, `node -e "require('fs').rmSync(...)"`, `node -e "require('child_process').execSync('rm ...')"`, `ruby -e "system('rm ...')"`, `bash -c "rm ..."` — 인터프리터를 거쳐 위험 명령을 실행하는 패턴
>
> 위 패턴이 필요한 경우 사용자에게 직접 실행을 부탁드린다고 안내
- **버그 수정 자율성**: 로그·에러·테스트를 직접 추적해 수정. 범위 확대(파일 3개+) 시 합의
- **교훈 기록**: 사용자 피드백 수신 시 `.codex/lessons.md` 기록. 동일 에러 2회+ 발생 시 필수
- **계획 대비 확인**: 계획을 세운 경우 구현 완료 후 누락 없는지 최종 확인

> 차단 시 재계획·동일 시도 회피·실패 대응(에러 → 가정 → 원인 → 다른 방법)은 `developer_instructions` `<collaboration_style>` 참조.

---

## 스킬 활용

`~/.agents/skills/` (또는 `~/.codex/skills/`) 디렉토리에 작업별 전문 가이드. 해당 분야 작업 시 `SKILL.md` 먼저 읽고 절차·품질 기준 준수.

### 스킬 카탈로그

| 스킬 | 용도 | 트리거 예시 |
|------|------|------------|
| `code-review` | 심각도 등급 포함 심층 리뷰 리포트 | PR 리뷰, 코드 품질 분석 |
| `work-verify` | 작업 완료 후 빠른 체크리스트 점검 | "점검해줘", "빠뜨린 거 없는지" |
| `work-plan` | Phase별 코드 예시 포함 심층 계획서 | "계획서 작성해줘" |
| `code-simplifier` | 기능 유지하며 명확성·유지보수성 개선 | "코드 정리해줘", "리팩토링" |
| `frontend-design` | 프로덕션 수준 UI 제작 | "페이지 만들어줘" |
| `web-design-guidelines` | UI/UX 디자인 패턴 검토 | "UI 리뷰해줘", "접근성 체크" |
| `react-best-practices` | React/Next.js 성능 최적화 | "컴포넌트 최적화" |
| `postgres-best-practices` | Supabase Postgres 최적화 | "쿼리 최적화", "RLS 정책" |
| `writing-prompts` | GPT/Claude 프롬프트 작성 | "프롬프트 작성해줘" |
| `llm-api-guide` | LLM API 연동 코드 | "API 연동해줘" |
| `langchain-guide` | LangChain/LangGraph 에이전트 | "에이전트 만들어줘" |
| `feedback-analysis` | 피드백 분석·우선순위 정리 | "피드백 분석해줘" |
| `update-docs` | agent-guide 문서 업데이트 | "문서 업데이트" |
| `init-project` | agent-guide 3종 파일 자동 생성 | "프로젝트 초기화" |
| `skill-creator` | 스킬 생성·수정·eval 테스트 | "스킬 만들어줘" |

---

## 레퍼런스 검증

학술 논문·연구 보고서·기술 사양서를 인용·구현·수치 비교할 때의 상세 규칙은 `~/.codex/AGENTS.references.md` 참조.

**핵심**: Abstract만으로 답변 금지 / 수식·코드 항 단위 대조 / 기억 기반 인용 금지 / 출처 섹션 명시 / 디버깅 사고(내 코드는 "틀렸다" 전제로 시작, 반증 먼저 설계).

---

## 비파괴 원칙

- `~/.claude` 디렉토리는 삭제/수정하지 않는다
- Codex 설정은 `~/.codex` 내에서만 관리한다
- 기존 uncommitted 변경을 revert하지 않는다 (사용자가 명시적으로 요청한 경우만 가능)
- 기존 테스트가 실패하면 테스트를 수정하지 않는다 — 어떤 테스트가 실패했는지, 원인이 무엇인지 보고한다
- **산출물 정리**: 테스트·실험·디버그 과정에서 본인이 만든 파일(임시 스크립트, 데모, 로그, 실험 결과, 체크포인트 등)은 작업 완료 시 `.archive/<YYYY-MM-DD>_<태그>/`로 이동하여 작업 경로 루트를 깨끗하게 유지. 보존이 목적이므로 `rm` 금지 (이동만). 사용자가 명시적으로 삭제를 요청한 경우만 예외. 관련 없는 기존 파일은 대상 아님 (언급만)
