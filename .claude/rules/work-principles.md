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
- **위험 명령은 사용자 요청 시에만**: 확인 프롬프트(ask) 계층은 전면 해제되어 아래 명령도 **기술적으로는 무확인 실행됩니다**. 그래서 이 지침이 유일한 통제입니다 — 자율 작업 중 시도 자체 금지, 사용자가 직접 요청한 경우에만 실행. 복합·래퍼 형태(`cd x && rm y`, `bash -c "rm ..."`, `python -c "shutil.rmtree(...)"`)로 돌려 쓰는 것도 동일하게 금지:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`, `find -delete` — 보존 원칙상 `.archive/`로 `mv`가 기본. `/tmp` 스크래치는 지우지 말고 두기(재부팅 시 소멸)
  - **Git 쓰기**: `push`, `commit`, `reset`, `clean`, `rebase`, `merge`, `cherry-pick`, `revert`, `am`, `apply`, `branch -d/-D`, `tag -d/-f` (조회와 `add`·`checkout`·`switch`·`stash`는 자유)
  - **GitHub CLI 쓰기**: `gh pr/issue/release/repo`의 create·close·delete·merge·edit·comment, `gh api` 쓰기 플래그, `gh auth login/logout`
  - **시스템/권한**: `sudo`, `reboot`, `shutdown`, `dd`, `mkfs`, `fdisk`, `parted`, `chmod`, `chown` — 파국형(`rm -rf /` 등)은 `permissions.deny`가 차단
  - **in-place 수정/링크 강제/Docker 삭제**: `sed -i`, `ln -sf/-f`, `docker rm/rmi`, `docker(-)compose down/rm` — 파일 수정은 Read+Edit 도구 사용
  - **빌드툴/셸 설정 파일 쓰기** (Claude Code 내장 동작): `.npmrc`·`.bashrc`·`.zshrc`·`.profile` 등은 Edit/Write에 확인이 뜰 수 있음 — 수정 필요 시 사용자에게 먼저 고지
  - **백그라운드 `&` 연산자** (Claude Code 내장 동작): `cmd &` 대신 Bash 도구 `run_in_background: true` 사용
