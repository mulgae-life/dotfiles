---
name: hw-design
description: 한화(Hanwha) 브랜드 톤으로 UI를 만들 때 DESIGN.md + tokens.css + AtoZ/IBM Plex 웹폰트 + Tailwind 프리셋 + 공식 트리서클 로고(PNG) + token-audit 스크립트를 한 번에 프로젝트에 배포해 AI 세션 간 룩앤필을 고정하는 스킬. 오렌지 #F37321 + 네이비 #1A2B4A 2색축·3단계 모션·네이비 톤 그림자 DNA를 Google 공식 DESIGN.md v0.1.0 포맷 + Hardik Pandya 3-layer token 패턴으로 토큰화했다. 진실의 원천은 DESIGN.md 하나 — 프로젝트 CLAUDE.md 에 별도 규칙을 주입하지 않는다. stitch-design(Stitch MCP로 새 DESIGN.md 생성)이나 frontend-design(코드 UI 구현)과 달리 이미 확정된 한화 표준을 고정 배포한다. "한화", "hw", "Hanwha" 키워드 또는 한화 계열사 프로젝트 맥락이면 명시적 요청이 없어도 최우선 참조한다.
when_to_use: "한화 디자인으로 만들어줘, 한화 톤으로 UI 만들어줘, hw 적용해줘, 한화 스타일 랜딩페이지/대시보드/웹앱/컴포넌트 만들어줘 요청 시. 한화 관련 신규 프로젝트 초기 세팅, 기존 프로젝트에 한화 브랜드 덧씌우기, 팀원이 여러 명이라 디자인 일관성이 필요한 바이브 코딩 세션 등에서 사용."
allowed-tools:
  - "Read"
  - "Write"
  - "Edit"
  - "Bash"
---

# HW Design — 한화 디자인 범용 표준

