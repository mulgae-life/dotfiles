---
name: Hanwha Group Identity (HW)
version: alpha
description: 한화그룹 비주얼 아이덴티티 범용 디자인 표준. Orange + Navy 2색 대비축 + 한화체(Display·로고) + 한화고딕(본문) + IBM Plex(영문·숫자) 페어링 + AtoZ/Pretendard 폴백 + 네이비 톤 그림자 + 3단계 모션 리듬을 기본 DNA로 한다. 프로젝트 루트에 배치하면 AI 에이전트가 이 파일 하나를 참조해 한화 룩앤필을 재현한다.
colors:
  # ────────────────────────────────────────────────────────────────
  # Brand — 2색 대비축 (Orange + Navy)
  # ────────────────────────────────────────────────────────────────
  primary: "#F37321"               # Hanwha Orange (brand/CTA/focus)
  primary-hover: "#E06A1B"         # hover, gradient end
  primary-pressed: "#C75E14"       # pressed, icon stroke, text focus
  primary-light: "#FFF3EB"         # badge/chip background
  primary-muted: "#FDEEDE"         # subtle hover background

  neutral: "#1A2B4A"               # Hanwha Navy (header/sidebar/body text)
  neutral-light: "#2D4168"         # gradient end, hover
  neutral-muted: "#3D537F"         # secondary text, dividers on navy

  # ────────────────────────────────────────────────────────────────
  # Text — LLM과 audit 스크립트가 참조할 역할 기반 별칭
  # ────────────────────────────────────────────────────────────────
  text-primary: "#1A2B4A"          # 본문 텍스트 (= neutral)
  text-secondary: "#64748B"        # 보조 설명
  text-tertiary: "#94A3B8"         # placeholder, meta
  text-on-primary: "#FFFFFF"       # 오렌지 배경 위 텍스트
  text-on-neutral: "#FFFFFF"       # 네이비 배경 위 텍스트

  # ────────────────────────────────────────────────────────────────
  # Surface & Border — 3 + 2 단계
  # ────────────────────────────────────────────────────────────────
  surface: "#FFFFFF"               # 카드, 모달
  surface-secondary: "#F7F9FC"     # 페이지 배경
  surface-tertiary: "#EEF2F7"      # 테이블 헤더, deep 영역
  border: "#CBD5E0"                # 기본 보더
  border-light: "#E2E8F0"          # 얇은 구분선

  # ────────────────────────────────────────────────────────────────
  # State — 시맨틱 페어 (한화 2색축과 충돌하지 않도록 채도 조율)
  # ────────────────────────────────────────────────────────────────
  success: "#16A34A"
  success-bg: "#DCFCE7"
  warning: "#B45309"
  warning-bg: "#FEF3C7"
  danger: "#DC2626"                # 긴급 (pulse-ring 동반 가능)
  danger-bg: "#FEE2E2"
  info: "#3B82F6"
  info-bg: "#EFF6FF"

typography:
  # ────────────────────────────────────────────────────────────────
  # Display (히어로, 스플래시) — 한화체 (로고 DNA)
  # ────────────────────────────────────────────────────────────────
  display:
    fontFamily: "Hanwha, HanwhaGothic, AtoZ, 'IBM Plex Sans', Pretendard, -apple-system, 'Apple SD Gothic Neo', sans-serif"
    fontSize: 2.75rem
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -0.02em

  # ────────────────────────────────────────────────────────────────
  # Headings — 한화체 (브랜드 위계)
  # ────────────────────────────────────────────────────────────────
  h1:
    fontFamily: "Hanwha, HanwhaGothic, AtoZ, 'IBM Plex Sans', Pretendard, sans-serif"
    fontSize: 2rem
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.015em
  h2:
    fontFamily: "Hanwha, HanwhaGothic, AtoZ, 'IBM Plex Sans', Pretendard, sans-serif"
    fontSize: 1.5rem
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: -0.01em
  h3:
    fontFamily: "Hanwha, HanwhaGothic, AtoZ, 'IBM Plex Sans', Pretendard, sans-serif"
    fontSize: 1.25rem
    fontWeight: 400
    lineHeight: 1.35

  # ────────────────────────────────────────────────────────────────
  # Body — 한화고딕 (5w 가독성). 모바일 15~17px 존 (Tailwind 기본보다 큼)
  # ────────────────────────────────────────────────────────────────
  body-lg:
    fontFamily: "HanwhaGothic, AtoZ, Pretendard, sans-serif"
    fontSize: 1.0625rem             # 17px
    fontWeight: 400
    lineHeight: 1.6
  body:
    fontFamily: "HanwhaGothic, AtoZ, Pretendard, sans-serif"
    fontSize: 0.9375rem             # 15px — 한글 본문 기본
    fontWeight: 400
    lineHeight: 1.6
  body-sm:
    fontFamily: "HanwhaGothic, AtoZ, Pretendard, sans-serif"
    fontSize: 0.8125rem             # 13px — 메타, 보조
    fontWeight: 300                 # 한화고딕 L (300)
    lineHeight: 1.5

  # ────────────────────────────────────────────────────────────────
  # Micro
  # ────────────────────────────────────────────────────────────────
  caption:
    fontFamily: "HanwhaGothic, AtoZ, Pretendard, sans-serif"
    fontSize: 0.75rem               # 12px
    fontWeight: 400
    lineHeight: 1.4
  label-caps:
    fontFamily: "'IBM Plex Sans', HanwhaGothic, AtoZ, sans-serif"
    fontSize: 0.75rem
    fontWeight: 600
    lineHeight: 1
    letterSpacing: 0.2em            # 영문 라벨 (uppercase 권장)
  button:
    fontFamily: "HanwhaGothic, Hanwha, 'IBM Plex Sans', AtoZ, sans-serif"
    fontSize: 0.9375rem
    fontWeight: 400                 # 한화고딕 R (한화체 weight 부재 시 동등 자연스러움)
    lineHeight: 1
  # 숫자·평점·대시보드 지표용
  numeric:
    fontFamily: "'IBM Plex Sans', -apple-system, sans-serif"
    fontSize: 1.5rem
    fontWeight: 600
    lineHeight: 1
    fontFeature: "'tnum' 1, 'lnum' 1"    # tabular + lining numerals

