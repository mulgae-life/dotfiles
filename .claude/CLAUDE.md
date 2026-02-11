# Claude Code 가이드

> 전역 진입점. 작업 원칙은 `agent-guide/GUIDE.md` 참고.

## 시작하기

1. 사용자가 **"시작"**이라고 하면 **`agent-guide/GUIDE.md`를 먼저 읽고** 작업 원칙과 세션 시작 절차를 파악하세요.
2. 그 다음 프로젝트 구조 파악을 위해 `agent-guide/PROJECT.md`를 꼼꼼하게 읽고 파악하세요.
3. 그 다음 `agent-guide/SESSION.md`를 읽고 현재 상태를 요약합니다.

> `agent-guide/` 디렉토리가 없으면 `/init-project` 스킬로 생성할 수 있습니다.

## 커뮤니케이션

- 모든 응답과 설명은 **한국어**로 제공
- 영어 기술 용어는 한국어 설명과 함께 병기 (예: "스트리밍(Streaming)")
- 코드 변경 시 **그 이유를 항상 상세히 설명**

## 도구 힌트

| 도구 | 용도 |
|------|------|
| **파일 탐색** | Glob, Grep으로 코드베이스 검색 |
| **작업 관리** | TodoWrite로 진행 상황 추적 |

> 프로젝트별 MCP 도구는 `agent-guide/GUIDE.md`의 MCP 섹션 참고.
