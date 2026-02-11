---
name: security
description: 보안 규칙. 시크릿 관리, 입력 검증, 취약점 방지에 대한 필수 규칙을 정의합니다.
alwaysApply: true
---

# 보안 규칙

## 시크릿 관리

### 절대 금지 사항

하드코딩 시크릿은 **절대 금지**:

```typescript
// ❌ 절대 금지
const API_KEY = "sk-1234567890abcdef"
const DB_PASSWORD = "mypassword123"
const JWT_SECRET = "super-secret-key"

// ✓ 반드시 환경변수 사용
const API_KEY = process.env.API_KEY
const DB_PASSWORD = process.env.DB_PASSWORD
const JWT_SECRET = process.env.JWT_SECRET
```

### 환경변수 검증

환경변수는 앱 시작 시 검증:

```typescript
// lib/env.ts
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  OPENAI_API_KEY: z.string().startsWith('sk-'),
  NODE_ENV: z.enum(['development', 'production', 'test']),
})

export const env = envSchema.parse(process.env)
```

## 입력 검증

### 모든 사용자 입력 검증 필수

```typescript
// ❌ 위험: 검증 없음
async function createUser(req: Request) {
  const { email, name } = await req.json()
  await db.users.create({ email, name })
}

// ✓ 안전: Zod 스키마로 검증
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
})

async function createUser(req: Request) {
  const body = await req.json()
  const { email, name } = CreateUserSchema.parse(body)
  await db.users.create({ email, name })
}
```

## 취약점 방지

### SQL 인젝션

```typescript
// ❌ 위험: 문자열 연결
const query = `SELECT * FROM users WHERE id = ${userId}`

// ✓ 안전: 파라미터 바인딩
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('id', userId)
```

### XSS (Cross-Site Scripting)

```typescript
// ❌ 위험: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✓ 안전: 텍스트로 렌더링
<div>{userInput}</div>

// 필요 시 sanitize 라이브러리 사용
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />
```

### CSRF (Cross-Site Request Forgery)

- 상태 변경 API는 POST/PUT/DELETE 사용
- CSRF 토큰 검증 또는 SameSite 쿠키 설정

## 보안 문제 발견 시 대응

보안 문제 발견 시 다음 순서로 대응:

1. **즉시 중단**: 현재 작업 중단
2. **심각도 평가**: P0(즉시), P1(긴급), P2(중요)
3. **security-reviewer 에이전트 위임**: 자동 보안 분석
4. **수정 후 검증**: 취약점 재발 방지 확인
5. **코드베이스 검토**: 유사한 패턴 추가 검색

## 커밋 전 체크리스트

- [ ] 하드코딩된 시크릿 없음
- [ ] 모든 사용자 입력 검증됨
- [ ] SQL 쿼리 파라미터화됨
- [ ] XSS 취약점 없음
- [ ] 민감한 데이터 로깅 안함
- [ ] 에러 메시지에 내부 정보 노출 안함
