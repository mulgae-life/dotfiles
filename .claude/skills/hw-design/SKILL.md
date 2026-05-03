---
name: hw-design
description: 한화(Hanwha) 브랜드 톤으로 UI를 만들 때 DESIGN.md + tokens.css + 한화체 3w + 한화고딕 5w + IBM Plex 웹폰트 + Tailwind 프리셋 + 공식 트리서클 로고(PNG) + token-audit 스크립트를 한 번에 프로젝트에 배포해 AI 세션 간 룩앤필을 고정하는 스킬. 오렌지 #F37321 + 네이비 #1A2B4A 2색축·3단계 모션·네이비 톤 그림자 DNA를 Google 공식 DESIGN.md v0.1.0 포맷 + Hardik Pandya 3-layer token 패턴으로 토큰화했다. 진실의 원천은 DESIGN.md 하나 — 프로젝트 CLAUDE.md 에 별도 규칙을 주입하지 않는다. stitch-design(Stitch MCP로 새 DESIGN.md 생성)이나 frontend-design(코드 UI 구현)과 달리 이미 확정된 한화 표준을 고정 배포한다. "한화", "hw", "Hanwha" 키워드 또는 한화 계열사 프로젝트 맥락이면 명시적 요청이 없어도 최우선 참조한다.
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
├── build-standalone.mjs      ← 외부 공유용 단일 HTML 빌더 (Node 단독 실행)
├── public/fonts/
│   ├── Hanwha/*.woff2        ← 한화체 3-weight (L/R/B) — Display·로고
│   ├── HanwhaGothic/*.woff2  ← 한화고딕 5-weight (T/EL/L/R/B) — 본문
│   ├── AtoZ/*.woff2          ← 폴백 한글 9-weight
│   ├── IBMPlexSans/*.ttf     ← 영문 variable
│   └── fonts.css             ← @font-face 선언 묶음
└── public/logo/
    ├── hanwha-tricircle.png              ← 원본 (on-white 기본)
    ├── hanwha-tricircle-on-navy.png      ← on-navy 헤더 기본 (컬러 + 흰 wordmark)
    ├── hanwha-tricircle-mono-white.png   ← on-navy 스플래시·히어로 (전체 흰)
    ├── tricircle-symbol-white.png        ← on-navy 모바일 축약 (심볼만 흰)
    └── favicon.png                        ← 파비콘 (심볼만 컬러)
```

프로젝트 `CLAUDE.md` 에 별도 규칙을 주입하지 않는다. 진실의 원천은 오직 `DESIGN.md` — LLM 이 스킬 호출 시(또는 파일을 직접 읽을 때) 여기서 토큰과 컴포넌트 스펙을 모두 확인한다.

## 사용법 (4단계)

### 1) 전체 세트 배포

```bash
SKILL=~/.claude/skills/hw-design/assets

# 필수 파일
cp "$SKILL/DESIGN.md"            ./DESIGN.md
cp "$SKILL/tokens.css"           ./tokens.css
cp "$SKILL/token-audit.mjs"      ./token-audit.mjs
cp "$SKILL/build-standalone.mjs" ./build-standalone.mjs

# 폰트 + 로고 (경로는 프로젝트에 맞게 조정)
mkdir -p ./public/fonts ./public/logo
cp -r "$SKILL/fonts/Hanwha"        ./public/fonts/   # 한화체 (Display·로고)
cp -r "$SKILL/fonts/HanwhaGothic"  ./public/fonts/   # 한화고딕 (본문)
cp -r "$SKILL/fonts/AtoZ"          ./public/fonts/   # 폴백
cp -r "$SKILL/fonts/IBMPlexSans"   ./public/fonts/   # 영문·숫자
cp    "$SKILL/fonts/fonts.css"     ./public/fonts/
cp -r "$SKILL/logo/"*              ./public/logo/

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

### 4) 외부 공유용 단일 HTML 빌드 (디자인 프로토타입 공유)

`index.html` + `tokens.css` + `fonts/` + `logo/` 를 모두 인라인하여 **외부 자산 0개**의 단일 HTML 한 개로 합친다. 이메일·메신저·드라이브로 파일 한 개만 보내면 어디서든 동일하게 렌더된다.

```bash
node build-standalone.mjs                    # 기본: core 4 weight 인라인 (~1.5MB)
node build-standalone.mjs --fonts none       # 시스템 폴백 (~200KB)
node build-standalone.mjs --fonts all        # 한화체 3w + 한화고딕 5w 전체 (~3MB)
node build-standalone.mjs index.html out.html  # 입력/출력 경로 지정
```

| 모드 | 인라인 폰트 | 사이즈 | 사용 시점 |
|------|------------|--------|-----------|
| `core` (기본) | 한화체 R/B + 한화고딕 R/B | ~1.5MB | 외부 공유 시 한화 룩앤필 100% 보존 |
| `none` | 없음 (시스템 폴백) | ~200KB | 가벼운 미리보기·내부 빠른 공유 |
| `all` | 한화체 3w + 한화고딕 5w | ~3MB | 모든 weight 사용한 풀 디자인 |

출력 파일은 같은 폴더의 `standalone.html` (또는 두 번째 인자로 지정한 경로). 외부 참조가 남아 있으면 종료 코드 1.

## 디자인 산출 후 안내 (MUST)

`/hw-design`을 활용해 UI/페이지/컴포넌트/대시보드를 만든 직후, 응답 마지막에 **"적용된 결정 + 변경 옵션"** 섹션을 반드시 덧붙인다. 기본 동작은 자동 결정 그대로 두되, 사용자가 결과물을 보고 자연어로 손쉽게 변경 요청할 수 있도록 안내하는 것이 목적이다.

### 출력 형식 (해당 작업에 결정된 항목만 포함)

```markdown
---
### 💡 적용된 결정 + 변경 옵션

| 항목 | 적용 | 다른 선택지 (요청 예시) |
|------|------|------------------------|
| **로고** | `hanwha-tricircle-on-navy.png` (컬러 + 흰 wordmark) | "mono-white로 바꿔줘", "심볼만 모바일 축약", "푸터는 on-white 원본으로" |
| **헤더 배경** | navy `#1A2B4A` | "white 헤더로 바꿔줘", "그래디언트로" |
| **헤딩 폰트** | 한화체 B (700) | "한화체 R(차분히)로", "한화고딕 B로 통일" |
| **본문 폰트** | 한화고딕 R (400) | "한화고딕 L(가볍게)", "한화체로 통일" |
| **다크모드** | 미적용 | "다크모드도 지원해줘" → `[data-theme="dark"]` 활성화 |
| **컨텐츠 폭** | 1280px (데스크톱) | "1440 와이드로", "모바일 우선으로 재구성" |

> 자세한 사양은 `DESIGN.md` 참조. 변경은 자연어로 그대로 말씀해주시면 됩니다.
---
```

### 데모·프로토타입 산출 시 standalone.html 도 함께 빌드 (MUST)

단일 페이지 데모·프로토타입·시안(`.archive/<태그>/index.html` 등)을 만들었으면, **외부 공유 가능한 단일 HTML 파일도 같이 생성**한다. 디자인 프로토타입은 "파일 한 개 보내면 끝"이 표준 산출물이기 때문이다.

```bash
# 데모 폴더 안에서 (index.html 옆에)
node build-standalone.mjs                    # 기본 core 4 weight 인라인
```

기본은 `core` 모드(한화 룩앤필 100% 보존). 가벼운 미리보기가 필요하면 `--fonts none`, 모든 weight를 쓴 풀 디자인이면 `--fonts all`. 자세한 옵션은 [§ 사용법 4)](#4-외부-공유용-단일-html-빌드-디자인-프로토타입-공유) 참조. 적용 후 옵션 표에 **"외부 공유 파일"** 행을 1줄 추가해 사용자에게 알린다 (카탈로그 참고).

### 포함 규칙

- **해당 작업에 실제로 결정된 항목만** 표에 포함 (예: 모달만 만들었으면 헤더 배경 행 생략, 다크모드 안 다뤘으면 그 행 생략)
- 각 행은 **"적용 / 변경 요청 예시"** 두 컬럼. 변경 예시는 자연어 1~2개
- 표 끝에 `DESIGN.md` 참조 안내 1줄 포함
- 사용자가 "안내 생략" 또는 "옵션 표 빼줘" 명시 요청 시에만 생략

### 안내 대상 항목 카탈로그

LLM이 다음 결정을 내렸으면 표에 1행씩 추가한다:

| 결정 카테고리 | 변경 가능 옵션 |
|---------------|---------------|
| 로고 변형 | `hanwha-tricircle.png` (on-white) / `-on-navy.png` (헤더 기본) / `-mono-white.png` (Hero·풋터 inverse) / `tricircle-symbol-white.png` (모바일 축약) / `favicon.png` |
| 헤더 배경 | navy `#1A2B4A` / white / `gradients.navy` 그래디언트 / 헤더 없음 |
| 헤딩 폰트 | 한화체 L(300) / R(400) / B(700) — 기본 B / 한화고딕 통일도 가능 |
| 본문 폰트 weight | 한화고딕 T(100) / EL(200) / L(300) / R(400) / B(700) — 기본 R |
| 다크모드 | `[data-theme="dark"]` 활성화 / 비활성 |
| 컨텐츠 폭 | 1280 (기본) / 1440 (대시보드 와이드) / 모바일 우선 단일 컬럼 |
| Primary 강도 | 면적 ≤ 20% (기본) / Hero에만 / 절제(테두리만) |
| 라운딩 키 | `lg`(12, 기본) / `xl`(16) / `2xl`(20) — 한 페이지 3종 이하 유지 |
| 그림자 강도 | flat / `card` / `card-hover` / `modal` — 3단계 계층 |
| 모션 속도 | `fast`(250) / `base`(350, 기본) / `slow`(550) |
| 외부 공유 파일 | `standalone.html` (core, ~1.5MB, 기본) / `--fonts none` (~200KB, 가벼운 미리보기) / `--fonts all` (~3MB, 풀 weight) |

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
| **Font (Display·로고)** | 한화체 3w (L/R/B) → 한화고딕 → AtoZ |
| **Font (한글 본문)** | 한화고딕 5w (T/EL/L/R/B) → AtoZ → Pretendard fallback |
| **Font (영문·숫자)** | IBM Plex Sans variable |
| **라운딩** | chip `md(8)` / button·input `lg(12)` / card `xl(16)` / CTA `2xl(20)` |
| **간격** | 4 / 8 / 12 / 16 / 24 / 32 / 48 / 80 / 128 px |
| **Motion** | fast 250 / base 350 / slow 550 ms — **3단계만** |
| **그림자 톤** | `rgba(26, 43, 74, x)` (네이비 기반) |

> 전체 스펙: [`assets/DESIGN.md`](assets/DESIGN.md)
> 브랜드 출처·검증: [`references/brand-identity.md`](references/brand-identity.md)
> 폰트 라이선스: [`references/font-license.md`](references/font-license.md)

## 브랜드 헤더 — 공식 로고 (MUST READ)

> **LLM 이 가장 자주 저지르는 실수 TOP 1**: SVG 로 원 3개 겹쳐서 트리서클을 자체 제작하는 것. 비율·색이 똑같아 보여도 **절대 금지**. CI 일관성과 법무 안전의 문제다.

### 번들 에셋 (5종)

| 파일 | 구성 | 용도 |
|------|------|------|
| `assets/logo/hanwha-tricircle.png` (707×353, RGBA) | symbol(컬러) + wordmark(**검정**) | **on-white 기본** — 일반 페이지·푸터 |
| `assets/logo/hanwha-tricircle-on-navy.png` | symbol(컬러) + wordmark(**흰색**) | **on-navy 헤더 기본** (가장 자주 사용) |
| `assets/logo/hanwha-tricircle-mono-white.png` | symbol(흰색, 농도 분리) + wordmark(흰색) | on-navy 스플래시·히어로·풋터 inverse |
| `assets/logo/favicon.png` (154×140, RGBA) | symbol only(컬러) | 파비콘 |
| `assets/logo/tricircle-symbol-white.png` | symbol only(흰색) | on-navy 모바일 헤더 축약·뱃지 |

> ⚠️ `*-on-navy.png` / `*-mono-white.png` / `tricircle-symbol-white.png` 는 원본의 **색상 변환 시안**입니다. 비율·형태는 100% 보존. 한화손보 BI 공식 mono/inverse 자산이 도착하면 교체 권장 (자세한 내용: `references/brand-identity.md`).

### ⚠️ 배경별 변형 결정 트리

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

> 흰 박스 컨테이너 방식(이전 권장)은 변형이 모두 갖춰진 현재로선 사용하지 않는다. (필요하다면 fallback 으로만.)

#### on-navy — Top Nav 기본 (Variant A: 컬러 + 흰 wordmark)

```html
<div class="brand">
  <img src="/public/logo/hanwha-tricircle-on-navy.png" alt="한화손보" class="brand__logo" />
</div>
```

```css
.brand {
  display: flex; align-items: center; gap: var(--sp-sm);
}
.brand__logo {
  height: 56px;              /* Top Nav 104px 전제 */
  width: auto;
  object-fit: contain;
  display: block;
}
```

#### on-navy — 스플래시·히어로 (Variant B: 전체 흰색)

```html
<img src="/public/logo/hanwha-tricircle-mono-white.png" alt="한화손보" class="brand__logo brand__logo--hero" />
```

```css
.brand__logo--hero { height: 96px; }   /* 또는 더 크게, 화면 비율에 맞춰 */
```

#### on-navy — 모바일 헤더 축약 (Variant C: 심볼만 흰색)

```html
<img src="/public/logo/tricircle-symbol-white.png" alt="한화손보" class="brand__logo brand__logo--symbol" />
```

```css
.brand__logo--symbol { height: 32px; }
```

#### on-white — 일반 페이지·푸터 (원본)

```html
<img src="/public/logo/hanwha-tricircle.png" alt="한화손보" class="brand__logo" />
```

### React / Next.js

```tsx
// 변형별로 import
import logoOnWhite from "@/public/logo/hanwha-tricircle.png";
import logoOnNavy  from "@/public/logo/hanwha-tricircle-on-navy.png";
import logoMono    from "@/public/logo/hanwha-tricircle-mono-white.png";
import logoSymbol  from "@/public/logo/tricircle-symbol-white.png";

