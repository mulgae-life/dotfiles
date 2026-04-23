---
name: postgres-best-practices
description: Supabase의 Postgres 성능 최적화 및 모범 사례 가이드.
when_to_use: "쿼리 최적화해줘, 인덱스 추가해줘, RLS 정책 작성해줘, DB 성능 개선해줘 요청 시. SQL 쿼리, 인덱스, RLS, 커넥션 풀링, 파티셔닝 관련 작업이면 명시적 요청 없이도 참조."
---

# Supabase Postgres 모범 사례

Supabase에서 관리하는 Postgres 성능 최적화 가이드. 8개 카테고리, 30개 규칙으로 구성되며 영향도 순으로 정렬되어 쿼리 최적화와 스키마 설계를 안내함.

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
rules/query-missing-indexes.md
rules/query-partial-indexes.md
rules/_sections.md
```

각 규칙 파일 구성:
- 중요한 이유 간략 설명
- 잘못된 SQL 예시 + 설명
- 올바른 SQL 예시 + 설명
- EXPLAIN 출력 또는 성능 지표 (선택)
- 추가 맥락 및 참고자료
- Supabase 관련 참고사항 (해당 시)

## 전체 규칙 문서

모든 규칙이 포함된 전체 가이드: `AGENTS.md`
