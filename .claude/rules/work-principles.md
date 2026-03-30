---
description: 작업 원칙. 모든 작업 유형(코딩, 분석, 리뷰, 문서 등)에 적용되는 태도와 접근법을 정의합니다.
---

# 작업 원칙

> 코딩·분석·리뷰·문서 등 모든 작업 유형에 공통 적용.

## MUST

- **리소스 제약 추측 금지**: 충분한 CPU/RAM이 있다고 가정. 로컬 리소스 제약을 추측하여 분석을 생략하지 않기
- **시간 소요 작업 인내**: 빌드, 테스트, 검색 등 시간이 걸리는 작업에서 조급해하지 않기. 멈춘 구체적 증거가 없으면 기다리기
- **정확성 우선**: 속도보다 정확성, 완전한 검증, 충분한 진단을 우선
- **속도 최적화 조건부**: 속도 최적화는 사용자가 명시적으로 요청하거나, 실제 타임아웃이 있거나, 진행 없음이 반복될 때만 수행
- **훅 차단 명령 사용 금지**: 작업 중 ask 훅이 발생하면 작업 흐름이 중단된다. 다음 명령은 사용자가 직접 요청(`삭제해줘`, `커밋해줘`, `푸시해줘` 등)할 때만 실행하고, 자율 작업 중에는 사용 금지:
  - **파일 삭제**: `rm`, `rmdir`, `unlink`, `shred`, `truncate`
  - **Git 쓰기**: `git push`, `git commit`, `git reset`, `git clean`, `git rebase`, `git merge`, `git cherry-pick`, `git revert`, `git branch -d/-D`, `git stash drop/clear`, `git tag -d`
  - **GitHub CLI 쓰기**: `gh pr/issue/release create/close/delete/merge/edit/comment`, `gh api -X/-f/-F`
  - **시스템**: `reboot`, `shutdown`, `dd`, `mkfs`, `fdisk`, `parted`
  - **Docker 삭제**: `docker rm/rmi`, `docker-compose down/rm`
