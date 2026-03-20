---
name: web-design-guidelines
description: 기존 UI 코드의 웹 인터페이스 가이드라인 준수 여부를 검토합니다. 접근성(a11y), 폼/입력, 애니메이션, 다크 모드, 터치/인터랙션, 레이아웃, 타이포그래피, 성능, 하이드레이션 안전성 등 카테고리 기반 규칙 점검. "UI 리뷰해줘", "접근성 체크", "디자인 검토", "UX 리뷰" 요청 시 트리거. frontend-design(UI 제작)과 달리 기존 코드 검토 전용. react-best-practices(React 성능)와 달리 프레임워크 무관한 웹 UX 패턴에 집중.
---

# Web Interface Guidelines 리뷰

웹 인터페이스 가이드라인 기반으로 기존 UI 코드의 품질을 검토합니다. 프레임워크에 무관하게 접근성, 인터랙션, 성능 등 웹 UX 패턴을 점검합니다.

## 작동 방식

1. **최신 가이드라인 fetch**: WebFetch로 아래 소스 URL에서 최신 규칙을 가져옴
2. **fetch 실패 시 fallback**: `references/web-interface-guidelines.md` 로컬 스냅샷 사용
3. **대상 파일 읽기 + 전체 규칙 적용**: 지정된 파일(또는 사용자 요청 파일)을 읽고 fetch/fallback 가이드라인의 모든 규칙 적용

## 검토 카테고리

| 카테고리 | 핵심 규칙 요약 |
|----------|---------------|
| **접근성(Accessibility)** | `aria-label`, 시맨틱 HTML, 키보드 핸들러, `aria-live`, skip link |
| **포커스 상태(Focus States)** | `focus-visible` 링, `outline-none` 금지, `:focus-within` 활용 |
| **폼(Forms)** | `autocomplete`/`name`, 올바른 `type`/`inputmode`, paste 차단 금지, 인라인 에러, 미저장 경고 |
| **애니메이션(Animation)** | `prefers-reduced-motion` 존중, `transform`/`opacity`만 애니메이트, `transition: all` 금지 |
| **타이포그래피(Typography)** | 말줄임표(`…`), 커리 따옴표, `tabular-nums`, `text-wrap: balance` |
| **콘텐츠 처리(Content Handling)** | `truncate`/`line-clamp`, `min-w-0`, 빈 상태 처리, UGC 대응 |
| **이미지(Images)** | `width`/`height` 명시(CLS 방지), `loading="lazy"`, `fetchpriority` |
| **성능(Performance)** | 50+ 항목 가상화, 렌더 중 레이아웃 읽기 금지, `preconnect`/`preload` |
| **내비게이션/상태(Navigation & State)** | URL에 상태 반영, `<a>`/`<Link>` 사용, 파괴적 액션 확인 |
| **터치/인터랙션(Touch & Interaction)** | `touch-action: manipulation`, `overscroll-behavior: contain`, 드래그 중 선택 비활성화 |
| **Safe Area/레이아웃(Layout)** | `env(safe-area-inset-*)`, 불필요한 스크롤바 방지, flex/grid 우선 |
| **다크 모드/테마(Dark Mode & Theming)** | `color-scheme: dark`, `theme-color` 메타, `<select>` 명시적 색상 |
| **로케일/i18n(Locale & i18n)** | `Intl.DateTimeFormat`/`Intl.NumberFormat` 사용, IP 기반 언어 감지 금지 |
| **하이드레이션 안전성(Hydration Safety)** | `value` + `onChange` 쌍, 날짜/시간 mismatch 방지, `suppressHydrationWarning` 최소화 |
| **호버/인터랙티브 상태(Hover & Interactive)** | `hover:` 피드백, 상태별 대비 증가 |
| **콘텐츠/카피(Content & Copy)** | 능동태, Title Case, 구체적 버튼 라벨, 에러에 해결책 포함 |
| **안티패턴(Anti-patterns)** | zoom 비활성화, paste 차단, `transition: all`, `div` 클릭 핸들러 등 플래그 |

## 출력 형식

결과는 심각도 3단계로 분류하고, 파일별로 그룹화하여 출력합니다.

**심각도 기준:**

| 심각도 | 기준 |
|--------|------|
| **Critical** | 접근성 위반, 보안 문제, 기능 장애 유발 |
| **Warning** | UX 저하, 성능 영향, 가이드라인 미준수 |
| **Info** | 스타일 개선, 모범 사례 권장 |

**출력 예시:**

```text
## src/Button.tsx

Critical:
src/Button.tsx:42 | Accessibility | aria-label 누락 | 아이콘 버튼에 접근성 라벨 필요
src/Button.tsx:18 | Forms | label 누락 | input에 연결된 label 없음

Warning:
src/Button.tsx:55 | Animation | prefers-reduced-motion 미처리 | 모션 감소 선호 사용자 미대응
src/Button.tsx:67 | Animation | transition: all 사용 | 속성 명시적 나열 필요

## src/Card.tsx

✓ pass
```

## 검토 우선순위

1. **접근성/보안** — aria, 시맨틱 HTML, 키보드 접근, zoom 비활성화 등
2. **기능 오류** — 하이드레이션 mismatch, paste 차단, 빈 상태 미처리
3. **UX 개선** — 포커스 상태, 터치 최적화, URL 상태 동기화
4. **스타일** — 타이포그래피, 카피 컨벤션, 호버 상태

## 가이드라인 소스

리뷰 전 최신 가이드라인을 WebFetch로 가져옵니다:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

fetch 실패 시 `references/web-interface-guidelines.md` 로컬 스냅샷을 fallback으로 사용합니다.
