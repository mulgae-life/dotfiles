# 코딩 스타일 규칙

> React/DB/UI 등 상세 기준은 해당 스킬을 "정답"으로 사용.

## 우선순위 (충돌 시)

1) 프로젝트 문서(`CLAUDE.md`, `agent-guide/*`, `README.md`)
2) 기존 코드베이스 패턴(에러 포맷/폴더 구조/네이밍/테스트)
3) 이 파일

## MUST

- **범위 준수**: 요청 범위 밖 리포맷/리네이밍/리팩토링 금지 (필요하면 먼저 합의). 관련 없는 데드 코드 발견 시 삭제하지 말고 언급만. 본인의 변경이 만든 고아(미사용 import/변수/함수)만 정리
  - 자기검증 1문장: "변경한 모든 라인이 사용자 요청과 직결되는가?" — 아니면 잘라낸다
- **최소 Diff**: 불필요한 파일 이동/스타일 변경 금지. 인접 코드의 주석·포맷·네이밍을 "개선"하지 않기. 기존 스타일(따옴표, 들여쓰기, 줄바꿈)과 일치시키기
- **경계 검증**: 외부 입력(HTTP/env/파일/DB/LLM 출력)은 초기에 validate/normalize
  - ✗ `data = req.json(); process(data["key"])` (검증 없이 직접 사용)
  - ✓ `data = MySchema.model_validate(req.json()); process(data.key)`
- **에러 처리**: 예외를 삼키지 않기. Fail-fast 원칙
  - ✗ `except: pass`, `except Exception: return default_value`
  - ✗ `value = config.get("key") or "fallback"` (에러를 기본값으로 흡수)
  - ✓ 타입별 catch + 로그 + 사용자 메시지 분리. 폴백은 최상위 에러 경계에서만 허용
- **리소스 수명주기**: HTTP client/DB pool/모델/토크나이저는 요청마다 생성 금지, 앱 수명주기로 관리
- **설정 분리**: 하드코딩 대신 env/설정 파일. 안전한 기본값 + 명확한 실패

## SHOULD

- **명확성 우선**: early return, 의미 있는 네이밍, 단일 책임(SRP)
- **독립 작업 병렬화**: 불필요한 순차 await/N+1 피하기
- **접근법 검토**: 비사소한 로직 변경 시 코딩 전 더 단순한 접근법 검토. 여러 해석이 가능한 요청은 선택지를 나열하고 확인 후 진행
- **단순성 자기검증**: 구현 후 "이게 시니어 엔지니어 보기에 과복잡한가? 절반 분량으로 같은 기능 가능한가?" 자문. Yes면 재작성. 1회용 코드·구현체 1개에는 추상화 도입 금지

## AVOID

- **에러 뭉개기**: 검증 실패(400)/권한(401)/외부 장애(502) 구분 없이 "그냥 500" 금지
- **과도한 방어적 코딩**: 실패를 숨기는 패턴 금지
  - ✗ `result = api_call() ?? default_value` (실패가 버그인데 기본값으로 숨김)
  - ✗ `.catch(() => fallback)` (에러 원인 추적 불가)
  - ✓ 에러를 내서 원인을 추적하고 제대로 고치기. 폴백은 global error boundary에서만
- **느슨한 계약**: dict/str 기반 지양. API/LLM 출력은 Pydantic/Zod 등 스키마 사용

## 언어별

- **Python**: public 함수/서비스 경계에 타입 힌트. request/response/LLM 출력은 `pydantic`. async에서 블로킹 I/O 금지
- **TS/React**: public API/props/return 타입 명확히 (`any`/단언 지양). `Promise.all`+타임아웃/취소/재시도 정책 명시
- **SQL/DB**: 파라미터 바인딩. 클라이언트는 앱 수명주기로 관리

## 작업 후 기본 점검

작업 완료 후 `work-verify` 스킬로 누락/영향도/정합성 확인 후 결과 요약.

### 에러 패턴 축적

빌드/린트/테스트 실패 해결 후 같은 유형 2회 이상 → memory `lessons.md`에 기록.
