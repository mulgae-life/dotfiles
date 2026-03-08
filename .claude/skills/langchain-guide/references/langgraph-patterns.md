# LangGraph 패턴 상세 가이드

> LangGraph v1.0 GA 기준

## 목차

- [1. StateGraph 구성](#1-stategraph-구성)
- [2. State 설계](#2-state-설계)
- [3. Edges 및 라우팅](#3-edges-및-라우팅)
- [4. Human-in-the-Loop](#4-human-in-the-loop)
- [5. Functional API](#5-functional-api)
- [6. 멀티에이전트 패턴](#6-멀티에이전트-패턴)
- [7. Subgraphs](#7-subgraphs)
- [8. Map-Reduce](#8-map-reduce)
- [9. Tool Calling in Graphs](#9-tool-calling-in-graphs)

---

## 1. StateGraph 구성

### 기본 구조

```python
from langgraph.graph import StateGraph, START, END

builder = StateGraph(AgentState)

# 노드 추가 (Python 함수)
builder.add_node("agent", agent_fn)
builder.add_node("tools", tool_fn)

# 엣지 추가
builder.add_edge(START, "agent")
builder.add_edge("tools", "agent")

# 조건부 엣지
builder.add_conditional_edges(
    "agent",
    routing_fn,
    {"use_tool": "tools", "done": END}
)

# 컴파일
graph = builder.compile(checkpointer=checkpointer)
```

### 노드 함수

노드는 State를 입력받고 State 업데이트(부분 dict)를 반환하는 함수:

```python
# 시그니처 1: State만 (기본)
def agent_fn(state: AgentState) -> dict:
    response = model.invoke(state["messages"])
    return {"messages": [response]}  # Reducer에 따라 병합

# 시그니처 2: State + Config (thread_id, tags 등 접근)
def agent_fn_with_config(state: AgentState, config: RunnableConfig) -> dict:
    thread_id = config["configurable"]["thread_id"]
    return {"messages": [...]}

# 시그니처 3: State + Runtime (store, context, stream_writer 접근)
from langgraph.runtime import Runtime
def agent_fn_with_runtime(state: AgentState, runtime: Runtime) -> dict:
    user_prefs = runtime.store.get((state["user_id"], "prefs"), "lang")
    return {"messages": [...]}
```

> **주의:** 노드는 반드시 **부분 업데이트 dict**만 반환. 전체 state를 변경 후 반환하면 안 됨.

### Command — 상태 업데이트 + 라우팅 결합

```python
from langgraph.types import Command
from typing import Literal

# 반환 타입에 Literal로 유효한 goto 대상 선언 (필수)
def my_node(state) -> Command[Literal["next_node", "fallback"]]:
    return Command(
        update={"key": "new_value"},   # 상태 업데이트
        goto="next_node",              # 다음 노드
        graph=Command.PARENT           # 서브그래프에서 부모로 전이
    )
```

> **⚠ 정적 엣지 경고:** Command의 `goto`는 **동적 엣지만** 추가. `add_edge("node_a", "node_b")`로 정적 엣지도 있으면 **둘 다 실행**됨. Command를 쓰는 노드에는 `add_edge` 대신 `add_conditional_edges` 사용할 것.

---

## 2. State 설계

### TypedDict (권장)

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]  # Reducer: 메시지 추가
    context: str                              # Reducer 없음: 덮어쓰기
    iteration_count: int
```

### Reducer 패턴

| Reducer | 동작 | 용도 |
|---------|------|------|
| 없음 (기본) | 값 덮어쓰기 | 단순 값 |
| `add` (`operator.add`) | 리스트에 추가 | 로그, 이력 |
| `add_messages` | 메시지 ID 기반 병합 | LLM 대화 |
| 커스텀 함수 | 사용자 정의 | 복잡한 병합 |

> **흔한 실수:** 리스트 필드에 Reducer를 빠뜨리면 마지막 값이 이전 값을 **덮어씀**. `messages: list` → 데이터 유실. 반드시 `messages: Annotated[list, operator.add]` 사용.

### Reducer 바이패스

```python
from langgraph.types import Overwrite

# Reducer가 있는 필드를 덮어쓰고 싶을 때
graph.update_state(config, {"items": Overwrite(["new_only"])})
# Reducer 통과: ["old", "new_only"] → Overwrite: ["new_only"]

# 메시지 삭제 (add_messages Reducer에서)
from langchain_core.messages import RemoveMessage
return {"messages": [RemoveMessage(id=msg_id)]}
```

### MessagesState (프리빌트)

```python
from langgraph.graph import MessagesState
# messages: Annotated[list, add_messages] 미리 설정
# 간단한 대화형 에이전트에 바로 사용 가능
```

### Pydantic / Dataclass State

```python
# Pydantic (재귀적 검증 필요 시)
from pydantic import BaseModel
class State(BaseModel):
    messages: list
    context: str = ""

# Dataclass (기본값 필요 시)
from dataclasses import dataclass, field
@dataclass
class State:
    messages: list = field(default_factory=list)
```

### 다중 스키마 (Input/Output 분리)

내부 State와 별도로 입력/출력 스키마를 정의하여 그래프 인터페이스 제한 가능.

---

## 3. Edges 및 라우팅

### 일반 엣지

```python
builder.add_edge("node_a", "node_b")  # A 완료 후 항상 B 실행
```

### 조건부 엣지

```python
def should_continue(state) -> str:
    last_msg = state["messages"][-1]
    if last_msg.tool_calls:
        return "tools"
    return "end"

builder.add_conditional_edges(
    "agent",
    should_continue,
    {"tools": "tools", "end": END}
)
```

### 조건부 진입점

```python
builder.add_conditional_edges(
    START,
    classify_input,
    {"question": "qa_agent", "task": "task_agent"}
)
```

---

## 4. Human-in-the-Loop

### 동적 인터럽트 (프로덕션 권장)

```python
from langgraph.types import interrupt, Command

def approval_node(state):
    # 실행 중단, 외부 입력 대기
    decision = interrupt({
        "question": "이 작업을 승인하시겠습니까?",
        "details": state["action_details"]
    })
    if decision["approved"]:
        return {"status": "approved"}
    return Command(goto="cancel")
```

### 실행 흐름

```python
config = {"configurable": {"thread_id": "thread-1"}}

# 1. 실행 → 인터럽트 발생 → 중단
result = graph.invoke({"input": "data"}, config=config)

# 2. 사용자 검토 후 재개
graph.invoke(Command(resume={"approved": True}), config=config)
```

### 정적 인터럽트 (디버깅용)

```python
graph = builder.compile(
    interrupt_before=["critical_node"],
    interrupt_after=["review_node"],
    checkpointer=checkpointer
)
```

### 검증 루프 패턴

`interrupt()`를 루프 안에서 사용하여 유효한 입력을 받을 때까지 반복:

```python
def get_age_node(state):
    prompt = "나이를 입력하세요:"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}'은 유효하지 않습니다. 양의 정수를 입력하세요."
    return {"age": answer}

# 사용: Command(resume="thirty") → 재요청 → Command(resume=30) → 통과
```

### 주요 패턴

| 패턴 | 설명 |
|------|------|
| 승인 워크플로우 | 중요 작업 전 승인 요청 |
| 검토 및 편집 | AI 결과물을 사람이 검토/수정 |
| 도구 호출 승인 | `@tool` 내부에서 interrupt |
| 입력 검증 | while 루프 + interrupt로 유효 입력까지 반복 |
| 다중 인터럽트 | 병렬 브랜치 동시 인터럽트 → `resume_map` |

### 중요 규칙

- `interrupt()`를 **try/except 블록 안에 넣지 말 것** (예외 기반 메커니즘)
- interrupt 전의 코드는 **재개 시 재실행됨** → 부수효과는 멱등(idempotent)해야 함
- **JSON 직렬화 가능한 값**만 interrupt에 전달
- interrupt 호출 순서 일관 유지
- `Command(resume=...)`만 invoke 입력으로 사용. `Command(update=...)`를 입력으로 넣으면 그래프가 멈춤

### 멱등성 가이드

interrupt 전 코드는 재개 시 **매번 재실행**됨. 부수효과 배치에 주의:

```python
# GOOD: upsert는 멱등 — interrupt 전 안전
def node(state):
    db.upsert_user(user_id=state["user_id"], status="pending")
    approved = interrupt("승인하시겠습니까?")
    return {"approved": approved}

# GOOD: 부수효과를 interrupt 후에 배치 — 한 번만 실행
def node(state):
    approved = interrupt("승인하시겠습니까?")
    if approved:
        db.create_audit_log(user_id=state["user_id"])  # 재개 후 1회만
    return {"approved": approved}

# BAD: insert는 재개마다 중복 생성!
def node(state):
    db.create_audit_log(...)  # 재개될 때마다 새 레코드!
    approved = interrupt("승인하시겠습니까?")
    return {"approved": approved}
```

> **서브그래프 주의:** 서브그래프에 interrupt가 있으면 재개 시 **부모 노드와 서브그래프 노드 모두** 처음부터 재실행됨.

---

## 5. Functional API

그래프 구조 없이 일반 Python으로 LangGraph 기능(체크포인팅, HITL 등) 활용.

### @entrypoint — 워크플로우 진입점

```python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver

@entrypoint(checkpointer=InMemorySaver())
def my_workflow(topic: str) -> dict:
    essay = write_essay(topic).result()
    is_approved = interrupt({"essay": essay})
    return {"essay": essay, "approved": is_approved}
```

### @task — 작업 단위

```python
@task
def write_essay(topic: str) -> str:
    return llm.invoke(f"Write about {topic}")

@task
def review_essay(essay: str) -> str:
    return llm.invoke(f"Review: {essay}")
```

### Graph API vs Functional API

| 측면 | Graph API | Functional API |
|------|-----------|----------------|
| 제어 흐름 | 명시적 DAG | 일반 Python (if/for/while) |
| 상태 관리 | State + Reducer | 함수 범위, 명시적 관리 불필요 |
| 시각화 | 그래프 시각화 지원 | 미지원 |
| 보일러플레이트 | 더 많음 | 더 적음 |
| 체크포인팅 | 슈퍼스텝 후 새 체크포인트 | 태스크 결과 기존 체크포인트에 저장 |

### 제약사항

- 입출력은 JSON 직렬화 가능해야 함
- 랜덤성은 반드시 @task 내부에 캡슐화
- 부수효과도 @task로 감싸기

### Injectable 파라미터

- `previous` — 이전 체크포인트 상태 (단기 메모리)
- `store` — BaseStore 인스턴스 (장기 메모리)
- `writer` — StreamWriter
- `config` — RunnableConfig

---

## 6. 멀티에이전트 패턴

### Supervisor 패턴

감독 에이전트가 작업을 분배하고 결과를 조율:

```
[Supervisor Agent]
    ├→ [Research Agent]
    ├→ [Coding Agent]
    └→ [Review Agent]
```

- 각 에이전트는 자체 스크래치패드 유지
- 감독 에이전트가 능력 기반으로 작업 위임
- 가장 일반적인 멀티에이전트 패턴

### 계층적(Hierarchical) 패턴

서브그래프를 활용한 중첩 구조:

```
[Manager]
    ├→ [Team Lead A]
    │    ├→ [Worker A1]
    │    └→ [Worker A2]
    └→ [Team Lead B]
         └→ [Worker B1]
```

- 각 레벨이 독립적 상태 관리
- 대규모 조직적 워크플로우에 적합

### Peer-to-Peer 패턴

- 에이전트 간 직접 데이터 공유
- 공유 상태를 통한 자유로운 정보 흐름
- 복잡한 협업 워크플로우에 적합

---

## 7. Subgraphs

### 공유 상태 서브그래프

에이전트 간 자유로운 정보 흐름:

```python
# 서브그래프 정의
sub_builder = StateGraph(SubState)
sub_builder.add_node("sub_agent", sub_fn)
sub_graph = sub_builder.compile()

# 부모 그래프에 추가
builder.add_node("sub", sub_graph)
```

### 격리 상태 서브그래프

명시적 변환 함수로 데이터 교환:

```python
def transform_input(parent_state):
    return {"sub_messages": parent_state["messages"][-3:]}

builder.add_node("sub", sub_graph, input=transform_input)
```

### 부모-자식 통신

```python
# 서브그래프에서 부모로 라우팅
def sub_node(state):
    return Command(goto="parent_node", graph=Command.PARENT)
```

### 서브그래프 체크포인터 스코핑

| `checkpointer=` | interrupt 지원 | 멀티턴 메모리 | 동일 서브그래프 병렬 실행 |
|-----------------|:-------------:|:------------:|:---------------------:|
| `False` | X | X | O |
| `None` (기본) | O | X | O |
| `True` | O | O | **X** (네임스페이스 충돌) |

```python
# interrupt 불필요 → 체크포인트 오버헤드 제거
sub = sub_builder.compile(checkpointer=False)

# interrupt 필요, 멀티턴 불필요 (기본)
sub = sub_builder.compile()

# 호출 간 상태 유지 필요 (대화형 서브에이전트)
sub = sub_builder.compile(checkpointer=True)
```

### 서브그래프 스트리밍

```python
# subgraphs=True로 서브그래프 출력도 스트리밍
for chunk in graph.stream(input, subgraphs=True):
    print(chunk)
```

---

## 8. Map-Reduce

Send API로 런타임에 동적 병렬 태스크 생성:

```python
from langgraph.types import Send

def map_step(state):
    """항목 수에 따라 동적으로 워커 생성"""
    return [Send("process_item", {"item": item}) for item in state["items"]]

def reduce_step(state):
    """모든 워커 결과를 병합"""
    return {"summary": aggregate(state["results"])}

builder.add_conditional_edges("splitter", map_step)
builder.add_edge("process_item", "reducer")
```

**특징:**
- 태스크 수와 구성이 런타임에 결정
- 독립 작업의 동시 실행으로 처리 시간 단축
- Reducer 함수로 결과 병합

---

## 9. Tool Calling in Graphs

### ToolNode

```python
from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode

@tool
def search(query: str) -> str:
    """Search the web for current information.

    Use this when you need recent data or facts.

    Args:
        query: The search query (2-10 words recommended)
    """
    return search_engine.search(query)

tools = [search]
llm_with_tools = llm.bind_tools(tools)

# handle_tool_errors=True: 도구 에러를 ToolMessage로 반환 → LLM이 복구 시도
tool_node = ToolNode(tools, handle_tool_errors=True)

builder.add_node("agent", lambda s: {"messages": [llm_with_tools.invoke(s["messages"])]})
builder.add_node("tools", tool_node)
```

> **도구 설명 품질이 에이전트 성능에 직결됨.** docstring에 용도, 사용 시점, Args 설명을 명확히 작성할 것.

### Prebuilt ReAct Agent

```python
from langgraph.prebuilt import create_react_agent

graph = create_react_agent(model=llm, tools=tools, checkpointer=checkpointer)
```

**참고:** `langgraph.prebuilt`의 `create_react_agent`는 deprecated. `langchain.agents.create_agent`가 새 표준이나, 간단한 프로토타이핑에는 여전히 사용 가능.

---

## 참고

- [LangGraph Graph API](https://docs.langchain.com/oss/python/langgraph/graph-api)
- [LangGraph Interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts)
- [LangGraph Functional API](https://docs.langchain.com/oss/python/langgraph/functional-api)
- [LangGraph 1.0 GA](https://changelog.langchain.com/announcements/langgraph-1-0-is-now-generally-available)
