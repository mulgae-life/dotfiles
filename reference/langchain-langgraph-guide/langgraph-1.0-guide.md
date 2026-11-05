# LangGraph v1.0 종합 가이드

> 버전: LangGraph v1.0 GA (2025-10) / 라이선스: MIT
> 프로덕션 채택: Uber, LinkedIn, Klarna, Coinbase, Elastic, Harvey 등

---

## 1. 개요

LangGraph는 **에이전트 런타임 및 저수준 오케스트레이션 프레임워크**로, LLM 기반의 상태 유지(stateful) 워크플로우를 방향 그래프(Directed Graph)로 모델링한다.

**핵심 모델**: 노드(Node)는 작업 단위, 엣지(Edge)는 전이 경로.

```
[START] → [Node A] → [Node B] → [END]
                ↘ (조건부) → [Node C] ↗
```

**LangChain과의 관계**: LangChain 생태계의 일부이나 독립 사용 가능. LangChain의 `create_agent`는 내부적으로 LangGraph 런타임 사용.

---

## 2. StateGraph

### 기본 구성

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END, add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    context: str
    iteration_count: int

builder = StateGraph(AgentState)

builder.add_node("agent", agent_fn)
builder.add_node("tools", tool_fn)

builder.add_edge(START, "agent")
builder.add_edge("tools", "agent")
builder.add_conditional_edges("agent", should_continue, {"tools": "tools", "end": END})

graph = builder.compile(checkpointer=checkpointer)
```

### State 정의 방법

| 방법 | 적합 상황 |
|------|----------|
| TypedDict + Annotated | 일반적 (권장) |
| Pydantic BaseModel | 재귀적 검증 필요 시 |
| Dataclass | 기본값 많을 때 |
| MessagesState (프리빌트) | 대화형 에이전트 빠른 시작 |

### Reducer 패턴

| Reducer | 동작 | 용도 |
|---------|------|------|
| 없음 | 덮어쓰기 | 단순 값 |
| `add` | 리스트 추가 | 로그 |
| `add_messages` | ID 기반 병합 | LLM 대화 |
| 커스텀 함수 | 사용자 정의 | 복잡한 병합 |

### Command — 상태 업데이트 + 라우팅 결합

```python
from langgraph.types import Command

def my_node(state):
    return Command(
        update={"key": "value"},
        goto="next_node",
        graph=Command.PARENT  # 서브그래프 → 부모
    )
```

---

## 3. Human-in-the-Loop

### 동적 인터럽트 (프로덕션 권장)

```python
from langgraph.types import interrupt, Command

def approval_node(state):
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action"]
    })
    if decision["approved"]:
        return {"status": "approved"}
    return Command(goto="cancel")
```

```python
# 실행 → 인터럽트 → 재개
config = {"configurable": {"thread_id": "t1"}}
result = graph.invoke(input, config)
graph.invoke(Command(resume={"approved": True}), config)
```

### 정적 인터럽트 (디버깅용)

```python
graph = builder.compile(
    interrupt_before=["critical_node"],
    interrupt_after=["review_node"],
    checkpointer=checkpointer
)
```

### 규칙

- interrupt()를 try/except 안에 넣지 말 것
- 재개 시 interrupt 전 코드 재실행됨 → 부수효과 멱등하게
- JSON 직렬화 가능한 값만 전달
- 호출 순서 일관 유지

---

## 4. Functional API

그래프 없이 일반 Python으로 LangGraph 기능 활용:

```python
from langgraph.func import entrypoint, task

@task
def write_essay(topic: str) -> str:
    return llm.invoke(f"Write about {topic}")

@entrypoint(checkpointer=InMemorySaver())
def workflow(topic: str) -> dict:
    essay = write_essay(topic).result()
    approved = interrupt({"essay": essay})
    return {"essay": essay, "approved": approved}
```

| 측면 | Graph API | Functional API |
|------|-----------|----------------|
| 제어 흐름 | 명시적 DAG | Python (if/for/while) |
| 상태 관리 | State + Reducer | 함수 범위 |
| 시각화 | 지원 | 미지원 |
| 보일러플레이트 | 더 많음 | 더 적음 |

---

## 5. 멀티에이전트 패턴

### Supervisor

```
[Supervisor] → [Research Agent] / [Coding Agent] / [Review Agent]
```

### 계층적 (Hierarchical)

```
[Manager] → [Team Lead A] → [Worker A1, A2]
          → [Team Lead B] → [Worker B1]
```

### Peer-to-Peer

공유 상태를 통한 자유 정보 흐름.

---

## 6. Subgraphs

```python
# 공유 상태
builder.add_node("sub", sub_graph)

# 격리 상태 (변환 함수)
builder.add_node("sub", sub_graph, input=transform_fn)

# 부모-자식 통신
return Command(goto="parent_node", graph=Command.PARENT)
```

### 서브그래프 체크포인터 스코핑

| `checkpointer=` | interrupt | 멀티턴 메모리 | 동일 서브그래프 병렬 |
|-----------------|:---------:|:------------:|:------------------:|
| `False` | X | X | O |
| `None` (기본) | O | X | O |
| `True` | O | O | **X** (충돌) |

---

## 7. Map-Reduce

```python
from langgraph.types import Send

