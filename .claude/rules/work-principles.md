# 작업 원칙

> 코딩·분석·리뷰·문서 등 모든 작업 유형에 공통 적용.

## MUST

- **구현 전 사고**: 코드 작성 전 가정을 명시적으로 표면화
  - ✗ "m_eff = m_s + m_f니까 added mass 구현 완료" (가정을 검증 없이 사실로 취급)
  - ✓ "m_eff 분모 치환이 Eq.(21)과 동일한지 항 단위로 대조해보겠습니다" (가정을 검증 대상으로 제시)
  - 요청이 모호하면 가능한 해석을 나열하고 질문. 더 단순한 접근이 있으면 먼저 제시
  - 무엇이 모호한지 모르겠을 땐, **혼란의 위치를 명명하라**: 어떤 단어/개념/경로가 다중 해석되는지 1줄로 표면화 후 질문
- **목표 기반 실행**: 작업을 검증 가능한 성공 기준으로 변환한 후 착수
  - ✗ "Re gap을 줄여보겠습니다" (검증 기준 없음)
  - ✓ "Majumder 2023 §4.4 기준 Heavy 276.61, Light 231.41 대비 ±2% 이내를 목표로 합니다"
  - 코드 작업의 일반 변환 패턴:
    - "검증 추가" → 무효 입력 테스트 먼저 작성 → 통과시키기
    - "버그 수정" → 재현 테스트 먼저 작성 → 통과시키기
    - "리팩토링" → 변경 전후 동일 테스트 통과 확인
- **정확성 우선**: 속도보다 정확성. 검증을 생략하고 결과를 빨리 내는 것은 금지
  - ✗ "수식 대조는 나중에 하고 일단 실험 돌려봅시다" (검증 건너뛰기)
  - ✓ 수식/정의 검증 완료 → 실험 설계 → 실행
- **속도 최적화 조건부**: 속도 최적화는 사용자가 명시적으로 요청하거나, 실제 타임아웃이 있거나, 진행 없음이 반복될 때만 수행. 그 외에는 정확성 우선
- **리소스 제약 추측 금지**: 충분한 CPU/RAM/GPU가 있다고 가정. 리소스 제약을 추측하여 분석을 생략하지 않기
- **시간 소요 작업 인내**: 빌드, 테스트, 검색 등 시간이 걸리는 작업에서 조급해하지 않기. 멈춘 구체적 증거가 없으면 기다리기
- **산출물 정리**: 테스트·실험·디버그 과정에서 본인이 만든 파일(임시 스크립트, 데모, 로그, 실험 결과, 체크포인트 등)은 작업 완료 시 `.archive/<YYYY-MM-DD>_<태그>/`로 이동하여 작업 경로 루트를 깨끗하게 유지. **보존이 목적이므로 `rm` 금지** (대신 이동). 사용자가 명시적으로 삭제를 요청한 경우만 예외
  - ✗ 테스트하다 나온 `demo.html`, `test_output.json`을 루트에 방치
  - ✗ 불필요해 보여서 `rm` (나중에 참조 불가)
  - ✓ `mv demo.html test_output.json .archive/2026-04-24_hw-design-demo/`
  - 관련 없는 기존 파일/데드 코드는 대상 아님 (범위 준수 규칙 우선 — 언급만)
