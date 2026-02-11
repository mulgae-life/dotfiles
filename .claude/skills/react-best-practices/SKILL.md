---
name: react-best-practices
description: Vercel Engineering의 React/Next.js 성능 최적화 가이드. React 컴포넌트, Next.js 페이지, 데이터 페칭, 번들 최적화, 성능 개선 작업 시 트리거됨.
license: MIT
metadata:
  author: vercel
  version: "1.0.0"
---

# React Best Practices

Vercel Engineering의 React/Next.js 성능 최적화 가이드입니다. 8개 카테고리, 45개 이상의 룰을 우선순위별로 정리했습니다.

## 적용 시점

다음 작업 시 이 가이드라인을 참조하세요:
- React 컴포넌트 또는 Next.js 페이지 작성
- 데이터 페칭 구현 (클라이언트/서버)
- 성능 이슈 코드 리뷰
- 기존 React/Next.js 코드 리팩토링
- 번들 사이즈 또는 로드 시간 최적화

## 카테고리별 우선순위

| 우선순위 | 카테고리 | 영향도 | 접두사 |
|----------|----------|--------|--------|
| 1 | Waterfall 제거 | CRITICAL | `async-` |
| 2 | 번들 사이즈 최적화 | CRITICAL | `bundle-` |
| 3 | 서버 사이드 성능 | HIGH | `server-` |
| 4 | 클라이언트 데이터 페칭 | MEDIUM-HIGH | `client-` |
| 5 | 리렌더 최적화 | MEDIUM | `rerender-` |
| 6 | 렌더링 성능 | MEDIUM | `rendering-` |
| 7 | JavaScript 성능 | LOW-MEDIUM | `js-` |
| 8 | 고급 패턴 | LOW | `advanced-` |

## 빠른 참조

### 1. Waterfall 제거 (CRITICAL)

- `async-defer-await` - await를 실제 사용 분기로 이동
- `async-parallel` - 독립 작업에 Promise.all() 사용
- `async-dependencies` - 부분 의존성에 better-all 사용
- `async-api-routes` - API 라우트에서 Promise 일찍 시작, 늦게 await
- `async-suspense-boundaries` - Suspense로 콘텐츠 스트리밍

### 2. 번들 사이즈 최적화 (CRITICAL)

- `bundle-barrel-imports` - 직접 import, barrel 파일 피하기
- `bundle-dynamic-imports` - 무거운 컴포넌트에 next/dynamic 사용
- `bundle-defer-third-party` - 분석/로깅은 hydration 후 로드
- `bundle-conditional` - 기능 활성화 시에만 모듈 로드
- `bundle-preload` - hover/focus 시 preload로 체감 속도 향상

### 3. 서버 사이드 성능 (HIGH)

- `server-cache-react` - 요청별 중복 제거에 React.cache() 사용
- `server-cache-lru` - 요청 간 캐싱에 LRU 캐시 사용
- `server-serialization` - 클라이언트 컴포넌트로 전달 데이터 최소화
- `server-parallel-fetching` - 컴포넌트 구조 변경으로 fetch 병렬화
- `server-after-nonblocking` - 논블로킹 작업에 after() 사용

### 4. 클라이언트 데이터 페칭 (MEDIUM-HIGH)

- `client-swr-dedup` - 자동 요청 중복 제거에 SWR 사용
- `client-event-listeners` - 전역 이벤트 리스너 중복 제거

### 5. 리렌더 최적화 (MEDIUM)

- `rerender-defer-reads` - 콜백에서만 쓰는 상태 구독 금지
- `rerender-memo` - 비용 큰 작업은 메모이제이션 컴포넌트로 추출
- `rerender-dependencies` - effect에 원시값 의존성 사용
- `rerender-derived-state` - 원본 값 대신 파생 boolean 구독
- `rerender-functional-setstate` - 안정적 콜백에 함수형 setState 사용
- `rerender-lazy-state-init` - 비용 큰 초기값에 함수 전달
- `rerender-transitions` - 비긴급 업데이트에 startTransition 사용

### 6. 렌더링 성능 (MEDIUM)

- `rendering-animate-svg-wrapper` - SVG 요소 대신 div 래퍼 애니메이션
- `rendering-content-visibility` - 긴 리스트에 content-visibility 사용
- `rendering-hoist-jsx` - 정적 JSX를 컴포넌트 밖으로 추출
- `rendering-svg-precision` - SVG 좌표 정밀도 줄이기
- `rendering-hydration-no-flicker` - 클라이언트 전용 데이터에 인라인 스크립트
- `rendering-activity` - show/hide에 Activity 컴포넌트 사용
- `rendering-conditional-render` - && 대신 삼항 연산자 사용

### 7. JavaScript 성능 (LOW-MEDIUM)

- `js-batch-dom-css` - 클래스나 cssText로 CSS 변경 일괄 처리
- `js-index-maps` - 반복 조회에 Map 빌드
- `js-cache-property-access` - 루프에서 객체 속성 캐싱
- `js-cache-function-results` - 모듈 레벨 Map에 함수 결과 캐싱
- `js-cache-storage` - localStorage/sessionStorage 읽기 캐싱
- `js-combine-iterations` - 여러 filter/map을 하나의 루프로 결합
- `js-length-check-first` - 비용 큰 비교 전 배열 길이 먼저 체크
- `js-early-exit` - 함수에서 조기 반환
- `js-hoist-regexp` - RegExp 생성을 루프 밖으로
- `js-min-max-loop` - sort 대신 루프로 min/max 찾기
- `js-set-map-lookups` - O(1) 조회에 Set/Map 사용
- `js-tosorted-immutable` - 불변성에 toSorted() 사용

### 8. 고급 패턴 (LOW)

- `advanced-event-handler-refs` - 이벤트 핸들러를 ref에 저장
- `advanced-use-latest` - 안정적 콜백 ref에 useLatest

## 사용 방법

개별 룰 파일에서 상세 설명과 코드 예제를 확인하세요:

```
rules/async-parallel.md
rules/bundle-barrel-imports.md
rules/_sections.md
```

각 룰 파일 포함 내용:
- 중요한 이유 설명
- 잘못된 코드 예제 + 설명
- 올바른 코드 예제 + 설명
- 추가 컨텍스트 및 참조

## 전체 문서

모든 룰이 포함된 완전한 가이드: `AGENTS.md`