def map_step(state):
    return [Send("worker", {"item": item}) for item in state["items"]]

builder.add_conditional_edges("splitter", map_step)
builder.add_edge("worker", "reducer")
```

---

## 8. Checkpointing

### 체크포인터 종류

| 체크포인터 | 용도 |
|-----------|------|
| `InMemorySaver` | 개발 전용 |
| `SqliteSaver` | 로컬 |
| `PostgresSaver` | **프로덕션** |

### Time Travel

```python
history = list(graph.get_state_history(config))
old_config = {"configurable": {"thread_id": "1", "checkpoint_id": "..."}}
graph.invoke(None, config=old_config)  # 포크
```

### Memory Store (Cross-Thread)

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
store.put((user_id, "memories"), "pref1", {"food": "pizza"})
memories = store.search((user_id, "memories"), query="food?", limit=3)

graph = builder.compile(checkpointer=checkpointer, store=store)
```

---

## 9. 스트리밍

| 모드 | 설명 |
|------|------|
| `values` | 스텝마다 전체 상태 |
| `updates` | 변경분만 |
| `messages` | LLM 토큰 |
| `custom` | 커스텀 데이터 |
| `debug` | 최대 정보 |

```python
# 커스텀 스트리밍
from langgraph.config import get_stream_writer

def node(state):
    writer = get_stream_writer()
    writer({"progress": "50%"})
    return {"result": "done"}
```

---

## 10. 에러 핸들링

### 에러 전략 계층 (4-tier)

| 계층 | 에러 유형 | 전략 |
|------|----------|------|
| 1. RetryPolicy | 일시적 (네트워크, 레이트 리밋) | `add_node(..., retry_policy=RetryPolicy(...))` |
| 2. ToolNode 에러 | LLM 복구 가능 | `ToolNode(tools, handle_tool_errors=True)` |
| 3. interrupt | 사용자 개입 필요 | `interrupt({"error": ...})` |
| 4. Bubble up | 예상 외 | `raise` |

```python
from langgraph.types import RetryPolicy

# 노드 레벨 자동 재시도
builder.add_node(
    "api_call", api_call_fn,
    retry_policy=RetryPolicy(max_attempts=3, initial_interval=1.0, backoff_factor=2.0)
)

# recursion_limit (프로덕션 25~50)
config = {"recursion_limit": 25}
```

### 추가 전략

- 회로 차단기 (연속 실패 시 차단)
- 폴백 (대안 경로/모델)
- RemainingSteps로 선제적 종료

---

## 11. 노드 캐싱

```python
from langgraph.cache.memory import InMemoryCache

graph = builder.compile(cache=InMemoryCache())
builder.add_node("expensive", fn, cache_policy=CachePolicy(ttl=300))
```

---

## 12. Tool Calling

```python
from langgraph.prebuilt import ToolNode

tools = [search_tool, calc_tool]
llm_with_tools = llm.bind_tools(tools)
tool_node = ToolNode(tools)

builder.add_node("agent", lambda s: {"messages": [llm_with_tools.invoke(s["messages"])]})
builder.add_node("tools", tool_node)
```

---

## 13. 배포 (LangSmith Deployment)

| 옵션 | 설명 |
|------|------|
| Developer | 자체 호스팅, 월 100k 노드 무료 |
| Cloud | 완전 관리형 |
| Hybrid (BYOC) | SaaS 제어 + 자체 VPC |
| Self-Hosted | 완전 자체 인프라 |

---

## 14. 프레임워크 비교

| 항목 | LangGraph | CrewAI | AutoGen |
|------|-----------|--------|---------|
| 아키텍처 | 방향 그래프 | 역할 기반 | 대화 기반 |
| 프로덕션 준비도 | **최고** | 중간 | 낮음 |
| 학습 곡선 | 높음 | 낮음 | 중간 |
| 적합 | 복잡한 워크플로우 | 프로토타이핑 | 토론/합의 |

---

## 참고 출처

- [LangGraph 공식 사이트](https://www.langchain.com/langgraph)
- [LangGraph 1.0 GA](https://changelog.langchain.com/announcements/langgraph-1-0-is-now-generally-available)
- [LangGraph Graph API](https://docs.langchain.com/oss/python/langgraph/graph-api)
- [LangGraph Persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangGraph Interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts)
- [LangGraph Functional API](https://docs.langchain.com/oss/python/langgraph/functional-api)
- [Functional API 블로그](https://blog.langchain.com/introducing-the-langgraph-functional-api/)
- [NVIDIA Scaling Guide](https://developer.nvidia.com/blog/how-to-scale-your-langgraph-agents-in-production-from-a-single-user-to-1000-coworkers/)
- [AutoGen vs LangGraph vs CrewAI](https://dev.to/synsun/autogen-vs-langgraph-vs-crewai-which-agent-framework-actually-holds-up-in-2026-3fl8)
