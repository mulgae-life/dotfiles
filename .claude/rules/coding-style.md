---
name: coding-style
description: 코딩 스타일 규칙. 프로젝트 공통 품질 기준, 언어별 코딩 패턴을 정의합니다.
alwaysApply: true
---

# 코딩 스타일 규칙

> 목표: 프로젝트가 달라도 "항상 같은 품질"이 나오게 하는 최소 규칙.
> React/DB/UI 등 상세 기준은 해당 스킬을 "정답"으로 사용합니다.

## 우선순위 (충돌 시)

1) 프로젝트 문서(`CLAUDE.md`, `agent-guide/*`, `README.md`)
2) 기존 코드베이스 패턴(에러 포맷/폴더 구조/네이밍/테스트)
3) 이 파일(`.claude/rules/coding-style.md`)

## MUST (항상 지켜야 함)

### 범위 준수

요청 범위 밖 리포맷/리네이밍/리팩토링 **금지** (필요하면 먼저 합의).

### 최소 Diff

불필요한 파일 이동/스타일 변경 **금지**.

### 경계 검증

외부 입력(HTTP/env/파일/DB/LLM 출력)은 **초기에 validate/normalize**.

### 에러 처리

예외를 삼키지 않기. 사용자 메시지와 내부 로그 **분리**:

```python
# ❌ 예외 삼키기
try:
    result = api_call()
except:
    pass

# ✓ 적절한 처리
try:
    result = api_call()
except ApiError as e:
    logger.error(f"API 호출 실패: {e}")
    raise UserFacingError("서비스 일시 오류")
```

### 리소스 수명주기

HTTP client/DB pool/모델은 **요청마다 생성 금지** (앱 수명주기로 관리):

```python
# ❌ 요청마다 생성
@app.post("/chat")
async def chat():
    client = OpenAI()  # 매번 생성
    return client.chat(...)

# ✓ 앱 시작 시 1회 생성
client = OpenAI()  # 모듈 레벨

@app.post("/chat")
async def chat():
    return client.chat(...)
```

### 설정 분리

하드코딩 대신 env/설정 파일. 안전한 기본값 + 명확한 실패.

## SHOULD (권장)

- **명확성 우선**: early return, 의미 있는 네이밍, 단일 책임(SRP)
- **독립 작업 병렬화**: 불필요한 순차 await/N+1 피하기 (`Promise.all` 활용)

## AVOID (피해야 함)

### 에러 뭉개기

"그냥 500"으로 뭉개기 **금지** (검증 실패/권한/외부 의존 장애를 구분):

```typescript
// ❌ 모든 에러를 500으로
catch (e) {
  return res.status(500).json({ error: "Server error" })
}

// ✓ 에러 유형별 구분
catch (e) {
  if (e instanceof ValidationError) return res.status(400).json(...)
  if (e instanceof AuthError) return res.status(401).json(...)
  if (e instanceof ExternalApiError) return res.status(502).json(...)
  return res.status(500).json(...)
}
```

### 느슨한 계약

dict/str 기반의 느슨한 계약 **지양** (특히 API/LLM 출력):

```python
# ❌ 느슨한 타입
def process(data: dict) -> str:
    return data["result"]

# ✓ 명확한 스키마
class Response(BaseModel):
    result: str

def process(data: Response) -> str:
    return data.result
```

## TS/React/Next.js

- public API/props/return에서 타입 명확히 (무분별한 `any`/단언 지양)
- 독립 작업은 `Promise.all`, 타임아웃/취소/재시도 정책 명시
- 성능/패턴: `react-best-practices` 스킬 참조
- UI/접근성/UX: `web-design-guidelines` 스킬 참조

## Python

- public 함수/라우터/서비스 경계에 타입 힌트 적용
- request/response/LLM 출력은 `pydantic`으로 스키마 정의
- async 컨텍스트에서 블로킹 I/O 금지, 공유 상태는 `asyncio.Lock`

## FastAPI/REST

Pydantic 모델로 request/response 정의, 상태코드/에러 포맷 일관 유지:

```python
# ❌ dict 반환
@app.post("/users")
async def create_user(data: dict):
    return {"id": 1, "name": data["name"]}

# ✓ Pydantic 모델
@app.post("/users", response_model=UserResponse)
async def create_user(data: CreateUserRequest) -> UserResponse:
    return UserResponse(id=1, name=data.name)
```

- 전역 예외 핸들러: HTTPException/ValidationError/외부API예외 각각 처리
- SSE/streaming: 전역 핸들러 미적용 → 제너레이터 내부에서 안전 포맷으로 변환

## SQL/DB (Supabase/Postgres)

- 쿼리 최적화/인덱스/RLS: `postgres-best-practices` 스킬 참조
- Supabase 클라이언트는 앱 수명주기로 관리 (요청마다 생성 금지)

## LLM/ML

- API 연동: `llm-api-guide` 스킬 참조
- 프롬프트 작성: `writing-prompts` 스킬 참조
- 모델/클라이언트/토크나이저는 앱 시작 시 1회 초기화 (요청 핸들러 내부 금지)
- 모델별 파라미터 차이(reasoning/temperature)는 설정 기반으로 분기
- 프롬프트 안전: 시스템/개발자 지침/시크릿이 사용자 입력으로 유출/오염되지 않게

### 출력 검증

LLM 출력은 스키마 검증 + 실패 대비 (파싱 실패/부분 실패 전략):

```python
# ❌ 검증 없이 사용
response = await client.chat(...)
return response.content

# ✓ 스키마 검증
response = await client.chat(...)
try:
    result = OutputSchema.model_validate_json(response.content)
except ValidationError:
    # 파싱 실패 대비 로직
    ...
```

## 작업 후 기본 점검

코드/설정 변경 후에는 기본적으로 `code-verify` 스킬로 누락/영향도/정합성을 확인하고 결과를 요약합니다.
