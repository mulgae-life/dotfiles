# Python 코딩 표준

code-simplifier 스킬에서 Python 코드 단순화 시 참조하는 표준.

## 클래스 vs 함수
```python
# 상태(state)가 필요하면 → 클래스
class HistoryManager:
    def __init__(self, ttl: int = 3600):
        self._sessions: dict[str, Session] = {}
        self._ttl = ttl

# 상태가 없으면 → 함수
def sanitize_text(text: str) -> str:
    return text.strip().lower()
```

## 타입 힌트
- 모든 함수의 매개변수와 반환값에 타입 명시
- 복잡한 타입은 `TypeAlias` 또는 `TypedDict` 활용
```python
# Good
def fetch_events(region: str, limit: int = 10) -> list[Event]:
    ...

# Bad
def fetch_events(region, limit=10):
    ...
```

## Docstring (Google 스타일)
```python
def translate_text(text: str, target_lang: str) -> TranslateResult:
    """텍스트를 지정된 언어로 번역합니다.

    Args:
        text: 번역할 원본 텍스트
        target_lang: 목표 언어 코드 (예: 'en', 'ko', 'ja')

    Returns:
        번역 결과. 원본과 번역문 포함.

    Raises:
        ValueError: 지원하지 않는 언어 코드
        APIError: LLM API 호출 실패
    """
```

## Import 정렬
```python
# 1. 표준 라이브러리
import asyncio
from datetime import datetime

# 2. 서드파티
from fastapi import FastAPI, HTTPException
from openai import AsyncOpenAI

# 3. 로컬
from app.services import HistoryManager
from app.models import Session
```

## 에러 처리
- 복구 가능한 에러만 try/except
- 광범위한 `except Exception` 지양
- 에러 메시지에 컨텍스트 포함
```python
# Good
try:
    response = await client.chat.completions.create(...)
except openai.RateLimitError as e:
    raise APIError(f"Rate limit 초과: {e}") from e

# Bad
try:
    response = await client.chat.completions.create(...)
except Exception:
    pass
```
