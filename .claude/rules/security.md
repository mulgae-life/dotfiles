# 보안 규칙

> 코드 품질(경계 검증, 설정 분리)은 `coding-style.md`가 담당. 이 파일은 보안 전용.

## 시크릿 관리

- 하드코딩 시크릿 **절대 금지**, 반드시 환경변수 사용
  - ✗ `API_KEY = "sk-abc123..."` (코드에 직접)
  - ✓ `API_KEY = os.environ["API_KEY"]` + 앱 시작 시 스키마 검증

## 취약점 방지

- **SQL 인젝션**: 문자열 연결 금지 → 파라미터 바인딩/ORM 사용
  - ✗ `f"SELECT * FROM users WHERE id = {user_id}"`
  - ✓ `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))`
- **XSS**: `dangerouslySetInnerHTML` 사용 시 반드시 DOMPurify 적용
- **CSRF**: 상태 변경은 POST/PUT/DELETE + CSRF 토큰 또는 SameSite 쿠키

## 보안 문제 발견 시 대응

1. 현재 작업 중단
2. 심각도 평가: P0(즉시), P1(긴급), P2(중요)
3. `security-reviewer` 에이전트 위임
4. 수정 후 검증 + 코드베이스에서 유사 패턴 추가 검색

## 커밋 전 체크리스트

- [ ] 하드코딩된 시크릿 없음
- [ ] 모든 사용자 입력 검증됨
- [ ] 민감 데이터 로깅/에러 메시지 노출 없음
