# 디자인 시스템 (Design System)

> `ai_assist` 프로젝트에서 정리한 Tailwind + Framer Motion 기반 디자인 시스템입니다.
> 다른 프로젝트에 이식할 때 이 문서 하나로 색/그림자/애니메이션/컴포넌트 패턴을 옮길 수 있도록 정리했습니다.
> 브랜드 컬러(오렌지/네이비)는 그대로 쓰거나, 같은 키를 유지한 채 값만 교체하면 모든 스타일이 자동으로 재배색됩니다.

---

## 🎨 1. 컬러 팔레트 (Color Tokens)

### 1.1 브랜드 컬러 — Primary & Neutral 두 축

| 역할 | 토큰 | HEX | 용도 |
|------|------|------|------|
| **Primary (강조)** | `brand.orange` | `#F37321` | CTA 버튼, 액티브 탭, 포커스 링, 액센트 |
| | `brand.orange-dark` | `#E06A1B` | 그래디언트 끝점, hover |
| | `brand.orange-deeper` | `#C75E14` | 아이콘 외곽선, 텍스트 포커스 |
| | `brand.orange-light` | `#FFF3EB` | 배지/칩 배경 |
| | `brand.orange-muted` | `#FDEEDE` | Subtle hover 배경 |
| **Neutral (프레임)** | `brand.navy` | `#1A2B4A` | 헤더/사이드바 배경, 본문 텍스트 |
| | `brand.navy-light` | `#2D4168` | 그래디언트 끝점 |
| | `brand.navy-muted` | `#3D537F` | 보조 텍스트, 구분선 |

> **구조 원칙**: Primary 오렌지 1색 + Neutral 네이비 1색이 **대비축**을 만들고, 모든 UI는 이 두 축을 기반으로 구성. 세컨더리 컬러는 쓰지 않음 → 집중도 ↑.

### 1.2 서피스(Surface) & 보더

| 토큰 | HEX | 용도 |
|------|------|------|
| `surface.DEFAULT` | `#FFFFFF` | 카드, 모달 |
| `surface.secondary` | `#F7F9FC` | 페이지 배경 |
| `surface.tertiary` | `#EEF2F7` | Deep 배경 (테이블 헤더 등) |
| `border.light` | `#E2E8F0` | 얇은 구분선 |
| `border.DEFAULT` | `#CBD5E0` | 기본 보더 |

### 1.3 시맨틱 컬러 (상태 표현)

카드/배지/뱃지에서 반복적으로 쓰이는 페어:

```ts
// 성공 (발송 완료, 긍정 상태)
{ bg: "#DCFCE7", text: "#16A34A" }

// 긴급 (urgent — pulse-ring 애니메이션 동반)
{ bg: "#FEE2E2", text: "#DC2626" }

// 여성 / 감성 톤
{ bg: "#FDF2F8", text: "#EC4899" }

// 남성 / 정보 톤
{ bg: "#EFF6FF", text: "#3B82F6" }

// 강조 — 오렌지 카테고리
{ bg: "#FFF7ED", text: "#C2571A", border: "#FED7AA" }

// 북마크 / 경고 (amber)
{ bg: "#FBBF24", text: "#1A2B4A" }
```

### 1.4 그래디언트 (Design Tokens로 관리)

`lib/design-tokens.ts` 패턴 — **Tailwind 클래스로 표현 불가한 복합 CSS는 토큰 객체로 중앙화**.

```ts
export const GRADIENT = {
  navy:       "linear-gradient(135deg, #1A2B4A 0%, #2D4168 100%)",
  orange:     "linear-gradient(135deg, #F37321 0%, #E06A1B 100%)",
  orangeH:    "linear-gradient(90deg,  #F37321, #E06A1B)",            // 프로그레스바
  pageBg:     "linear-gradient(180deg, #F7F9FC 0%, #EEF2F6 100%)",    // 콘텐츠 페이지
  pageBgLight:"linear-gradient(155deg, #F8FAFC 0%, #EBF0F7 50%, #E3EBF5 100%)", // 로그인/로그아웃
} as const;

// 3-stop 네이비 (스플래시 전용 — 깊이감 강조)
// "linear-gradient(135deg, #1A2B4A 0%, #2D4168 40%, #1A2B4A 100%)"
```

---

## 🌓 2. 그림자 시스템 (Shadow)

