---
name: start
description: 새 세션 시작 시 프로젝트를 파악하고 현재 상태를 요약합니다.
---

# /start 커맨드

새 세션 시작 시 프로젝트 내용을 파악합니다.

## 핵심 지침

**`CLAUDE.md`의 "시작하기" 섹션을 따르세요.**

1. `agent-guide/GUIDE.md` 읽기 → 작업 원칙 파악
2. `agent-guide/PROJECT.md` 읽기 → 프로젝트 구조 파악
3. `agent-guide/SESSION.md` 읽기 → 현재 상태 확인
4. (MCP 가능 시) 작업 관리 도구에서 백로그 조회

## 출력

파악한 내용을 요약하고 다음 작업을 제안합니다.

## 에러 처리

- 파일 없음: 사용 가능한 정보로 요약
- MCP 연결 실패: SESSION.md 정보로 대체