**Hanwha Group Identity**를 어느 프로젝트에서든 재현 가능한 형태로 토큰화한 스킬. Google Labs의 공식 [`DESIGN.md` v0.1.0 (alpha)](https://github.com/google-labs-code/design.md) 포맷 + Hardik Pandya의 [3-layer token architecture](https://hvpandya.com/llm-design-systems) + 커뮤니티 고수 노하우를 녹여 만들었다.

## 이 스킬이 해결하는 문제

LLM은 세션 간 기억이 없다. "한화 느낌으로 만들어줘"라고 매번 다르게 말하면 매번 다른 오렌지, 다른 폰트, 다른 라운딩이 나온다. 이 스킬은 다음을 해결한다:

1. **설계 의사결정을 기계 판독 가능 토큰으로 고정** — `DESIGN.md` + `tokens.css`
2. **위반을 자동 감지** — `token-audit.mjs`
3. **프레임워크별 연결 번들** — `tailwind.preset.js`, `fonts.css`

결과: **10번째 AI 세션이 1번째와 같은 한화 룩앤필**을 낸다. 프로젝트 루트의 `DESIGN.md` 가 진실의 원천이므로 별도 `CLAUDE.md` 규칙 주입은 두지 않는다 — 스킬 호출 시 LLM 이 `DESIGN.md` 를 먼저 읽도록 유도하는 것으로 충분하다.

## 배포되는 파일 (한 번에 세트로)

```
프로젝트루트/
├── DESIGN.md                 ← 토큰+8섹션 공식 포맷 (진실의 원천)
├── tokens.css                ← 3-layer CSS 변수 (Layer 1 → 2 → 컴포넌트)
├── tailwind.preset.hw.js     ← Tailwind 사용 시 옵션
├── token-audit.mjs           ← 하드코딩 감지 스크립트 (Node 단독 실행)
├── public/fonts/
│   ├── AtoZ/*.woff2          ← 한글 9-weight
│   ├── IBMPlexSans/*.ttf     ← 영문 variable
│   └── fonts.css             ← @font-face 선언 묶음
└── public/logo/
    ├── hanwha-tricircle.png  ← 한화 CI 로고
    └── favicon.png
```

프로젝트 `CLAUDE.md` 에 별도 규칙을 주입하지 않는다. 진실의 원천은 오직 `DESIGN.md` — LLM 이 스킬 호출 시(또는 파일을 직접 읽을 때) 여기서 토큰과 컴포넌트 스펙을 모두 확인한다.

## 사용법 (3단계)

### 1) 전체 세트 배포

```bash
SKILL=~/.claude/skills/hw-design/assets

# 필수 파일
cp "$SKILL/DESIGN.md"         ./DESIGN.md
cp "$SKILL/tokens.css"        ./tokens.css
cp "$SKILL/token-audit.mjs"   ./token-audit.mjs

# 폰트 + 로고 (경로는 프로젝트에 맞게 조정)
mkdir -p ./public/fonts ./public/logo
cp -r "$SKILL/fonts/AtoZ"        ./public/fonts/
cp -r "$SKILL/fonts/IBMPlexSans" ./public/fonts/
cp    "$SKILL/fonts/fonts.css"   ./public/fonts/
cp -r "$SKILL/logo/"*            ./public/logo/

# Tailwind 사용 시
cp "$SKILL/tailwind.preset.js" ./tailwind.preset.hw.js
```

또는 대화에서 **"hw 적용해줘"** → 이 스킬이 위를 수행한다.

### 2) 진입점 CSS 에 tokens/폰트 import

```css
/* app/globals.css 또는 src/index.css 맨 위에 */
@import "./public/fonts/fonts.css";
@import "./tokens.css";
```

Tailwind 쓰면 `tailwind.config.js` 에 프리셋 추가:
```js
module.exports = {
  presets: [require("./tailwind.preset.hw.js")],
  content: [...],
};
```

### 3) 감사 (커밋 전 또는 CI)

```bash
node token-audit.mjs
```

하드코딩된 hex/px/duration 이 있으면 파일·라인과 함께 정정 토큰을 제안한다. 오류 있으면 exit 1.

```bash
node token-audit.mjs --format json     # CI 파이프에 물릴 때
node token-audit.mjs --strict          # warning 도 exit 1 처리
node token-audit.mjs src/components    # 특정 폴더만
```

## 공식 CLI 연계 (선택)

```bash
# 토큰 무결성 + WCAG AA 대비 검증
npx @google/design.md lint ./DESIGN.md

# W3C DTCG 표준 토큰 포맷으로 내보내기
npx @google/design.md export --format dtcg ./DESIGN.md > tokens.hw.dtcg.json
```

## 빠른 참조

| 항목 | 값 |
|------|-----|
| **Primary** | `#F37321` (Hanwha Orange) |
| **Primary Hover** | `#E06A1B` |
| **Primary Pressed** | `#C75E14` |
| **Neutral (Navy)** | `#1A2B4A` — 헤더·사이드바·본문 텍스트 |
| **Surface** | `#FFFFFF` / `#F7F9FC` (secondary) / `#EEF2F7` (tertiary) |
| **State** | success `#16A34A` · warning `#B45309` · danger `#DC2626` · info `#3B82F6` |
| **Font (한글)** | AtoZ 9w → Pretendard fallback |
| **Font (영문)** | IBM Plex Sans variable |
| **라운딩** | chip `md(8)` / button·input `lg(12)` / card `xl(16)` / CTA `2xl(20)` |
| **간격** | 4 / 8 / 12 / 16 / 24 / 32 / 48 / 80 / 128 px |
| **Motion** | fast 250 / base 350 / slow 550 ms — **3단계만** |
| **그림자 톤** | `rgba(26, 43, 74, x)` (네이비 기반) |

> 전체 스펙: [`assets/DESIGN.md`](assets/DESIGN.md)
> 고수 노하우 출처·방법론: [`references/design-md-playbook.md`](references/design-md-playbook.md)
> 브랜드 출처·이력: [`references/brand-identity.md`](references/brand-identity.md)
> 원본 참고(실전 프로젝트): [`references/source-design.md`](references/source-design.md)

## 브랜드 헤더 — 공식 로고 (MUST READ)

> **LLM 이 가장 자주 저지르는 실수 TOP 1**: SVG 로 원 3개 겹쳐서 트리서클을 자체 제작하는 것. 비율·색이 똑같아 보여도 **절대 금지**. CI 일관성과 법무 안전의 문제다.

### 번들 에셋

| 파일 | 구성 | 용도 |
|------|------|------|
| `assets/logo/hanwha-tricircle.png` (707×353, RGBA) | symbol(트리서클 오렌지) + wordmark(**검은** 한글) 가로 로고타이프 | 모든 화면의 브랜드 로고 |
| `assets/logo/favicon.png` (154×140) | symbol only | 파비콘 |

### ⚠️ 배경 대비 규칙 (핵심)

wordmark 가 **검은 글씨**라 네이비 헤더 위에 그대로 올리면 **글자가 묻힌다**.
→ **on-navy 배경에선 반드시 흰 박스 컨테이너로 감싼다**.

#### on-navy 배경 (Top Nav, 히어로, 스플래시 기본)

```html
<div class="brand">
  <span class="brand__logo-box">
    <img src="/public/logo/hanwha-tricircle.png" alt="한화" class="brand__logo" />
  </span>
  <span class="brand__name">서비스명</span>
</div>
```

```css
.brand {                                     /* 브랜드명 타이틀 (로고 옆 한글) */
  display: flex; align-items: center; gap: var(--sp-sm);
  font-weight: 700; font-size: 1.375rem;     /* 22px — 한화 브랜드 타이틀 기본 */
  letter-spacing: -0.015em;
}
.brand__logo-box {
  display: inline-grid; place-items: center;
  padding: 2px 10px;                         /* 세로 슬림 — 로고가 박스 전체를 채움 */
  background: var(--color-surface);          /* #fff */
  border-radius: var(--radius-md);           /* 8px */
  box-shadow: 0 2px 8px rgba(26, 43, 74, .18);
}
.brand__logo {
  height: 84px;                              /* Top Nav 기본 (Nav 104px 전제) */
  width: auto;
  object-fit: contain;
  display: block;
}
```

#### on-white / on-light 배경 (일반 페이지, 푸터)

컨테이너 불필요. 로고 단독 배치:

```html
<img src="/public/logo/hanwha-tricircle.png" alt="한화" class="brand__logo" />
```

### React / Next.js

```tsx
import logo from "@/public/logo/hanwha-tricircle.png";

// on-navy (헤더 기본)
<span className="brand__logo-box">
  <Image src={logo} alt="한화" height={28} priority className="brand__logo" />
</span>

// on-white (푸터 등)
<Image src={logo} alt="한화" height={28} priority className="brand__logo" />
```

### 사이즈

| 위치 | 배경 | Nav/컨테이너 높이 | 로고 이미지 높이 | 박스 패딩 | 박스 라운딩 |
|------|------|-------------------|----------------|----------|------------|
| Top Nav | navy | **Nav 104px** | **84px** | `2px 10px` | `md (8)` |
| Hero splash | navy | — | 96–128px | `6px 16px` | `lg (12)` |
| Footer | white | — | 24–28px | — (컨테이너 없음) | — |
| Favicon | — | — | `favicon.png` 사용 | — | — |

**브랜드 타이틀 폰트** (로고 옆 한글 서비스명): `1.375rem (22px)` · `weight 700` · `letter-spacing -0.015em`. Nav 높이 104px 기준 시각 균형에 맞춘 값.

**세이프존**: 로고 높이의 1/2 이상. 흰 박스 패딩이 이 역할을 겸한다.

### 단일 파일 데모 시나리오 (3가지 중 택 1)

- **권장**: 로고 PNG 를 데모 HTML 과 **같은 폴더에 복사** 후 상대경로 `<img src="hanwha-tricircle.png">`
- 외부 파일 금지 조건: `data:image/png;base64,...` 로 **인라인** (PNG 65KB → base64 ≈ 86KB, 수용 가능)
- **금지**: SVG `<circle>` 3개로 트리서클 재현, Canvas drawing, 아이콘 폰트 대체 — 배포 가능한 산출물에는 모두 불가

### 배포 후 검증 (필수)

```bash
# 1) 공식 에셋이 실제 렌더되는지
grep -rn "hanwha-tricircle\|data:image/png;base64,iVBOR" ./

# 2) SVG 로 그린 금지 패턴이 섞여 있지 않은지
grep -rn '<circle[^>]*fill="url(#' ./          # 원 3개 + 그래디언트 → 의심

# 3) on-navy 영역에 brand__logo-box 래퍼가 있는지 (네이비 헤더 사용 시)
grep -n "brand__logo-box" ./

# 없으면 wordmark 묻힘. 래퍼 추가 또는 on-white 배경으로 변경.
```

## Do's and Don'ts (요약)

**✅ Do**
- `var(--color-*)` / `{colors.*}` 토큰만 사용 — 인라인 hex/px 금지
- Primary 는 포인트 — 화면 면적 ≤ 20%
- 본문 `line-height ≥ 1.5`, 한글 최소 15px, `word-break: keep-all`
- 그림자는 네이비 톤 (`rgba(26, 43, 74, x)`)
- 모션은 `fast/base/slow` 3단계만
- 터치 타겟 ≥ 44×44px, `focus-visible` 링 필수
- **로고는 번들 PNG 만** (`public/logo/hanwha-tricircle.png`)
- **on-navy 배경에선 흰 박스 컨테이너** 로 로고를 감싸기 (검은 wordmark 대비 확보)

**❌ Don't**
- 오렌지 위에 오렌지 쌓기 (계층 붕괴)
- 세컨더리 컬러 추가 (2색 대비축이 한화 DNA)
- 그라디언트·네온 남용 (한화는 단색 기조)
- 순검정 `#000000` 본문 텍스트 (디지털은 `#1A2B4A`)
- 한 페이지 3종 이상 라운딩 혼용
- 임의 duration (`0.4s` 같은 값)
- 트리서클 로고 색·비율 변형
- **트리서클을 SVG/Canvas/코드로 자체 제작** (원 3개 겹치기, 유사 오렌지 그래디언트 — 전부 금지)
- **on-navy 배경에 로고 그대로 올리기** (검은 wordmark 가 묻힘 — 흰 박스 컨테이너 필수)

## 관련 스킬

- **`/stitch-design`** — Stitch MCP로 **새 DESIGN.md 생성**. `/hw-design`은 **이미 확정된 한화 표준을 배포**.
- **`/frontend-design`** — 코드로 UI 구현. `/hw-design`으로 토큰 깔고 `/frontend-design`으로 컴포넌트 짜는 조합.
- **`/web-design-guidelines`** — 완성된 UI 가 브랜드 규칙을 지켰는지 감사. `token-audit.mjs` 와 상호 보완.