**대비 그림자**: 밝은 면(화이트 카드) + 어두운 rgba 그림자로 고도감 표현.
네이비(`26,43,74`)를 rgba 기반으로 재사용 → **컬러 통일성** 유지.

```ts
boxShadow: {
  card:          "0 2px 12px 0 rgba(26, 43, 74, 0.08)",   // 기본 카드
  "card-hover":  "0 8px 24px 0 rgba(26, 43, 74, 0.14)",   // hover 시
  modal:         "0 20px 60px 0 rgba(26, 43, 74, 0.20)",  // 모달/드롭다운
  glass:         "0 4px 24px 0 rgba(26, 43, 74, 0.06)",   // 글래스모피즘
  elevated:      "0 18px 45px rgba(26, 43, 74, 0.16)",    // 플로팅 패널
  bubble:        "0 10px 30px rgba(15, 23, 42, 0.06)",    // 메시지 버블
  "bubble-accent": "0 10px 24px rgba(243, 115, 33, 0.22)",// 오렌지 버블
  toast:         "0 12px 40px rgba(26, 43, 74, 0.3)",     // 토스트
  glow:          "0 0 20px rgba(243, 115, 33, 0.25)",     // 브랜드 글로우
}

// 인라인 전용 (특수 컨텍스트)
export const SHADOW = {
  splashGlow:   "0 0 40px rgba(243, 115, 33, 0.5)",   // 스플래시 로고
  stepGlow:     "0 6px 16px rgba(243, 115, 33, 0.24)",// 챗봇 step
  searchButton: "0 14px 30px rgba(243, 115, 33, 0.22)",
};
```

---

## 🔤 3. 타이포그래피

### 3.1 폰트 패밀리

```ts
fontFamily: {
  // 본문 — 한국어 최적화 (A2Z 9-weight)
  sans: ["A2Z", "-apple-system", "BlinkMacSystemFont",
         "Apple SD Gothic Neo", "Malgun Gothic", "system-ui", "sans-serif"],

  // 숫자/영문 강조 — 대시보드 지표, 평점
  plex: ["var(--font-plex)", "IBM Plex Sans", "-apple-system",
         "BlinkMacSystemFont", "system-ui", "sans-serif"],
}
```

**A2Z 폰트**: `public/fonts/에이투지체-*.woff2` 9-weight (100~900) 모두 `font-display: swap` 로 로드.
다른 프로젝트 이식 시 Pretendard / Noto Sans KR 로 교체 가능.

### 3.2 타이포그래피 규칙

- **본문**: `text-[15px]` ~ `text-[17px]` — 모바일 가독성 우선 (Tailwind 기본 `text-sm`/`text-base`보다 큰 값 사용)
- **한글 줄바꿈**: `word-break: keep-all; overflow-wrap: break-word;` (단어 단위 끊김 방지)
- **제목**: `font-bold tracking-tight` + `text-hanwha-navy`
- **보조 텍스트**: `text-gray-400` ~ `text-gray-500`
- **라벨**: `text-[12px] font-semibold tracking-[0.2em]` + `uppercase` (영문만)

### 3.3 그래디언트 텍스트

```css
.gradient-text {
  background: linear-gradient(135deg, #F37321 0%, #E06A1B 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

### 3.4 Prose (마크다운/약관 렌더링)

`.comp-prose` 클래스로 HTML/Markdown 콘텐츠를 브랜드 스타일에 맞게 렌더:
- `h1~h4`: `font-weight: 700`, 색상 = 네이비
- `li::marker`: 오렌지
- `blockquote`: 좌측 3px 오렌지 보더 + `#FFFBF5` 배경 + 우측 둥근 모서리
- `code`: `#F1F5F9` 배경 + `#E2E8F0` 보더 + 네이비 텍스트

---

## 🎬 4. 애니메이션 & 모션

### 4.1 Keyframes (globals.css + tailwind.config.ts)

