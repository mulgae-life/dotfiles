# 마이그레이션 & 안티패턴 가이드

> 레거시 LangChain → 최신 LangChain 1.x / LangGraph v1.0 마이그레이션

## 목차

- [1. Deprecated 기능 마이그레이션](#1-deprecated-기능-마이그레이션)
- [2. 안티패턴](#2-안티패턴)
- [3. 프레임워크 비교](#3-프레임워크-비교)
- [4. LangChain 사용 시 주의점](#4-langchain-사용-시-주의점)

---

## 1. Deprecated 기능 마이그레이션

### 체인 마이그레이션

```python
# ❌ Deprecated: LLMChain
from langchain.chains import LLMChain
chain = LLMChain(llm=model, prompt=prompt)

# ✅ 대체: LCEL 파이프라인
chain = prompt | model | StrOutputParser()
```

```python
# ❌ Deprecated: ConversationalRetrievalChain
from langchain.chains import ConversationalRetrievalChain
chain = ConversationalRetrievalChain.from_llm(llm, retriever)

# ✅ 대체: RAG 에이전트
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve documents."""
    docs = retriever.invoke(query)
    return "\n".join(d.page_content for d in docs), docs

agent = create_agent(model, tools=[retrieve], system_prompt="Answer using context.")
```

### 에이전트 마이그레이션

```python
# ❌ Deprecated: AgentExecutor
from langchain.agents import AgentExecutor, create_react_agent
agent_executor = AgentExecutor(agent=agent, tools=tools)

# ✅ 대체: create_agent
from langchain.agents import create_agent
agent = create_agent(model, tools=tools, system_prompt="...")
```

```python
# ❌ Deprecated: langgraph.prebuilt.create_react_agent (아직 작동하지만 권장 안 함)
from langgraph.prebuilt import create_react_agent

# ✅ 대체: langchain.agents.create_agent
from langchain.agents import create_agent
```

### 메모리 마이그레이션

```python
# ❌ Deprecated: ConversationBufferMemory
from langchain.memory import ConversationBufferMemory
memory = ConversationBufferMemory()

# ✅ 대체: LangGraph 체크포인터
from langgraph.checkpoint.postgres import PostgresSaver
checkpointer = PostgresSaver(conn_string="...")
agent = create_agent(model, tools, checkpointer=checkpointer)

# thread_id로 대화 관리
config = {"configurable": {"thread_id": "user-123"}}
```

### 임포트 경로 마이그레이션

```python
# ❌ Deprecated
from langchain.chat_models import ChatOpenAI
from langchain.embeddings import OpenAIEmbeddings

# ✅ 대체: 프로바이더별 패키지
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_anthropic import ChatAnthropic
```

### 전체 마이그레이션 매핑

| Deprecated | 대체 |
|-----------|------|
| `LLMChain` | `prompt \| model \| parser` (LCEL) |
| `ConversationalRetrievalChain` | `create_agent` + retriever tool |
| `ConversationBufferMemory` | LangGraph 체크포인터 |
| `ConversationSummaryMemory` | SummarizationMiddleware |
| `AgentExecutor` | `create_agent` |
| `create_react_agent` (prebuilt) | `create_agent` (langchain.agents) |
| `from langchain.chat_models` | `from langchain_openai` 등 |

---

## 2. 안티패턴

### 2.1 레거시 체인 사용

```python
# ❌ 안티패턴
from langchain.chains import LLMChain, SequentialChain
chain1 = LLMChain(llm=model, prompt=prompt1)
chain2 = LLMChain(llm=model, prompt=prompt2)
seq = SequentialChain(chains=[chain1, chain2])

# ✅ LCEL
chain = prompt1 | model | parser | prompt2 | model | parser
```

### 2.2 레거시 메모리 사용

```python
# ❌ 안티패턴: API 호출당 1초+ 지연 추가
memory = ConversationBufferMemory(return_messages=True)
chain = ConversationalRetrievalChain.from_llm(llm, retriever, memory=memory)

# ✅ 체크포인터: 효율적 상태 관리
agent = create_agent(model, tools, checkpointer=PostgresSaver(conn))
```

### 2.3 고정 청크 사이즈 RAG

```python
# ❌ 안티패턴: 고정 512 토큰 청킹 (faithfulness 0.47~0.51)
splitter = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=50)

# ✅ 시맨틱 청킹 (faithfulness 0.79~0.82)
from langchain_experimental.text_splitter import SemanticChunker
splitter = SemanticChunker(embeddings, breakpoint_threshold_type="percentile")
```

### 2.4 과도한 추상화

```python
# ❌ 안티패턴: 불필요한 추상화 계층
class MyCustomChainWrapper:
    def __init__(self):
        self.chain = LLMChain(...)
        self.memory = ConversationBufferMemory(...)
        self.retriever = ...

    def run(self, query):
        context = self.retriever.invoke(query)
        self.memory.save_context(...)
        return self.chain.run(query=query, context=context)

# ✅ LCEL 또는 create_agent로 단순하게
agent = create_agent(model, tools=[retrieve_tool], system_prompt="...")
```

### 2.5 동기 블로킹 in 비동기

```python
# ❌ 안티패턴: async 함수 내 블로킹 I/O
async def my_tool(query: str):
    result = requests.get(f"https://api.example.com?q={query}")  # 블로킹!
    return result.text

# ✅ 비동기 HTTP 클라이언트 사용
async def my_tool(query: str):
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.example.com?q={query}") as resp:
            return await resp.text()
```

### 2.6 무한 에이전트 루프

```python
# ❌ 안티패턴: recursion_limit 미설정 (기본 1000)
graph.invoke(input)

# ✅ 적절한 제한 + 안전장치
config = {"recursion_limit": 25}
graph.invoke(input, config=config)
```

### 2.7 interrupt()를 try/except에서 사용

```python
# ❌ 안티패턴
def my_node(state):
    try:
        result = interrupt({"question": "Approve?"})
    except Exception:
        result = {"approved": False}

# ✅ interrupt는 예외 기반 메커니즘 — try/except 밖에서 사용
def my_node(state):
    result = interrupt({"question": "Approve?"})
    if result["approved"]:
        return {"status": "approved"}
```

### 안티패턴 요약

| 안티패턴 | 문제 | 대안 |
|---------|------|------|
| 레거시 체인 | Deprecated, 유지보수 중단 | LCEL / create_agent |
| 레거시 메모리 | 성능 저하 (1초+/호출) | LangGraph 체크포인터 |
| 고정 청킹 | RAG 정확도 저하 | 시맨틱 청킹 |
| 과도한 추상화 | 디버깅 어려움, 벤더 락인 | 필요한 추상화만 |
| 동기 I/O in async | 이벤트 루프 블로킹 | aiohttp/httpx 사용 |
| 무한 루프 | 비용 폭증, 무응답 | recursion_limit 설정 |
| interrupt in try/except | 인터럽트 무시됨 | try/except 밖에서 사용 |

---

## 3. 프레임워크 비교

### LangGraph vs CrewAI vs AutoGen

| 비교 항목 | LangGraph | CrewAI | AutoGen |
|-----------|-----------|--------|---------|
| 아키텍처 | 방향 그래프 (노드+엣지) | 역할 기반 팀 (크루) | 대화 기반 (멀티파티) |
| 상태 관리 | 명시적, 타입화된 State | 암묵적, 태스크 위임 | 메시지 히스토리 |
| 사이클/루프 | 1급 지원 | 제한적 | 대화 루프 |
| HITL | interrupt() + Command | 기본 지원 | GroupChat |
| 프로덕션 준비도 | **가장 높음** (v1.0 GA) | 중간 (프로토타이핑) | 낮음 (유지보수 모드) |
| 디버깅 | LangSmith 통합 | 터미널 로그 | Studio UI |
| 학습 곡선 | 높음 | 낮음 | 중간 |

### 선택 기준

- **복잡한 프로덕션 워크플로우** → LangGraph
- **빠른 프로토타이핑** → CrewAI
- **대화형 에이전트/토론** → AutoGen (단, MS Agent Framework으로 전환 예정)

### LangChain vs LangGraph 선택

| 상황 | 권장 |
|------|------|
| 단순 에이전트/챗봇/RAG | LangChain (`create_agent`) |
| 복잡한 멀티스텝 워크플로우 | LangGraph (StateGraph) |
| 커스텀 그래프 로직 | LangGraph |
| 고급 상태 관리 | LangGraph |
| 빠른 개발 | LangChain |

**참고:** `create_agent`는 내부적으로 LangGraph 런타임을 사용.

---

## 4. LangChain 사용 시 주의점

### 장점

- 풍부한 통합 생태계 (400+ 프로바이더)
- 빠른 프로토타이핑
- LangSmith 통합 관찰가능성
- 활발한 커뮤니티

### 단점/주의점

| 주의점 | 설명 |
|--------|------|
| 추상화 오버헤드 | 레거시 Memory 래퍼 1초+/호출 추가 가능 |
| 디버깅 어려움 | 다층 추상화 → 에러 원인 추적 복잡 |
| 벤더 락인 | LangChain 추상화 의존 시 교체 비용 |
| 학습 곡선 | 체인, 에이전트, 메모리, 도구 등 다수 개념 |

### LangChain 없이 직접 구현이 나은 경우

- 지연시간이 극히 중요 (50~100ms 오버헤드)
- 매우 단순한 prompt → response 파이프라인
- 특정 프로바이더만 사용 (추상화 불필요)
- SDK 직접 호출이 더 명확한 경우

### 프로덕션 채택 사례

| 기업 | 용도 |
|------|------|
| Klarna | 고객 지원 (8,500만 사용자, 해결시간 80% 단축) |
| Uber | 내부 도구 |
| LinkedIn | 검색/추천 |
| Coinbase | 고객 서비스 |
| Elastic | 검색+분석 멀티에이전트 |

---

## 참고

- [LangChain Migration Guide](https://python.langchain.com/docs/versions/migrating_memory/)
- [LangChain 1.0 Changelog](https://changelog.langchain.com/announcements/langchain-1-0-now-generally-available)
- [AutoGen vs LangGraph vs CrewAI](https://dev.to/synsun/autogen-vs-langgraph-vs-crewai-which-agent-framework-actually-holds-up-in-2026-3fl8)
- [CVE-2025-68664](https://cyata.ai/blog/langgrinch-langchain-core-cve-2025-68664/)