// on-navy 헤더 기본
<Image src={logoOnNavy}  alt="한화손보" height={56} priority className="brand__logo" />

// on-navy 스플래시
<Image src={logoMono}    alt="한화손보" height={96} priority className="brand__logo brand__logo--hero" />

// on-navy 모바일 축약
<Image src={logoSymbol}  alt="한화손보" height={32} priority className="brand__logo brand__logo--symbol" />

// on-white 푸터
<Image src={logoOnWhite} alt="한화손보" height={28} priority className="brand__logo" />
```

### 사이즈

| 위치 | 배경 | 사용 변형 | Nav 높이 | 로고 이미지 높이 |
|------|------|----------|---------|----------------|
| Top Nav (데스크톱) | navy | `-on-navy.png` | 104px | 56px |
| Hero splash | navy | `-mono-white.png` | — | 96–128px |
| Footer (on-navy inverse) | navy | `-mono-white.png` | — | 24–28px |
| Mobile compact header | navy | `tricircle-symbol-white.png` | 56px | 32px |
| Footer (on-white) | white | `hanwha-tricircle.png` (원본) | — | 24–28px |
| Favicon | — | `favicon.png` (원본) | — | favicon.png 사용 |

**브랜드 타이틀 폰트** (로고 옆에 별도 서비스명 텍스트를 둘 경우): `1.375rem (22px)` · `weight 700` · `letter-spacing -0.015em`.

**세이프존**: 로고 높이의 1/2 이상.

### 단일 파일 데모 시나리오 (3가지 중 택 1)

- **권장**: 사용할 변형 PNG 를 데모 HTML 과 **같은 폴더에 복사** 후 상대경로 `<img src="hanwha-tricircle-on-navy.png">`
- 외부 파일 금지 조건: `data:image/png;base64,...` 로 **인라인** (변형 PNG 6~64KB → base64 약 8~86KB, 수용 가능)
- **금지**: SVG `<circle>` 3개로 트리서클 재현, Canvas drawing, 아이콘 폰트 대체 — 배포 가능한 산출물에는 모두 불가

### 배포 후 검증 (필수)

```bash
# 1) 공식 에셋(원본 + 변형)이 실제 렌더되는지
grep -rEn 'hanwha-tricircle(-on-navy|-mono-white)?\.png|tricircle-symbol-white\.png|data:image/png;base64,iVBOR' ./

