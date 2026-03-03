# Agent Teams

> Claude Code의 다중 에이전트 협업 기능. 여러 Claude Code 인스턴스를 병렬로 조율하여 복잡한 작업을 수행한다.

**상태**: 연구 프리뷰 (Research Preview) — Claude Opus 4.6+

## 개요 및 아키텍처

Agent Teams는 하나의 Claude Code 세션(Lead)이 여러 Teammate 인스턴스를 생성하고 조율하는 기능이다. 각 Teammate는 독립적인 컨텍스트 윈도우에서 동작하며, 공유 태스크 리스트와 메일박스를 통해 협업한다.

### 핵심 구성 요소

| 구성 요소 | 역할 |
|-----------|------|
| **Lead** | 팀을 생성하고 조율하는 메인 세션. 태스크 배분, Teammate 생성/종료 담당 |
| **Teammates** | Lead가 생성한 독립 Claude Code 인스턴스. 각자 Opus 4.6 수준의 완전한 에이전트 |
| **Task List** | 모든 에이전트가 공유하는 작업 목록. pending → in_progress → completed 상태 관리 |
| **Mailbox** | 에이전트 간 직접 메시지 전달 시스템 |

### 저장 경로

- 팀 설정: `~/.claude/teams/{team-name}/config.json`
- 태스크 목록: `~/.claude/tasks/{team-name}/`

## Subagent와의 차이

| 특성 | Subagent (Agent 도구) | Agent Teams |
|------|----------------------|-------------|
| **컨텍스트** | 독립 윈도우, 결과만 호출자에게 반환 | 독립 윈도우, 완전히 자율적 |
| **커뮤니케이션** | 메인 에이전트에만 결과 보고 | Teammate 간 직접 메시지 가능 |
| **조율** | 메인 에이전트가 모든 작업 관리 | 공유 태스크 리스트로 자기 조율 |
| **적합한 용도** | 결과만 중요한 집중 작업 | 토론/협업이 필요한 복잡한 작업 |
| **토큰 비용** | 중간 (결과 요약 반환) | 높음 (각 Teammate가 독립 인스턴스) |

**선택 기준**:
- Teammate 간 토론이 필요하면 → Agent Teams
- 결과만 필요하면 → Subagent
- 직접 제어가 필요하면 → Git Worktree 수동 세션

## 활성화 방법

Agent Teams는 기본 비활성화 상태이다.

### 방법 A: settings.json (영구 적용)

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 방법 B: 환경변수 (일회성)

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude
```

## 디스플레이 모드

### In-Process 모드 (기본)

모든 Teammate가 메인 터미널 내에서 실행된다.

| 단축키 | 동작 |
|--------|------|
| **Shift+Down** | Teammate 간 순환 이동 |
| **Enter** | 선택한 Teammate 세션 보기 |
| **Escape** | Teammate 중단 |
| **Ctrl+T** | 태스크 리스트 토글 |

### Split Panes 모드

각 Teammate가 별도 패널에서 실행된다. 요구사항:
- **tmux**: 패키지 매니저로 설치
- **iTerm2**: Python API 활성화 + `it2` CLI 설치

### 설정

```json
{
  "teammateMode": "in-process"  // "tmux" | "auto" (기본값)
}
```

또는 실행 시 플래그:

```bash
claude --teammate-mode in-process
```

> **참고**: VS Code 내장 터미널, Windows Terminal, Ghostty에서는 Split Panes 미지원.

## 사용법

### 팀 생성

자연어로 팀 구조와 작업을 지시한다:

```
CLI 도구를 설계하려고 합니다. 에이전트 팀을 만들어서
UX 담당, 기술 아키텍처 담당, 비판적 검토 담당으로 나눠 병렬 탐색해주세요.
```

Claude가 자동으로:
1. 팀을 생성하고 Teammate를 생성
2. 공유 태스크 리스트를 설정
3. 작업을 조율하고 결과를 종합

### Teammate 및 모델 지정

```
4명의 Teammate로 팀을 만들어서 이 모듈들을 병렬 리팩토링해주세요.
각 Teammate는 Sonnet을 사용해주세요.
```

### Teammate에 직접 메시지

- **In-process**: Shift+Down으로 순환 → 메시지 입력
- **Split Panes**: 해당 패널 클릭 후 직접 상호작용

### 태스크 관리

- **Lead가 할당**: "보안 검토 태스크를 researcher Teammate에게 할당해주세요"
- **자동 수령**: Teammate는 작업 완료 후 다음 미할당 태스크를 자동으로 수령
- 태스크 상태: pending → in_progress → completed
- 태스크 간 의존성(dependency) 지원

### 계획 승인 요구

```
architect Teammate를 생성해서 인증 모듈을 리팩토링하게 하되,
변경 전에 계획 승인을 요구해주세요.
```

Teammate는 Lead가 승인할 때까지 읽기 전용 계획 모드로 동작한다.

### 팀 종료

```
팀을 정리해주세요.
```

항상 Lead를 통해 정리한다 (Teammate가 아닌).

## 훅(Hook) 연동

Agent Teams 전용 훅 2종이 있다.

### TeammateIdle

Teammate가 작업 완료 후 유휴 상태로 전환되기 전에 실행된다.

**용도**: 품질 게이트 — Teammate가 멈추기 전에 조건 충족 확인

```bash
#!/bin/bash
# 빌드 산출물이 없으면 유휴 전환 차단
if [ ! -f "./dist/output.js" ]; then
  echo "빌드 산출물 없음. 빌드를 먼저 실행하세요." >&2
  exit 2  # exit 2: 동작 차단, Teammate 계속 작업
