# Codex 작업 지침 (전역)

## 우선순위

1. 사용자의 현재 요청 (신규 지시가 이전 지시와 충돌하면 신규 우선; 충돌 없는 이전 지시는 유지)
2. 저장소의 실제 코드/구조/테스트 결과
3. 이 문서의 지침

> 응답 형식·범위 규율·작업 사고(outcome-first)·코딩·구조·보안 규칙·언어 규칙·협업 스타일·도구 사용·검증은 `~/.codex/config.toml`의 `developer_instructions`에 정의되어 있다. 이 문서는 **에이전트 운영·스킬 카탈로그·세션 시작·레퍼런스 검증·비파괴 원칙**에 집중한다.

---

## 에이전트 운영 (Codex 절차형 대응)

Codex는 서브에이전트를 지원하지만, 이 레포는 역할 트리거만으로 자동 위임하지 않는다. 기본은 직접 수행이며, 사용자 요청 또는 적용되는 프로젝트·스킬 지시가 위임을 요구할 때만 서브에이전트를 사용한다.

### 역할별 트리거

| 순위 | 역할 | 트리거 | 절차 |
|------|------|-------|------|
| 1 | **빌드 해결** | 빌드 실패 (`npm run build`, `tsc` 에러) | 최우선, 최소 변경으로 해결 |
| 2 | **보안 점검** | auth/login/session/token, 암호화, 시크릿 처리 | OWASP Top 10 기반 점검 |
| 3 | **계획 수립** | 아키텍처 결정이 필요하거나 요구가 불명확한 복잡 요청, 또는 사용자가 계획을 요청할 때 | 계획 초안 → 사용자 논의 → 확정 |
| 4 | **작업 점검** | 사용자가 점검을 요청할 때 ("점검해줘/확인해줘/이상 없어?") | `work-verify` 절차 수행. 완료 보고 전 자동 점검 단계 없음 — 입증은 작업 중 확보한 테스트·빌드·실측 출력으로 |

일반 흐름: 구현 → (보안 시) 보안 점검 → (빌드 에러 시) 빌드 해결. 계획 수립·작업 점검은 조건 충족·요청 시에만.

### 직접 처리 (역할 분리 불필요)

- 단순 질문/설명
- 1-2줄 간단 수정
- 사용자가 "직접 해줘" 명시적 요청
- 요구와 범위가 명확한 작업 — 파일 수가 많아도 역할 분리 불필요, 경로는 직접 계획해 실행

### 멀티 에이전트 활용

- 서브에이전트는 토큰을 더 쓴다. 독립적인 읽기·탐색·테스트·요약부터 적용하고, 병렬 쓰기는 충돌·조정 비용이 이득보다 작을 때만 사용한다.
- 필요한 최소 인원만 생성하고 모든 결과를 기다린 뒤 한 번 종합한다.
- 위임 프롬프트에는 맡기는 갈래, 리더가 직접 쥐는 범위, 워커가 돌려줄 요약 형식을 명시한다.

### 복잡 작업 착수 프로토콜

아키텍처 결정이 필요하거나 여러 단계로 이어지는 작업은 착수 전 아래 항목을 명시:

| 항목 | 설명 |
|------|------|
| **task** | 수행할 작업 (1문장) |
| **context_files** | 관련 파일 경로 목록 |
| **constraints** | 제약 조건 (변경 범위, API 호환성 등) |
| **success_criteria** | 검증 기준 (테스트 통과, 수치 목표, 비교 기준 등) |
| **stop_rules** | 중단 조건 (시도 횟수, 진전 없음 시점, 가설 재구성 트리거) |

> 코드 수정 시점의 outcome 사고(goal·success_criteria·stop_rules)는 `developer_instructions` `<process>` 참조.

### 행동 원칙

