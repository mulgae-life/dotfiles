# 프로덕션 패턴 가이드

> LangChain 1.2.x / LangGraph v1.0 프로덕션 배포 기준

## 목차

- [1. 체크포인팅 (Persistence)](#1-체크포인팅-persistence)
- [2. Memory Store (Cross-Thread)](#2-memory-store-cross-thread)
- [3. 스트리밍 전략](#3-스트리밍-전략)
- [4. 에러 핸들링 및 재시도](#4-에러-핸들링-및-재시도)
- [5. 성능 최적화](#5-성능-최적화)
- [6. LangSmith 관찰가능성](#6-langsmith-관찰가능성)
- [7. 배포 옵션](#7-배포-옵션)
- [8. 보안](#8-보안)

---

## 1. 체크포인팅 (Persistence)

### 체크포인터 종류

| 체크포인터 | 패키지 | 용도 |
|-----------|--------|------|
| `InMemorySaver` | `langgraph` (내장) | 개발/테스트 전용 |
| `SqliteSaver` | `langgraph-checkpoint-sqlite` | 로컬 워크플로우 |
| `PostgresSaver` | `langgraph-checkpoint-postgres` | **프로덕션** (권장) |
| CosmosDB / DynamoDB | 커뮤니티 | 클라우드 환경 |

### 기본 사용

```python
from langgraph.checkpoint.postgres import PostgresSaver

checkpointer = PostgresSaver(conn_string="postgresql://user:pass@host/db")
graph = builder.compile(checkpointer=checkpointer)

config = {"configurable": {"thread_id": "user-123"}}
result = graph.invoke(input_data, config)
```

### StateSnapshot

```python
snapshot = graph.get_state(config)
# snapshot.values     — 현재 상태
# snapshot.next       — 다음 실행 노드
# snapshot.tasks      — 실행 상세 + 에러
# snapshot.metadata   — source, writes, step
```

### 상태 히스토리 및 Time Travel

```python
# 전체 히스토리 (최신순)
history = list(graph.get_state_history(config))

# 특정 시점에서 재개 (포크)
old_config = {"configurable": {"thread_id": "1", "checkpoint_id": "..."}}
graph.invoke(None, config=old_config)
```

### 상태 직접 업데이트

```python
graph.update_state(config, {"foo": 2, "bar": ["b"]})
# Reducer 있는 키: 병합, 없는 키: 덮어쓰기
# as_node 파라미터로 다음 실행 노드 제어

# Reducer를 바이패스하고 값 교체하려면 Overwrite 사용
from langgraph.types import Overwrite
graph.update_state(config, {"bar": Overwrite(["new_only"])})
# Reducer 통과: ["old", "new_only"] → Overwrite: ["new_only"]
```

---

## 2. Memory Store (Cross-Thread)

thread_id를 넘어 사용자 수준의 장기 기억:

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
namespace = (user_id, "memories")

# 저장
store.put(namespace, memory_id, {"preference": "pizza"})

# 검색
memories = store.search(namespace)

# 시맨틱 검색 (임베딩 기반)
store = InMemoryStore(
    index={"embed": init_embeddings("openai:text-embedding-3-small"),
           "dims": 1536, "fields": ["preference", "$"]}
)
memories = store.search(namespace, query="food preferences?", limit=3)

# 그래프에 통합
graph = builder.compile(checkpointer=checkpointer, store=store)

# 노드 내에서 Store 접근: Runtime 파라미터 사용
from langgraph.runtime import Runtime
def my_node(state, runtime: Runtime):
    prefs = runtime.store.get((state["user_id"], "preferences"), "lang")
    runtime.store.put((state["user_id"], "preferences"), "last_seen", {"ts": now()})
    return {"response": "..."}
```

---

## 3. 스트리밍 전략

### 5가지 스트리밍 모드

| 모드 | 설명 | 용도 |
|------|------|------|
| `values` | 스텝마다 전체 상태 | 상태 추적 |
| `updates` | 상태 변경분만 | 효율적 업데이트 |
| `messages` | LLM 토큰 스트리밍 | 실시간 텍스트 |
| `custom` | 노드 내 임의 데이터 | 진행 상황 |
| `debug` | 최대 정보 | 디버깅 |

### 커스텀 스트리밍

```python
from langgraph.config import get_stream_writer

def processing_node(state):
    writer = get_stream_writer()
    writer({"progress": "50%"})
    # ... 작업 ...
    writer({"progress": "100%"})
    return {"result": "done"}
```

### 토큰 필터링

```python
# 태그 기반 필터
model = ChatOpenAI(tags=["main_llm"])
for token, metadata in graph.stream(input, stream_mode="messages"):
    if "main_llm" in metadata.get("tags", []):
        print(token.content, end="")

# 노드 기반 필터
for token, metadata in graph.stream(input, stream_mode="messages"):
    if metadata.get("langgraph_node") == "agent":
        print(token.content, end="")
```

---

## 4. 에러 핸들링 및 재시도

### 에러 전략 계층 (4-tier)

에러 유형에 따라 적절한 계층에서 처리:

| 계층 | 에러 유형 | 처리 주체 | 전략 | 예시 |
|------|----------|----------|------|------|
| 1. **RetryPolicy** | 일시적 (네트워크, 레이트 리밋) | 시스템 자동 | `add_node(..., retry_policy=...)` | API 타임아웃 |
| 2. **ToolNode 에러** | LLM 복구 가능 (도구 실패) | LLM | `ToolNode(tools, handle_tool_errors=True)` | 잘못된 도구 입력 |
| 3. **interrupt** | 사용자 개입 필요 | 사람 | `interrupt({"error": ...})` | 누락 정보, 승인 |
| 4. **Bubble up** | 예상 외 에러 | 개발자 | `raise` | 코드 버그 |

### 1계층: RetryPolicy (노드 레벨 재시도)

```python
from langgraph.types import RetryPolicy

# 일시적 에러 자동 재시도 (네트워크, 레이트 리밋)
builder.add_node(
    "api_call",
    api_call_fn,
    retry_policy=RetryPolicy(
        max_attempts=3,
        initial_interval=1.0,     # 첫 재시도 대기(초)
        backoff_factor=2.0,       # 지수 백오프 배수
    )
)
```

### 2계층: 재시도 미들웨어 (모델 레벨)

```python
from langchain.middleware import ModelRetryMiddleware

agent = create_agent(
    model, tools,
    middleware=[ModelRetryMiddleware(max_retries=3, backoff_factor=2.0)]
)
```

### 도구 에러 처리 미들웨어

```python
@wrap_tool_call
def handle_errors(request, handler):
    try:
        return handler(request)
    except TimeoutError:
        return ToolMessage(content="Timed out", tool_call_id=request.tool_call["id"])
    except Exception as e:
        logger.error(f"Tool error: {e}", exc_info=True)
        return ToolMessage(content=f"Error: {e}", tool_call_id=request.tool_call["id"])
```

### 상태 기반 에러 추적

```python
class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    error_count: int
    error_types: list[str]
```

### 안전장치

```python
# recursion_limit으로 무한 루프 방지
config = {"recursion_limit": 25}  # 기본 1000, 프로덕션에서는 25~50

# RemainingSteps로 선제적 종료
# 노드 내에서 남은 스텝 확인 → 우아한 종료
```

---

## 5. 성능 최적화

### 그래프 설계

- `recursion_limit` 적절히 설정 (프로덕션 25~50)
- 조건부 엣지, `Command`, 명시적 루프 종료 조건
- `RemainingSteps`로 선제적 종료

### 상태 최적화

- **데이터 프루닝**: 필수 데이터만 상태에 포함
- **타겟 업데이트**: 의미 있는 변경만 상태 키 업데이트
- **경량 Reducer**: 빠르게 실행되는 Reducer 함수
- **메시지 트리밍**: `trim_messages()`로 토큰 한도 관리

### 병렬 처리

- `Send` API로 독립 작업 동시 실행
- 동시성 제한(concurrency limit) 설정
- 배치 요청으로 중복 API 호출 최소화

### 노드 캐싱

```python
from langgraph.cache.memory import InMemoryCache

graph = builder.compile(
    checkpointer=checkpointer,
    cache=InMemoryCache()
)

builder.add_node("expensive_node", fn, cache_policy=CachePolicy(ttl=300))
```

---

## 6. LangSmith 관찰가능성

### 설정

```python
import os
os.environ["LANGSMITH_TRACING"] = "true"
os.environ["LANGSMITH_API_KEY"] = "ls-..."
os.environ["LANGSMITH_PROJECT"] = "my-agent"
```

### 핵심 기능

| 기능 | 설명 |
|------|------|
| 트레이싱 | 모든 LLM 호출, 도구 실행, 노드 전이 추적 |
| 대시보드 | 토큰 사용량, 지연(P50/P99), 에러율, 비용 분석 |
| 평가(Evals) | 온라인 멀티턴 평가, 복합 피드백 |
| 알림 | 임계값 초과 시 Webhook/PagerDuty |
| OpenTelemetry | 기존 모니터링(Datadog 등) 통합 |

### 대안

- **Langfuse**: 오픈소스 LLM 관찰가능성
- **OpenTelemetry 직접 통합**: 벤더 중립

---

## 7. 배포 옵션

### LangSmith Deployment (구 LangGraph Platform)

| 옵션 | 설명 | 가격 |
|------|------|------|
| Developer | 자체 호스팅, 월 100k 노드 무료 | 무료 |
| Cloud (SaaS) | 완전 관리형 | Plus/Enterprise |
| Hybrid (BYOC) | SaaS 제어 + 자체 VPC | Enterprise |
| Self-Hosted | 완전 자체 인프라 | Enterprise |

### 핵심 기능
- 원클릭 배포 (GitHub 통합)
- 수평 확장 / 자동 스케일링
- 30+ API 엔드포인트
- LangGraph Studio (시각적 디버깅)
- Remote Graphs (분산 멀티에이전트)

### 프로덕션 스케일링 절차

1. 단일 사용자로 프로파일링
2. 로드 테스트로 하드웨어 요구사항 추정
3. 단계적 롤아웃 + 모니터링
4. 커넥션 풀링 (PostgreSQL)
5. 비용 모니터링 (토큰 사용량)

---

## 8. 보안

### 체크포인트 암호화

```python
from langgraph.checkpoint.serde.encrypted import EncryptedSerializer

serde = EncryptedSerializer.from_pycryptodome_aes()  # LANGGRAPH_AES_KEY 환경변수 필요
checkpointer = SqliteSaver(connection, serde=serde)
```

### CVE-2025-68664

`dumps()`/`dumpd()`에서 예약 키 `lc`를 포함한 사용자 입력 dict가 임의 객체 인스턴스화를 허용하는 취약점. 최신 버전 업데이트 필수. 사용자 입력 dict를 `dumpd()`/`dumps()`에 직접 전달 금지.

### 일반 보안 원칙

- 환경변수로 시크릿 관리 (API 키, DB 연결문자열)
- 도구 입력 검증 (Pydantic 스키마)
- interrupt()로 위험한 작업 전 승인 요청
- LangSmith에서 민감 데이터 마스킹

---

## 참고

- [LangGraph Persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangGraph Streaming](https://docs.langchain.com/oss/python/langgraph/streaming)
- [LangSmith Observability](https://docs.langchain.com/oss/python/langgraph/observability)
- [LangGraph Platform GA](https://blog.langchain.com/langgraph-platform-ga/)
- [NVIDIA Scaling Guide](https://developer.nvidia.com/blog/how-to-scale-your-langgraph-agents-in-production-from-a-single-user-to-1000-coworkers/)
