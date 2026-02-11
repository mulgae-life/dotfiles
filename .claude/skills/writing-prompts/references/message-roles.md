# Message Roles

OpenAI API는 메시지 역할을 통해 권한 수준을 제어합니다.

## 역할 구분

| 역할 | 용도 | 우선순위 | 비유 |
|------|------|----------|------|
| `developer` | 시스템 규칙, 비즈니스 로직 | ⭐⭐⭐ 최고 | 함수 정의 |
| `user` | 사용자 입력, 질문 | ⭐⭐ 중간 | 함수 인자 |
| `assistant` | 모델 응답 | - | 함수 반환값 |

**핵심 개념**: `developer` 메시지는 시스템의 불변 규칙, `user` 메시지는 가변 입력.

## 사용 방법

### 방법 1: instructions 파라미터 (권장)

```python
response = client.responses.create(
    model="gpt-5",
    instructions="반드시 격식체(~습니다, ~입니다)를 사용하세요.",
    input="안녕하세요"
)
```

**장점**: 간결함, 명확한 의도

### 방법 2: developer role

```python
response = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "developer",
            "content": "반드시 격식체(~습니다, ~입니다)를 사용하세요."
        },
        {
            "role": "user",
            "content": "안녕하세요"
        }
    ]
)
```

**장점**: 대화 이력 관리 용이

## 우선순위

충돌 시 우선순위:
1. `developer` 메시지
2. `instructions` 파라미터
3. `user` 메시지

**예시**:
```python
# developer가 우선
input=[
    {"role": "developer", "content": "반드시 격식체 사용"},
    {"role": "user", "content": "반말로 대답해"}  # 무시됨
]
```

## 대화 이력 관리

### previous_response_id 사용

```python
# 첫 요청
response1 = client.responses.create(
    model="gpt-5",
    instructions="격식체 사용",
    input="안녕하세요"
)

# 후속 요청 (instructions는 자동 유지 안 됨!)
response2 = client.responses.create(
    model="gpt-5",
    previous_response_id=response1.id,
    instructions="격식체 사용",  # 다시 명시 필요
    input="계속 이야기해주세요"
)
```

**주의**: `instructions`는 각 요청마다 다시 전달해야 함.

## 실전 예시

### 고객 서비스

```python
response = client.responses.create(
    model="gpt-5",
    instructions="""
    당신은 NewTelco 고객 서비스 에이전트입니다.

    <rules>
    - 반드시 격식체를 사용하세요
    - 회사 정책에 대한 질문은 도구를 먼저 호출하세요
    </rules>

    <constraints>
    - 정치, 종교 주제 논의 금지
    - 추측 금지 - 확실하지 않으면 상담원에게 에스컬레이션
    </constraints>
    """,
    input="가족 요금제에 대해 알려주세요"
)
```

### Agentic 작업

```python
response = client.responses.create(
    model="gpt-5",
    instructions="""
    당신은 소프트웨어 엔지니어링 에이전트입니다.

    <persistence>
    - 문제가 완전히 해결될 때까지 계속 진행하세요
    - 불확실한 경우에도 멈추지 마세요
    </persistence>

    <tool_usage>
    - 파일 내용이나 구조에 대해 확실하지 않으면 도구를 사용하세요
    - 추측하지 마세요
    </tool_usage>
    """,
    tools=[...],
    input="login.py의 인증 버그를 수정해줘"
)
```

## 참고

- OpenAI Model Spec: https://model-spec.openai.com/2025-02-12.html#chain_of_command