```css
/* 메시지/카드 등장 */
@keyframes fadeInUp {
  0%   { opacity: 0; transform: translateY(12px); }
  100% { opacity: 1; transform: translateY(0); }
}
/* = 0.35~0.4s ease-out */

/* 리스트 슬라이드 */
@keyframes slideInLeft {
  0%   { opacity: 0; transform: translateX(-16px); }
  100% { opacity: 1; transform: translateX(0); }
}

/* 타이핑 도트 (챗봇 "입력중" 표시) */
@keyframes typingBounce {
  0%, 60%, 100% { transform: translateY(0); opacity: 0.6; }
  30%           { transform: translateY(-6px); opacity: 1; }
}
/* 3개 도트, 각 0.2s delay, 1.4s infinite */

/* 긴급 배지 pulse ring */
@keyframes pulseRing {
  0%   { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
  70%  { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}

/* 스트리밍 커서 (LLM 스트림) */
@keyframes streaming-cursor-blink {
  0%, 100% { opacity: 1; }
  50%      { opacity: 0; }
}

/* 토스트 */
@keyframes toastIn {
  0%   { opacity: 0; transform: translateY(20px) scale(0.95); }
  100% { opacity: 1; transform: translateY(0) scale(1); }
}

/* Shimmer (스켈레톤 로딩) */
@keyframes shimmerMove {
  0%   { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

/* 브랜드 글로우 */
@keyframes pulseGlow {
  0%, 100% { box-shadow: 0 0 0 0 rgba(243, 115, 33, 0.3); }
  50%      { box-shadow: 0 0 16px 4px rgba(243, 115, 33, 0.15); }
}

/* 스플래시 */
@keyframes splashFadeIn  { 0% { opacity: 0; transform: scale(0.92); } 100% { opacity: 1; transform: scale(1); } }
@keyframes splashFadeOut { 0% { opacity: 1; } 100% { opacity: 0; pointer-events: none; } }
```

### 4.2 Tailwind 유틸리티

```ts
animation: {
  "bounce-dot":    "bounceDot 1.4s ease-in-out infinite",
  "fade-in-up":    "fadeInUp 0.4s ease-out",
  "fade-in":       "fadeIn 0.3s ease-out",
  "slide-in-left": "slideInLeft 0.4s ease-out",
  shimmer:         "shimmer 1.5s infinite",
}
```

### 4.3 Framer Motion 표준 패턴

**카드 등장**:
```tsx
<motion.div
  initial={{ opacity: 0, y: 12 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.3, delay: index * 0.07 }}  // 스태거
  whileHover={{ y: -3 }}
  whileTap={{ scale: 0.98 }}
/>
```

**메시지 버블**:
```tsx
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 0.25 }}
/>
```

**버튼(활성 상태만 인터랙션)**:
```tsx
<motion.button
  whileHover={enabled ? { scale: 1.05 } : {}}
  whileTap={enabled ? { scale: 0.95 } : {}}
/>
```

**스플래시 로고 (스프링)**:
```tsx
<motion.div
  initial={{ scale: 0.5, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ duration: 0.5, delay: 0.15, type: "spring", stiffness: 200 }}
/>
```

> **원칙**: 시간(duration)은 `0.25s` (빠름, 메시지) / `0.35~0.4s` (카드) / `0.55~0.6s` (페이지 전환) 3단계로만.

---

## 🧩 5. 컴포넌트 패턴

### 5.1 카드 (Card)

**공통 스타일**:
```
bg-white rounded-2xl p-4
shadow-card hover:shadow-card-hover
border border-[#F3F4F6]
transition-all duration-200
focus:outline-none focus:ring-2 focus:ring-hanwha-orange/50
```

**가로 스크롤 카드 리스트 — 반응형 너비**:
```tsx
style={{ width: "clamp(196px, 72vw, 260px)" }}
```

### 5.2 배지 (Badge)

둥근 직사각형, 아이콘 + 라벨 패턴:
```tsx
<div
  className="inline-flex items-center gap-1.5 text-xs font-semibold
             px-2.5 py-1 rounded-lg"
  style={{ background, color, border: `1px solid ${border}` }}
>
  <Icon /> {label}
</div>
```

**Pulse-ring 배지 (긴급)**: 추가 클래스 `pulse-ring` → 빨강 글로우 링 확산.

### 5.3 칩 / 토글 (Quick Actions)

```
rounded-full border px-3 py-1.5
text-[15px] font-medium
active:scale-95 transition-colors duration-150
```

**선택됨** (오렌지): `bg-hanwha-orange text-white border-hanwha-orange`
**유휴**: `bg-orange-50 text-hanwha-orange border-orange-200 hover:bg-orange-100`
**Neutral 유휴**: `bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100`

### 5.4 입력 필드 (Input)

```tsx
<div className="flex items-center gap-2
                bg-gray-50 border rounded-xl px-4 h-12
                shadow-sm border-gray-200
                transition-colors duration-200
                focus-within:border-hanwha-orange focus-within:bg-white">
  <SearchIcon />
  <input className="flex-1 bg-transparent text-[17px] text-hanwha-navy
                    placeholder-gray-400 outline-none" />
</div>
```