# 2) SVG 로 그린 금지 패턴이 섞여 있지 않은지
grep -rn '<circle[^>]*fill="url(#' ./          # 원 3개 + 그래디언트 → 의심

# 3) on-navy 영역에서 원본(`hanwha-tricircle.png`)을 그대로 쓰고 있지는 않은지
#    (네이비 배경 컨테이너 안에 검정 wordmark 원본이 있으면 묻힘 — 변형으로 교체)
grep -rn 'hanwha-tricircle\.png' ./            # 푸터·on-white 페이지에만 있어야 정상

# 4) (구버전 호환) `brand__logo-box` 래퍼가 남아 있다면 변형으로 마이그레이션 권장
grep -rn "brand__logo-box" ./
```

## Do's and Don'ts (요약)

**✅ Do**
- `var(--color-*)` / `{colors.*}` 토큰만 사용 — 인라인 hex/px 금지
- Primary 는 포인트 — 화면 면적 ≤ 20%
- 본문 `line-height ≥ 1.5`, 한글 최소 15px, `word-break: keep-all`
- 그림자는 네이비 톤 (`rgba(26, 43, 74, x)`)
- 모션은 `fast/base/slow` 3단계만
- 터치 타겟 ≥ 44×44px, `focus-visible` 링 필수
- **로고는 번들 PNG 만** (원본 + 4종 변형 — `public/logo/hanwha-tricircle*.png`, `tricircle-symbol-white.png`, `favicon.png`)
- **on-navy 배경에선 변형 PNG 직접 사용** (`-on-navy` / `-mono-white` / `tricircle-symbol-white`) — 흰 박스 컨테이너 fallback 은 변형이 없을 때만

**❌ Don't**
- 오렌지 위에 오렌지 쌓기 (계층 붕괴)
- 세컨더리 컬러 추가 (2색 대비축이 한화 DNA)
- 그라디언트·네온 남용 (한화는 단색 기조)
- 순검정 `#000000` 본문 텍스트 (디지털은 `#1A2B4A`)
- 한 페이지 3종 이상 라운딩 혼용
- 임의 duration (`0.4s` 같은 값)
- 트리서클 로고 색·비율 변형
- **트리서클을 SVG/Canvas/코드로 자체 제작** (원 3개 겹치기, 유사 오렌지 그래디언트 — 전부 금지)
- **on-navy 배경에 원본 로고(`hanwha-tricircle.png`) 그대로 올리기** (검은 wordmark 가 묻힘 — `-on-navy` / `-mono-white` / `tricircle-symbol-white` 변형으로 교체)

## 관련 스킬

- **`/stitch-design`** — Stitch MCP로 **새 DESIGN.md 생성**. `/hw-design`은 **이미 확정된 한화 표준을 배포**.
- **`/frontend-design`** — 코드로 UI 구현. `/hw-design`으로 토큰 깔고 `/frontend-design`으로 컴포넌트 짜는 조합.
- **`/web-design-guidelines`** — 완성된 UI 가 브랜드 규칙을 지켰는지 감사. `token-audit.mjs` 와 상호 보완.
