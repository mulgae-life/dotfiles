# 작업 원칙

> 코딩·분석·리뷰·문서 등 모든 작업 유형에 공통 적용.

## MUST

- **구현 전 사고**: 코드 작성 전 가정을 명시적으로 표면화
  - ✗ "m_eff = m_s + m_f니까 added mass 구현 완료" (가정을 검증 없이 사실로 취급)
  - ✓ "m_eff 분모 치환이 Eq.(21)과 동일한지 항 단위로 대조해보겠습니다" (가정을 검증 대상으로 제시)
  - 요청이 모호하면 가능한 해석을 나열하고 질문. 더 단순한 접근이 있으면 먼저 제시
  - 무엇이 모호한지 모르겠을 땐 **혼란의 위치를 명명**: 어떤 단어/개념/경로가 다중 해석되는지 1줄로 표면화 후 질문
- **목표 기반 실행**: 작업을 검증 가능한 성공 기준으로 변환한 후 착수
  - ✗ "Re gap을 줄여보겠습니다" (검증 기준 없음)
  - ✓ "Majumder 2023 §4.4 기준 Heavy 276.61, Light 231.41 대비 ±2% 이내를 목표로 합니다"
  - 일반 변환 패턴: "검증 추가"→무효 입력 테스트 먼저 작성, "버그 수정"→재현 테스트 먼저 작성, "리팩토링"→전후 동일 테스트 통과
- **정확성 우선**: 속도보다 정확성. 검증을 생략하고 결과를 빨리 내는 것 금지. 속도 최적화는 명시 요청·실제 타임아웃·진행 없음 반복 시에만
- **리소스 제약 추측 금지**: 충분한 CPU/RAM/GPU가 있다고 가정. 제약을 추측해 분석을 생략하지 않기
- **시간 소요 작업 인내**: 빌드/테스트/검색이 진행 중이면 멈춘 구체적 증거 없이 조급해하지 않기
- **산출물 정리**: 본인이 만든 임시 파일(스크립트·데모·로그·실험 결과·체크포인트)은 작업 완료 시 `.archive/<YYYY-MM-DD>_<태그>/`로 **이동** — 보존 목적이므로 `rm` 금지, 사용자가 명시적으로 삭제를 요청한 경우만 예외. 관련 없는 기존 파일/데드 코드는 대상 아님(언급만)
- **훅 ask 발동 명령 사용 금지**: 아래 명령은 hook이 사용자 승인(`ask`)을 발동시켜 **자율 작업 흐름이 중단됩니다**. 자율 작업 중 시도 자체 금지 — 필요하면 사용자에게 먼저 묻고, 사용자가 직접 요청한 경우에만 ask로 진행:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate` — 보존 원칙상 `.archive/`로 `mv`가 기본
  - **Git 쓰기**: `push`, `commit`, `reset`, `clean`, `rebase`, `merge`, `cherry-pick`, `revert`, `am`, `apply`, `branch -d/-D`, `tag -d/-f`
  - **Git 상태 변경**: `checkout`, `switch`, `restore`, `stash`, `add` — working tree·staging 변경
  - **GitHub CLI 쓰기**: `gh pr/issue/release create·close·delete·merge·edit·comment`, `gh api` 쓰기 플래그(`-X`/`--method`/`-f`/`-F`/`--field`/`--raw-field`/`--input`), `gh auth login/logout`
  - **시스템**: `sudo`, `reboot`, `shutdown`, `poweroff`, `halt`, `dd`, `mkfs`, `fdisk`, `parted`
  - **in-place 수정/링크 강제/권한**: `sed -i`, `awk -i inplace`, `ln -sf`, `chmod`, `chown` — 파일 수정은 Read+Edit 도구 사용
  - **Docker 삭제**: `docker rm/rmi`, `docker-compose down/rm`
  - **셸/인터프리터 우회**: `... | bash`, `bash <(...)`, `find -delete`, `bash -c "rm ..."`, `python -c "os.system/shutil.rmtree(...)"`, `node -e "rmSync(...)"` 등 — hook이 못 잡는 형태여도 시도 자체 금지
  - **빌드툴/셸 설정 파일 쓰기** (Claude Code 내장 동작): `.npmrc`·`.yarnrc*`·`.bazelrc`·`.bashrc`·`.zshrc`·`.profile` 등은 Edit/Write도 ask — 수정 필요 시 사용자에게 먼저 고지
  - **백그라운드 `&` 연산자** (Claude Code 내장 동작): `cmd &`·`nohup ... &`는 hook allow와 무관하게 ask. 대신 Bash 도구 `run_in_background: true`로 실행하고 후속 확인은 별도 명령으로 분리
  - (참고: `cp`·`mv`·`>`·`>>`·`tee`·`kill`/`pkill`, 빌드·테스트·패키지 설치는 allow)

  > **`/tmp` 예외**: 위 명령 중 "대상 경로형"(파일 삭제류·`chmod`·`chown`·`sed -i`·`awk -i`·`ln -sf`·`find -delete`)은 **대상이 전부 `/tmp/` 하위면 hook이 자동 허용**한다(임시 디렉토리=프로젝트 무관). 작성 요령 4가지:
  > 1. **`/tmp/...` 절대경로가 기본** — 멀티라인·복합 명령 어디에 있어도 통과하는 만능형 (`find -delete`만 단일 명령 한정). 망설여지면 절대경로로 쓴다
  > 2. 상대경로 대상은 리터럴 `cd /tmp/... &&`에 직결된 체인 안에서만 — 체인이 명령 어디에 있든 통과(`;`·줄바꿈 뒤 포함). 단, 체인 내 조각은 조회성(echo/cat 등)·파일조작·cd만 허용 — 빌드/실행 명령(npx·make 등)과는 `&&`로 잇지 말고 `;`로 끊기
  > 3. 파일조작 세그먼트는 해당 명령으로 **직접 시작** — `env`/`nohup`/`timeout`/`bash -c` 등 래퍼 경유는 ask
  > 4. 파일조작 세그먼트에 비따옴표 `$`·리다이렉트·`..` 혼합 금지(정적 판정 불가) — 상대경로 체인(요령 2)은 `..`가 **명령 전체**에 없어야 함. 걸리면 삭제만 리터럴 경로로 분리 실행
  >
  > `sudo`·`git`·`gh`·`docker`·`echo|bash`는 `/tmp`여도 항상 ask(경로 무관 위험). 상세 판정 명세는 `auto-approve-readonly.sh` 주석 참조.
