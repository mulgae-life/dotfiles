# 공통 패턴 (초기화, 에러, 스트리밍, SSE)

OpenAI와 Anthropic API에서 공통으로 적용되는 패턴들입니다.

---

## 1. 클라이언트 초기화

### 핵심 원칙

**앱 수명주기로 관리** - 요청마다 클라이언트 생성 금지.

### FastAPI 예시

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from openai import OpenAI
from anthropic import Anthropic

# 모듈 레벨 초기화
openai_client: OpenAI | None = None
anthropic_client: Anthropic | None = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global openai_client, anthropic_client

    # 앱 시작 시 초기화
    openai_client = OpenAI(timeout=60.0, max_retries=3)
    anthropic_client = Anthropic(timeout=60.0, max_retries=3)

    yield

    # 앱 종료 시 정리 (필요한 경우)
    openai_client = None
    anthropic_client = None

app = FastAPI(lifespan=lifespan)

@app.post("/chat")
async def chat(message: str):
    response = openai_client.responses.create(
        model="gpt-5",
        input=message
    )
    return {"response": response.output_text}
```

### 의존성 주입 패턴

```python
from functools import lru_cache
from openai import OpenAI

@lru_cache
def get_openai_client() -> OpenAI:
    return OpenAI(timeout=60.0, max_retries=3)

@app.post("/chat")
async def chat(
    message: str,
    client: OpenAI = Depends(get_openai_client)
):
    response = client.responses.create(...)
```

---

## 2. 에러 핸들링

### 공통 에러 타입

| 에러 | 원인 | 대응 |
|------|------|------|
| `RateLimitError` | 요청 한도 초과 | 지수 백오프 재시도 |
| `APIConnectionError` | 네트워크 문제 | 재시도 또는 실패 |
| `AuthenticationError` | API 키 문제 | 즉시 실패 (재시도 무의미) |
| `APIError` | 기타 서버 에러 | 로깅 후 적절히 처리 |

### OpenAI 에러 핸들링

```python
from openai import (
    OpenAI,
    APIError,
    RateLimitError,
    APIConnectionError,
    AuthenticationError
)
import logging

logger = logging.getLogger(__name__)

def call_openai(client: OpenAI, input: str) -> str:
    try:
        response = client.responses.create(
            model="gpt-5",
            input=input
        )
        return response.output_text

    except RateLimitError as e:
        logger.warning(f"Rate limited: {e}")
        # 재시도 로직 또는 큐에 넣기
        raise

    except AuthenticationError as e:
        logger.error(f"Authentication failed: {e}")
        # 재시도 무의미
        raise

    except APIConnectionError as e:
        logger.error(f"Connection error: {e}")
        raise

    except APIError as e:
        logger.error(f"API error {e.status_code}: {e.message}")
        raise
```

### Anthropic 에러 핸들링

```python
from anthropic import (
    Anthropic,
    APIError,
    RateLimitError,
    APIConnectionError,
    AuthenticationError
)

def call_anthropic(client: Anthropic, message: str) -> str:
    try:
        response = client.messages.create(
            model="claude-sonnet-4-5",
            messages=[{"role": "user", "content": message}],
            max_tokens=1024
        )
        return response.content[0].text

    except RateLimitError as e:
        logger.warning(f"Rate limited: {e}")
        raise

    except AuthenticationError as e:
        logger.error(f"Authentication failed: {e}")
        raise

    except APIConnectionError as e:
        logger.error(f"Connection error: {e}")
        raise

    except APIError as e:
        logger.error(f"API error {e.status_code}: {e.message}")
        raise
```

### 지수 백오프 재시도

```python
import time
from functools import wraps

def retry_with_backoff(max_retries: int = 3, base_delay: float = 1.0):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except RateLimitError as e:
                    if attempt == max_retries - 1:
                        raise
                    delay = base_delay * (2 ** attempt)
                    logger.warning(f"Rate limited, retrying in {delay}s...")
                    time.sleep(delay)
        return wrapper
    return decorator

@retry_with_backoff(max_retries=3)
def call_llm(client, input):
    return client.responses.create(model="gpt-5", input=input)
```

### tenacity 라이브러리 사용

```python
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=60),
    retry=retry_if_exception_type(RateLimitError)
)
def call_llm(client, input):
    return client.responses.create(model="gpt-5", input=input)
```

---

## 3. 스트리밍

### SSE (Server-Sent Events) with FastAPI

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from openai import OpenAI

app = FastAPI()
client = OpenAI()

async def generate_stream(message: str):
    stream = client.responses.create(
        model="gpt-5",
        input=message,
        stream=True
    )

    for event in stream:
        if event.type == "response.output_text.delta":
            yield f"data: {event.delta}\n\n"

    yield "data: [DONE]\n\n"

@app.get("/stream")
async def stream_chat(message: str):
    return StreamingResponse(
        generate_stream(message),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )
```

### Anthropic 스트리밍 SSE

