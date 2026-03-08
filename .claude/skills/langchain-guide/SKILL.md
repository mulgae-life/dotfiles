---
name: langchain-guide
description: LangChain 1.x 및 LangGraph v1.0 기반 에이전트, 체인, 워크플로우 구현 가이드. LangChain 에이전트 생성, LCEL 체인, RAG 파이프라인, LangGraph 그래프 설계, 멀티에이전트, Human-in-the-loop, 상태 관리, 스트리밍 구현 시 사용. "LangChain 에이전트 만들어줘", "LangGraph 워크플로우 구현해줘", "RAG 파이프라인 만들어줘", "멀티에이전트 시스템 설계해줘", "LangGraph 상태 관리", "LCEL 체인 작성" 등의 요청에 트리거. LangChain이나 LangGraph 관련 코드를 작성하거나 리뷰할 때, 또는 에이전트 프레임워크를 선택하거나 비교할 때 이 스킬을 반드시 참조하세요.
---

# LangChain & LangGraph 가이드

> LangChain 1.2.x / LangGraph v1.0 GA 기준 (2026-03)

## TL;DR — 핵심 결정 트리

```
에이전트/체인이 필요한가?
├── 단순 체인 (prompt → model → parser) → LCEL 파이프라인
├── 도구 호출 에이전트 → create_agent()
├── 복잡한 상태 관리/분기/루프 → LangGraph StateGraph
├── 그래프 없이 Python 흐름 → LangGraph Functional API (@entrypoint/@task)
└── 멀티에이전트 → LangGraph (Supervisor/계층적/P2P)
```

## 1. 패키지 구조

```
langchain-core          # 핵심 추상화 + LCEL (Runnable)
langchain               # 에이전트(create_agent), 미들웨어, 고수준 API
langchain-classic       # 레거시 코드 (하위 호환성)
langchain-openai        # OpenAI 통합
langchain-anthropic     # Anthropic 통합
langchain-community     # 서드파티 통합
langgraph               # 그래프 기반 런타임/오케스트레이션
langgraph-checkpoint-*  # 체크포인터 (postgres, sqlite 등)
```

**설치 예시:**
```bash
pip install langchain langchain-openai langgraph
# 프로덕션: + langgraph-checkpoint-postgres
```

## 2. LangChain 핵심 패턴

### 2.1 모델 초기화

```python
# 방법 1: init_chat_model (권장 - 프로바이더 독립적)
from langchain.chat_models import init_chat_model
model = init_chat_model("openai:gpt-5", temperature=0)

# 방법 2: 프로바이더 패키지 직접 (상세 설정)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5", temperature=0, max_tokens=1000)

# 방법 3: create_agent에서 문자열로 (간편)
agent = create_agent("openai:gpt-5", tools=tools)
```

### 2.2 에이전트 생성 (create_agent)

`create_agent`는 LangChain 1.0+의 표준 에이전트 생성 API. 내부적으로 LangGraph 런타임 사용.

```python
from langchain.agents import create_agent
from langchain.tools import tool
from langchain.middleware import ModelRetryMiddleware
from langgraph.checkpoint.postgres import PostgresSaver

@tool
def search(query: str) -> str:
    """Search the web for information."""
    return search_engine.search(query)

agent = create_agent(
    "openai:gpt-5",
    tools=[search],
    system_prompt="You are a research assistant.",
    middleware=[ModelRetryMiddleware(max_retries=3)],
    checkpointer=PostgresSaver(conn_string="..."),
)

# 실행
result = agent.invoke(
    {"messages": [{"role": "user", "content": "한국 GDP는?"}]},
    config={"configurable": {"thread_id": "session-1"}}
)
```

### 2.3 LCEL 체인

LCEL은 단순 파이프라인(RAG, 변환 등)에 여전히 적합.

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{question}"),
])

chain = prompt | model | StrOutputParser()
result = chain.invoke({"question": "What is LCEL?"})
```

### 2.4 구조화된 출력

```python
from pydantic import BaseModel
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class Answer(BaseModel):
    summary: str
    sources: list[str]
    confidence: float

# 에이전트에서
agent = create_agent(model, tools, response_format=ToolStrategy(Answer))

# LCEL 체인에서
structured_llm = model.with_structured_output(Answer)
```

### 2.5 도구 정의

```python
from langchain.tools import tool

@tool
def calculate(expression: str) -> str:
    """Perform mathematical calculations."""
    return str(eval(expression))

