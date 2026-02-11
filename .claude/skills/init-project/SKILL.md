---
name: init-project
description: >
  새 프로젝트의 agent-guide 3종 파일(GUIDE.md, PROJECT.md, SESSION.md)을
  자동 생성합니다. 기획 대화 후 "/init-project" 명령으로 트리거.
  "프로젝트 초기화해줘", "agent-guide 만들어줘", "새 프로젝트 세팅해줘" 등의 요청에도 트리거.
---

# init-project

새 프로젝트에서 기획 대화(티키타카) 완료 후, **대화 맥락만으로** agent-guide 3종 파일을 자동 생성합니다.

**원칙**:
- 디렉토리 스캔 안 함 — 대화에서 추출한 정보만 사용
- 부족한 정보는 `[TODO]` 플레이스홀더로 남김
- 섹션 제목은 항상 생성 (빈 섹션이라도 자리 확보)

---

## 사전 조건

### 필수 정보 확인

아래 **필수 항목**이 대화에 있는지 확인. 누락 시 사용자에게 질문:

| 항목 | 필수 | 대상 파일 |
|------|:----:|----------|
| 프로젝트명 | O | PROJECT |
| 목적 (1-2문장) | O | PROJECT |
| 기술 스택 (영역별) | O | PROJECT |
| MVP 기능 목록 | O | PROJECT |
| 작업 관리 도구 | - | GUIDE, SESSION |
| 프로젝트 구조 | - | PROJECT |
| 빠른 시작 명령어 | - | PROJECT |
| 다음 작업 | - | SESSION |
| 프로젝트 특수 용어 | - | GUIDE |

### 기존 파일 확인

`agent-guide/` 디렉토리가 이미 존재하면 **덮어쓰기 여부**를 사용자에게 확인.

---

## 실행 절차

### 1단계: 대화 맥락에서 정보 추출

대화 전체를 훑어 위 테이블의 항목을 추출. 추출 결과를 아래 형식으로 요약하여 **사용자 확인**을 받음:

```
📋 추출 결과:
- 프로젝트명: {{project_name}}
- 목적: {{purpose}}
- 기술 스택: {{tech_stack}}
- MVP 기능: {{mvp_features}}
- 작업 관리: {{task_tool}} (없으면 "[TODO]")
- 프로젝트 구조: (없으면 "[TODO: 구조 확정 후 업데이트]")
- 빠른 시작: (없으면 "[TODO: 환경 설정 확정 후 작성]")
- 다음 작업: {{next_tasks}} (없으면 "프로젝트 초기화 완료, 첫 작업 선택 필요")
- 특수 용어: {{terms}} (없으면 기본 용어만)

이대로 생성할까요? 수정할 부분이 있으면 알려주세요.
```

### 2단계: GUIDE.md 생성

`agent-guide/GUIDE.md` — 대부분 **고정** 템플릿, 용어/도구만 맞춤.

### 3단계: PROJECT.md 생성

`agent-guide/PROJECT.md` — 대화 맥락 **의존도 가장 높음**.

### 4단계: SESSION.md 생성

`agent-guide/SESSION.md` — **최소 템플릿** (초기 기록 1건).

### 생성 후 확인

3개 파일 생성 완료 후:
1. 각 파일 요약 (핵심 내용 1-2줄)
2. `[TODO]` 항목 목록 안내
3. 수정 필요 여부 확인

---

## 템플릿

### GUIDE.md 템플릿