```python
from anthropic import Anthropic

client = Anthropic()

async def generate_stream(message: str):
    with client.messages.stream(
        model="claude-sonnet-4-5",
        messages=[{"role": "user", "content": message}],
        max_tokens=1024
    ) as stream:
        for text in stream.text_stream:
            yield f"data: {text}\n\n"

    yield "data: [DONE]\n\n"
```

### 스트리밍 에러 핸들링

```python
async def generate_stream_safe(message: str):
    try:
        stream = client.responses.create(
            model="gpt-5",
            input=message,
            stream=True
        )

        for event in stream:
            if event.type == "response.output_text.delta":
                yield f"data: {event.delta}\n\n"

        yield "data: [DONE]\n\n"

    except Exception as e:
        # 스트리밍 중 에러는 전역 예외 핸들러 미적용
        # 제너레이터 내부에서 안전한 포맷으로 변환
        logger.error(f"Stream error: {e}")
        yield f"data: [ERROR] {str(e)}\n\n"
```

---

## 4. 출력 검증 (LLM 출력 파싱)

### Pydantic을 이용한 검증

```python
from pydantic import BaseModel, ValidationError
import json

class ExtractedData(BaseModel):
    name: str
    age: int
    email: str | None = None

def extract_structured_data(client: OpenAI, text: str) -> ExtractedData:
    response = client.responses.create(
        model="gpt-5",
        instructions="Extract structured data as JSON. Return only valid JSON.",
        input=f"Extract name, age, email from: {text}"
    )

    try:
        data = json.loads(response.output_text)
        return ExtractedData(**data)
    except json.JSONDecodeError as e:
        logger.error(f"JSON parse error: {e}")
        raise ValueError("LLM returned invalid JSON")
    except ValidationError as e:
        logger.error(f"Validation error: {e}")
        raise ValueError("LLM output doesn't match schema")
```

### 재시도 전략

```python
def extract_with_retry(client, text: str, max_retries: int = 2) -> ExtractedData:
    last_error = None

    for attempt in range(max_retries):
        try:
            return extract_structured_data(client, text)
        except ValueError as e:
            last_error = e
            logger.warning(f"Attempt {attempt + 1} failed: {e}")
            continue

    raise last_error
```

---

## 5. 비동기 패턴

### 비동기 클라이언트

```python
from openai import AsyncOpenAI
from anthropic import AsyncAnthropic

# OpenAI
async_openai = AsyncOpenAI()

async def call_openai_async(message: str) -> str:
    response = await async_openai.responses.create(
        model="gpt-5",
        input=message
    )
    return response.output_text

# Anthropic
async_anthropic = AsyncAnthropic()

async def call_anthropic_async(message: str) -> str:
    response = await async_anthropic.messages.create(
        model="claude-sonnet-4-5",
        messages=[{"role": "user", "content": message}],
        max_tokens=1024
    )
    return response.content[0].text
```

### 병렬 호출

```python
import asyncio

async def parallel_calls(messages: list[str]) -> list[str]:
    tasks = [call_openai_async(msg) for msg in messages]
    return await asyncio.gather(*tasks)

# 사용
results = await parallel_calls(["질문1", "질문2", "질문3"])
```

### 세마포어로 동시 요청 제한

```python
semaphore = asyncio.Semaphore(5)  # 최대 5개 동시 요청

async def call_with_limit(message: str) -> str:
    async with semaphore:
        return await call_openai_async(message)

async def parallel_calls_limited(messages: list[str]) -> list[str]:
    tasks = [call_with_limit(msg) for msg in messages]
    return await asyncio.gather(*tasks)
```

---

## 6. 타임아웃 설정

### 클라이언트 레벨

```python
# OpenAI
client = OpenAI(
    timeout=60.0,  # 전체 요청 타임아웃
    max_retries=3
)

# Anthropic
client = Anthropic(
    timeout=60.0,
    max_retries=3
)
```

### 요청별 타임아웃

```python
import httpx

# OpenAI
response = client.responses.create(
    model="gpt-5",
    input="...",
    timeout=httpx.Timeout(30.0, connect=5.0)  # 연결 5초, 전체 30초
)

# Anthropic
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[...],
    max_tokens=1024,
    timeout=httpx.Timeout(30.0, connect=5.0)
)
```

---

## 7. 환경변수 검증

```python
from pydantic_settings import BaseSettings

class LLMSettings(BaseSettings):
    openai_api_key: str
    anthropic_api_key: str | None = None
    default_model: str = "gpt-5"
    timeout: float = 60.0
    max_retries: int = 3

    class Config:
        env_prefix = ""  # 또는 "LLM_"

# 앱 시작 시 검증
settings = LLMSettings()  # 환경변수 없으면 ValidationError

# 클라이언트 초기화
client = OpenAI(
    api_key=settings.openai_api_key,
    timeout=settings.timeout,
    max_retries=settings.max_retries
)
```

---

## 참고 자료

- [OpenAI Python SDK](https://github.com/openai/openai-python)
- [Anthropic Python SDK](https://github.com/anthropics/anthropic-sdk-python)
- [Tenacity - Retry Library](https://tenacity.readthedocs.io/)