rounded:
  none: 0px
  sm: 4px
  md: 8px                           # chip, small badge
  lg: 12px                          # button, input
  xl: 16px                          # card (기본)
  2xl: 20px                         # CTA 큰 버튼
  3xl: 24px                         # hero modal
  full: 9999px                      # pill, avatar, nav indicator

spacing:
  # 4/8 이중 기반 (4px micro, 8px macro)
  0: 0px
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  xxxl: 80px
  hero: 128px                       # 히어로 상/하단

components:
  # ────────────────────────────────────────────────────────────────
  # Buttons
  # ────────────────────────────────────────────────────────────────
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: 12px 24px
    height: 44px

  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    borderColor: "{colors.primary}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: 12px 24px
    height: 44px

  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.text-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: 12px 20px
    height: 44px

  button-destructive:
    backgroundColor: "{colors.danger}"
    textColor: "{colors.text-on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: 12px 24px
    height: 44px

  # Chip/Pill (Quick actions, filter)
  chip-idle:
    backgroundColor: "{colors.primary-muted}"
    textColor: "{colors.primary-pressed}"
    borderColor: "{colors.primary-light}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.full}"
    padding: 6px 12px
  chip-active:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-on-primary}"
    borderColor: "{colors.primary}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.full}"
    padding: 6px 12px

  # ────────────────────────────────────────────────────────────────
  # Card / Container
  # ────────────────────────────────────────────────────────────────
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border-light}"
    rounded: "{rounded.xl}"         # 16px 기본
    padding: 16px

  card-feature:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border-light}"
    rounded: "{rounded.2xl}"
    padding: 24px

  # ────────────────────────────────────────────────────────────────
  # Input
  # ────────────────────────────────────────────────────────────────
  input:
    backgroundColor: "{colors.surface-secondary}"
    textColor: "{colors.text-primary}"
    borderColor: "{colors.border}"
    typography: "{typography.body-lg}"
    rounded: "{rounded.lg}"
    padding: 12px 16px
    height: 48px

  # ────────────────────────────────────────────────────────────────
  # Badge (state pair)
  # ────────────────────────────────────────────────────────────────
  badge-success:
    backgroundColor: "{colors.success-bg}"
    textColor: "{colors.success}"
    typography: "{typography.caption}"
    rounded: "{rounded.md}"
    padding: 4px 10px
  badge-danger:
    backgroundColor: "{colors.danger-bg}"
    textColor: "{colors.danger}"
    typography: "{typography.caption}"
    rounded: "{rounded.md}"
    padding: 4px 10px
  badge-warning:
    backgroundColor: "{colors.warning-bg}"
    textColor: "{colors.warning}"
    typography: "{typography.caption}"
    rounded: "{rounded.md}"
    padding: 4px 10px
  badge-info:
    backgroundColor: "{colors.info-bg}"
    textColor: "{colors.info}"
    typography: "{typography.caption}"
    rounded: "{rounded.md}"
    padding: 4px 10px

  # ────────────────────────────────────────────────────────────────
  # Navigation
  # ────────────────────────────────────────────────────────────────
  nav-top:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.text-on-neutral}"
    height: 104px                                 # 로고 84px + 브랜드 타이틀 22px 기준 시각 균형
    padding: 0 24px

  # ────────────────────────────────────────────────────────────────
  # Avatar
  # ────────────────────────────────────────────────────────────────
  avatar:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-on-primary}"
    rounded: "{rounded.full}"
    size: 40px

  # ────────────────────────────────────────────────────────────────
  # Brand Logo — 반드시 번들 PNG 사용, SVG/Canvas/코드 자체 제작 금지
  # 배경별 변형 PNG 5종 — 결정 트리는 §Brand Header 참조
  # ────────────────────────────────────────────────────────────────
  brand-logo:
    # on-white 기본 (원본)
    source: "assets/logo/hanwha-tricircle.png"                       # 707×353 · symbol(컬러) + wordmark(검정)
    favicon: "assets/logo/favicon.png"                               # 154×140 · symbol only(컬러)
    # on-navy 변형 (원본의 색상 변환 시안 — references/brand-identity.md)
    source-on-navy: "assets/logo/hanwha-tricircle-on-navy.png"       # symbol(컬러) + wordmark(흰) — on-navy 헤더 기본
    source-mono-white: "assets/logo/hanwha-tricircle-mono-white.png" # 전체 흰색 — on-navy 스플래시·히어로·풋터 inverse
    source-symbol-white: "assets/logo/tricircle-symbol-white.png"    # 심볼만 흰색 — on-navy 모바일 축약
    # 사이즈
    height-nav: 56px                              # Top Nav 104px 기준 (변형 PNG 직접 사용)
    height-hero: 96px                             # Hero 섹션 (96~128px 범위)
    height-mobile: 32px                           # 모바일 헤더 축약 (Nav 56px)
    height-footer: 28px                           # 푸터 (on-white)
    safezone: "height / 2"

  # DEPRECATED: 변형 PNG 도입으로 더 이상 권장되지 않음. 변형 PNG 미배포 환경에서만 fallback.
  brand-logo-box:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "2px 10px"
    shadow: "0 2px 8px rgba(26, 43, 74, 0.18)"

  # 브랜드 헤더 — 로고 옆 한글 서비스명(타이틀) 의 시각 균형
  brand-header:
    gap: "{spacing.sm}"                           # 로고 ↔ 타이틀 사이 12px
    titleFontSize: 1.375rem                       # 22px — h2(24) 바로 아래. Nav 104 / 로고 84 와 균형
    titleFontWeight: 700
    titleLetterSpacing: -0.015em                  # 한글 제목은 음의 자간으로 짜임새 확보