```markdown
---
name: guide
description: AI 에이전트 작업 원칙과 세션 시작 체크리스트. 세션 시작 시 가장 먼저 읽기.
last-updated: {{date}}
---

# 에이전트 가이드

> AI 에이전트가 세션을 시작할 때 읽는 문서입니다.

---

## 작업 원칙

- 모든 커뮤니케이션은 **한국어**로
- **최소 변경**: 꼭 필요한 범위만 수정
- **근본 원인 해결** 우선, 우회 패치 지양
- 기존 코드 스타일 준수
- 커밋 메시지: `feat/fix/docs/refactor/chore` 형태

---

## 용어 정리

| 용어 | 설명 |
|------|------|
{{terms_table}}

> 프로젝트 특수 용어가 없으면 아래 기본 용어만 포함:
> | **MCP** | Model Context Protocol. AI가 외부 도구와 통신하는 방식 |
> | **P0/P1/P2** | 우선순위. P0(긴급) > P1(중요) > P2(보통) |

---

## 세션 시작 체크리스트

1. **프로젝트 파악**: `PROJECT.md` 읽기
2. **현재 상태 파악**: `SESSION.md` 읽기
3. **작업 확인**: {{task_check_step}}
4. **작업 제안**: 1-3개 제안, 큰 변경은 계획 먼저

> {{task_check_step}} 예시:
> - Notion 사용 시: "Notion 백로그 확인: MCP `get_backlog`로 작업 선택"
> - GitHub Issues 사용 시: "GitHub Issues 확인: 우선순위별 작업 선택"
> - 도구 미정 시: "[TODO: 작업 관리 도구 연동 후 업데이트]"

---

## MCP 도구

[TODO: MCP 연동 시 도구 목록 추가]

---

## 문서 역할

| 문서 | 갱신 시점 |
|------|----------|
| `SESSION.md` | 세션 종료 시 (오늘 한 일, 이슈) |
| `PROJECT.md` | 범위/아키텍처 변경 시에만 |

---

## 시작 예시

> "현재 상태 요약하고, 오늘 작업 제안해줘"

> "SESSION.md 읽고 이어서 진행하자"
```

### PROJECT.md 템플릿

```markdown
---
name: project
description: {{project_name}} 프로젝트 핵심 요약. 프로젝트 구조와 기술 스택 파악용.
last-updated: {{date}}
---

# 프로젝트 개요

> {{purpose}}

---

## TL;DR

| 항목 | 내용 |
|------|------|
| **프로젝트** | {{project_name}} |
| **목적** | {{purpose}} |
| **기술 스택** | {{tech_stack_summary}} |
| **MVP 기능** | {{mvp_features_summary}} |
| **작업 관리** | {{task_tool_link}} |

---

## 프로젝트 구조

[TODO: 구조 확정 후 업데이트]

> 대화에서 구조가 언급되었으면 아래 형식으로 채움:
> ```
> project-name/
> ├── ...
> ```

---

## 기술 스택

| 영역 | 기술 |
|------|------|
{{tech_stack_table}}

---

## 핵심 파일

[TODO: 구현 후 핵심 파일 추가]

---

## 빠른 시작

[TODO: 환경 설정 확정 후 작성]

> 대화에서 명령어가 언급되었으면 채움:
> ```bash
> # 의존성 설치
> ...
> # 개발 서버 실행
> ...
> ```

---

## 상세 참조

| 문서 | 내용 |
|------|------|
| [SESSION.md](SESSION.md) | 현재 상태, 세션 로그 |
| [GUIDE.md](GUIDE.md) | 작업 원칙, MCP 도구 |
```

### SESSION.md 템플릿

```markdown
---
name: session
description: 프로젝트 현재 상태. 세션 시작 시 현재 상태 파악용.
last-updated: {{date}}
---

# 세션 상태

> 세션 시작 시 현재 상태를 빠르게 파악하기 위한 문서

---

## 작업 관리

| 항목 | 내용 |
|------|------|
{{task_management_table}}

> 예시:
> | **Notion** | [Product Backlog](링크) |
> | **GitHub** | [Issues](링크) |
> 없으면: | **작업 관리** | [TODO: 도구 선정 후 링크 추가] |

---

## 최근 완료

### {{date}}
- **프로젝트 초기화**: agent-guide 3종 파일 생성 (GUIDE.md, PROJECT.md, SESSION.md)

---

## 다음 작업

| 우선순위 | 작업 | 상태 |
|---------|------|------|
{{next_tasks_table}}

> 대화에서 다음 작업이 언급되지 않았으면:
> | P0 | 첫 번째 구현 작업 선택 | Todo |

---

## 기타 이슈

없음
```
