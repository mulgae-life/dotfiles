---
description: 코딩 스타일 규칙. 프로젝트 공통 품질 기준, 언어별 코딩 패턴을 정의합니다.
---

# 코딩 스타일 규칙

> React/DB/UI 등 상세 기준은 해당 스킬을 "정답"으로 사용.

## 우선순위 (충돌 시)

1) 프로젝트 문서(`CLAUDE.md`, `agent-guide/*`, `README.md`)
2) 기존 코드베이스 패턴(에러 포맷/폴더 구조/네이밍/테스트)
3) 이 파일(`.claude/rules/coding-style.md`)

## MUST

- **범위 준수**: 요청 범위 밖 리포맷/리네이밍/리팩토링 금지 (필요하면 먼저 합의). 관련 없는 데드 코드 발견 시 삭제하지 말고 언급만. 본인의 변경이 만든 고아(미사용 import/변수/함수)만 정리
- **최소 Diff**: 불필요한 파일 이동/스타일 변경 금지. 인접 코드의 주석·포맷·네이밍을 "개선"하지 않기. 기존 스타일(따옴표, 들여쓰기, 줄바꿈)과 일치시키기
- **경계 검증**: 외부 입력(HTTP/env/파일/DB/LLM 출력)은 초기에 validate/normalize (보안 검증은 `security.md` 참조)
- **에러 처리**: 예외를 삼키지 않기. `except: pass` 금지, 타입별 catch + 로그 + 사용자 메시지 분리. **Fail-fast 원칙** — 동작해야 할 코드가 실패하면 에러를 표면화하여 제대로 고쳐야 한다. 폴백/기본값으로 에러를 흡수하면 근본 원인이 묻힌다
- **리소스 수명주기**: HTTP client/DB pool/모델/토크나이저는 요청마다 생성 금지, 앱 수명주기로 관리
- **설정 분리**: 하드코딩 대신 env/설정 파일. 안전한 기본값 + 명확한 실패 (시크릿 관리는 `security.md` 참조)

## SHOULD

- **명확성 우선**: early return, 의미 있는 네이밍, 단일 책임(SRP)
- **독립 작업 병렬화**: 불필요한 순차 await/N+1 피하기 (`Promise.all` 활용)
- **접근법 검토**: 비사소한 로직/알고리즘 변경 시 코딩 전 더 단순한 접근법 검토. 여러 해석이 가능한 요청은 선택지를 나열하고 확인 후 진행. 스타일 변경이 아닌 설계 수준만 해당

## AVOID

- **에러 뭉개기**: "그냥 500"으로 뭉개기 금지. 검증 실패(400)/권한(401)/외부 장애(502) 구분
- **과도한 방어적 코딩**: `?? defaultValue`, `.catch(() => fallback)`, `try/catch → return default` 등으로 실패를 숨기는 패턴 금지. 값이 없거나 호출이 실패하면 그 자체가 버그 — 에러를 내야 원인을 추적하고 제대로 고칠 수 있다. 폴백은 최상위 에러 경계(global error handler, error boundary)에서만 최후 방어로 허용
- **느슨한 계약**: dict/str 기반 지양. API/LLM 출력은 Pydantic/Zod 등 스키마 사용

## 언어별

- **TS/React/Next.js**: public API/props/return 타입 명확히 (`any`/단언 지양). `Promise.all`+타임아웃/취소/재시도 정책 명시. → 성능: `react-best-practices`, UI: `web-design-guidelines` 스킬 참조
- **Python**: public 함수/라우터/서비스 경계에 타입 힌트. request/response/LLM 출력은 `pydantic` 스키마. async에서 블로킹 I/O 금지, 공유 상태는 `asyncio.Lock`
- **FastAPI/REST**: Pydantic 모델로 request/response 정의, 상태코드/에러 포맷 일관. 전역 예외 핸들러로 HTTPException/ValidationError/외부API예외 각각 처리. SSE는 제너레이터 내 안전 포맷 변환
- **SQL/DB**: → `postgres-best-practices` 스킬 참조. Supabase 클라이언트는 앱 수명주기로 관리
- **LLM/ML**: → API: `llm-api-guide`, 프롬프트: `writing-prompts` 스킬 참조. 프롬프트 안전(시스템 지침/시크릿 유출 방지). LLM 출력은 스키마 검증 + 파싱 실패 대비 전략 필수

## 작업 후 기본 점검

작업 완료 후 `work-verify` 스킬로 누락/영향도/정합성 확인 후 결과 요약.

### 에러 패턴 축적

빌드/린트/테스트 실패 해결 후:
1. **반복 감지**: 같은 유형의 에러 2회 이상 → memory `lessons.md`에 기록 (auto memory)
2. **기록 형식**: 에러 코드 + 근본 원인 + 해결 패턴
3. **세션 참조**: `/start` 시 lessons.md를 읽고 알려진 패턴을 사전 적용