# ──────────────────────────────────────────────────────────────────
# Extended tokens — 공식 스펙의 known 타입은 아니지만 린터가 보존함
# (spec: "unknown token names and properties are accepted with warnings")
# ──────────────────────────────────────────────────────────────────

# 그림자: 검정이 아니라 네이비 rgba — 브랜드 통일
shadows:
  card: "0 2px 12px 0 rgba(26, 43, 74, 0.08)"
  card-hover: "0 8px 24px 0 rgba(26, 43, 74, 0.14)"
  modal: "0 20px 60px 0 rgba(26, 43, 74, 0.20)"
  glass: "0 4px 24px 0 rgba(26, 43, 74, 0.06)"
  elevated: "0 18px 45px rgba(26, 43, 74, 0.16)"
  bubble: "0 10px 30px rgba(15, 23, 42, 0.06)"
  bubble-accent: "0 10px 24px rgba(243, 115, 33, 0.22)"
  toast: "0 12px 40px rgba(26, 43, 74, 0.30)"
  glow: "0 0 20px rgba(243, 115, 33, 0.25)"

gradients:
  navy: "linear-gradient(135deg, #1A2B4A 0%, #2D4168 100%)"
  navy-3stop: "linear-gradient(135deg, #1A2B4A 0%, #2D4168 40%, #1A2B4A 100%)"
  primary: "linear-gradient(135deg, #F37321 0%, #E06A1B 100%)"
  primary-h: "linear-gradient(90deg, #F37321, #E06A1B)"
  page-bg: "linear-gradient(180deg, #F7F9FC 0%, #EEF2F6 100%)"
  page-bg-light: "linear-gradient(155deg, #F8FAFC 0%, #EBF0F7 50%, #E3EBF5 100%)"

motion:
  # 단 3단계 duration (임의 값 금지)
  fast: 250ms        # 메시지/버블
  base: 350ms        # 카드/일반 전환
  slow: 550ms        # 페이지/스플래시
  ease: cubic-bezier(0.4, 0, 0.2, 1)
  spring: cubic-bezier(0.175, 0.885, 0.32, 1.275)
  stagger: 70ms      # 리스트 index * 이 값
---

## Overview

한화그룹 비주얼 아이덴티티를 디지털 제품에 옮긴 **범용 표준**이다. 브랜드 에센스 "Energy for Life"와 트리서클이 상징하는 **조화·확장·신뢰**를 레이아웃·위계·모션으로 번역했다. 특정 프로젝트에 의존하지 않도록 프레임워크 중립 토큰만 담았다.

