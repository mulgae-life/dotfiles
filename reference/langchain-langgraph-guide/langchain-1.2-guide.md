# LangChain 1.2.x 종합 가이드

> 버전: LangChain 1.2.10 / langchain-core 1.2.17 (2026-03 기준)
> 라이선스: MIT / Python >=3.10

---

## 1. 아키텍처 및 패키지 구조

### 1.1 패키지 구조

```
langchain-core         # 핵심 추상화 + LCEL (Runnable 인터페이스)
langchain              # 에이전트(create_agent), 미들웨어, 고수준 API
langchain-classic      # [1.0 신규] 레거시 체인/에이전트 이전 (하위 호환성)
langchain-openai       # OpenAI 전용 통합
langchain-anthropic    # Anthropic 전용 통합
langchain-google-genai # Google 전용 통합
langchain-aws          # AWS 전용 통합
langchain-community    # 서드파티 범용 통합
langgraph              # 그래프 기반 런타임/오케스트레이션
```

### 1.2 주요 릴리스

| 버전 | 릴리스일 | 핵심 변경 |
|------|---------|----------|
| **1.0 GA** | 2025-10 | `create_agent`, `langchain-classic`, 미들웨어 시스템, Python 3.9 중단 |
| **1.1** | 2025-12 | Model Profiles, ModelRetryMiddleware, SummarizationMiddleware, SystemMessage 지원 |
| **1.2.x** | 2025-12~ | 안정성 개선, 버그 수정 |

**안정성 약속**: "2.0까지 breaking changes 없음"

---

## 2. 모델 초기화

### init_chat_model (프로바이더 독립적, 권장)

```python
from langchain.chat_models import init_chat_model

# 단축 문법 (provider:model)
model = init_chat_model("openai:gpt-5", temperature=0)
model = init_chat_model("anthropic:claude-sonnet-4-5", temperature=0)
model = init_chat_model("google_vertexai:gemini-2.5-flash", temperature=0)

# 명시적 지정
model = init_chat_model("gpt-5", model_provider="openai", temperature=0.1)
```

### 직접 클래스 초기화

```python
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5", temperature=0, max_tokens=1000, timeout=30)

from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-5", max_tokens=1024, temperature=0)
```

> **주의**: `from langchain.chat_models import ChatOpenAI`는 deprecated. 프로바이더 패키지에서 임포트.

### Model Profiles (1.1+)

```python
model.profile  # structured_output, function_calling, json_modes 등 자동 감지
# profiles은 models.dev에서 소싱
```

---

## 3. create_agent (1.0+ 표준)

### 기본 사용

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
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "한국 GDP는?"}]},
    config={"configurable": {"thread_id": "session-1"}}
)
```

### 미들웨어 통합

```python
from langchain.middleware import ModelRetryMiddleware

agent = create_agent(
    model, tools,
    middleware=[ModelRetryMiddleware(max_retries=3, backoff_factor=2.0)],
    checkpointer=PostgresSaver(conn_string="..."),
)
```

### 구조화된 출력

```python
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class ResearchResult(BaseModel):
    summary: str
    sources: list[str]

# ToolStrategy (범용) — 모든 tool calling 모델
agent = create_agent(model, tools, response_format=ToolStrategy(ResearchResult))

# ProviderStrategy (고성능) — 네이티브 구조화 출력 모델
agent = create_agent(model, tools, response_format=ProviderStrategy(ResearchResult))
```

---

## 4. LCEL (LangChain Expression Language)

### 기본 체인

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

### Runnable 타입

| Runnable | 용도 |
|----------|------|
| `RunnableLambda` | 임의 함수 래핑 |
| `RunnableParallel` | 병렬 실행 |
| `RunnableBranch` | 조건부 분기 |
| `RunnablePassthrough` | 입력 패스스루 |

### 통합 인터페이스

- `invoke()` / `ainvoke()` — 단일 실행
- `batch()` / `abatch()` — 배치
- `stream()` / `astream()` — 스트리밍

---

## 5. 프롬프트 템플릿

```python
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

# 기본
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{question}"),
])

# 대화 이력 포함
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    MessagesPlaceholder("history"),
    ("human", "{question}"),
])
```

---

## 6. 도구 정의

### @tool 데코레이터

```python
@tool
def search(query: str) -> str:
    """Search the web for information."""
    return search_engine.search(query)
