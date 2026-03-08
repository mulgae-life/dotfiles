# LangChain Core 상세 가이드

> LangChain 1.2.x / langchain-core 1.2.17 기준

## 목차

- [1. 패키지 구조](#1-패키지-구조)
- [2. 모델 초기화](#2-모델-초기화)
- [3. LCEL (LangChain Expression Language)](#3-lcel-langchain-expression-language)
- [4. 프롬프트 템플릿](#4-프롬프트-템플릿)
- [5. 구조화된 출력](#5-구조화된-출력)
- [6. 도구 정의 및 호출](#6-도구-정의-및-호출)
- [7. RAG 파이프라인](#7-rag-파이프라인)
- [8. 스트리밍](#8-스트리밍)
- [9. 비동기 패턴](#9-비동기-패턴)
- [10. 미들웨어](#10-미들웨어)

---

## 1. 패키지 구조

```
langchain-core         # 핵심 추상화 + LCEL (Runnable 인터페이스)
langchain              # 에이전트(create_agent), 미들웨어, 고수준 API
langchain-classic      # 레거시 체인/에이전트 (하위 호환성)
langchain-openai       # OpenAI 전용 통합
langchain-anthropic    # Anthropic 전용 통합
langchain-google-genai # Google 전용 통합
langchain-community    # 서드파티 통합 (범용)
```

**임포트 규칙:**
- `from langchain_openai import ChatOpenAI` (O)
- `from langchain.chat_models import ChatOpenAI` (X - deprecated)
- 프로바이더별 패키지 직접 설치 필수: `pip install langchain-openai`

---

## 2. 모델 초기화

### init_chat_model (프로바이더 독립적, 권장)

```python
from langchain.chat_models import init_chat_model

# 단축 문법 (provider:model)
model = init_chat_model("openai:gpt-5", temperature=0)
model = init_chat_model("anthropic:claude-sonnet-4-5", temperature=0)

# 명시적 provider 지정
model = init_chat_model("gpt-5", model_provider="openai", temperature=0)
```

### 직접 클래스 초기화 (상세 설정)

```python
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5", temperature=0, max_tokens=1000, timeout=30)

from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-5", max_tokens=1024, temperature=0)
```

### Model Profiles (LangChain 1.1+)

```python
model.profile  # structured_output, function_calling, json_modes 등 자동 감지
# profiles은 models.dev에서 소싱
```

### 동적 모델 선택 (미들웨어)

```python
@wrap_model_call
def dynamic_model_selection(request, handler):
    if len(request.state["messages"]) > 10:
        model = advanced_model
    else:
        model = basic_model
    return handler(request.override(model=model))
```

---

## 3. LCEL (LangChain Expression Language)

LCEL은 `langchain-core`의 핵심. 파이프 연산자(`|`)로 체인을 선언적으로 구성.

### 기본 체인

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_template("Describe {topic} in 3 sentences.")
chain = prompt | model | StrOutputParser()
result = chain.invoke({"topic": "quantum computing"})
```

### Runnable 타입

| Runnable | 용도 |
|----------|------|
| `RunnableLambda` | 임의 함수를 Runnable로 래핑 |
| `RunnableParallel` | 병렬 실행 (독립 작업 동시 수행) |
| `RunnableBranch` | 조건부 분기 |
| `RunnablePassthrough` | 입력을 그대로 전달 |
| `RunnableSequence` | 순차 실행 (파이프 연산자 내부 구현) |

### RunnableParallel — 병렬 실행

```python
from langchain_core.runnables import RunnableParallel, RunnablePassthrough

retrieval = RunnableParallel(
    context_a=retriever_a,
    context_b=retriever_b,
    question=RunnablePassthrough()
)

chain = retrieval | prompt | model | StrOutputParser()
```

### RunnableLambda — 커스텀 함수

```python
from langchain_core.runnables import RunnableLambda

def format_docs(docs):
    return "\n\n".join(d.page_content for d in docs)

chain = retriever | RunnableLambda(format_docs) | prompt | model
```

### RunnableBranch — 조건부 라우팅

```python
from langchain_core.runnables import RunnableBranch

branch = RunnableBranch(
    (lambda x: "code" in x["question"], code_chain),
    (lambda x: "math" in x["question"], math_chain),
    default_chain  # 기본 분기
)
```

### 통합 인터페이스 메서드

모든 Runnable은 동일한 인터페이스 제공:
- `invoke()` / `ainvoke()` — 동기/비동기 단일 실행
- `batch()` / `abatch()` — 배치 처리
- `stream()` / `astream()` — 스트리밍
- `astream_events()` — 이벤트 기반 스트리밍

---

## 4. 프롬프트 템플릿

### ChatPromptTemplate

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

result = prompt.invoke({
    "history": [HumanMessage("Hi"), AIMessage("Hello!")],
    "question": "What can you do?",
})
```

### create_agent에서의 시스템 프롬프트

```python
# 문자열
agent = create_agent(model, tools, system_prompt="Be concise.")

# SystemMessage 인스턴스 (LangChain 1.1+ — 캐시 제어 등 고급 기능)
from langchain_core.messages import SystemMessage
agent = create_agent(model, tools, system_prompt=SystemMessage(content="..."))
```

---

## 5. 구조화된 출력

### 에이전트에서 (create_agent)

```python
from pydantic import BaseModel
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class ContactInfo(BaseModel):
    name: str
    email: str
    phone: str

# ToolStrategy — 모든 tool calling 지원 모델 (범용)
agent = create_agent(model, tools, response_format=ToolStrategy(ContactInfo))

# ProviderStrategy — 네이티브 구조화 출력 지원 모델 (더 빠름)
agent = create_agent(model, tools, response_format=ProviderStrategy(ContactInfo))
```

### LCEL 체인에서

```python
# with_structured_output (가장 간단)
structured_llm = model.with_structured_output(ContactInfo)
result = structured_llm.invoke("Extract contact from: John, john@ex.com, 010-1234")
```

**주의:** `bind_tools()`가 이미 호출된 모델에서는 구조화된 출력이 지원되지 않음.

---

## 6. 도구 정의 및 호출

### @tool 데코레이터 (간단)

```python
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Search the web for information."""
    return search_engine.search(query)
```

### 클래스 기반 (복잡한 입력/검증)

```python
from langchain.tools import BaseTool
from pydantic import BaseModel

class CalculatorInput(BaseModel):
    expression: str

class Calculator(BaseTool):
    name = "calculator"
    description = "Perform math calculations"
    args_schema = CalculatorInput

    def _run(self, expression: str) -> str:
        return str(eval(expression))

    async def _arun(self, expression: str) -> str:
        return self._run(expression)
```

### RAG 도구 (content_and_artifact)

```python
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search relevant documents."""
    docs = vector_store.similarity_search(query, k=3)
    serialized = "\n\n".join(
        f"Source: {d.metadata}\nContent: {d.page_content}" for d in docs
    )
    return serialized, docs
```

### 도구 이름 규칙
- `snake_case` 권장 (공백/특수문자 제외)
- docstring이 도구 설명으로 사용됨 — 명확하게 작성

---

## 7. RAG 파이프라인

### 기본 RAG

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

# 1. 로드
docs = WebBaseLoader("https://example.com").load()

# 2. 청킹
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
splits = splitter.split_documents(docs)

# 3. 임베딩 + 저장
vector_store = InMemoryVectorStore.from_documents(splits, OpenAIEmbeddings())

# 4. 리트리버 도구로 래핑
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve relevant documents."""
    docs = vector_store.similarity_search(query, k=3)
    return "\n\n".join(d.page_content for d in docs), docs

# 5. 에이전트에 통합
agent = create_agent(model, tools=[retrieve], system_prompt="Answer using retrieved context.")
```

### 고급 검색 기법

| 기법 | 설명 |
|------|------|
| **Semantic Chunking** | 의미 단위 분할 (faithfulness 0.79~0.82 vs 고정 분할 0.47~0.51) |
| **Multi-Vector Retriever** | 문서당 여러 벡터 (요약, 가상 질문 등) |
| **MMR** | 관련성과 다양성 균형 |
| **Parent Document Retriever** | 작은 청크로 검색, 큰 문서 반환 |

### 벡터 스토어 옵션

- **인메모리**: `InMemoryVectorStore` (개발용)
- **클라우드**: Pinecone, Qdrant, Chroma, Weaviate
- **DB**: PostgreSQL (PGVector), MongoDB Atlas, Milvus

---

## 8. 스트리밍

### 3가지 스트리밍 모드

```python
# 1. updates — 에이전트 단계별 상태 변경
for chunk in agent.stream(input, stream_mode="updates"):
    for step, data in chunk.items():
        print(f"Step: {step}")

# 2. messages — LLM 토큰 스트리밍
for token, metadata in agent.stream(input, stream_mode="messages"):
    print(token.content, end="", flush=True)

# 3. custom — 사용자 정의 데이터
from langgraph.config import get_stream_writer

@tool
def long_task(query: str) -> str:
    writer = get_stream_writer()
    writer("Processing...")
    return "Done"
```

### 다중 모드 스트리밍

```python
for mode, chunk in agent.stream(input, stream_mode=["updates", "custom"]):
    if mode == "updates":
        handle_state_update(chunk)
    elif mode == "custom":
        handle_progress(chunk)
```

---

## 9. 비동기 패턴

```python
# 비동기 실행
result = await agent.ainvoke({"messages": [...]})

# 비동기 스트리밍
async for chunk in agent.astream(input, stream_mode="messages"):
    token, metadata = chunk
    print(token.content, end="", flush=True)

# 비동기 배치
results = await agent.abatch([input1, input2, input3])

# 비동기 도구
@tool
async def async_search(query: str) -> str:
    """Async web search."""
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.example.com/search?q={query}") as resp:
            return await resp.text()
```

**주의:**
- Python 3.11+ 권장 (3.10 이하에서는 `RunnableConfig`을 `ainvoke()`에 명시적 전달 필요)
- 블로킹 I/O를 async 함수 내에서 직접 호출 금지
- 고트래픽: `AsyncPostgresSaver` 사용

---

## 10. 미들웨어

LangChain 1.0+에서 cross-cutting concern을 분리하는 패턴.

### 모델 호출 미들웨어

```python
@wrap_model_call
def log_calls(request, handler):
    logger.info(f"Model: {request.model}, tokens: {len(request.messages)}")
    response = handler(request)
    logger.info(f"Response tokens: {response.usage}")
    return response
```

### 도구 호출 미들웨어

```python
@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except TimeoutError:
        return ToolMessage(content="Tool timed out", tool_call_id=request.tool_call["id"])
    except ValueError as e:
        return ToolMessage(content=f"Invalid input: {e}", tool_call_id=request.tool_call["id"])
    except Exception as e:
        logger.error(f"Tool error: {e}", exc_info=True)
        return ToolMessage(content=f"Error: {e}", tool_call_id=request.tool_call["id"])
```

### 내장 미들웨어 (LangChain 1.1+)

| 미들웨어 | 기능 |
|---------|------|
| `ModelRetryMiddleware` | 자동 재시도 + 지수 백오프 |
| `ModelFallbackMiddleware` | 1차 모델 실패 시 백업 모델 전환 |
| `SummarizationMiddleware` | 긴 대화 자동 요약 (Model Profiles 기반 트리거) |
| `ContentModerationMiddleware` | OpenAI 모더레이션 API 적용 |

```python
from langchain.middleware import ModelRetryMiddleware

agent = create_agent(
    model, tools,
    middleware=[ModelRetryMiddleware(max_retries=3, backoff_factor=2.0)]
)
```

---

## 참고

- [LangChain 1.0 GA](https://changelog.langchain.com/announcements/langchain-1-0-now-generally-available)
- [LangChain 1.1](https://changelog.langchain.com/announcements/langchain-1-1)
- [LangChain Agents 문서](https://docs.langchain.com/oss/python/langchain/agents)
- [LangChain Streaming 문서](https://docs.langchain.com/oss/python/langchain/streaming)
- [LangChain RAG 문서](https://docs.langchain.com/oss/python/langchain/rag)
