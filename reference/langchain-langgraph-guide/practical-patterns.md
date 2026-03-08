# LangChain + LangGraph 실전 코드 패턴

> LangChain 1.2.x / LangGraph v1.0 / Python 3.10+ 기준

---

## 1. 모델 초기화 패턴

### init_chat_model (통합 초기화)

```python
from langchain.chat_models import init_chat_model

gpt = init_chat_model("openai:gpt-5", temperature=0)
claude = init_chat_model("anthropic:claude-sonnet-4-5", temperature=0)
gemini = init_chat_model("google_vertexai:gemini-2.5-flash", temperature=0)
```

### 직접 클래스 초기화

```python
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic

model = ChatOpenAI(model="gpt-5", temperature=0, max_tokens=1000, timeout=30)
model = ChatAnthropic(model="claude-sonnet-4-5", max_tokens=1024, temperature=0)
```

---

## 2. LCEL 체인 패턴

### 기본 체인

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_template("Describe {topic} in 3 sentences.")
chain = prompt | model | StrOutputParser()
result = chain.invoke({"topic": "machine learning"})
```

### 병렬 실행 (RunnableParallel)

```python
from langchain_core.runnables import RunnableParallel, RunnablePassthrough

retrieval = RunnableParallel(
    context_a=retriever_a,
    context_b=retriever_b,
    question=RunnablePassthrough()
)
chain = retrieval | prompt | model | StrOutputParser()
```

### 조건부 분기 (RunnableBranch)

```python
from langchain_core.runnables import RunnableBranch

branch = RunnableBranch(
    (lambda x: "code" in x["question"], code_chain),
    (lambda x: "math" in x["question"], math_chain),
    default_chain
)
```

### 커스텀 함수 체인 (RunnableLambda)

```python
from langchain_core.runnables import RunnableLambda

def format_docs(docs):
    return "\n\n".join(d.page_content for d in docs)

chain = retriever | RunnableLambda(format_docs) | prompt | model
```

---

## 3. 에이전트 패턴

### create_agent (표준)

```python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Search the web."""
    return search_engine.search(query)

agent = create_agent(
    "openai:gpt-5",
    tools=[search],
    system_prompt="You are a research assistant.",
    checkpointer=PostgresSaver(conn_string="..."),
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "한국 GDP는?"}]},
    config={"configurable": {"thread_id": "s1"}}
)
```

### 구조화된 출력 에이전트

```python
from langchain.agents.structured_output import ToolStrategy

class Answer(BaseModel):
    summary: str
    sources: list[str]
    confidence: float

agent = create_agent(model, tools, response_format=ToolStrategy(Answer))
```

---

## 4. RAG 패턴

### 기본 RAG 에이전트

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_openai import OpenAIEmbeddings

# 준비
docs = WebBaseLoader("https://example.com").load()
splits = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200).split_documents(docs)
vector_store = InMemoryVectorStore.from_documents(splits, OpenAIEmbeddings())

# 도구
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve relevant documents."""
    docs = vector_store.similarity_search(query, k=3)
    return "\n\n".join(d.page_content for d in docs), docs

# 에이전트
agent = create_agent(model, tools=[retrieve], system_prompt="Answer using retrieved context.")
```

### Agentic RAG (LangGraph)

```python
# 자기 교정 RAG: 검색 → 관련성 평가 → 재작성 루프
class RagState(TypedDict):
    messages: Annotated[list, add_messages]
    documents: list
    query: str

def grade_documents(state):
    """관련성 평가 → 관련 없으면 질문 재작성"""
    relevance = llm.with_structured_output(GradeDocuments).invoke(...)
    if relevance.relevant:
        return Command(goto="generate")
    return Command(goto="rewrite_query")

builder = StateGraph(RagState)
builder.add_node("retrieve", retrieve_fn)
builder.add_node("grade", grade_documents)
builder.add_node("generate", generate_fn)
builder.add_node("rewrite_query", rewrite_fn)
```

---

## 5. LangGraph 워크플로우 패턴

### ReAct 에이전트

```python
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.prebuilt import ToolNode

def agent(state):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state):
    if state["messages"][-1].tool_calls:
        return "tools"
    return "end"

builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", ToolNode(tools))
builder.add_edge(START, "agent")
builder.add_conditional_edges("agent", should_continue, {"tools": "tools", "end": END})
builder.add_edge("tools", "agent")
graph = builder.compile(checkpointer=InMemorySaver())
```

### Human-in-the-Loop 워크플로우

```python
from langgraph.types import interrupt, Command

def plan(state):
    plan = llm.invoke("Create a plan for: " + state["task"])
    return {"plan": plan}

