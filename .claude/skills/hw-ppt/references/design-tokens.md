# Design Tokens — 컬러 · 타이포 · 간격 · 라운딩

> 모든 토큰은 **1920×1080 px 디자인 그리드** (144dpi Full HD 가정). HTML deck은 그대로 CSS px. PPTX 변환은 `round(px × 6350)` EMU (PowerPoint 표준 13.333"×7.5" 슬라이드에 매핑). ⚠️ 일반적인 96dpi 변환 `× 9525`는 1920×1080 디자인에 사용 시 슬라이드 밖으로 콘텐츠가 나가므로 금지.

## 1. Color Tokens

### Primary (Orange family)

| Token | Value | RGB | 용도 |
|---|---|---|---|
| `--hw-orange` | `#ED6F1F` | `237, 111, 31` | **Primary accent**. 섹션 타이틀, 차트 메인 시리즈, 핵심 콜아웃 |
| `--hw-orange-deep` | `#D85A0E` | `216, 90, 14` | Hover, active 상태, 강조 |
| `--hw-orange-mid` | `#F5A678` | `245, 166, 120` | 차트 중간 세그먼트, 보조 액센트 |
| `--hw-orange-soft` | `#FBD5BD` | `251, 213, 189` | 차트 약한 세그먼트, 부드러운 강조 |
| `--hw-orange-tint` | `#FCE6D6` | `252, 230, 214` | 본문 wash, As-Is/To-Be 패널, 테이블 호버 |

### Neutral

| Token | Value | RGB | 용도 |
|---|---|---|---|
| `--hw-ink` | `#1A1A1A` | `26, 26, 26` | 본문 텍스트, 타이틀 |
| `--hw-graphite` | `#4A4A4A` | `74, 74, 74` | 본문, 챕터 라벨, 보조 카피 |
| `--hw-mute` | `#9A9A9A` | `154, 154, 154` | 캡션, 축 라벨 |
| `--hw-line` | `#E1E1E1` | `225, 225, 225` | 디바이더, 표 그리드, 헤더 하단선 |
| `--hw-mist` | `#F5F5F5` | `245, 245, 245` | 헤더 strip 배경, 표 alt 행 |
| `--hw-paper` | `#FFFFFF` | `255, 255, 255` | 슬라이드 배경 |

### 사용 규칙

- 오렌지는 **액센트** — 본문 텍스트 뒤 flood-fill 금지
- `orange-soft`/`mid`/`tint`은 차트·As-Is/To-Be 바·테이블 헤더·약한 wash 전용
- 한 차트의 시리즈 색상 순서: `orange` → `orange-mid` → `orange-soft` → `orange-tint` → `mute`
- 본문은 `--hw-graphite` 또는 `--hw-ink` — 순검정 `#000000` 금지

## 2. Typography Tokens

### Font family

- **Primary**: 한화체 (Hanwha) — Bold(B) / Regular(R) / Light(L)
- **Fallback**: sans-serif (시스템 폴백, 가시 노출되면 안 됨)

`hw-design` 스킬에 .ttf 3종 존재:
- `~/.claude/skills/hw-design/assets/fonts/Hanwha/HanwhaB.ttf` (700)
- `~/.claude/skills/hw-design/assets/fonts/Hanwha/HanwhaR.ttf` (400)
- `~/.claude/skills/hw-design/assets/fonts/Hanwha/HanwhaL.ttf` (300)

PPTX는 .ttf 직접 임베드. HTML deck은 base64 인라인 또는 외부 참조.

### Scale (1920×1080 기준)

| Level | Weight | Size (px) | Color | Usage |
|---|---|---|---|---|
| Display (cover) | Bold | 72 | `--hw-ink` | 표지 타이틀만 |
| Section title | Bold | 48 | `--hw-orange` | 차트·섹션 hero 타이틀 |
| Slide title | Bold | 40 | `--hw-ink` | 기본 본문 슬라이드 타이틀 |
| Subtitle | Bold | 24 | `--hw-ink` | 타이틀 하단 |
| Chapter cue | Bold | 16 | `--hw-orange` | 타이틀 위 미니 라벨 |
| Header chapter label | Regular | 14 | `--hw-graphite` | 상단 헤더 strip 내부 |
| Body | Regular | 15 | `--hw-graphite` | 기본 본문 |
| Body small | Light | 13 | `--hw-graphite` | 장문 |
| Caption | Light | 12 | `--hw-mute` | 출처, 축 라벨 |
| Stat number | Bold | 56 | `--hw-orange` or `--hw-ink` | 숫자 콜아웃 |
| Page indicator | Regular | 13 | `--hw-mute` | "1 / 4" |