**설계 원칙**

1. **2색 대비축**: Primary(Hanwha Orange) + Neutral(Hanwha Navy) **만**으로 전체 UI를 구성. 세컨더리 컬러를 추가하지 않는다 — 브랜드가 시끄러워지는 순간 신뢰감이 깎인다.
2. **토큰만 쓴다**: 인라인 hex/px 금지. 재브랜딩이나 다크모드 확장이 토큰 한 곳 수정으로 끝나야 한다.
3. **그래디언트·그림자도 브랜드 톤**: 그림자는 검정 대신 `rgba(26, 43, 74, x)` (네이비). 색의 일관성이 품격을 만든다.
4. **모션은 3단계**: 250/350/550ms 세 구간만. 임의 duration 생성 금지.
5. **한글 가독성이 품격을 만든다**: 본문 최소 15px, `word-break: keep-all`, 양의 자간 금지.
6. **터치 우선 설계**: 터치 타겟 ≥ 44×44px. `:hover`에만 의존하지 않는다 — `:active` 와 `focus-visible` 병행.
7. **3단계 계층감**: 배경 → 카드(`shadow.card`) → 플로팅(`shadow.modal`) 세 레이어로만 깊이 표현.

**재현 목표**: 어느 프로젝트에서든 이 `DESIGN.md` 하나만 보이면 AI가 같은 한화 룩앤필을 낸다.

## Colors

### 시그니처 2축

| 역할 | 토큰 | Hex | 용도 |
|------|------|-----|------|
| **Primary** | `primary` | `#F37321` | CTA 버튼, 액티브 탭, 포커스 링, 강조 아이콘 |
| Primary Hover | `primary-hover` | `#E06A1B` | hover 종료 색, 그래디언트 끝 |
| Primary Pressed | `primary-pressed` | `#C75E14` | pressed, 외곽선, 텍스트 포커스 |
| Primary Light | `primary-light` | `#FFF3EB` | 배지/칩 배경 |
| Primary Muted | `primary-muted` | `#FDEEDE` | subtle hover 배경 |
| **Neutral** | `neutral` | `#1A2B4A` | 헤더/사이드바 배경, 본문 텍스트 |
| Neutral Light | `neutral-light` | `#2D4168` | 그래디언트 끝, hover |
| Neutral Muted | `neutral-muted` | `#3D537F` | 보조 텍스트, 구분선 (on-navy 위) |

> **사용 비율**: Primary는 화면 면적 ≤ 20%. CTA/브랜딩 포인트/핵심 강조에만. 오렌지 위에 오렌지를 쌓지 않는다.

### 텍스트

`text-primary` / `text-secondary` / `text-tertiary` 는 **역할 기반 alias**다. 본문은 `#1A2B4A` (neutral과 동일 — 순검정 `#000000` 쓰지 않는다, 디지털에서 눈부심이 심해진다).

### 서피스·보더

3단 서피스(`surface` / `secondary` / `tertiary`) + 2단 보더(`border` / `border-light`)로 레이어 구성.

### 상태

`success/warning/danger/info` 각각 **글자색 + 배경색 페어**로 제공 — 배지는 바로 `bg=state-bg, text=state` 로 쓰면 된다. `danger`는 긴급 상황에 pulse-ring 애니메이션을 덧붙일 수 있다.

## Typography

### 폰트 페어링

- **Hanwha (한화체)** — 한화 로고 DNA를 잇는 **Display·헤딩 전용** 서체. 3-weight (Light 300 / Regular 400 / Bold 700). `assets/fonts/Hanwha/` 에 번들 (woff2 + woff + ttf). 한화그룹 공식 BI 폰트.
- **HanwhaGothic (한화고딕)** — **본문·UI 전용**. 5-weight (Thin 100 / ExtraLight 200 / Light 300 / Regular 400 / Bold 700). `assets/fonts/HanwhaGothic/` 에 번들 (woff2). 한화그룹 공식 본문 서체.
- **IBM Plex Sans** — 영문·숫자 강조. 대시보드 지표, 평점, 라벨(uppercase)에 사용. Variable font 번들. `tabular-nums`·`lining-nums` 기본.
- **AtoZ (에이투지체)** — 한화 폰트 로드 실패 시 폴백. 9-weight 번들 유지.
- **Pretendard** — 마지막 한글 폴백.

> 한화체와 한화고딕의 라이선스 출처·사용 권한은 [`references/font-license.md`](../references/font-license.md) 참조. 한화그룹 IP — 외부 재배포 금지.

### 스케일 요약 (rem 기반, 루트 16px 가정)