fi
exit 0
```

**입력 JSON**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "TeammateIdle",
  "teammate_name": "researcher",
  "team_name": "my-project",
  "cwd": "/path/to/project",
  "permission_mode": "default"
}
```

**종료 코드**: `0` = 유휴 허용, `2` = 차단 (stderr 피드백 전달)

> **참고**: TeammateIdle은 command 훅만 지원.

### TaskCompleted

태스크가 완료 처리되기 전에 실행된다.

**용도**: 완료 기준 검증 — 테스트 통과, 린트 검사 등

```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

if ! npm test 2>&1; then
  echo "테스트 실패. 완료 전에 수정 필요: $TASK_SUBJECT" >&2
  exit 2
fi
exit 0
```

**입력 JSON**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "TaskCompleted",
  "task_id": "task-001",
  "task_subject": "사용자 인증 구현",
  "task_description": "로그인 및 회원가입 엔드포인트 추가",
  "teammate_name": "implementer",
  "team_name": "my-project",
  "cwd": "/path/to/project"
}
```

**종료 코드**: `0` = 완료 허용, `2` = 차단 (stderr 피드백 전달)

> **참고**: TaskCompleted는 모든 훅 유형 지원 (command, HTTP, prompt, agent).

### settings.json 훅 설정 예시

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/teammate-idle-check.sh"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/task-completed-check.sh"
          }
        ]
      }
    ]
  }
}
```

## 베스트 프랙티스

### 팀 크기

- **권장**: 3~5명의 Teammate
- 토큰 비용은 Teammate 수에 비례하여 선형 증가
- 팀이 클수록 조율 오버헤드 증가, 수확체감 발생
- Teammate당 5~6개 태스크가 적절

### 충분한 컨텍스트 제공

Teammate는 Lead의 대화 이력을 상속하지 않는다. 생성 시 구체적 맥락을 포함해야 한다:

```
보안 리뷰 Teammate를 생성해주세요. 프롬프트: "src/auth/ 디렉토리의
인증 모듈을 보안 취약점 관점에서 검토해주세요. 토큰 처리, 세션 관리,
입력 검증에 집중. 앱은 httpOnly 쿠키에 저장된 JWT 토큰을 사용합니다.
심각도 등급과 함께 이슈를 보고해주세요."
```

### 태스크 크기 조절

| 크기 | 문제점 |
|------|--------|
| 너무 작음 | 조율 오버헤드가 이득을 초과 |
| 너무 큼 | 체크인 없이 오래 작업 → 노력 낭비 위험 |
| 적절함 | 명확한 산출물이 있는 자기 완결적 단위 (함수, 테스트 파일, 리뷰 섹션) |

### 파일 충돌 방지

두 Teammate가 같은 파일을 편집하면 덮어쓰기가 발생한다. **각 Teammate가 서로 다른 파일을 담당하도록 작업을 분할**해야 한다.

### 리서치/리뷰부터 시작

Agent Teams에 익숙해지려면 경계가 명확한 작업부터 시작:
- 코드 리뷰 (같은 코드에 대한 병렬 관점)
- 라이브러리 조사 (다른 측면)
- 버그 조사 (경쟁 가설)

### Lead 대기 지시

Lead가 직접 구현을 시작하면:
```
Teammate들이 작업을 완료할 때까지 기다려주세요.
```