```

### content_and_artifact (RAG 도구)

```python
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve documents."""
    docs = vector_store.similarity_search(query, k=3)
    return "\n".join(d.page_content for d in docs), docs
```

### 미들웨어로 도구 에러 처리

```python
@wrap_tool_call
def handle_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(content=f"Error: {e}", tool_call_id=request.tool_call["id"])
```

---

## 7. RAG 파이프라인

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

# 1. 로드 + 청킹
docs = WebBaseLoader("https://example.com").load()
splits = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200).split_documents(docs)

# 2. 벡터 스토어
vector_store = InMemoryVectorStore.from_documents(splits, OpenAIEmbeddings())

# 3. 에이전트에 통합
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve documents."""
    docs = vector_store.similarity_search(query, k=3)
    return "\n".join(d.page_content for d in docs), docs

agent = create_agent(model, tools=[retrieve], system_prompt="Answer using context.")
```

### 고급 검색 기법

- **Semantic Chunking**: faithfulness 0.79~0.82 (고정 분할 0.47~0.51)
- **Multi-Vector Retriever**: 문서당 여러 벡터
- **MMR**: 관련성 + 다양성 균형

---

## 8. 미들웨어 시스템

### 내장 미들웨어 (1.1+)

| 미들웨어 | 기능 |
|---------|------|
| `ModelRetryMiddleware` | 재시도 + 지수 백오프 |
| `ModelFallbackMiddleware` | 백업 모델 전환 |
| `SummarizationMiddleware` | 긴 대화 자동 요약 |
| `ContentModerationMiddleware` | 모더레이션 API |

### 동적 모델 선택

```python
@wrap_model_call
def dynamic_model(request, handler):
    if len(request.state["messages"]) > 10:
        return handler(request.override(model=advanced_model))
    return handler(request)
```

---

## 9. 스트리밍

```python
# 토큰 스트리밍
for token, metadata in agent.stream(input, stream_mode="messages"):
    print(token.content, end="", flush=True)

# 다중 모드
for mode, chunk in agent.stream(input, stream_mode=["updates", "custom"]):
    if mode == "custom":
        handle_progress(chunk)
```

---

## 10. 메모리 관리

**레거시 (사용 금지)**:
- `ConversationBufferMemory`, `ConversationSummaryMemory` 등

**현재 권장**: LangGraph 체크포인터

```python
from langgraph.checkpoint.postgres import PostgresSaver

checkpointer = PostgresSaver(conn_string="...")
agent = create_agent(model, tools, checkpointer=checkpointer)
config = {"configurable": {"thread_id": "user-123"}}
```

---

## 11. Deprecated 기능 매핑

| Deprecated | 대체 |
|-----------|------|
| `LLMChain` | LCEL (`prompt \| model \| parser`) |
| `ConversationalRetrievalChain` | `create_agent` + retriever tool |
| `ConversationBufferMemory` | LangGraph 체크포인터 |
| `AgentExecutor` | `create_agent` |
| `create_react_agent` (prebuilt) | `create_agent` (langchain.agents) |
| `from langchain.chat_models` | `from langchain_openai` 등 |

---

## 12. 보안

- **CVE-2025-68664**: `dumps()`/`dumpd()`에 사용자 입력 dict 직접 전달 금지 → 최신 버전 업데이트
- API 키는 환경변수로 관리
- 도구 입력은 Pydantic 스키마로 검증

---

## 참고 출처

- [LangChain 1.0 GA](https://changelog.langchain.com/announcements/langchain-1-0-now-generally-available)
- [LangChain 1.1](https://changelog.langchain.com/announcements/langchain-1-1)
- [langchain PyPI](https://pypi.org/project/langchain/) — v1.2.10
- [LangChain Agents 문서](https://docs.langchain.com/oss/python/langchain/agents)
- [LangChain Streaming 문서](https://docs.langchain.com/oss/python/langchain/streaming)
- [LangChain RAG 문서](https://docs.langchain.com/oss/python/langchain/rag)
- [JetBrains LangChain Tutorial 2026](https://blog.jetbrains.com/pycharm/2026/02/langchain-tutorial-2026/)