| 토큰 | Size | Weight | LH | 용도 |
|------|------|--------|-----|------|
| `display` | 44px | 700 | 1.15 | 히어로 헤드라인 (한화체 B) |
| `h1` | 32px | 700 | 1.2 | 페이지 타이틀 (한화체 B) |
| `h2` | 24px | 700 | 1.25 | 섹션 헤더 (한화체 B) |
| `h3` | 20px | 400 | 1.35 | 서브 헤더 (한화체 R) |
| `body-lg` | 17px | 400 | 1.6 | 리드 문단, 인풋 (한화고딕 R) |
| `body` | **15px** | 400 | 1.6 | **본문 기본** (한화고딕 R) |
| `body-sm` | 13px | 300 | 1.5 | 메타, 보조 (한화고딕 L) |
| `caption` | 12px | 400 | 1.4 | 태그, 타임스탬프 (한화고딕 R) |
| `label-caps` | 12px | 600 | 1 | 영문 uppercase 라벨 (자간 0.2em) |
| `button` | 15px | 400 | 1 | 버튼 라벨 (한화고딕 R) |
| `numeric` | 24px | 600 | 1 | 숫자 지표 (tabular, IBM Plex) |

### 한글 타이포 규칙

- **자간**: 제목은 `-0.01 ~ -0.02em` (음의 자간). 본문·그 이하는 **자간 0** (한글은 기본 자간이 이미 넓다 — 양의 자간 금지).
- **줄바꿈**: `word-break: keep-all; overflow-wrap: break-word;` — 단어 단위 끊김 방지.
- **mix-weight**: 한 페이지에서 동시 사용 weight ≤ 3단계 (보통 300/400/700 — 한화고딕 L/R + 한화체 B).

### 그래디언트 텍스트

오렌지 그래디언트 텍스트는 브랜드 강조용. 사용 시:
```css
background: var(--gradient-primary);
-webkit-background-clip: text;
color: transparent;
```

## Layout

### 반응형 브레이크포인트

| 이름 | 폭 | 동작 |
|------|------|------|
| mobile | `< 640px` | 단일 컬럼, 사이드바 drawer |
| tablet | `640–1023px` | 2컬럼 가능, 사이드바 선택 |
| desktop | `1024–1439px` | 풀 레이아웃, max-width 1280 |
| wide | `≥ 1440px` | max-width 1440 (대시보드만 확장) |

### 그리드

- **12컬럼**, gutter 16(mobile) / 24(tablet) / 32(desktop)
- **Max content width**: 1280px 기본 / 1440px 대시보드
- **Edge padding**: mobile `md(16)`, tablet `lg(24)`, desktop `xl(32)`

### 간격 (8pt + 4pt 이중 grid)

- 컴포넌트 내부: `xxs(4)` ~ `sm(12)`
- 컴포넌트 간: `md(16)` ~ `lg(24)`
- 섹션 간: `xxl(48)` ~ `xxxl(80)`
- 히어로: `hero(128)` 상/하

### Touch & Safe Area

- 터치 타겟 ≥ 44×44px (WCAG AA+)
- 모바일 하단 패딩: `pb-[calc(0.5rem + env(safe-area-inset-bottom))]` 패턴

### Z-index 계층

| Z | 역할 |
|---|------|
| 10 | 고정된 입력 영역 |
| 30 | sticky 헤더 |
| 40 | 토스트 |
| 50 | 모달·드롭다운·스플래시 |

## Elevation & Depth

**기본은 플랫**. 상호작용이나 계층 분리가 필요한 순간에만 그림자로 깊이를 만든다. 그림자 색은 **네이비 rgba** — 이게 한화 톤의 핵심.

| 토큰 | 용도 | 값 |
|------|------|-----|
| `shadows.card` | 카드 기본 | `0 2px 12px 0 rgba(26, 43, 74, 0.08)` |
| `shadows.card-hover` | hover된 카드 | `0 8px 24px 0 rgba(26, 43, 74, 0.14)` |
| `shadows.modal` | 모달·드롭다운 | `0 20px 60px 0 rgba(26, 43, 74, 0.20)` |
| `shadows.glass` | 글래스모피즘 | `0 4px 24px 0 rgba(26, 43, 74, 0.06)` |
| `shadows.elevated` | 플로팅 패널 | `0 18px 45px rgba(26, 43, 74, 0.16)` |
| `shadows.bubble` | 메시지 버블 | `0 10px 30px rgba(15, 23, 42, 0.06)` |
| `shadows.bubble-accent` | 오렌지 버블 | `0 10px 24px rgba(243, 115, 33, 0.22)` |
| `shadows.toast` | 토스트 | `0 12px 40px rgba(26, 43, 74, 0.30)` |
| `shadows.glow` | 브랜드 글로우 | `0 0 20px rgba(243, 115, 33, 0.25)` |

