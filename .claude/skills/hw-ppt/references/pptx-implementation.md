# PPTX / HTML 구현 가이드

> .pptx와 HTML deck 두 포맷의 실제 코드. Anthropic 공식 `pptx` 스킬 연계 + python-pptx 직접 사용 + 단일 파일 HTML 모두 다룸.

## 목차

1. [Anthropic pptx 스킬 활용 (권장)](#1-anthropic-pptx-스킬-활용-권장)
2. [python-pptx 직접 사용](#2-python-pptx-직접-사용)
3. [HTML deck 템플릿](#3-html-deck-템플릿)
4. [폰트 임베드](#4-폰트-임베드)
5. [로고 알파 변환](#5-로고-알파-변환)
6. [px → EMU 변환 헬퍼](#6-px--emu-변환-헬퍼)

---

## 1. Anthropic pptx 스킬 활용 (권장)

Anthropic 공식 `pptx` 스킬은 python-pptx 기반의 .pptx 생성·편집 엔진이다. `hw-ppt`가 디자인 표준(좌표·컬러·아키타입)을 정의하면, 호출 시 `pptx` 스킬이 파일 생성을 담당한다.

### 패턴

```
1. hw-ppt 트리거 → SKILL.md + references/ 로드
2. archetypes.md에서 슬라이드별 아키타입 결정
3. design-tokens.md에서 컬러·타이포·좌표 확정
4. pptx 스킬 호출 (또는 직접 python-pptx 사용)
5. 셀프 체크 → 산출
```

Claude Code 환경에서는 `pptx` 스킬이 별도 플러그인으로 설치되어 있어야 한다 (`/plugin install pptx@anthropic-skills` 또는 동등). 미설치 시 [§2 직접 사용](#2-python-pptx-직접-사용)으로 fallback.

---

## 2. python-pptx 직접 사용

### 환경 준비

```bash
pip install python-pptx
# 한화체 .ttf는 ~/.claude/skills/hw-design/assets/fonts/Hanwha/ 에 이미 존재
```

### 기본 셋업

```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pathlib import Path

# Color tokens (design-tokens.md 참조)
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

FONT_NAME = "Hanwha"  # 한화체

# px → EMU 변환 (1920×1080 디자인 좌표를 13.333"×7.5" 슬라이드에 매핑)
# ⚠️ 96dpi 가정의 9525가 아니라 6350 (= 12,191,996/1920) 사용해야 슬라이드 안에 맞음
def px(n):
    """1920×1080 디자인 좌표 → PPTX EMU."""
    return Emu(round(n * 6350))

# Slide setup — PowerPoint Widescreen 16:9 표준 (PPT 2013+ 기본값)
# 슬라이드 크기는 EMU 12,191,996 × 6,858,000 으로 고정 (13.333" × 7.5").
# 디자인 좌표 1920×1080 는 "144dpi Full HD 디자이너 관행" 으로, 이 슬라이드에
# 정확히 매핑하려면 1 디자인 px = 6,350 EMU (=12,191,996/1920) 비율 사용.
prs = Presentation()
prs.slide_width  = Inches(13.333)  # = 12,191,996 EMU = 1920 px @144dpi
prs.slide_height = Inches(7.5)     # =  6,858,000 EMU = 1080 px @144dpi
```

### 헤더 strip (모든 콘텐츠 슬라이드)

```python
def add_header(slide, chapter_label: str, symbol_path: str):
    # 1. Strip background (gray fill, full width, y=0~56)
    strip = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE,
        left=px(0), top=px(0),
        width=px(1920), height=px(56),
    )
    strip.fill.solid()
    strip.fill.fore_color.rgb = HW_MIST
    strip.line.color.rgb = HW_LINE  # 하단 1px line
    strip.line.width = Emu(9525)  # 1px

    # 2. Chapter label (left, 40px inset)
    lbl = slide.shapes.add_textbox(
        left=px(40), top=px(0),
        width=px(600), height=px(56),
    )
    p = lbl.text_frame.paragraphs[0]
    p.text = chapter_label
    p.font.name = FONT_NAME
    p.font.size = Pt(10.5)  # 14px ≈ 10.5pt @72dpi
    p.font.color.rgb = HW_GRAPHITE
    lbl.text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE

    # 3. Signature (right, 40px inset)
    # 심볼은 28px 높이, 우측 가장자리에서 40px + wordmark 폭만큼 안쪽
    wordmark_text = "한화손보"
    # 시그니처는 정확한 우측 정렬이 중요 — 한 textbox에 심볼 inline 대신
    # 심볼 이미지 + wordmark textbox 두 개를 좌표 계산하여 배치
    sym = slide.shapes.add_picture(
        symbol_path,
        left=px(1920 - 40 - 100),  # 추정 — wordmark 폭 따라 조정
        top=px(14),                 # 56px strip 안에서 28px 심볼 중앙
        height=px(28),
    )
    wm = slide.shapes.add_textbox(
        left=px(1920 - 40 - 70),  # wordmark 너비 ~70px
        top=px(0),
        width=px(70),
        height=px(56),
    )
    p = wm.text_frame.paragraphs[0]
    p.text = wordmark_text
    p.font.name = FONT_NAME
    p.font.size = Pt(13.5)  # 18px ≈ 13.5pt
    p.font.bold = True
    p.font.color.rgb = HW_INK
    wm.text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE
```

### Title band (모든 콘텐츠 슬라이드)

```python
def add_title(slide, title: str, subtitle: str = "",
              chapter_cue: str = "", title_color=HW_INK, title_size_pt=30):
    """타이틀 밴드 y=110–270. 좌측 정렬 기본."""
    y = 110
    if chapter_cue:
        cue = slide.shapes.add_textbox(
            left=px(80), top=px(y), width=px(800), height=px(24),
        )
        p = cue.text_frame.paragraphs[0]
        p.text = chapter_cue
        p.font.name = FONT_NAME
        p.font.size = Pt(12)  # 16px
        p.font.bold = True
        p.font.color.rgb = HW_ORANGE
        y += 30  # next line

    tit = slide.shapes.add_textbox(
        left=px(80), top=px(y), width=px(1760), height=px(60),
    )
    p = tit.text_frame.paragraphs[0]
    p.text = title
    p.font.name = FONT_NAME
    p.font.size = Pt(title_size_pt)  # 40px → 30pt, 48px → 36pt, 72px → 54pt
    p.font.bold = True
    p.font.color.rgb = title_color
    y += title_size_pt + 10

    if subtitle:
        sub = slide.shapes.add_textbox(
            left=px(80), top=px(y), width=px(1760), height=px(36),
        )
        p = sub.text_frame.paragraphs[0]
        p.text = subtitle
        p.font.name = FONT_NAME
        p.font.size = Pt(18)  # 24px
        p.font.bold = True
        p.font.color.rgb = HW_INK
```

### Density Zone — Stat strip 예시

```python
def add_density_stat_strip(slide, stats: list[tuple[str, str]]):
    """stats = [(value, label), ...]"""
    n = len(stats)
    col_w = (1920 - 160) // n  # 좌우 마진 80*2
    for i, (val, lbl) in enumerate(stats):
        x = 80 + i * col_w
        # Value
        v = slide.shapes.add_textbox(
            left=px(x), top=px(840), width=px(col_w), height=px(56),
        )
        p = v.text_frame.paragraphs[0]
        p.text = val
        p.font.name = FONT_NAME
        p.font.size = Pt(30)  # 40px
        p.font.bold = True
        p.font.color.rgb = HW_ORANGE
        # Label
        l = slide.shapes.add_textbox(
            left=px(x), top=px(905), width=px(col_w), height=px(20),
        )
        p = l.text_frame.paragraphs[0]
        p.text = lbl
        p.font.name = FONT_NAME
        p.font.size = Pt(9.75)  # 13px
        p.font.color.rgb = HW_GRAPHITE
```

### 전체 데크 생성 흐름

```python
def build_deck(output_path: str, symbol_path: str):
    prs = Presentation()
    prs.slide_width  = Inches(13.333)
    prs.slide_height = Inches(7.5)

    # 1. Cover
    slide1 = prs.slides.add_slide(prs.slide_layouts[6])  # blank
    add_header(slide1, "신상품 소개", symbol_path)
    add_title(slide1, "운전자 보험 리뉴얼", chapter_cue="2026 신상품", title_size_pt=54)
    # ... cover의 우측 hero image, 좌측 intro body 추가 ...

    # 2. Two-column
    slide2 = prs.slides.add_slide(prs.slide_layouts[6])
    add_header(slide2, "신상품 소개", symbol_path)
    add_title(slide2, "안녕하세요", subtitle="한화손해보험입니다", title_size_pt=42)
    # ... 좌측 이미지, 우측 본문 ...
    add_density_stat_strip(slide2, [
        ("1,234", "가입 고객"),
        ("23.4%", "YoY 성장"),
        ("98.7%", "고객 만족도"),
        ("1566-8000", "24시 고객센터"),
    ])

    # ... 나머지 슬라이드 ...

    prs.save(output_path)

if __name__ == "__main__":
    build_deck(
        "out.pptx",
        symbol_path=str(Path.home() / ".claude/skills/hw-ppt/assets/logo/hanwha-symbol.png"),
    )
```

---

## 3. HTML deck 템플릿

단일 파일 HTML — 각 `<section class="slide">` 가 1920×1080 px.

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>한화손해보험 — [덱 제목]</title>
<style>
  @font-face { font-family: "Hanwha"; src: url("HanwhaL.ttf") format("truetype"); font-weight: 300; }
  @font-face { font-family: "Hanwha"; src: url("HanwhaR.ttf") format("truetype"); font-weight: 400; }
  @font-face { font-family: "Hanwha"; src: url("HanwhaB.ttf") format("truetype"); font-weight: 700; }

  :root {
    --hw-orange: #ED6F1F; --hw-orange-deep: #D85A0E;
    --hw-orange-mid: #F5A678; --hw-orange-soft: #FBD5BD; --hw-orange-tint: #FCE6D6;
    --hw-ink: #1A1A1A; --hw-graphite: #4A4A4A; --hw-mute: #9A9A9A;
    --hw-line: #E1E1E1; --hw-mist: #F5F5F5; --hw-paper: #FFFFFF;
  }

  * { box-sizing: border-box; font-family: "Hanwha", sans-serif; -webkit-font-smoothing: antialiased; }
  body { margin: 0; background: #222; padding: 40px 0; }

  .slide {
    position: relative;
    width: 1920px; height: 1080px;
    background: var(--hw-paper);
    margin: 0 auto 40px;
    overflow: hidden;
  }

  /* Header strip — 모든 콘텐츠 슬라이드 동일 */
  .hw-header {
    position: absolute; inset: 0 0 auto 0;
    height: 56px;
    background: var(--hw-mist);
    border-bottom: 1px solid var(--hw-line);
    display: flex; align-items: center; justify-content: space-between;
    padding: 0 40px;
  }
  .hw-chapter-label {
    font-weight: 400; font-size: 14px;
    color: var(--hw-graphite); letter-spacing: 0.01em;
  }
  .hw-signature { display: flex; align-items: center; gap: 8px; }
  .hw-signature img { height: 28px; width: auto; display: block; }
  .hw-signature span {
    font-weight: 700; font-size: 18px;
    color: var(--hw-ink); line-height: 1;
  }

  /* Title band — y = 110–270 */
  .chapter-cue {
    position: absolute; left: 80px; top: 110px;
    font-weight: 700; font-size: 16px; color: var(--hw-orange); margin: 0;
  }
  h1, h2, .section-title {
    position: absolute; left: 80px; top: 140px;
    margin: 0; line-height: 1.1;
  }
  h1 { font-weight: 700; font-size: 40px; color: var(--hw-ink); }
  .section-title { font-weight: 700; font-size: 48px; color: var(--hw-orange); }
  .subtitle {
    position: absolute; left: 80px; top: 200px;
    font-weight: 700; font-size: 24px; color: var(--hw-ink); margin: 0;
  }

  /* Body zone — y = 300–820 */
  .body { position: absolute; left: 80px; right: 80px; top: 300px;
    font-weight: 400; font-size: 15px; color: var(--hw-graphite); line-height: 1.6; }

  /* Density Zone — y = 840–1010 */
  .density-stat-strip {
    position: absolute; left: 80px; right: 80px; top: 840px;
    display: grid; grid-template-columns: repeat(var(--cols, 4), 1fr); gap: 24px;
  }
  .density-stat-strip .stat b {
    display: block; font-weight: 700; font-size: 40px; color: var(--hw-orange); line-height: 1;
  }
  .density-stat-strip .stat span {
    display: block; font-weight: 300; font-size: 13px; color: var(--hw-graphite); margin-top: 8px;
  }

  /* Page indicator */
  .page-ind {
    position: absolute; right: 80px; top: 1040px;
    font-weight: 400; font-size: 13px; color: var(--hw-mute);
  }
</style>
</head>
<body>

<!-- Slide 1: Cover -->
<section class="slide">
  <header class="hw-header">
    <span class="hw-chapter-label">신상품 소개</span>
    <div class="hw-signature">
      <img src="assets/logo/hanwha-symbol.png" alt="한화손보" />
      <span>한화손보</span>
    </div>
  </header>
  <p class="chapter-cue">2026 신상품</p>
  <h1>운전자 보험 리뉴얼</h1>
  <!-- ... -->
</section>

<!-- Slide 2: Two-column -->
<section class="slide">
  <header class="hw-header">...</header>
  <h1>안녕하세요</h1>
  <p class="subtitle">한화손해보험입니다</p>
  <p class="body">...</p>
  <div class="density-stat-strip" style="--cols: 4">
    <div class="stat"><b>1,234</b><span>가입 고객</span></div>
    <div class="stat"><b>23.4%</b><span>YoY 성장</span></div>
    <div class="stat"><b>98.7%</b><span>고객 만족도</span></div>
    <div class="stat"><b>1566-8000</b><span>24시 고객센터</span></div>
  </div>
  <span class="page-ind">2 / 4</span>
</section>

<!-- ... 나머지 슬라이드 ... -->

</body>
</html>
```

---

## 4. 폰트 임베드

### 한화체 .ttf (hw-design 스킬에서 복사)

```bash
SRC=~/.claude/skills/hw-design/assets/fonts/Hanwha
DST=./fonts  # 또는 PPTX 산출물 폴더

mkdir -p $DST
cp $SRC/HanwhaB.ttf $DST/
cp $SRC/HanwhaR.ttf $DST/
cp $SRC/HanwhaL.ttf $DST/
```

PPTX는 .ttf를 직접 사용 (별도 임베드 불필요 — `python-pptx`의 `font.name = "Hanwha"`로 참조).

HTML deck은 `@font-face` + 상대 경로 (또는 base64 인라인).

### ⚠️ 한글 렌더링: eastAsia typeface 설정

`python-pptx`의 `run.font.name = "Hanwha"`는 **latin typeface만** 설정한다. 한글 글자는 PowerPoint가 fallback 폰트로 렌더링하여 한화체가 아닌 시스템 한글 폰트(예: 맑은 고딕)로 보일 수 있다.

해결: `<a:ea typeface="Hanwha"/>` XML을 직접 삽입.

```python
from lxml import etree
from pptx.oxml.ns import qn

def set_font_with_korean(run, font_name: str = "Hanwha", bold: bool = False, size_pt: int = 15):
    """run에 latin + eastAsia typeface 모두 설정. 한글이 한화체로 렌더링되도록."""
    run.font.name = font_name        # latin typeface
    run.font.bold = bold
    run.font.size = Pt(size_pt)

    # eastAsia typeface 직접 XML 삽입
    rPr = run._r.get_or_add_rPr()
    # 기존 ea 요소 제거 (중복 방지)
    for existing in rPr.findall(qn('a:ea')):
        rPr.remove(existing)
    ea = etree.SubElement(rPr, qn('a:ea'))
    ea.set('typeface', font_name)

# 사용
p = textbox.text_frame.paragraphs[0]
run = p.add_run()
run.text = "한화손해보험 신상품 안내"  # 한글
set_font_with_korean(run, font_name="Hanwha", bold=True, size_pt=40)
```

> 영문/숫자만 있는 텍스트는 `font.name`만으로 충분. 한글 포함 시 반드시 `set_font_with_korean` 헬퍼 사용.

### 한화고딕 .woff2 → .ttf 변환 (본문 폰트 필요 시)

`hw-design` 스킬은 한화고딕을 .woff2로만 갖고 있다. .pptx는 .ttf/.otf만 지원하므로 변환 필요.

```bash
pip install fonttools brotli

python3 << 'PYEOF'
from fontTools.ttLib import TTFont
import os

src_dir = os.path.expanduser("~/.claude/skills/hw-design/assets/fonts/HanwhaGothic")
dst_dir = "./fonts"
os.makedirs(dst_dir, exist_ok=True)

for name in ["HanwhaGothicB", "HanwhaGothicEL", "HanwhaGothicL", "HanwhaGothicR", "HanwhaGothicT"]:
    src = f"{src_dir}/{name}.woff2"
    dst = f"{dst_dir}/{name}.ttf"
    f = TTFont(src)
    f.flavor = None  # remove woff2 compression
    f.save(dst)
    print(f"{src} → {dst}")
PYEOF
```

> 보통은 한화체 3종(B/R/L)만으로 충분. 한화고딕은 본문 장문 가독성이 정말 필요할 때만 변환.

---

## 5. 로고 알파 변환

`assets/logo/hanwha-signature.png`와 `hanwha-symbol.png`는 현재 검정 배경 JPEG (사용자가 클로드 웹에서 사용하던 원본). 알파 PNG로 변환 권장.

### Pillow 사용

```bash
pip install Pillow

python3 << 'PYEOF'
from PIL import Image
from pathlib import Path

logo_dir = Path.home() / ".claude/skills/hw-ppt/assets/logo"
for fname in ["hanwha-signature.png", "hanwha-symbol.png"]:
    p = logo_dir / fname
    img = Image.open(p).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    # 어두운 픽셀 (R,G,B < 30) → 알파 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r < 30 and g < 30 and b < 30:
                pixels[x, y] = (0, 0, 0, 0)
    img.save(p, "PNG")
    print(f"{p}: {w}×{h} → alpha PNG 저장")
PYEOF
```

### ImageMagick 사용 (대안)

```bash
cd ~/.claude/skills/hw-ppt/assets/logo
for f in hanwha-signature.png hanwha-symbol.png; do
  convert "$f" -fuzz 10% -transparent black "alpha-$f"
  mv "alpha-$f" "$f"
done
```

> Pillow도 ImageMagick도 없으면 SKILL.md 안내에 따라 .pptx에서 검정 배경 그대로 사용 가능 (단, 슬라이드 헤더 배경이 `--hw-mist` 회색이면 검정이 도드라짐 — 알파 변환 권장).

---

## 6. px → EMU 변환 헬퍼

PPTX 내부 단위는 EMU (English Metric Unit). 1 inch = 914,400 EMU.

**중요**: PowerPoint Widescreen 16:9 슬라이드는 13.333" × 7.5" (= 12,191,996 × 6,858,000 EMU) 고정. 디자인 좌표 1920×1080은 144dpi Full HD 가정이므로 1 디자인 px = **6,350 EMU** (= 12,191,996 / 1920).

```python
from pptx.util import Emu, Inches, Pt

def px(n):
    """1920×1080 디자인 좌표 → PPTX EMU (13.333"×7.5" 슬라이드)."""
    return Emu(round(n * 6350))

# 사용
slide_w_design = 1920    # → Emu(12,192,000) ≈ Inches(13.333)
slide_h_design = 1080    # → Emu( 6,858,000) = Inches(7.5)
header_h_design = 56     # → Emu(  355,600)
margin_x_design = 80     # → Emu(  508,000)

# 폰트 px → pt
# 디자인 px는 1/96 inch (CSS 스펙)이고, 144dpi 디스플레이에선 1 디자인 px가
# 1.5 디스플레이 px로 보임. PPTX 폰트는 pt 단위(1pt = 1/72 inch)이므로
# 디자인 px → pt 변환은 ×0.75 (= 72/96) 그대로 유지.
def px_to_pt(px_size):
    return Pt(px_size * 0.75)

# 예: 72px → 54pt (Display), 48px → 36pt (Section), 40px → 30pt (Title),
#     24px → 18pt (Subtitle), 15px → 11.25pt (Body)
```

### 주요 좌표 EMU 표 (1920×1080 디자인 → PPTX EMU)

| 위치 | 디자인 px | EMU | 인치 |
|------|-----------|------|------|
| 헤더 y=0 | 0 | 0 | 0" |
| 헤더 y=56 (끝) | 56 | 355,600 | 0.39" |
| 타이틀 y=110 | 110 | 698,500 | 0.76" |
| 타이틀 y=140 | 140 | 889,000 | 0.97" |
| 본문 y=300 | 300 | 1,905,000 | 2.08" |
| Density y=840 | 840 | 5,334,000 | 5.83" |
| 페이지 인디 y=1040 | 1040 | 6,604,000 | 7.22" |
| 좌측 마진 x=80 | 80 | 508,000 | 0.56" |
| 좌측 인셋 x=40 (헤더) | 40 | 254,000 | 0.28" |
| 슬라이드 폭 1920 | 1920 | 12,192,000 | 13.333" |
| 슬라이드 높이 1080 | 1080 | 6,858,000 | 7.5" |

### ⚠️ 자주 하는 실수: 9525 비율 오용

`1 px @96dpi = 9525 EMU`는 일반적인 변환식이지만 PowerPoint 표준 슬라이드 디자인에는 **부적합**. 1920×1080 디자인 좌표에 9525를 곱하면:
- 1920 × 9525 = 18,288,000 EMU = **20 inch** (= 표준 슬라이드 폭 13.333"의 1.5배 밖)
- 결과: 모든 우측 콘텐츠가 슬라이드 경계 밖으로 나가 보이지 않음

올바른 변환: **`× 6350`** (= 12,191,996/1920). 또는 슬라이드 크기를 20" × 11.25"로 키우면 9525 사용 가능하나 비표준이라 권장 X.

---

## 7. 파이 차트 (MSO_SHAPE.PIE 각도 조정)

`MSO_SHAPE.PIE`는 기본적으로 90° 슬라이스만 그린다. 정확한 슬라이스 각도는 `adjustments` 속성을 통해 `degree × 60000` 단위로 설정.

```python
from pptx.enum.shapes import MSO_SHAPE
from pptx.util import Emu
import math

def add_pie_slice(slide, cx_px, cy_px, radius_px, start_deg, end_deg, fill_color):
    """
    파이 슬라이스 추가.
    start_deg, end_deg: 시계 방향, 0° = 위쪽 (12시), 90° = 오른쪽 (3시)
    """
    # MSO_SHAPE.PIE는 좌상단 기준 bounding box + adj1(시작각)/adj2(종료각)
    left = px(cx_px - radius_px)
    top  = px(cy_px - radius_px)
    w    = px(radius_px * 2)
    h    = px(radius_px * 2)

    shape = slide.shapes.add_shape(MSO_SHAPE.PIE, left, top, w, h)

    # PowerPoint의 PIE adjustment: 0° = 동(3시), 반시계 방향 양수
    # 일반 차트의 0° = 북(12시), 시계 방향과 다르다 — 변환 필요
    # PPT 각도 = (90 - normal_deg) % 360
    ppt_start = (90 - end_deg) % 360
    ppt_end   = (90 - start_deg) % 360

    shape.adjustments[0] = ppt_start  # adj1
    shape.adjustments[1] = ppt_end    # adj2

    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    shape.line.fill.background()  # no border
    return shape


def add_pie_chart(slide, cx_px, cy_px, radius_px, data: list[tuple[float, "RGBColor"]],
                  donut_hole_radius_px: int = 0, center_image_path: str = None):
    """
    data: [(value, color), ...]. 합산하여 percentage 계산.
    donut_hole_radius_px: 0이면 솔리드 파이, > 0이면 도넛
    center_image_path: 도넛 중앙에 배치할 이미지 (예: hanwha-symbol.png)
    """
    total = sum(v for v, _ in data)
    current_deg = 0
    for value, color in data:
        slice_deg = 360 * value / total
        add_pie_slice(slide, cx_px, cy_px, radius_px,
                      current_deg, current_deg + slice_deg, color)
        current_deg += slice_deg

    # 도넛 효과: 중앙에 흰 원
    if donut_hole_radius_px > 0:
        hole = slide.shapes.add_shape(
            MSO_SHAPE.OVAL,
            px(cx_px - donut_hole_radius_px), px(cy_px - donut_hole_radius_px),
            px(donut_hole_radius_px * 2), px(donut_hole_radius_px * 2),
        )
        hole.fill.solid(); hole.fill.fore_color.rgb = HW_PAPER
        hole.line.fill.background()

    # 도넛 중앙 심볼
    if center_image_path and donut_hole_radius_px > 0:
        img_size = donut_hole_radius_px  # 직경의 절반
        slide.shapes.add_picture(
            center_image_path,
            px(cx_px - img_size // 2), px(cy_px - img_size // 2),
            width=px(img_size), height=px(img_size),
        )


# 사용 (archetype 5 Pie chart)
add_pie_chart(
    slide,
    cx_px=1350, cy_px=540, radius_px=260,
    data=[
        (60, HW_ORANGE),
        (20, HW_ORANGE_MID),
        (10, HW_ORANGE_SOFT),
        ( 8, HW_ORANGE_TINT),
        ( 2, HW_MUTE),
    ],
    donut_hole_radius_px=100,
    center_image_path="assets/logo/hanwha-symbol.png",
)
```

> `MSO_SHAPE.PIE`의 각도 좌표계가 일반적인 시계 방향 0°=북 표기와 다른 점을 주의. 위 헬퍼는 normal_deg(0°=12시, 시계방향)를 PPT 좌표로 자동 변환한다.

---

## 부록: Anthropic pptx 스킬과 hw-ppt의 결합 패턴

```
사용자: "신상품 소개 PPT 5장 만들어줘 (한화손보 톤)"
         ↓
[Claude]
  1. hw-ppt 트리거 (description 매칭)
  2. SKILL.md + references/archetypes.md + density-zone.md 로드
  3. 슬라이드 매핑:
     - S1: Cover (아키타입 1)
     - S2: Two-column image-left (아키타입 2)
     - S3: Pie chart (아키타입 5)
     - S4: Comparison bars (아키타입 6)
     - S5: Closing (아키타입 9b)
  4. 각 슬라이드 Density Zone 패턴 결정
  5. pptx 스킬 호출 (있으면) 또는 직접 python-pptx
     - 컬러: design-tokens.md
     - 좌표: archetypes.md
     - 헤더/시그니처: 동일 좌표 보장
  6. 셀프 체크 (§11)
  7. 산출 + "적용된 결정 + 변경 옵션" 표
```
