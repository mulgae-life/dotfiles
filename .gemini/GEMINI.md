# Antigravity 작업 지침 (전역)

`~/.claude/CLAUDE.md`의 절차와 규칙을 따른다.
이 문서는 Antigravity(Gemini Code Assist) 고유의 차이점만 정의한다.

## 우선순위

1. `~/.claude/CLAUDE.md` (기준 문서)
2. 사용자의 현재 요청
3. 저장소의 실제 코드/구조/테스트 결과
4. 이 문서의 보충 지침

## 핵심 규칙

Antigravity는 `.claude/rules/*.md`를 자동 로드하지 않는다.
**세션 시작 시 아래 파일을 반드시 읽고 전체 내용을 적용한다.**

| 파일 | 내용 |
|------|------|
| `~/.claude/rules/communication.md` | 한국어 응답, 변경 이유 설명, 에러 설명 형식 |
| `~/.claude/rules/architecture.md` | 기존 구조 파악, 단일 역할 원칙, 의존성 단방향, Co-location |
| `~/.claude/rules/coding-style.md` | 범위 준수, 최소 diff, 에러 처리, 리소스 수명주기, 언어별 패턴 |
| `~/.claude/rules/security.md` | 시크릿 관리, 입력 검증, SQL 인젝션/XSS/CSRF 방지 |
| `~/.claude/rules/agents.md` | 에이전트 위임 트리거, 우선순위, 체이닝 절차 |

> 아래는 파일 접근 불가 시 최소 기준선이다.

- **언어**: 모든 응답과 설명은 **한국어**로 작성. 영어 기술 용어는 한국어 설명과 병기.
- **변경 설명**: 코드 변경 시 **이유를 상세히 설명**. 에러는 원인과 해결책을 함께 제시.
- **구조**: 기존 프로젝트 패턴 우선. 파일당 단일 역할. UI→로직→데이터→타입 단방향 의존.
- **보안**: 하드코딩 시크릿 **절대 금지**. 모든 사용자 입력 검증. SQL 인젝션/XSS 방지.
- **범위**: 요청 범위 밖 리팩토링 **금지**. 최소 diff 원칙. 경계 검증 필수.

## 에이전트 운영 (Antigravity 대응)

Claude Code의 자동 위임을 Antigravity에서는 절차형으로 대응한다.
**각 에이전트의 상세 절차와 출력 형식은 아래 파일을 반드시 읽고 따른다.**

| 파일 | 역할 |
|------|------|
| `~/.claude/agents/planner.md` | 계획 초안 작성 절차, 분석 프로세스, 출력 형식 |
| `~/.claude/agents/build-resolver.md` | 빌드 에러 해결 프로세스, 최소 diff 원칙, 에러 패턴 |
| `~/.claude/agents/security-reviewer.md` | OWASP Top 10 분석, 취약점 분류, 보안 체크리스트 |
| `~/.claude/agents/verifier.md` | 코딩 완료 후 점검 절차, 자동 수정 범위 |

> 아래는 파일 접근 불가 시 최소 기준선이다.

- **planner**: 복잡한 요청(파일 3개 이상) → 계획 먼저 정리
- **build-resolver**: 빌드/타입 에러 → 최우선, 최소 변경 해결
- **security-reviewer**: 보안 민감 코드 → OWASP 점검 강화
- **verifier**: 구현 완료 후 → 기본 점검 수행

## 스킬 활용

`~/.agents/skills/` 디렉토리에 작업별 전문 가이드가 있다.
해당 분야 작업 시 `SKILL.md`를 읽고 절차와 품질 기준을 따른다.

```
~/.agents/skills/{skill-name}/SKILL.md
```

예: React 성능 최적화 → `react-best-practices/SKILL.md`,
코드 리뷰 → `code-review/SKILL.md`, 보안 점검 → `code-verify/SKILL.md`

## 워크플로우

전역 워크플로우는 `~/.gemini/antigravity/global_workflows/`에 위치한다.
워크플로우 파일은 YAML frontmatter + 마크다운 단계별 지침 형식이다.

```yaml
---
description: 워크플로우 설명
---
1. 첫 번째 단계
2. 두 번째 단계
```

## 비파괴 원칙

- `~/.claude` 디렉토리는 삭제/수정하지 않는다.
- Antigravity 설정은 `~/.gemini` 내에서만 관리한다.