**3단계 계층감**: 배경(flat) → 카드(`shadows.card`) → 플로팅(`shadows.modal`). 그 이상은 만들지 않는다.

### 글래스모피즘 레시피

```css
background: rgba(255, 255, 255, 0.85);
backdrop-filter: blur(12px);
border: 1px solid rgba(255, 255, 255, 0.6);
box-shadow: var(--shadow-glass);
```

## Shapes

트리서클의 **원형 조화**를 UI에 무리하게 옮기지 않는다. 대부분은 부드럽지만 과하지 않은 라운딩.

| 토큰 | 값 | 용도 |
|------|-----|------|
| `rounded.none` | 0 | 테이블 셀, 풀블리드 배너 |
| `rounded.sm` | 4px | 인라인 태그 |
| `rounded.md` | 8px | **배지·칩**, small badge |
| `rounded.lg` | 12px | **버튼·인풋** |
| `rounded.xl` | 16px | **카드 기본** |
| `rounded.2xl` | 20px | CTA 큰 버튼 |
| `rounded.3xl` | 24px | hero 모달 |
| `rounded.full` | 9999px | pill, avatar, nav indicator |

**원칙**: 한 페이지에 3종 이상 라운딩 섞지 않는다. 버튼과 인풋은 동일 라운딩(`lg`)으로 리듬을 맞춘다.

## Components

### Button

| Variant | 용도 | 핵심 속성 |
|---------|------|-----------|
| **primary** | 주요 액션 1개/화면 | `primary` 배경, 흰 텍스트, `rounded.lg`, height 44 |
| **secondary** | 보조 액션 | 흰 배경, `primary` 1px 테두리 + 텍스트 |
| **ghost** | 인라인 액션 | 배경 없음, hover 시 `surface-secondary` |
| **destructive** | 삭제·파괴적 | `danger` 배경, 흰 텍스트 |

**상태**
- `hover`: `primary-hover` 로 전환, 250ms `motion.ease`
- `active`: `primary-pressed` + `active:scale-95` (터치 피드백)
- `focus-visible`: 외부 2px `primary` 링 (outline-offset 2px) — 접근성 필수
- `disabled`: `opacity: 0.4`, `cursor: not-allowed`

**사이즈**: sm (h 36, pad `xs md`) / md (h 44, pad `sm lg`) / lg (h 52, pad `md xl`)

### Card

- **기본**: `surface` 배경, `rounded.xl`, `border-light` 1px, `shadows.card`.
- **Hoverable**: hover 시 `shadows.card-hover` + 선택적 `translateY(-3px)`. 전환 350ms.
- **Padding**: 기본 `md(16)`, feature 카드 `lg(24)`.

### Input / Form

- **Border**: 기본 `border` 1px.
- **Focus**: border → `primary`, 배경 `surface-secondary` → `surface` 로 elevation. 외부 2px `primary` 링(40% 투명도) 옵션.
- **Error**: border `danger` + 하단 `caption` 크기 에러 메시지 (`danger` 컬러).
- **Height**: 48px (`body-lg` 17px 와 조화).
- **Label**: 인풋 위 6~8px 간격, `body-sm`, `text-secondary`.

### Navigation

- **Top Bar**: `neutral` 배경, 높이 64px, `sticky top-0 z-30`. 하단 1px `border-light` (on-light 버전) 또는 없음(on-navy).
- **Logo 영역**: 좌측. 트리서클 로고의 세이프존은 로고 높이의 1/2 이상.
- **Menu Item**: `body` 크기, `text-on-neutral`. active 시 `primary` 배경 + 흰 텍스트, 또는 좌측 3px `primary` 인디케이터 막대.
- **Mobile**: 햄버거 → 전폭 drawer. 드로어 헤더는 `neutral` 그래디언트.

### Brand Header (로고)

**MUST**: 번들 PNG 5종(`assets/logo/`) 만 사용한다. SVG/Canvas/코드로 트리서클을 재현하지 않는다 — 원 3개 겹치기, 유사 오렌지 그래디언트 전부 금지. CI 일관성 + 법무 안전.

**번들 5종**:

| 파일 | 구성 | 용도 |
|------|------|------|
| `hanwha-tricircle.png` | symbol(컬러) + wordmark(검정) | on-white 기본 — 일반 페이지·푸터 |
| `hanwha-tricircle-on-navy.png` | symbol(컬러) + wordmark(흰) | **on-navy 헤더 기본** |
| `hanwha-tricircle-mono-white.png` | 전체 흰색(농도 분리) | on-navy 스플래시·히어로·풋터 inverse |
| `favicon.png` | symbol only(컬러) | 파비콘 |
| `tricircle-symbol-white.png` | symbol only(흰) | on-navy 모바일 축약 |