**포커스 시 색상 전환**: 보더만 오렌지로 변경 (배경은 화이트로 elevation).

### 5.5 CTA 버튼 (Submit)

```tsx
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
  className="w-11 h-11 rounded-2xl flex items-center justify-center
             shadow-sm transition-all duration-200
             disabled:opacity-40 disabled:cursor-not-allowed"
  style={{ background: enabled ? GRADIENT.orange : "#E5E7EB" }}
/>
```

### 5.6 아바타 (Initial Avatar)

그래디언트 원형 + 이니셜:
```tsx
<div
  className="w-10 h-10 rounded-full flex items-center justify-center
             text-white text-sm font-bold"
  style={{ background: GRADIENT.orange }}
>
  {initials}
</div>

// 성별별 그래디언트 예시:
// 여: linear-gradient(135deg, #EC4899, #DB2777)
// 남: linear-gradient(135deg, #3B82F6, #2563EB)
```

### 5.7 드롭다운 / 모달

```
absolute right-0 top-full mt-2
bg-white rounded-2xl shadow-modal border border-gray-100
overflow-hidden z-50
```

**헤더 영역은 네이비 그래디언트**로 계층 분리:
```tsx
<div style={{ background: GRADIENT.navy }} className="px-4 py-4">...</div>
```

### 5.8 헤더 (App Header)

- 배경: `bg-hanwha-navy` (=네이비 단색, `sticky top-0 z-30`)
- 탭: 기본 `text-white/60`, 활성 `bg-hanwha-orange text-white`, 호버 `bg-white/10`
- 보조 정보(날짜/시스템상태): `bg-white/10 rounded-full px-3 py-1.5` + 이모랄드 pulse 도트

### 5.9 메시지 버블 (Chat)

- **봇**: 좌측 정렬, 아바타 (`bg-gradient-to-br from-orange-50 to-amber-50`) + 말풍선
- **유저**: 우측 정렬 (`flex-row-reverse`)
- 공통: `max-w-[88~92%]`, `gap-1.5`, 하단에 타임스탬프 + 복사 버튼
- 등장: Framer Motion `opacity 0 → 1` (0.25s)

### 5.10 글래스모피즘 카드

```css
.glass-card {
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.6);
}
```

### 5.11 스플래시 / 로딩 스크린

```
고정 전체화면 + 네이비 그래디언트 (3-stop)
+ 라디얼 오렌지 스팟(좌하/우상, opacity 10%)
+ 40px 그리드 패턴 (opacity 5%)
+ 중앙 흰색 라운드 로고 (+ ping 링 2px 오렌지)
+ 로고 밑 태그라인 + 1.2s width 0→100% 오렌지 프로그레스바
```

> **미니멀 변종** (로그인/로그아웃 전환): 네이비 hero 금지, 연한 배경 + 로고 + 한 줄 + slim bar만.

---

## 🎭 6. 특수 유틸리티

### 6.1 Custom Scrollbar

```css
::-webkit-scrollbar { width: 5px; height: 5px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #CBD5E0; border-radius: 99px; }
::-webkit-scrollbar-thumb:hover { background: #A0AEC0; }

/* 얇은 scrollbar 변종 */
.chat-scroll::-webkit-scrollbar { width: 4px; }
.chat-scroll::-webkit-scrollbar-thumb { background: #E2E8F0; }

/* 스크롤바 숨김 */
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
```

### 6.2 Focus Ring (접근성)

```css
button:focus-visible {
  outline: 2px solid var(--hanwha-orange);
  outline-offset: 2px;
}
```

+ 포커스 가능한 카드: `focus:ring-2 focus:ring-hanwha-orange/50`.

### 6.3 Nav Active Indicator (좌측 막대)

```css
.nav-active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 60%;
  background: var(--hanwha-orange);
  border-radius: 0 2px 2px 0;
}
```

### 6.4 Keyword Highlight (검색 결과)

```css
mark.kw-hit {
  background: linear-gradient(180deg,
    rgba(243, 115, 33, 0.14) 0%,
    rgba(243, 115, 33, 0.24) 100%);
  color: var(--hanwha-navy);
  font-weight: 700;
  padding: 0 4px;
  border-radius: 999px;
  box-shadow: inset 0 0 0 1px rgba(243, 115, 33, 0.16);
}
```

