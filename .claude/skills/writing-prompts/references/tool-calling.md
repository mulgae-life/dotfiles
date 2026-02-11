# Tool Calling (Agentic 작업)

Agentic 작업에서 Tool calling을 최적화하는 가이드.

## 핵심 패턴

### 1. Persistence (지속성)

모델이 작업을 끝까지 완료하도록 유도합니다.

```yaml
<persistence>
- 당신은 에이전트입니다 - 사용자의 요청이 완전히 해결될 때까지 계속 진행하세요
- 작업이 완전히 완료되었다고 확신할 때만 종료하세요
- 불확실성에서 멈추지 마세요 - 가장 합리적인 접근 방식을 조사하거나 추론하여 계속 진행하세요
- 사용자에게 확인을 요청하지 마세요 - 가정을 문서화하고 실행한 후 필요 시 중간에 조정하세요
</persistence>
```

### 2. Tool Preambles (진행 상황 알림)

Tool 호출 전에 사용자에게 진행 상황을 알립니다.

```yaml
<tool_preambles>
- 항상 Tool을 호출하기 전에 사용자의 목표를 친절하고 명확하게 다시 표현하세요
- 그런 다음 즉시 각 논리적 단계를 자세히 설명하는 구조화된 계획을 제시하세요
- 파일 편집을 실행할 때 각 단계를 간결하고 순차적으로 설명하고 진행 상황을 명확히 표시하세요
- 완료된 작업을 초기 계획과 구별하여 요약하여 마무리하세요
</tool_preambles>
```

### 3. Tool 정의

Tool은 `tools` 필드에 정의하고, 프롬프트에는 사용법만 기술합니다.

**❌ 나쁜 예**: 프롬프트에 Tool 스키마 직접 삽입
**✅ 좋은 예**: API `tools` 필드 + 프롬프트에 예시

```python
# API 호출
response = client.responses.create(
    model="gpt-5",
    tools=[
        {
            "type": "function",
            "name": "get_weather",
            "description": "현재 날씨 정보를 가져옵니다",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"},
                    "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
                },
                "required": ["location"]
            }
        }
    ],
    instructions="""
    # Tool Usage Examples
    <tool_usage>
    사용자: "서울 날씨 알려줘"

    1. "서울의 현재 날씨를 확인하겠습니다"
    2. get_weather(location="서울", unit="celsius") 호출
    3. 결과를 격식체로 요약
    </tool_usage>
    """,
    input="서울 날씨 알려줘"
)
```

## Agentic Eagerness 제어

### Less Eager (덜 적극적)

빠른 응답, 최소 Tool 호출:

```yaml
<context_gathering>
Goal: 충분한 맥락을 빠르게 수집. 병렬화하고 행동 가능해지면 즉시 중단.

Method:
- 넓게 시작한 후 집중된 하위 쿼리로 확장
- 병렬로 다양한 쿼리 실행
- 경로 중복 제거 및 캐싱
- 과도한 맥락 검색 피하기

Early stop:
- 변경할 정확한 내용을 명시할 수 있음
- 상위 결과가 하나의 영역에 ~70% 수렴

Depth:
- 수정할 심볼만 추적
- 불필요한 전이적 확장 피하기
</context_gathering>
```

### More Eager (더 적극적)

철저한 탐색, 자율적 작업:

```yaml
<persistence>
- 당신은 에이전트입니다 - 완전히 해결될 때까지 계속 진행하세요
- 문제가 해결되었다고 확신할 때만 종료하세요
- 불확실성에서 멈추지 마세요 - 조사하거나 추론하여 계속하세요
- 가정을 확인하도록 요청하지 마세요 - 결정하고 실행한 후 틀리면 조정하세요
</persistence>
```

## 실전 예시

### 코딩 에이전트

```yaml
system_prompt: |
  # Identity
  당신은 소프트웨어 엔지니어링 에이전트입니다.

  # Instructions
  <persistence>
  - 문제가 완전히 해결될 때까지 계속 진행하세요
  - 작업이 완료되었다고 확신할 때만 종료하세요
  </persistence>

  <tool_usage>
  - 파일 내용이나 구조에 대해 확실하지 않으면 도구를 사용하세요
  - 추측하지 마세요
  </tool_usage>

  <planning>
  - 각 함수 호출 전에 광범위하게 계획하세요
  - 이전 호출 결과를 반영하세요
  - 텍스트로 사고 과정을 명시하세요
  </planning>

  <workflow>
  1. 문제 깊이 이해
  2. 코드베이스 조사
  3. 상세한 계획 개발
  4. 점진적 구현
  5. 디버깅
  6. 테스트
  7. 반복
  </workflow>
```

### SWE-bench 에이전트

```yaml
<workflow>
## 문제 해결 전략

1. 문제를 깊이 이해하세요
2. 코드베이스를 조사하세요 (도구 사용)
3. 명확한 단계별 계획을 개발하세요
4. 수정을 점진적으로 구현하세요
5. 필요에 따라 디버깅하세요
6. 자주 테스트하세요
7. 모든 테스트가 통과할 때까지 반복하세요
8. 최종적으로 원래 의도를 반영하고 추가 테스트 작성
</workflow>

<tool_calling>
파일 내용이나 구조에 대해 확실하지 않으면 도구를 사용하세요.
추측하거나 답을 만들어내지 마세요.
</tool_calling>

<planning>
각 함수 호출 전에 광범위하게 계획하세요.
이전 함수 호출의 결과를 광범위하게 반영하세요.
함수 호출만으로 전체 프로세스를 수행하지 마세요 - 이는 문제 해결과 통찰력 있는 사고 능력을 저해할 수 있습니다.
</planning>
```

### 고객 서비스 에이전트

```yaml
<tool_calling>
- 회사, 제품 또는 사용자 계정에 대한 사실 질문에 답변하기 전에 항상 도구를 호출하세요
- 검색된 컨텍스트만 사용하고 자체 지식에 의존하지 마세요
- 도구를 적절히 호출할 충분한 정보가 없으면 사용자에게 필요한 정보를 요청하세요
</tool_calling>

<sample_phrases>
도구 호출 전:
- "그 정보를 확인해 드리겠습니다. 잠시만 기다려 주세요."
- "최신 정보를 확인하겠습니다."

도구 호출 후:
- "확인해 본 결과입니다: [응답]"
</sample_phrases>

<response_steps>
각 응답마다:
1. 필요한 경우 사용자의 원하는 작업을 수행하기 위해 도구를 호출하세요
   - 도구를 호출하기 전과 후에 항상 사용자에게 진행 상황을 알리세요
2. 사용자에게 응답할 때:
   a. 적극적 경청 - 사용자가 요청한 내용을 다시 말하세요
   b. 가이드라인에 따라 적절하게 응답하세요
</response_steps>
```

## 체크리스트

Agentic 작업 프롬프트 작성 시:

- [ ] Persistence 지침 추가
- [ ] Tool Preambles 지침 추가
- [ ] Tool 사용 예시 제공
- [ ] Workflow 단계 명시
- [ ] Eagerness 수준 결정 (Less/More)
- [ ] reasoning_effort=high 설정
- [ ] Planning 지침 추가

## 출처

- GPT-5 Prompting Guide (Agentic Workflow)
- GPT-4.1 Prompting Guide (SWE-bench)