> ⚠️ on-navy/mono-white/symbol-white 는 원본의 **색상 변환 시안**. 비율·형태는 100% 보존. 한화손보 BI 공식 mono/inverse 자산 도착 시 교체 권장 (`references/brand-identity.md`).

#### 배경별 변형 결정 트리

검정 wordmark 의 원본을 네이비 위에 그대로 올리면 글자가 묻힌다. **흰 박스 컨테이너로 감싸는 방식 대신, 배경에 맞는 변형을 직접 사용**한다.

```
배경이 어두운가? (네이비 #1A2B4A 등)
├── YES (on-navy)
│   ├── 헤더 기본 (컬러 + 흰 wordmark)        → hanwha-tricircle-on-navy.png
│   ├── 스플래시·히어로·풋터 inverse (전체 흰) → hanwha-tricircle-mono-white.png
│   └── 모바일 헤더 축약·뱃지 (심볼만)         → tricircle-symbol-white.png
└── NO (on-white)
    └── 일반 페이지·푸터                       → hanwha-tricircle.png (원본)
```

> 이전 권장이던 흰 박스 컨테이너(`brand-logo-box`)는 변형 PNG 가 모두 갖춰진 현재로선 사용하지 않는다 (필요 시 fallback 으로만).

#### on-navy — Top Nav 기본 (Variant A)

```html
<div class="brand">
  <img src="/public/logo/hanwha-tricircle-on-navy.png" alt="한화손보" class="brand__logo"/>
</div>
```
```css
.brand {
  display: flex; align-items: center; gap: var(--sp-sm);
}
.brand__logo {
  height: 56px;             /* brand-logo.height-nav — Top Nav 104px 전제 */
  width: auto; object-fit: contain; display: block;
}
```

#### on-navy — 스플래시·히어로 / 풋터 inverse (Variant B)

```html
<img src="/public/logo/hanwha-tricircle-mono-white.png" alt="한화손보" class="brand__logo brand__logo--hero"/>
```
```css
.brand__logo--hero { height: 96px; }   /* brand-logo.height-hero — 또는 더 크게 */
```

#### on-navy — 모바일 헤더 축약 (Variant C)

```html
<img src="/public/logo/tricircle-symbol-white.png" alt="한화손보" class="brand__logo brand__logo--symbol"/>
```
```css
.brand__logo--symbol { height: 32px; }  /* brand-logo.height-mobile */
```

#### on-white — 일반 페이지·푸터 (원본)

```html
<img src="/public/logo/hanwha-tricircle.png" alt="한화손보" class="brand__logo"/>
```

#### 사이즈

| 위치 | 배경 | 사용 변형 | Nav 높이 | 로고 이미지 높이 |
|------|------|----------|---------|----------------|
| Top Nav (데스크톱) | navy | `-on-navy.png` | 104px (`nav-top.height`) | 56px (`brand-logo.height-nav`) |
| Hero splash | navy | `-mono-white.png` | — | 96–128px (`brand-logo.height-hero`) |
| Footer (on-navy inverse) | navy | `-mono-white.png` | — | 24–28px |
| Mobile compact header | navy | `tricircle-symbol-white.png` | 56px | 32px (`brand-logo.height-mobile`) |
| Footer (on-white) | white | `hanwha-tricircle.png` (원본) | — | 24–28px (`brand-logo.height-footer`) |
| Favicon | — | `favicon.png` (원본) | — | favicon.png 사용 |

**브랜드 타이틀 폰트** (`brand-header.title*`, 로고 옆 별도 서비스명 텍스트가 있을 경우): `1.375rem (22px)` · `weight 700` · `letter-spacing -0.015em`.

세이프존은 로고 높이의 1/2 이상.

#### 금지

- **코드로 트리서클 재현** (SVG `<circle>` 3개 겹치기, Canvas drawing, 유사 오렌지 그래디언트)
- **on-navy 배경에 원본(`hanwha-tricircle.png`) 단독 배치** — 검은 wordmark 가 묻힌다. 변형 PNG(`-on-navy` / `-mono-white` / `tricircle-symbol-white`) 로 교체.
- **로고 색·비율·세이프존 변형**, 트리서클 심볼만 따로 잘라 쓰기 (대신 번들 `tricircle-symbol-white.png` / `favicon.png` 사용)

### Badge

- Solid 페어 4종(success/warning/danger/info): `bg = state-bg`, `text = state`.
- Outline 변형: 투명 배경 + 1px `border`.
- 페이지 내에서 같은 카테고리 배지는 같은 모서리(`rounded.md` 또는 `rounded.full`)로 통일.

### Chip / Pill (Quick Action)

- **Idle**: `primary-muted` 배경, `primary-pressed` 텍스트, `primary-light` 1px border, `rounded.full`.
- **Active**: `primary` 배경, 흰 텍스트.
- 터치 피드백: `active:scale(0.95)` + `motion.fast`.