def approve(state):
    decision = interrupt({
        "plan": state["plan"],
        "question": "Approve this plan?"
    })
    if decision["approved"]:
        return Command(goto="execute")
    return Command(goto="plan")  # 재계획

def execute(state):
    return {"result": execute_plan(state["plan"])}

builder = StateGraph(WorkflowState)
builder.add_node("plan", plan)
builder.add_node("approve", approve)
builder.add_node("execute", execute)
builder.add_edge(START, "plan")
builder.add_edge("plan", "approve")
builder.add_edge("execute", END)
```

### Map-Reduce

```python
from langgraph.types import Send

def fan_out(state):
    return [Send("analyze", {"doc": doc}) for doc in state["documents"]]

def analyze(state):
    return {"analysis": llm.invoke(f"Analyze: {state['doc']}")}

def synthesize(state):
    all_analyses = state["analyses"]
    return {"summary": llm.invoke(f"Synthesize: {all_analyses}")}

builder.add_conditional_edges("splitter", fan_out)
builder.add_edge("analyze", "synthesize")
```

---

## 6. 스트리밍 패턴

### 토큰 스트리밍

```python
for token, metadata in agent.stream(input, stream_mode="messages"):
    print(token.content, end="", flush=True)
```

### 비동기 스트리밍

```python
async for chunk in agent.astream(input, stream_mode="messages"):
    token, metadata = chunk
    print(token.content, end="", flush=True)
```

### 커스텀 진행 상황

```python
from langgraph.config import get_stream_writer

def processing_node(state):
    writer = get_stream_writer()
    for i, item in enumerate(state["items"]):
        writer({"progress": f"{i+1}/{len(state['items'])}"})
        process(item)
    return {"status": "done"}
```

---

## 7. 미들웨어 패턴

### 에러 전략 계층 (4-tier)

| 계층 | 에러 유형 | 처리 주체 | 전략 |
|------|----------|----------|------|
| 1. RetryPolicy | 일시적 (네트워크, 레이트 리밋) | 시스템 자동 | `add_node(..., retry_policy=...)` |
| 2. ToolNode 에러 | LLM 복구 가능 | LLM | `ToolNode(tools, handle_tool_errors=True)` |
| 3. interrupt | 사용자 개입 필요 | 사람 | `interrupt({"error": ...})` |
| 4. Bubble up | 예상 외 | 개발자 | `raise` |

### RetryPolicy (노드 레벨 재시도)

```python
from langgraph.types import RetryPolicy

builder.add_node(
    "api_call", api_call_fn,
    retry_policy=RetryPolicy(max_attempts=3, initial_interval=1.0, backoff_factor=2.0)
)
```

### 재시도 + 폴백 (모델 레벨)

```python
from langchain.middleware import ModelRetryMiddleware, ModelFallbackMiddleware

agent = create_agent(
    "openai:gpt-5",
    tools=tools,
    middleware=[
        ModelRetryMiddleware(max_retries=3, backoff_factor=2.0),
        # ModelFallbackMiddleware로 백업 모델 설정 가능
    ]
)
```

### 도구 에러 처리

```python
@wrap_tool_call
def safe_tools(request, handler):
    try:
        return handler(request)
    except TimeoutError:
        return ToolMessage(content="Timed out", tool_call_id=request.tool_call["id"])
    except Exception as e:
        logger.error(f"Tool error: {e}", exc_info=True)
        return ToolMessage(content=f"Error: {e}", tool_call_id=request.tool_call["id"])
```

---

## 8. 프로덕션 체크리스트

- [ ] 체크포인터: `PostgresSaver` (InMemorySaver 아님)
- [ ] recursion_limit: 25~50 설정
- [ ] RetryPolicy: 외부 API 호출 노드에 적용
- [ ] LangSmith 트레이싱 활성화
- [ ] 도구 에러 미들웨어 적용
- [ ] 재시도 미들웨어 (ModelRetryMiddleware)
- [ ] 메시지 트리밍 (`trim_messages()`)
- [ ] 비동기 패턴 (고트래픽 시)
- [ ] 환경변수로 시크릿 관리
- [ ] 모델 스냅샷 고정 (출력 드리프트 방지)
- [ ] 모니터링 + 알림 설정

---

## 참고

- [LangChain Agents](https://docs.langchain.com/oss/python/langchain/agents)
- [LangGraph Agentic RAG](https://docs.langchain.com/oss/python/langgraph/agentic-rag)
- [LangChain Streaming](https://docs.langchain.com/oss/python/langchain/streaming)
- [LangGraph Best Practices](https://www.swarnendu.de/blog/langgraph-best-practices/)
