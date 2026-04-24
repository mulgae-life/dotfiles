---
name: hw-design
description: 한화(Hanwha) 브랜드 톤으로 UI를 만들 때 DESIGN.md + tokens.css + AtoZ/IBM Plex 웹폰트 + Tailwind 프리셋 + CLAUDE.md 규칙 + token-audit 스크립트를 한 번에 프로젝트에 배포해 AI 세션 간 룩앤필을 고정하는 스킬. 오렌지 #F37321 + 네이비 #1A2B4A 2색축·3단계 모션·네이비 톤 그림자 DNA를 Google 공식 DESIGN.md v0.1.0 포맷 + Hardik Pandya 3-layer token 패턴으로 토큰화했다. stitch-design(Stitch MCP로 새 DESIGN.md 생성)이나 frontend-design(코드 UI 구현)과 달리 이미 확정된 한화 표준을 고정 배포한다. "한화", "hw", "Hanwha" 키워드 또는 한화 계열사 프로젝트 맥락이면 명시적 요청이 없어도 최우선 참조한다.
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
2. **LLM이 읽어야 할 규칙을 프로젝트에 주입** — `CLAUDE.md.snippet`
3. **위반을 자동 감지** — `token-audit.mjs`
4. **프레임워크별 연결 번들** — `tailwind.preset.js`, `fonts.css`

결과: **10번째 AI 세션이 1번째와 같은 한화 룩앤필**을 낸다.

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

그리고 프로젝트 `CLAUDE.md` 에 4줄짜리 규칙 블록을 주입해 AI가 매 세션 이 토큰들만 보도록 강제한다.

## 사용법 (4단계)

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

### 3) `CLAUDE.md` 에 규칙 블록 주입

`~/.claude/skills/hw-design/assets/CLAUDE.md.snippet` 내용을 프로젝트 `CLAUDE.md` 하단에 붙여넣는다. (없으면 새로 만든다.) 4줄짜리 지시가 AI 를 토큰 기반 작업으로 묶는다:

> 1. `DESIGN.md` 먼저 읽기 · 2. 토큰에서만 값 선택 · 3. 컴포넌트는 `components.*` 기본 · 4. 커밋 전 `token-audit`

### 4) 감사 (커밋 전 또는 CI)

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

## Do's and Don'ts (요약)

**✅ Do**
- `var(--color-*)` / `{colors.*}` 토큰만 사용 — 인라인 hex/px 금지
- Primary 는 포인트 — 화면 면적 ≤ 20%
- 본문 `line-height ≥ 1.5`, 한글 최소 15px, `word-break: keep-all`
- 그림자는 네이비 톤 (`rgba(26, 43, 74, x)`)
- 모션은 `fast/base/slow` 3단계만
- 터치 타겟 ≥ 44×44px, `focus-visible` 링 필수

**❌ Don't**
- 오렌지 위에 오렌지 쌓기 (계층 붕괴)
- 세컨더리 컬러 추가 (2색 대비축이 한화 DNA)
- 그라디언트·네온 남용 (한화는 단색 기조)
- 순검정 `#000000` 본문 텍스트 (디지털은 `#1A2B4A`)
- 한 페이지 3종 이상 라운딩 혼용
- 임의 duration (`0.4s` 같은 값)
- 트리서클 로고 색·비율 변형

## 관련 스킬

- **`/stitch-design`** — Stitch MCP로 **새 DESIGN.md 생성**. `/hw-design`은 **이미 확정된 한화 표준을 배포**.
- **`/frontend-design`** — 코드로 UI 구현. `/hw-design`으로 토큰 깔고 `/frontend-design`으로 컴포넌트 짜는 조합.
- **`/web-design-guidelines`** — 완성된 UI 가 브랜드 규칙을 지켰는지 감사. `token-audit.mjs` 와 상호 보완.