- **위험 명령은 사용자 요청 시에만**: `approval_policy = "never"`라 아래 명령도 **확인 없이 그대로 실행됩니다**. 파국형 명령만 `.codex/rules/default.rules`가 기계적으로 차단하고, 나머지 위험 명령의 통제는 이 지침뿐입니다 — 자율 작업 중 시도 자체 금지, 사용자가 직접 요청한 경우에만 실행. 복합·래퍼 형태(`cd x && rm y`, `bash -c "rm ..."`)로 돌려 쓰는 것도 동일하게 금지:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`, `git rm`, Windows PowerShell의 `Remove-Item`(`ri`·`del`·`erase`·`rd` 포함)·`Clear-Content` — 보존이 원칙이므로 `.archive/`로 옮기는 것이 기본. `/tmp` 스크래치는 지우지 말고 둔다(재부팅 시 소멸). 요청받은 삭제에 `-f`를 쓸 때는 `rm -rf build`처럼 경로를 그대로 적는다(변수·`~`·글롭·리다이렉션이 들면 Codex 내장 검사가 거부한다)
  - **Git 쓰기**: `git push`, `git commit`, `git reset`, `git clean`, `git rebase`, `git merge`, `git cherry-pick`, `git revert`, `git am`, `git apply`, `git branch -d/-D`, `git tag -d/-f` (조회와 `git add`·`checkout`·`switch`·`stash`는 자유)
  - **GitHub CLI 쓰기**: `gh pr/issue/release/repo create/close/delete/merge/edit/comment`, `gh api` 쓰기 플래그(`-X`/`--method`/`-f`/`--field`/`-F`/`--raw-field`/`--input` — 결합형·위치무관 포함), `gh auth login/logout`
  - **시스템/권한**: `sudo`, `dd`, `fdisk`, `parted`, `chmod`, `chown`
  - **파일 in-place 수정/링크 강제**: `sed -i`, `awk -i inplace`, `ln -sf` (force overwrite) — 파일 수정은 apply_patch 사용
  - **Docker 삭제**: `docker rm/rmi`, `docker-compose down/rm`
  - **셸 우회**: `echo "..." | bash` / `curl ... | bash` (파이프로 셸 전달 — 따옴표 stripping 우회), `bash <(...)` (process substitution), `xargs rm`, `find ... -delete` (rm 없이 동일 효과) — 위험 명령을 직접 호출하지 않고 우회 실행하는 패턴
  - **인라인 스크립트 우회**: `python -c "import os; os.system('rm ...')"`, `python -c "import shutil; shutil.rmtree(...)"`, `node -e "require('fs').rmSync(...)"`, `node -e "require('child_process').execSync('rm ...')"`, `ruby -e "system('rm ...')"`, `bash -c "rm ..."` — 인터프리터를 거쳐 위험 명령을 실행하는 패턴
- **규칙이 막는 파국형 명령은 요청을 받아도 실행되지 않는다**: 루트·홈·현재 폴더를 통째로 지우는 `rm -rf`(`/`, `~`, `.`, `..` 등), 전원 조작(`reboot`·`shutdown`·`poweroff`·`halt`), `mkfs`, 디스크 장치(`/dev/sda` 등)를 대상으로 한 `dd`·`fdisk`·`parted`·`shred`, `crontab -r`, Windows의 `Stop-Computer`·`Restart-Computer`·`Format-Volume`·`Clear-Disk`·`Remove-Partition`·`diskpart`. 규칙은 토큰이 정확히 같을 때만 맞으므로 걸리지 않는 형태로 바꿔 시도하지 않는다. 꼭 필요하면 사용자에게 직접 실행을 부탁드린다고 안내
- **버그 수정 자율성**: 로그·에러·테스트를 직접 추적해 수정. 범위 확대(파일 3개+) 시 합의
- **교훈 기록**: 세션 첫 작업 전에 `<프로젝트 루트>/.codex/lessons.md`가 있으면 읽어 반영. 사용자 피드백 수신 시 같은 파일에 기록(작업 디렉토리 기준 상대 경로가 아님). 동일 에러 2회+ 발생 시 필수
- **계획 대비 확인**: 계획을 세운 경우 구현 완료 후 누락 없는지 최종 확인

> 차단 시 재계획·동일 시도 회피·실패 대응(에러 → 가정 → 원인 → 다른 방법)은 `developer_instructions` `<collaboration_style>` 참조.

---

## 스킬 활용

`~/.agents/skills/` (또는 `~/.codex/skills/`) 디렉토리에 작업별 전문 가이드. 해당 분야 작업 시 `SKILL.md` 먼저 읽고 절차·품질 기준 준수. 스킬별 용도와 호출 조건은 세션에 주입되는 스킬 목록의 설명을 따른다.

> `cowork-set`(프로젝트에 Claude–Codex 협업 체계 세팅)은 자동으로 주입되는 스킬 목록에 나오지 않는다. 대표님이 `$cowork-set`으로 직접 호출할 때만 쓴다.
>
> `stitch-design`은 공유 스킬이지만 Google Stitch MCP가 Claude 쪽에만 붙어 있어 Codex에서는 쓰지 않는다.

---

## 세션 시작

사용자가 "시작"이라고 하면 `start` 스킬(`~/.agents/skills/start/SKILL.md`)을 따른다 — `agent-guide/` GUIDE → PROJECT → SESSION 읽기 → 코드 지도의 골격·관련 영역 코드 읽기 → 현재 상태와 실행 흐름 요약. 디렉토리가 없으면 프로젝트 내 참조할 문서를 읽고 파악.

---

## 레퍼런스 검증

학술 논문·연구 보고서·기술 사양서를 인용·구현·수치 비교할 때는 `reference-verification` 스킬(`~/.agents/skills/reference-verification/SKILL.md`)을 먼저 읽고 따른다.

**핵심**: Abstract만으로 답변 금지 / 수식·코드 항 단위 대조 / 기억 기반 인용 금지 / 출처 섹션 명시 / 디버깅 사고(내 코드는 "틀렸다" 전제로 시작, 반증 먼저 설계).

---

## 비파괴 원칙

- `~/.claude` 디렉토리는 삭제/수정하지 않는다
- Codex 설정은 `~/.codex` 내에서만 관리한다
- 기존 uncommitted 변경을 revert하지 않는다 (사용자가 명시적으로 요청한 경우만 가능)
- 기존 테스트가 실패하면 통과시키려고 테스트를 고치지 않는다 — 어떤 테스트가 왜 실패했는지 보고한다. 요청으로 동작이 바뀌어 기대값이 달라진 경우에만 그 사실을 밝히고 고친다
- **산출물 정리**: 테스트·실험·디버그 과정에서 본인이 만든 파일(임시 스크립트, 데모, 로그, 실험 결과, 체크포인트 등)은 작업 완료 시 `.archive/<YYYY-MM-DD>_<태그>/`로 이동하여 작업 경로 루트를 깨끗하게 유지. 보존이 목적이므로 `rm` 금지 (이동만). 사용자가 명시적으로 삭제를 요청한 경우만 예외. 관련 없는 기존 파일은 대상 아님 (언급만)
