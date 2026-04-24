# 작업 원칙

> 코딩·분석·리뷰·문서 등 모든 작업 유형에 공통 적용.

## MUST

- **구현 전 사고**: 코드 작성 전 가정을 명시적으로 표면화
  - ✗ "m_eff = m_s + m_f니까 added mass 구현 완료" (가정을 검증 없이 사실로 취급)
  - ✓ "m_eff 분모 치환이 Eq.(21)과 동일한지 항 단위로 대조해보겠습니다" (가정을 검증 대상으로 제시)
  - 요청이 모호하면 가능한 해석을 나열하고 질문. 더 단순한 접근이 있으면 먼저 제시
- **목표 기반 실행**: 작업을 검증 가능한 성공 기준으로 변환한 후 착수
  - ✗ "Re gap을 줄여보겠습니다" (검증 기준 없음)
  - ✓ "Majumder 2023 §4.4 기준 Heavy 276.61, Light 231.41 대비 ±2% 이내를 목표로 합니다"
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
- **훅 차단 명령 사용 금지**: 다음 명령은 사용자가 직접 요청할 때만 실행하고, 자율 작업 중에는 사용 금지:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`
  - **Git 쓰기**: `git push`, `git commit`, `git reset`, `git clean`, `git rebase`, `git merge`, `git cherry-pick`, `git revert`, `git branch -d/-D`, `git stash drop/clear`, `git tag -d`
  - **GitHub CLI 쓰기**: `gh pr/issue/release create/close/delete/merge/edit/comment`, `gh api -X/-f/-F`
  - **시스템**: `reboot`, `shutdown`, `dd`, `mkfs`, `fdisk`, `parted`
  - **Docker 삭제**: `docker rm/rmi`, `docker-compose down/rm`