### 6.5 Stream Fade-out (가로 스크롤 힌트)

```tsx
<div className="pointer-events-none absolute inset-y-0 right-0 w-10
                bg-gradient-to-l from-white via-white/85 to-transparent" />
```

### 6.6 터치 디바이스 대응

```css
/* Hover가 없는 기기에서 copy 버튼 상시 노출 */
@media (hover: none) {
  .copy-btn { opacity: 1 !important; }
}
```

---

## 📐 7. 레이아웃 원칙

### 7.1 반응형 브레이크포인트

| Breakpoint | 전환 |
|------------|------|
| `< sm` (~640px) | 모바일 — 사이드바 숨김, 전체폭 콘텐츠 |
| `sm ~ md` | 모바일 가로 — 사이드바 drawer |
| `>= md` (768px) | 데스크탑 — 2패널 레이아웃 |
| `lg` (1024px) | 콘텐츠 max-width 확장 (`max-w-5xl`) |

### 7.2 Safe Area (모바일)

```tsx
className="pb-[calc(0.5rem+env(safe-area-inset-bottom))]"
```

### 7.3 Radius 스케일

| 용도 | 값 |
|------|------|
| 배지, 칩 작은 것 | `rounded-lg` (8px) |
| 버튼 | `rounded-xl` (12px) |
| 카드, CTA 큰 버튼 | `rounded-2xl` (16px) |
| 아바타, pill, 인디케이터 도트 | `rounded-full` |

### 7.4 Z-index 계층

| Z | 역할 |
|---|------|
| `z-10` | 고정된 입력 영역 |
| `z-30` | 스티키 헤더 |
| `z-40` | 토스트 |
| `z-50` | 모달, 드롭다운, 스플래시 |

---

## 🧱 8. 다른 프로젝트 이식 체크리스트

### 8.1 필수 파일 (복사하면 바로 동작)

```
tailwind.config.ts        # 색/그림자/폰트/애니메이션 토큰
app/globals.css           # 폰트 로드 + keyframes + 유틸리티 클래스
lib/design-tokens.ts      # 그래디언트/인라인 그림자 객체
public/fonts/*.woff2      # A2Z 폰트 (또는 대체 폰트)
```

### 8.2 브랜드 컬러만 교체하는 경우

1. `tailwind.config.ts`의 `colors.hanwha.*` 키 유지, 값만 교체
2. `globals.css`의 `:root` CSS 변수 (`--hanwha-orange`, `--hanwha-navy`) 값 교체
3. `lib/design-tokens.ts`의 그래디언트 HEX 치환
4. 컴포넌트의 `bg-hanwha-orange`, `text-hanwha-navy` 등은 그대로 동작

### 8.3 대체 폰트 권장 (A2Z 없을 때)

- 한국어: **Pretendard Variable** (CDN 단일 URL + 전 weight)
- 영문/숫자 강조: **IBM Plex Sans** (이미 `plex` 키로 준비됨)

### 8.4 의존성

```json
{
  "dependencies": {
    "framer-motion": "^11",
    "tailwindcss": "^3.4"
  }
}
```

---

## 💡 9. 설계 원칙 요약

1. **2색 체계**: Primary(오렌지) + Neutral(네이비) → 세컨더리 금지, 상태색만 예외.
2. **그래디언트는 토큰**: 문자열 하드코딩 금지 — `GRADIENT.orange` 같이 객체로.
3. **그림자는 브랜드 톤**: 검정이 아닌 네이비 rgba → 컬러 통일.
4. **모션은 3단계**: 0.25s / 0.35s / 0.55s — 시간값 임의 생성 금지.
5. **한글 가독성**: 본문 최소 15px, `word-break: keep-all`.
6. **터치 우선**: `active:scale-95`, `hover:` 에만 의존하지 않기.
7. **접근성**: 모든 interactive 요소에 `focus-visible` 링(오렌지 2px).
8. **계층감**: 배경 → 카드(`shadow-card`) → 플로팅(`shadow-modal`) 3단계로만.

---

## 📎 참고

- Tailwind 공식: https://tailwindcss.com/docs
- Framer Motion 공식: https://www.framer.com/motion/
- IBM Plex Sans: https://fonts.google.com/specimen/IBM+Plex+Sans
- Pretendard: https://github.com/orioncactus/pretendard
