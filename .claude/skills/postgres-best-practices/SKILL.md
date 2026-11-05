---
name: postgres-best-practices
description: Supabase가 관리하는 Postgres 모범 사례. 성능만이 아니라 스키마·마이그레이션·RLS·SQL 작성 전반에 적용하며, 어디서 돌아가는 Postgres든 해당.
when_to_use: "쿼리 최적화해줘, 인덱스 추가해줘, RLS 정책 작성해줘, DB 성능 개선해줘, 테이블 만들어줘, 마이그레이션 작성해줘 요청 시. 테이블·컬럼·타입, 마이그레이션, RLS, 인덱스, 트리거, DB 함수, pg_cron·pgmq, pgvector, pg_restore 등 Postgres에 남는 것을 만들거나 바꾸는 작업이면 컬럼 하나여도 명시적 요청 없이 참조. 느린 쿼리·타임아웃·EXPLAIN·연결 고갈·잠금·블로트·다른 테넌트 행 노출 진단에도 참조."
---

# Supabase Postgres 모범 사례

Supabase가 관리하는 Postgres 최적화 가이드. 8개 카테고리, 31개 규칙으로 구성되며 영향도 순으로 정렬되어 쿼리 최적화와 스키마 설계를 안내함.

## 적용 시점

- SQL 쿼리를 쓰거나 스키마를 설계할 때
- 인덱스를 만들거나 쿼리를 최적화할 때
- 데이터베이스 성능 문제를 리뷰할 때
- 커넥션 풀링이나 스케일링을 설정할 때
- Postgres 고유 기능을 활용할 때
- 행 수준 보안(RLS)을 다룰 때

## 규칙 카테고리 (우선순위순)

| 우선순위 | 카테고리 | 영향도 | 접두사 |
|----------|----------|--------|--------|
| 1 | 쿼리 성능 | CRITICAL | `query-` |
| 2 | 연결 관리 | CRITICAL | `conn-` |
| 3 | 보안 & RLS | CRITICAL | `security-` |
| 4 | 스키마 설계 | HIGH | `schema-` |
| 5 | 동시성 & 잠금 | MEDIUM-HIGH | `lock-` |
| 6 | 데이터 접근 패턴 | MEDIUM | `data-` |
| 7 | 모니터링 & 진단 | LOW-MEDIUM | `monitor-` |
| 8 | 고급 기능 | LOW | `advanced-` |

## 사용 방법

상세 설명과 SQL 예시는 개별 규칙 파일 참조:

```
references/query-missing-indexes.md
references/query-partial-indexes.md
references/_sections.md
```

각 규칙 파일 구성:
- 중요한 이유 간략 설명
- 잘못된 SQL 예시 + 설명
- 올바른 SQL 예시 + 설명
- EXPLAIN 출력 또는 성능 지표 (선택)
- 추가 맥락 및 참고자료
- Supabase 관련 참고사항 (해당 시)

## 참고

- https://www.postgresql.org/docs/current/
- https://supabase.com/docs
- https://wiki.postgresql.org/wiki/Performance_Optimization
- https://supabase.com/docs/guides/database/overview
- https://supabase.com/docs/guides/auth/row-level-security
