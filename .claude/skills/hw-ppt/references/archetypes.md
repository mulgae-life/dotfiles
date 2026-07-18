# 9개 슬라이드 아키타입 — 좌표 · 구성 · 코드

> 모든 슬라이드는 이 9개 중 하나다. 생성 시 코드 주석에 아키타입 번호와 이름을 명시한다.
> 좌표는 **1920×1080 px 디자인 그리드** (144dpi Full HD 가정). PPTX EMU 변환은 `round(px × 6350)` (= 12,192,000/1920). HTML deck은 그대로 1920×1080 CSS px. ⚠️ 96dpi 변환 `× 9525`는 표준 슬라이드 밖으로 나가므로 사용 금지.
>
> **PowerPoint 실측 좌표 룰**:
> - 헤더 strip: **y = 0–80** (시그니처 이미지 64 px 수용)
> - 타이틀 밴드 시작: **y = 130** (chapter cue y=130, title y=165)
> - 헤더 시그니처: **`hanwha-signature-ink.png` 한 장** (심볼+wordmark 합본, 비율 2:1, height 64, 텍스트 ink 재페인트)
> - 한글 타이틀 박스 height: **font_px × 1.6** (descender + 두 줄 wrap 안전)
> - subtitle y 위치: **title 박스 끝(`y + font_px × 1.6`) + 24 px**
> - 부제-본문 vertical gap: **≥ 30 px**

## 목차