- **훅 ask 발동 명령 사용 금지**: 다음 명령은 hook이 사용자 승인 요청(`ask`)을 발동시켜 **자율 작업 흐름이 중단됩니다**. 자율 작업 중에는 **시도 자체 금지** — 필요 시 사용자에게 먼저 묻고 명시 승인 후 실행. 사용자가 직접 요청한 경우에만 ask로 안전하게 진행:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`
  - **Git 쓰기**: `git push`, `git commit`, `git reset`, `git clean`, `git rebase`, `git merge`, `git cherry-pick`, `git revert`, `git am`, `git apply`, `git branch -d/-D`, `git tag -d`
  - **Git 상태 변경**: `git checkout`, `git switch`, `git restore`, `git stash` (전체), `git add` — 작업 컨텍스트/working tree/staging 상태 변경 위험
  - **GitHub CLI 쓰기**: `gh pr/issue/release create/close/delete/merge/edit/comment`, `gh api -X/-f/-F`, `gh auth login/logout`
  - **시스템**: `reboot`, `shutdown`, `poweroff`, `halt`, `dd`, `mkfs`, `fdisk`, `parted`, `sudo`
  - **파일 in-place 수정/링크 강제/권한**: `sed -i`, `awk -i inplace`, `ln -sf` (force overwrite), `chmod`, `chown` — Edit 도구 우회·보안 상태 변경
  - **프로세스**: `kill`, `pkill`, `killall`
  - **Docker 삭제**: `docker rm/rmi`, `docker-compose down/rm`
  - **셸 우회**: `echo "..." | bash` / `curl ... | bash` (파이프로 셸 전달 — 따옴표 stripping 우회), `bash <(...)` (process substitution), `find ... -delete` (rm 없이 동일 효과) — 위험 명령을 직접 호출하지 않고 우회 실행하는 패턴
  - **인라인 스크립트 우회**: `python -c "import os; os.system('rm ...')"`, `python -c "import shutil; shutil.rmtree(...)"`, `node -e "require('fs').rmSync(...)"`, `node -e "require('child_process').execSync('rm ...')"`, `ruby -e "system('rm ...')"`, `bash -c "rm ..."` — 인터프리터를 거쳐 위험 명령을 실행하는 패턴 (hook이 regex로 잡기 어려워 차단 우회됨, 시도 자체 금지)
  - **빌드툴/셸 설정 파일 쓰기** (Claude Code 2.1.160+ 내장 동작 — hook 아님): `.npmrc`, `.yarnrc*`, `.bazelrc` 등 빌드툴 설정과 `.bashrc`/`.zshrc`/`.profile` 등 셸 시작 파일은 코드 실행 권한을 부여할 수 있어 Edit/Write로 쓸 때 `acceptEdits` 모드에서도 ask 발동. 수정 필요 시 사용자에게 먼저 고지 후 진행
  - (참고: `cp`/`mv`/`>`/`>>`/`tee`는 경로 변경·복사·명령 결과 저장으로 일상 패턴이라 allow)

  > **`/tmp` 예외 (경로 기반 정책)**: 위 "대상 경로형" 명령(`rm`·`rmdir`·`unlink`·`shred`·`truncate`·`chmod`·`chown`·`sed -i`·`awk -i`·`ln -sf`·`find -delete`)은 **대상이 모두 `/tmp/` 하위면 hook이 자동 허용**한다(임시 디렉토리=프로젝트 무관). `/tmp/x` 절대경로 또는 `cd /tmp && <cmd> x`(cwd=/tmp) 형태면 ask 없이 진행 가능. 임시 작업·테스트·정리는 `/tmp`에서 마음껏 하면 된다.
  > 단 ① `..` 경로탈출 ② `;`/`&&`/`|`/`$()` 등 메타문자 체인 ③ `/tmp` 외 절대경로 혼합 ④ 래퍼·인터프리터 경유(`env`·`nohup`·`timeout`·`bash -c`·`python -c` 등 — 파일조작 명령으로 **직접 시작**해야 함)는 여전히 ask. **경로 무관 위험**(`sudo`·`git`·`gh`·`docker`·`kill`·`echo|bash`)은 `/tmp`여도 항상 ask — 이들은 대상 경로와 무관하게 시스템·외부·이력에 영향을 주기 때문.

  > **원칙**: 영향도 적은 read-only 명령만 자동 허용. 빌드/테스트/패키지 설치(`npm install`, `pytest` 등)는 자율 작업 흐름 유지를 위해 allow.