### Line-height & letter-spacing

- 본문: line-height **1.55–1.7**
- 타이틀: line-height **1.1**
- letter-spacing: 한국어 기본 0, 영문 챕터 라벨은 `0.01em`

## 3. Spacing Tokens

| Token | Value | 용도 |
|---|---|---|
| `--space-xs` | `4 px` | 인라인 마이크로 간격 |
| `--space-sm` | `8 px` | 심볼-wordmark 갭, 차트 레전드 간격 |
| `--space-md` | `16 px` | 카드 내부 패딩 |
| `--space-lg` | `24 px` | 컬럼 간격, 타이틀 하단 마진 |
| `--space-xl` | `40 px` | 헤더 좌우 인셋, 페이지 인디케이터 인셋 |
| `--space-2xl` | `80 px` | 슬라이드 좌측 마진 (x = 80) |

## 4. Border Radius

| Token | Value | 용도 |
|---|---|---|
| `--radius-sm` | `4 px` | 작은 배지, 인라인 칩 |
| `--radius-md` | `8 px` | As-Is/To-Be 패널, 카드 |
| `--radius-lg` | `12 px` | 큰 카드 |
| `--radius-pill` | `999 px` | 둥근 버튼, 토큰 |

## 5. Layout Tokens

| Token | Value | 용도 |
|---|---|---|
| `--canvas-w` | `1920 px` | 슬라이드 폭 |
| `--canvas-h` | `1080 px` | 슬라이드 높이 |
| `--header-h` | `56 px` | 헤더 strip 높이 |
| `--margin-x` | `80 px` | 슬라이드 좌측 마진 (기본) |
| `--margin-header` | `40 px` | 헤더 좌우 인셋 |
| `--title-band-top` | `110 px` | 타이틀 밴드 시작 |
| `--title-band-bottom` | `270 px` | 타이틀 밴드 끝 |
| `--body-top` | `300 px` | 본문 zone 시작 |
| `--body-bottom` | `820 px` | 본문 zone 끝 |
| `--density-top` | `840 px` | Density Zone 시작 |
| `--density-bottom` | `1010 px` | Density Zone 끝 |
| `--page-ind-y` | `1040 px` | 페이지 인디케이터 위치 |

## 6. CSS 변수 모음

```css
:root {
  /* Color — Primary */
  --hw-orange: #ED6F1F;
  --hw-orange-deep: #D85A0E;
  --hw-orange-mid: #F5A678;
  --hw-orange-soft: #FBD5BD;
  --hw-orange-tint: #FCE6D6;
  /* Color — Neutral */
  --hw-ink: #1A1A1A;
  --hw-graphite: #4A4A4A;
  --hw-mute: #9A9A9A;
  --hw-line: #E1E1E1;
  --hw-mist: #F5F5F5;
  --hw-paper: #FFFFFF;
  /* Spacing */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 40px;
  --space-2xl: 80px;
  /* Layout */
  --canvas-w: 1920px;
  --canvas-h: 1080px;
  --header-h: 56px;
  --margin-x: 80px;
  --margin-header: 40px;
}

@font-face { font-family: "Hanwha"; src: url("fonts/HanwhaL.ttf") format("truetype"); font-weight: 300; }
@font-face { font-family: "Hanwha"; src: url("fonts/HanwhaR.ttf") format("truetype"); font-weight: 400; }
@font-face { font-family: "Hanwha"; src: url("fonts/HanwhaB.ttf") format("truetype"); font-weight: 700; }

* { font-family: "Hanwha", sans-serif; -webkit-font-smoothing: antialiased; }
```

## 7. Python (PPTX) RGBColor 정의

```python
from pptx.dml.color import RGBColor

HW_ORANGE       = RGBColor(0xED, 0x6F, 0x1F)
HW_ORANGE_DEEP  = RGBColor(0xD8, 0x5A, 0x0E)
HW_ORANGE_MID   = RGBColor(0xF5, 0xA6, 0x78)
HW_ORANGE_SOFT  = RGBColor(0xFB, 0xD5, 0xBD)
HW_ORANGE_TINT  = RGBColor(0xFC, 0xE6, 0xD6)
HW_INK          = RGBColor(0x1A, 0x1A, 0x1A)
HW_GRAPHITE     = RGBColor(0x4A, 0x4A, 0x4A)
HW_MUTE         = RGBColor(0x9A, 0x9A, 0x9A)
HW_LINE         = RGBColor(0xE1, 0xE1, 0xE1)
HW_MIST         = RGBColor(0xF5, 0xF5, 0xF5)
HW_PAPER        = RGBColor(0xFF, 0xFF, 0xFF)
```
