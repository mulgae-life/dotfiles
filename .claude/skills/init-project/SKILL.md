---
name: init-project
description: 새 프로젝트의 agent-guide 3종 파일(GUIDE.md, PROJECT.md, SESSION.md)을 자동 생성합니다. 새 프로젝트를 시작하거나, 프로젝트 구조를 잡거나, AI 에이전트 가이드 문서가 필요할 때 사용합니다. "프로젝트 초기화해줘", "agent-guide 만들어줘", "새 프로젝트 세팅해줘", "프로젝트 구조 잡아줘", "가이드 문서 만들어줘" 등의 요청에 트리거.
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
→ `templates/GUIDE.md.template` 읽어서 적용

### 3단계: PROJECT.md 생성

`agent-guide/PROJECT.md` — 대화 맥락 **의존도 가장 높음**.
→ `templates/PROJECT.md.template` 읽어서 적용

### 4단계: SESSION.md 생성

`agent-guide/SESSION.md` — **최소 템플릿** (초기 기록 1건).
→ `templates/SESSION.md.template` 읽어서 적용

### 생성 후 확인

3개 파일 생성 완료 후:
1. 각 파일 요약 (핵심 내용 1-2줄)
2. `[TODO]` 항목 목록 안내
3. 수정 필요 여부 확인

---

## 템플릿

각 템플릿 파일을 읽어서 `{{변수}}`를 대화 맥락으로 치환합니다:

| 파일 | 대상 | 핵심 변수 |
|------|------|----------|
| `templates/GUIDE.md.template` | agent-guide/GUIDE.md | terms_table, task_check_step 등 |
| `templates/PROJECT.md.template` | agent-guide/PROJECT.md | project_name, purpose, tech_stack_table 등 |
| `templates/SESSION.md.template` | agent-guide/SESSION.md | task_management_table, next_tasks_table, date 등 |
