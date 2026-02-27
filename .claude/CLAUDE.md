# Claude Code 가이드

> 전역 진입점. 작업 원칙은 `agent-guide/GUIDE.md` 참고.

## 시작하기

1. 사용자가 **"시작"**이라고 하면 **`agent-guide/GUIDE.md`를 먼저 읽고** 작업 원칙과 세션 시작 절차를 파악하세요.
2. 그 다음 프로젝트 구조 파악을 위해 `agent-guide/PROJECT.md`를 꼼꼼하게 읽고 파악하세요.
3. 그 다음 `agent-guide/SESSION.md`를 읽고 현재 상태를 요약합니다.

> `agent-guide/` 디렉토리가 없으면 프로젝트 경로 내 참조할 만한 문서들을 읽고 파악하세요.

## 커뮤니케이션

→ 상세 규칙은 `.claude/rules/communication.md` 참조 (한국어 응답, 용어 병기, 변경 이유 설명)

## 도구 힌트

| 도구 | 용도 |
|------|------|
| **파일 탐색** | Glob, Grep으로 코드베이스 검색 |
| **작업 관리** | TodoWrite로 진행 상황 추적 |
| **컨텍스트 관리** | 대량 출력은 `.claude/scratch/`에 저장, 요약만 컨텍스트에 유지 |

> 프로젝트별 MCP 도구는 `agent-guide/GUIDE.md`의 MCP 섹션 참고.