## 사용 사례

### 병렬 코드 리뷰

```
PR #142를 리뷰할 에이전트 팀을 만들어주세요.
- 보안 관점 리뷰어
- 성능 영향 리뷰어
- 테스트 커버리지 리뷰어
각자 리뷰 후 결과를 보고하게 해주세요.
```

### 경쟁 가설 조사

```
앱이 메시지 하나 보내고 종료되는 버그가 보고됐습니다.
5명의 Teammate로 서로 다른 가설을 조사하게 하고,
서로의 이론을 반증하도록 토론하게 해주세요.
합의된 결과를 findings 문서에 기록해주세요.
```

### 풀스택 기능 개발

```
새 기능을 구현할 팀을 만들어주세요:
- API 레이어 담당
- 프론트엔드 컴포넌트 담당
- 테스트 스위트 담당
```

### 대규모 리팩토링

```
리팩토링 팀을 구성해주세요:
- 라우트 레이어 변환 담당
- 서비스 클래스 업데이트 담당
- 영향받는 테스트 수정 담당
- 기존 계약 유지 확인 리뷰어
```

## 알려진 제한사항

| 제한 | 영향 |
|------|------|
| **세션 복원 미지원** | `/resume`, `/rewind`로 in-process Teammate 복원 불가. Lead가 없는 Teammate에 메시지 시도 가능 |
| **태스크 상태 지연** | Teammate가 태스크 완료 표시를 누락하여 의존 태스크가 차단될 수 있음 |
| **종료 지연** | Teammate는 현재 요청/도구 호출 완료 후에야 종료 |
| **세션당 1팀** | Lead는 한 번에 하나의 팀만 관리. 새 팀 시작 전 현재 팀 정리 필요 |
| **중첩 팀 불가** | Teammate는 자체 팀 생성 불가. Lead만 팀 관리 가능 |
| **Lead 고정** | 팀을 생성한 세션이 수명 동안 Lead로 유지. 리더십 이전 불가 |
| **권한 생성 시 고정** | 모든 Teammate는 Lead의 권한 모드로 시작. 생성 후 개별 변경 가능 |

**세션 복원 해결책**: `/resume` 후 새 Teammate를 생성하면 된다.

## 트러블슈팅

### Teammate가 나타나지 않음

- In-process 모드에서는 이미 실행 중일 수 있다 → **Shift+Down**으로 확인
- 태스크 복잡도를 확인 — Claude가 태스크 기반으로 생성 여부를 판단
- tmux가 PATH에 있는지 확인: `which tmux`
- iTerm2: `it2` CLI 설치 및 Python API 활성화 확인

### 권한 프롬프트 과다

Teammate 생성 전에 settings.json의 `permissions.allow`에 자주 쓰는 작업을 사전 승인하면 마찰을 줄일 수 있다.

### Teammate가 에러 시 중단

에러 발생 후 복구 대신 중단하는 경우:
1. 출력 확인 (in-process: Shift+Down, split: 패널 클릭)
2. 추가 지시를 직접 전달하거나
3. 대체 Teammate를 생성하여 계속

### Lead가 조기 종료

Lead가 작업 완료 전에 팀을 끝내려 할 때:

```
Teammate들이 아직 작업 중입니다. 계속 기다려주세요.
```

### tmux 세션 잔류

팀 종료 후에도 tmux 세션이 남아있을 때:

```bash
tmux ls
tmux kill-session -t <session-name>
```

### 태스크 상태 멈춤

Teammate가 태스크 완료 표시를 누락한 경우:
1. 실제 작업 완료 여부 확인
2. Lead에게 해당 태스크 상태 업데이트 요청

## 비용 고려사항

Agent Teams는 단일 세션보다 **상당히 많은 토큰을 사용**한다:

- 각 Teammate가 독립 컨텍스트 윈도우를 소비
- 토큰 사용량은 활성 Teammate 수에 비례
- `/cost` 명령으로 실시간 토큰 사용량 모니터링 가능

**비용 효율적 사용**:
- 리서치, 리뷰, 새 기능 개발 등 병렬 가치가 토큰 비용을 정당화하는 경우에 사용
- 단순 반복 작업은 단일 세션이 더 효율적
- 3~5명이 대부분 워크플로우의 최적점

## 참고 자료

- [공식 문서](https://code.claude.com/docs/en/agent-teams)
- [훅 레퍼런스](https://code.claude.com/docs/en/hooks)