- [1. Cover (표지)](#1-cover-표지) — `assets/layouts/01-cover.png`
- [2. Two-column (image-left)](#2-two-column-image-left) — `assets/layouts/02-two-column.png`
- [3. Two-column (text-left)](#3-two-column-text-left) — mirrored
- [4. As-Is / To-Be](#4-as-is--to-be) — `assets/layouts/03-as-is-to-be.png`
- [5. Pie chart](#5-pie-chart) — `assets/layouts/04-pie-chart.png`
- [6. Comparison bars](#6-comparison-bars) — `assets/layouts/05-comparison-bars.png`
- [7. Item table](#7-item-table) — `assets/layouts/06-item-table.png`
- [8. Rising graph](#8-rising-graph) — `assets/layouts/07-rising-graph.png`
- [9. Section divider / Closing](#9-section-divider--closing)

---

## 1. Cover (표지)

**Reference**: `assets/layouts/01-cover.png`

### 구성

- 헤더 strip 존재 (챕터 라벨 좌 + 시그니처 우)
- 좌측 절반 (x = 80–880):
  - 오렌지 챕터 cue (Bold 16 px) — `--hw-orange`
  - Display 타이틀 Bold 72 px — `--hw-ink` (※ 표지 전용 사이즈, **박스 height ≥ font_px × 1.6** — descender + 두 줄 wrap 안전)
  - 본문 인트로 5–8줄, Regular 15 px, `--hw-graphite`, line_spacing 1.65 명시
- **페이지 인디케이터**: 우측 하단 y=1040 (다른 슬라이드와 동일) — Cover 인라인 표기 금지
- 우측 절반 (x = 960–1840):
  - Hero 일러스트 / 캐릭터 아트
  - 세로 가득, 외곽 60 px 마진

**Density 처리**: 좌측 본문 인트로가 하단까지 흘러 Density Zone을 자연스럽게 채운다 (별도 stat strip 불필요).

### HTML 예시

```html
<section class="slide cover">
  <!-- 1. Cover -->
  <header class="hw-header">
    <span class="hw-chapter-label">신상품 소개</span>
    <div class="hw-signature">
      <img src="assets/logo/hanwha-signature-ink.png" alt="한화손보" />
    </div>
  </header>

  <div class="cover-left">
    <p class="chapter-cue">2026 신상품</p>
    <h1>운전자 보험 리뉴얼</h1>
    <p class="intro">
      자율주행 시대를 준비하는 한화손해보험의 새로운 운전자 보험.<br>
      음주·과속·신호위반 등 12대 중과실 사고에 대한 보장을 강화하고,<br>
      AI 사고 분석을 통한 즉시 보상 시스템을 도입했습니다.
      <!-- 5-8 lines total to fill density zone -->
    </p>
  </div>

  <div class="cover-right">
    <img src="hero-illustration.png" alt="" />
  </div>

  <!-- 페이지 인디케이터: 우측 하단 y=1040 독립 요소 (Cover도 다른 슬라이드와 동일, 타이틀 인라인 금지) -->
  <span class="page-ind">1 / 4</span>
</section>
```

---

## 2. Two-column (image-left)

**Reference**: `assets/layouts/02-two-column.png`

### 구성

- 헤더 strip 존재
- 좌측 절반 (x = 0–800):
  - 풀-블리드 이미지/사진, y = 80–1080
- 우측 절반 (x = 880–1840):
  - 타이틀 블록: Bold 56 px `--hw-ink` ("안녕하세요" 같은 인사 또는 섹션 타이틀)
  - 서브타이틀: Bold 32 px `--hw-orange` (바로 아래)
  - 본문 텍스트, y = 1010까지 채움
  - line-height 1.55–1.7

### HTML 예시

```html
<section class="slide two-column-image-left">
  <header class="hw-header">...</header>

  <div class="col-image">
    <img src="hero.png" alt="" />
  </div>

  <div class="col-text">
    <h2>안녕하세요</h2>
    <p class="subtitle">한화손해보험입니다</p>
    <p class="body">
      <!-- 본문 — Density Zone까지 자연스럽게 흐름 -->
    </p>
  </div>
</section>
```

```css
.two-column-image-left .col-image {
  position: absolute; left: 0; top: 80px; width: 800px; height: 1000px;
}
.two-column-image-left .col-image img { width: 100%; height: 100%; object-fit: cover; }
.two-column-image-left .col-text {
  position: absolute; left: 880px; top: 130px; width: 960px;
}
.two-column-image-left h2 { font-weight: 700; font-size: 56px; color: var(--hw-ink); margin: 0; }
.two-column-image-left .subtitle { font-weight: 700; font-size: 32px; color: var(--hw-orange); margin: 8px 0 24px; }
.two-column-image-left .body { font-weight: 400; font-size: 15px; color: var(--hw-graphite); line-height: 1.6; }
```

---

## 3. Two-column (text-left)

아키타입 2의 **좌우 미러링 버전**. 텍스트 좌(x = 80–960), 이미지 우(x = 1040–1840).

```css
.two-column-text-left .col-text { left: 80px; top: 130px; width: 880px; }
.two-column-text-left .col-image { left: 1040px; top: 130px; width: 760px; height: 850px; }
```

---

## 4. As-Is / To-Be

**Reference**: `assets/layouts/03-as-is-to-be.png`

### 구성

- 헤더 strip 존재
- 헤더 아래 x = 80에 작은 오렌지 챕터 cue (Regular 14 px) + `--hw-orange` underline
- **트윈 화살표 바**: y = 280–360, x = 100–1820
  - 좌측 절반 "As-Is" — 배경 `--hw-orange-soft`
  - 우측 절반 "To-Be" — 배경 `--hw-orange`
  - 중앙에 화살표 노치
  - 바 높이 80 px, 텍스트 Bold 32 px 흰색 중앙 정렬
- **비교 패널** (y = 380–880): `--hw-orange-tint` 배경, 라운드 8 px
  - 좌측 "현재 상태" / 우측 "목표 상태" 두 컬럼
  - 각 컬럼 4–6 bullets, Regular 15 px
- **Density Zone 예외** (y = 880–1010):
  - 좌측 중앙 (x = 480): **"2024"** Bold 32 px `--hw-orange`
  - 우측 중앙 (x = 1480): **"2025"** Bold 32 px `--hw-orange`
  - 각 연도 아래 한 줄 캡션, `--hw-graphite` 15 px

> ⚠️ As-Is/To-Be는 §6 Density Zone 룰의 **유일한 예외**. Stat strip 대신 연도/앵커 라벨을 사용한다.

---

## 5. Pie chart

**Reference**: `assets/layouts/04-pie-chart.png`

### 구성

- 헤더 strip 존재
- 좌측 (x = 80–800):
  - 오렌지 Bold 48 px 섹션 타이틀 ("비율그래프", "구성비" 등)
  - Bold 24 px 서브타이틀
  - Regular 15 px 본문 인트로 2줄
  - **2컬럼 레전드**, 5개 항목 max:
    - 각 행: bullet swatch + 라벨(Regular 15) + 값(Bold 15)
    - 색상 순서: `--hw-orange`, `--hw-orange-mid`, `--hw-orange-soft`, `--hw-orange-tint`, `--hw-mute`
- 우측 (x = 880–1820):
  - 파이 차트, 지름 ~520 px, 세로 중앙 정렬
  - **도넛 중앙에 시그니처 (작게, ~80 px)**: 단일 dominant slice를 강조할 때
  - Slice 컬러는 반드시 오렌지 패밀리
- Density Zone: Caption 12 px 출처 라인 + 한 줄 해석

### HTML 예시 (SVG 파이)

```html
<section class="slide pie-chart">
  <header class="hw-header">...</header>

  <div class="pie-left">
    <p class="chapter-cue">고객 분포</p>
    <h2 class="section-title">연령대별 가입 비율</h2>
    <p class="subtitle">2025년 1분기 기준</p>
    <p class="intro">자율주행 보험 가입 고객 1,234명 대상...</p>

    <ul class="legend">
      <li><span class="swatch" style="background:#ED6F1F"></span> 30대 <b>60%</b></li>
      <li><span class="swatch" style="background:#F5A678"></span> 40대 <b>20%</b></li>
      <li><span class="swatch" style="background:#FBD5BD"></span> 50대 <b>10%</b></li>
      <li><span class="swatch" style="background:#FCE6D6"></span> 20대 <b>8%</b></li>
      <li><span class="swatch" style="background:#9A9A9A"></span> 기타 <b>2%</b></li>
    </ul>
  </div>

  <div class="pie-right">
    <svg viewBox="0 0 520 520">
      <!-- pie slices -->
    </svg>
    <img src="assets/logo/hanwha-symbol.png" class="pie-center-symbol" alt="" />
  </div>

  <p class="source">출처: 한화손해보험 내부 데이터, 2025.03</p>
</section>
```

---

## 6. Comparison bars

**Reference**: `assets/layouts/05-comparison-bars.png`

### 구성

- 헤더 strip 존재
- 타이틀: 오렌지 Bold 48 px, 서브타이틀 Bold 24 px
- 본문 zone에 **두 차트 가로 배치**, 각 ~720×460 px
  - 좌측 (x = 80), 우측 (x = 920)
- 각 차트:
  - 스택드 바 — 오렌지 패밀리 (4–5 시리즈)
  - 얇은 `--hw-ink` 라인 오버레이로 핵심 메트릭 표시
- 레전드 strip (y = 980), 전체 너비:
  - bullet swatch + Regular 13 px 라벨
  - 최대 5개 항목

### Density Zone

레전드 strip이 Density Zone을 채움. 또는 추가로 한 줄 해석을 위에 배치.

---

## 7. Item table

**Reference**: `assets/layouts/06-item-table.png`

### 구성

- 헤더 strip 존재
- 타이틀 영역 중앙 정렬:
  - 오렌지 Bold 48 px ("항목별표")
  - 바로 아래 `--hw-ink` Bold 26 px 서브타이틀 (중앙)
- 본문 zone에 1–3개 테이블 스택:
  - 각 테이블 앞 한 행 오렌지 헤더 바 (`--hw-orange-tint` 배경, Bold 16 px `--hw-ink`)
- 테이블:
  - 3–5 컬럼
  - 행 교차 색: white / `--hw-mist`
  - 행 높이 56 px
- Density Zone: 레전드 또는 Caption 12 px 풋노트 (예: "– = 해당 없음")

### HTML 예시

```html
<section class="slide item-table">
  <header class="hw-header">...</header>

  <div class="title-center">
    <h2 class="section-title">항목별표</h2>
    <p class="subtitle">상품별 비교</p>
  </div>

  <table class="hw-table">
    <thead><tr><th colspan="3">상품 카테고리</th></tr></thead>
    <thead><tr><th>상품</th><th>설명</th><th>비고</th></tr></thead>
    <tbody>
      <tr><td>상품 A</td><td>자율주행 차량 전용</td><td>–</td></tr>
      <tr><td>상품 B</td><td>플러그인 하이브리드</td><td>–</td></tr>
    </tbody>
  </table>

  <table class="hw-table">
    <thead><tr><th colspan="3">특약</th></tr></thead>
    <thead><tr><th>특약</th><th>설명</th><th>비고</th></tr></thead>
    <tbody>
      <tr><td>특약 A</td><td>AI 사고 분석 즉시 보상</td><td>–</td></tr>
      <tr><td>특약 B</td><td>대인·대물 무한 보장</td><td>–</td></tr>
    </tbody>
  </table>

  <p class="footnote">– = 해당 없음</p>
</section>
```

---

## 8. Rising graph

**Reference**: `assets/layouts/07-rising-graph.png`

### 구성

- 헤더 strip 존재
- 타이틀: 오렌지 Bold 48 px, 서브타이틀 Bold 24 px, Regular 15 px 본문 2줄
- 본문 zone (y = 360–880):
  - **5개 상승 마운틴/화살표**, 좌→우
  - 각 위 라벨: 연도+분기 (Light 22 px)
  - 각 내부/아래 값 (Regular 14 px)
  - 마지막 화살표 solid `--hw-orange`
  - 앞 화살표들은 `--hw-orange-soft` → `--hw-orange-mid` 그라데이션
  - **점선** 트렌드라인이 정점들을 잇는다
- Density Zone: 2–3줄 트렌드 해석, Regular 15 px

### 시각적 특징

- 마운틴 모양: SVG path 또는 CSS clip-path
- 점선: stroke-dasharray
- "2024" → "2025"로 연도 변화 강조 시 좌측은 회색·우측은 오렌지로 색 변화

---

## 9. Section divider / Closing

### 9a. Section divider

- 헤더 strip 존재, 나머지 sparse
- 좌측 (x = 80, y = 280): 큰 챕터 번호 ("01") — `--hw-orange` Bold 200 px
- 바로 아래: 섹션 타이틀 `--hw-ink` Bold 56 px
- 한 줄 abstract: Light 22 px
- Density Zone: 가로 `--hw-orange-soft` strip + 해당 섹션 agenda (Regular 15 px)

### 9b. Closing

- 표지 구조 mirror
- 타이틀 → "감사합니다" 또는 연락처 라인
- 고객센터: **1566-8000**
- 옵션 QR → **hwgeneralins.com**

---

## 부록: PPTX EMU 좌표 (1920×1080 디자인 → 13.333"×7.5" 표준 슬라이드)

> **단위 가정**: 디자인 좌표 1920×1080은 144dpi Full HD 가정. PowerPoint Widescreen 16:9 표준 슬라이드 13.333" × 7.5"에 매핑. 변환 비율 **`1 디자인 px = 6,350 EMU`** (= 12,192,000 EMU / 1920 px). 일반적인 96dpi 변환 `× 9525`는 **사용 금지** — 1920×1080 디자인을 적용하면 20"×11.25" 비표준 슬라이드가 되거나 콘텐츠가 표준 슬라이드 밖으로 나간다.

| 위치 | 디자인 px | EMU | 인치 |
|------|-----------|------|------|
| 헤더 strip y=0 | 0 | 0 | 0" |
| 헤더 strip y=80 (끝) | 80 | 508,000 | 0.556" |
| 타이틀 밴드 시작 y=130 | 130 | 825,500 | 0.903" |
| 타이틀 밴드 끝 y=270 | 270 | 1,714,500 | 1.875" |
| 본문 zone 시작 y=300 | 300 | 1,905,000 | 2.083" |
| 본문 zone 끝 y=820 | 820 | 5,207,000 | 5.694" |
| Density Zone 시작 y=840 | 840 | 5,334,000 | 5.833" |
| Density Zone 끝 y=1010 | 1010 | 6,413,500 | 7.014" |
| 좌측 마진 x=80 | 80 | 508,000 | 0.556" |
| 우측 마진 x=1840 (=1920-80) | 1840 | 11,684,000 | 12.778" |
| 슬라이드 폭 1920 | 1920 | 12,192,000 | 13.333" |
| 슬라이드 높이 1080 | 1080 | 6,858,000 | 7.5" |

> 변환 헬퍼 `px(n) = Emu(round(n * 6350))` 및 폰트 변환은 `pptx-implementation.md` § 6 참조.
