---
name: start
description: 새 세션 시작 시 agent-guide를 읽어 프로젝트를 파악하고 현재 상태를 요약합니다. Claude·Codex·Antigravity 공용.
when_to_use: "시작, 세션 시작, 현재 상태 요약해줘, 이어서 하자, 프로젝트 파악해줘 요청 시. 새 대화를 열고 작업을 시작할 때."
---

# start

새 세션 시작 시 프로젝트 내용을 파악하고 현재 상태를 요약합니다.

## 절차

1. `agent-guide/GUIDE.md` 읽기 → 작업 원칙·용어·세션 시작 체크리스트 파악
2. `agent-guide/PROJECT.md` 읽기 → 프로젝트 구조 파악
3. `agent-guide/SESSION.md` 읽기 → 현재 상태 확인
4. 교훈 검토 → auto memory의 `lessons_*.md` 파일이 있으면 읽고 반영
5. (MCP 가능 시) 작업 관리 도구에서 백로그 조회

## 출력

파악한 내용을 요약하고 다음 작업을 1-3개 제안합니다.

## 에러 처리

- `agent-guide/` 없음: 프로젝트 경로 내 참조할 만한 문서(README 등)를 읽고 파악
- 파일 일부 없음: 사용 가능한 정보로 요약
- MCP 연결 실패: SESSION.md 정보로 대체