### Avatar

- `rounded.full`, 기본 40px.
- 단색 `primary` 배경 또는 `gradients.primary` 그래디언트 + 흰 이니셜.
- 카테고리별 차별이 필요하면 gradient alias를 프로젝트 쪽 `DESIGN.md` 연장판에 추가 (예: `gradient-avatar-a`, `-b`).

### Nav Active Indicator (좌측 막대)

```css
left: 0; top: 50%; transform: translateY(-50%);
width: 3px; height: 60%;
background: var(--color-primary);
border-radius: 0 2px 2px 0;
```

### Focus Ring (접근성)

```css
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

모든 interactive 요소는 이 링을 가진다 — 키보드 네비게이션 보장.

## Do's and Don'ts

### ✅ Do

- **토큰만 쓴다**. `var(--color-*)`, `{colors.*}`, `theme.colors.*` — 인라인 hex/px은 audit 스크립트가 잡아낸다.
- **Primary는 포인트**. 화면 면적 ≤ 20%. CTA 하나, 강조 하나.
- **그림자는 네이비 톤**. 검정 그림자는 브랜드 일관성을 깬다.
- **본문은 15px 이상**, `line-height ≥ 1.5`, `keep-all` 줄바꿈.
- **모션은 250/350/550ms** 세 단계만.
- **터치 타겟 ≥ 44×44px**, `focus-visible` 링 필수.

### ❌ Don't

- **오렌지 위에 오렌지 쌓기** (배경 오렌지 + 버튼 오렌지). 계층이 붕괴한다.
- **그라디언트·네온 남용**. 한화는 단색 기조가 기본. 그라디언트는 히어로·아바타·프로그레스 등 제한된 포인트에만.
- **순검정 `#000000`을 본문 텍스트에** 사용. 디지털에선 `text-primary (#1A2B4A)`.
- **한글에 양의 자간**. 한글 자형이 훼손된다.
- **3종 이상 라운딩 혼용**. 페이지가 어수선해진다.
- **트리서클 로고 색·비율 변형**. CI 가이드 준수.
- **트리서클을 SVG/Canvas/코드로 자체 제작** — 원 3개 겹치기, 유사 오렌지 그래디언트, 비율이 같아 보여도 전부 금지. 번들 PNG 5종(`assets/logo/`)만 사용.
- **on-navy 배경에 원본(`hanwha-tricircle.png`) 단독 배치** — 검은 wordmark 가 묻힌다. on-navy 변형(`-on-navy` / `-mono-white` / `tricircle-symbol-white`)으로 교체 (배경별 결정 트리는 §Brand Header 참조).
- **임의 duration 생성** (예: `0.4s`, `600ms`). `motion.fast/base/slow` 중 하나만 선택.
- **세컨더리 컬러 추가**. 2색 체계(오렌지+네이비)가 한화 DNA의 핵심.

---

## Extended — Patterns (공식 8섹션 밖, 참고 레시피)

아래는 공식 DESIGN.md 스펙의 필수 섹션이 아니고 **실무 패턴 레시피**다. 공식 린터는 "unknown sections"으로 보존한다.

### Card 등장 애니메이션 (Framer Motion 예)
```tsx
initial={{ opacity: 0, y: 12 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.35, delay: index * 0.07 }}
whileHover={{ y: -3 }}
whileTap={{ scale: 0.98 }}
```

### 메시지 버블 (대화형 UI)
```tsx
initial={{ opacity: 0 }}
animate={{ opacity: 1 }}
transition={{ duration: 0.25 }}
```

### 스플래시 패턴
- `neutral` 3-stop 그래디언트 배경
- 좌하·우상에 radial `primary` 스팟 (opacity 10%)
- 40px 그리드 패턴 오버레이 (opacity 5%)
- 중앙 흰색 라운드 로고 + ping 링 2px `primary`
- 로고 밑 태그라인 + width 0→100% `primary-h` 그래디언트 프로그레스바 (1.2s)

### Custom Scrollbar
```css
::-webkit-scrollbar { width: 5px; height: 5px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #CBD5E0; border-radius: 99px; }
::-webkit-scrollbar-thumb:hover { background: #A0AEC0; }
```

### Keyword Highlight
```css
mark.kw-hit {
  background: linear-gradient(180deg,
    rgba(243, 115, 33, 0.14),
    rgba(243, 115, 33, 0.24));
  color: var(--color-neutral);
  font-weight: 700;
  padding: 0 4px;
  border-radius: 999px;
}
```

### Stream Fade-out (가로 스크롤 힌트)
```tsx
<div className="pointer-events-none absolute inset-y-0 right-0 w-10
                bg-gradient-to-l from-white via-white/85 to-transparent" />
```
