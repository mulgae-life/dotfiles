---
description: 작업 원칙. 모든 작업 유형(코딩, 분석, 리뷰, 문서 등)에 적용되는 태도와 접근법을 정의합니다.
---

# 작업 원칙

> 코딩·분석·리뷰·문서 등 모든 작업 유형에 공통 적용.

## MUST

- **구현 전 사고(Think Before Coding)**: 코드 작성 전 가정을 명시적으로 표면화한다. 요청이 모호하면 가능한 해석을 나열하고 질문한다. 더 단순한 접근이 있으면 먼저 제시한다. 불확실하면 추측하지 말고 멈추고 질문한다
- **목표 기반 실행(Goal-Driven Execution)**: 작업을 검증 가능한 성공 기준으로 변환한 후 착수한다. "버그 수정" → "재현 테스트 작성 → 통과시키기", "기능 추가" → "동작 확인 기준 정의 → 구현 → 검증". 다단계 작업은 각 단계마다 검증 포인트를 명시한다
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
