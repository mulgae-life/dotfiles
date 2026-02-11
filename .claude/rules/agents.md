---
name: agents
description: 에이전트 자동 위임 오케스트레이션 규칙. 언제 어떤 에이전트를 자동으로 호출할지 정의합니다.
alwaysApply: true
---

# 에이전트 자동 위임 규칙

## 핵심 원칙

**자동 위임**: 조건 충족 시 사용자 요청 없이 Claude가 에이전트에 작업 위임

```
사용자 요청 → Claude 분석 → 조건 충족 → 에이전트 자동 위임
                         → 조건 미충족 → Claude 직접 처리
```

## 사용 가능한 에이전트

| 에이전트 | 역할 | 모델 |
|----------|------|------|
| `planner` | 복잡한 기능 구현 계획 초안 작성 | opus |
| `verifier` | 코딩 완료 후 자동 점검 | opus |
| `security-reviewer` | 보안 취약점 탐지 | opus |
| `build-resolver` | 빌드/타입 에러 해결 | opus |

## 자동 위임 트리거

### 1. build-resolver (최우선)

**트리거 조건**:
- `npm run build` 실패
- `tsc` 타입 에러 발생
- `pnpm build` 실패

```
빌드 명령 실행 → 에러 발생 → [build-resolver 즉시 위임]
```

**우선순위**: 다른 모든 에이전트보다 우선 (빌드 안되면 다른 작업 무의미)

### 2. security-reviewer

**트리거 조건**:
- 인증/인가 코드 작성 (auth, login, session, token)
- API 엔드포인트 추가/수정
- 비밀번호, 암호화 관련 코드
- 환경변수, 시크릿 처리 코드

```
보안 민감 코드 감지 → [security-reviewer 자동 위임]
```

### 3. planner (계획 초안용)

**트리거 조건**:
- 복잡한 기능 요청 (파일 3개 이상 수정 예상)
- 아키텍처 결정이 필요한 작업
- "어떻게 구현하지?", "구현해줘", "만들어줘" + 복잡한 요청

```
복잡한 요청 → [planner 초안 작성] → 사용자와 논의 → 계획 확정
```

**주의**: planner는 초안만 작성. 이후 사용자와 티키타카 논의하며 확정.

### 4. verifier

**트리거 조건**:
- 코드 작성/수정 완료 후
- "점검해줘", "확인해줘", "이상 없어?"

```
코딩 완료 → [verifier 자동 점검] → 결과 보고
```

## 위임 우선순위

충돌 시 우선순위:

```
1. build-resolver   ← 빌드 안되면 다른 작업 무의미
2. security-reviewer ← 보안 이슈는 기능보다 우선
3. planner          ← 계획 먼저, 구현 나중
4. verifier         ← 구현 완료 후 점검
```

## 에이전트 체이닝

일반적인 작업 흐름:

```
[사용자: 복잡한 기능 요청]
    ↓
[planner] → 계획 초안 작성
    ↓
[사용자] ↔ [Claude] 티키타카 논의
    ↓
[계획 확정]
    ↓
[Claude] → 구현 수행
    ↓
[verifier] → 자동 점검
    ↓
(보안 코드라면) [security-reviewer] → 자동 분석
    ↓
(빌드 에러 시) [build-resolver] → 즉시 수정
```

## 위임 금지 조건

다음 경우에는 에이전트 사용 안함:

- 단순 질문/설명 요청
- 1-2줄 간단한 수정
- 사용자가 "직접 해줘" 명시적 요청
- 파일 1-2개만 수정하는 간단한 작업

## 스킬과의 역할 분담

| 자동 (Agent) | 수동 (Skill) |
|--------------|--------------|
| verifier: 빠른 점검 | /code-review: 심층 리뷰 |
| security-reviewer: 자동 체크 | /code-simplifier: 코드 간소화 |
| build-resolver: 에러 수정 | /feedback-analysis: 피드백 분석 |
| planner: 계획 초안 | /update-docs: 문서 업데이트 |

심층 리뷰가 필요할 때는 `/code-review` 스킬을 수동으로 호출.