# RAG 도구 (content_and_artifact)
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search relevant documents."""
    docs = vector_store.similarity_search(query, k=3)
    serialized = "\n\n".join(d.page_content for d in docs)
    return serialized, docs
```

### 2.6 미들웨어

LangChain 1.0+의 cross-cutting concern 처리 패턴.

```python
from langchain.middleware import ModelRetryMiddleware

# 모델 호출 미들웨어
@wrap_model_call
def log_calls(request, handler):
    logger.info(f"Model call: {request}")
    return handler(request)

# 도구 호출 미들웨어
@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(content=f"Error: {e}", tool_call_id=request.tool_call["id"])

agent = create_agent(model, tools, middleware=[ModelRetryMiddleware(max_retries=3)])
```

## 3. LangGraph 핵심 패턴

복잡한 상태 관리, 분기/루프, Human-in-the-loop이 필요할 때 사용.

### 3.1 StateGraph 기본

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END, add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]  # Reducer: 메시지 추가
    context: str                              # Reducer 없음: 덮어쓰기

builder = StateGraph(State)
builder.add_node("agent", agent_fn)
builder.add_node("tools", tool_fn)
builder.add_edge(START, "agent")
builder.add_conditional_edges("agent", should_use_tool, {"yes": "tools", "no": END})
builder.add_edge("tools", "agent")

graph = builder.compile(checkpointer=checkpointer)
```

### 3.2 Human-in-the-Loop

```python
from langgraph.types import interrupt, Command

def approval_node(state):
    decision = interrupt({"question": "Approve?", "details": state["action"]})
    if decision["approved"]:
        return {"status": "approved"}
    return Command(goto="cancel")

# 실행 → 인터럽트 → 재개
result = graph.invoke(input, config)
graph.invoke(Command(resume={"approved": True}), config)
```

### 3.3 Functional API

그래프 구조 없이 일반 Python으로 워크플로우 정의.

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

## 4. 선택 가이드

| 상황 | 권장 |
|------|------|
| 단순 체인 (prompt→model→parse) | LCEL |
| 도구 호출 에이전트 | `create_agent()` |
| 복잡한 분기/루프/상태 관리 | LangGraph StateGraph |
| Python 흐름 선호, 그래프 불필요 | Functional API |
| 멀티에이전트 오케스트레이션 | LangGraph (Supervisor 패턴) |
| 대화 지속성 필요 | 체크포인터 (PostgresSaver) |
| 빠른 프로토타이핑 | `create_agent()` |

## 5. Deprecated 기능 (사용 금지)

| Deprecated | 대체 |
|-----------|------|
| `LLMChain` | LCEL 파이프라인 |
| `ConversationalRetrievalChain` | RAG 에이전트 (`create_agent` + retriever tool) |
| `ConversationBufferMemory` 등 | LangGraph 체크포인터 |
| `AgentExecutor` | `create_agent` |
| `from langchain.chat_models import ChatOpenAI` | `from langchain_openai import ChatOpenAI` |

## 6. 상세 가이드

상황별로 아래 참조 파일을 읽으세요:

| 파일 | 내용 | 언제 읽나 |
|------|------|----------|
| [langchain-core.md](references/langchain-core.md) | LCEL, Runnables, 모델 초기화, 프롬프트, 구조화 출력, RAG, 스트리밍 상세 | LangChain 체인/에이전트 구현 시 |
| [langgraph-patterns.md](references/langgraph-patterns.md) | StateGraph, State/Reducer, HITL, 멀티에이전트, Subgraph, Functional API, Map-Reduce | LangGraph 워크플로우 설계 시 |
| [production-patterns.md](references/production-patterns.md) | 체크포인팅, 스트리밍, 에러 핸들링, 성능 최적화, LangSmith, 배포 옵션 | 프로덕션 배포 준비 시 |
| [migration-antipatterns.md](references/migration-antipatterns.md) | 레거시→최신 마이그레이션, 안티패턴, 프레임워크 비교, 보안 | 기존 코드 마이그레이션/리뷰 시 |

## 7. 참고 자료

### 공식 문서
- [LangChain Agents](https://docs.langchain.com/oss/python/langchain/agents)
- [LangGraph Graph API](https://docs.langchain.com/oss/python/langgraph/graph-api)
- [LangGraph Persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangGraph Functional API](https://docs.langchain.com/oss/python/langgraph/functional-api)

### 릴리스 노트
- [LangChain 1.0 GA](https://changelog.langchain.com/announcements/langchain-1-0-now-generally-available)
- [LangChain 1.1](https://changelog.langchain.com/announcements/langchain-1-1)
- [LangGraph 1.0 GA](https://changelog.langchain.com/announcements/langgraph-1-0-is-now-generally-available)
