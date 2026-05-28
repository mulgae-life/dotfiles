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

> **헤더 strip 배경**: `HW_MIST` (#F5F5F5)는 본문 배경(#FFFFFF)과 명도 차가 부족해 PPTX 렌더 시 거의 invisible. **`HW_ORANGE_TINT` (#FCE6D6) + 2px `HW_ORANGE` 하단선**으로 시각 분리 + 브랜드 일관성 확보.
>
> **헤더 height + 시그니처**: 56 px strip + 시그니처 28 px는 PowerPoint 실측에서 거의 안 보임. **strip 80 px + 시그니처 합본 이미지 64 px**로 가시성 확보. 텍스트 wordmark 분리 사용은 박스 폭 부족 시 줄바꿈("한화\n손보") 발생 → 합본 이미지로 영구 해결.

```python
HEADER_H = 80

def add_header(slide, chapter_label: str, signature_path: str):
    """모든 콘텐츠 슬라이드 상단 헤더 strip.

    Args:
        signature_path: hanwha-signature-ink.png 경로 (심볼+wordmark 합본, 비율 2:1, 텍스트 ink 재페인트)
    """
    # 1. Strip background — orange-tint (브랜드 컬러)
    strip = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE,
        left=px(0), top=px(0),
        width=px(1920), height=px(HEADER_H),
    )
    strip.fill.solid()
    strip.fill.fore_color.rgb = HW_ORANGE_TINT
    strip.line.fill.background()

    # 2. 2px orange 하단선 (별도 shape으로 그려야 PPT 렌더 시 안 사라짐)
    bottom_line = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE,
        left=px(0), top=px(HEADER_H - 2),
        width=px(1920), height=px(2),
    )
    bottom_line.fill.solid()
    bottom_line.fill.fore_color.rgb = HW_ORANGE
    bottom_line.line.fill.background()

    # 3. Chapter label (left, 40px inset)
    lbl = slide.shapes.add_textbox(
        left=px(40), top=px(0),
        width=px(800), height=px(HEADER_H),
    )
    p = lbl.text_frame.paragraphs[0]
    p.text = chapter_label
    p.font.name = FONT_NAME
    p.font.size = Pt(10.5)  # 14px ≈ 10.5pt @72dpi
    p.font.color.rgb = HW_GRAPHITE
    lbl.text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE

    # 4. Signature — hanwha-signature-ink.png 합본 이미지 한 장 (텍스트 ink 재페인트 버전)
    # 비율 2:1 → height 64 px → width 128 px. 우측 40px inset.
    sig_h = 64
    sig_w = sig_h * 2  # 128
    sig_x = 1920 - 40 - sig_w  # 우측 40px inset → x = 1752
    sig_y = (HEADER_H - sig_h) // 2  # 세로 중앙 → y = 8
    slide.shapes.add_picture(
        signature_path,
        left=px(sig_x), top=px(sig_y),
        height=px(sig_h),
    )
```

### Title band (모든 콘텐츠 슬라이드)

> **타이틀 박스 height + subtitle gap**: font 크기 기준 계산(`font_size + 여유`)은 한글 descender + 두 줄 wrap 포함 시 부족 → 타이틀-부제 겹침. **title 박스 height = `font_px × 1.6`**, **subtitle y = `title 박스 끝 + 24`**로 확정.

```python
def add_title_band(slide, title: str, subtitle: str = "",
                   chapter_cue: str = "", title_color=HW_INK, title_size_px=40,
                   align="left", band_x=80):
    """타이틀 밴드 y=130–270 (헤더 80에 맞춰 시작 130).
    좌측 정렬 기본.

    Args:
        title_size_px: 디자인 px 단위 (40=기본 슬라이드, 48=섹션 hero, 72=Cover Display)
    """
    y = 130

    if chapter_cue:
        add_text(slide, chapter_cue, x=band_x, y=y, w=1760, h=28,
                 size_px=16, bold=True, color=HW_ORANGE, align=align)
        y = 165  # title 시작 y (chapter cue 있을 때)
    else:
        y = 165  # chapter cue 없어도 동일 위치 (밴드 간 정렬)

    # title 박스 height = font_px × 1.6 (descender + 두 줄 wrap 안전 마진)
    title_h = int(title_size_px * 1.6)
    add_text(slide, title, x=band_x, y=y, w=1760, h=title_h,
             size_px=title_size_px, bold=True, color=title_color,
             align=align, line_height=1.1)

    if subtitle:
        # subtitle y = title 박스 끝 + 24 (font_px 기준 계산은 부정확, +8 이하는 시각상 붙음)
        sub_y = y + title_h + 24
        add_text(slide, subtitle, x=band_x, y=sub_y, w=1760, h=50,
                 size_px=22, bold=True, color=HW_INK, align=align)
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
def build_deck(output_path: str, signature_path: str):
    prs = Presentation()
    prs.slide_width  = Inches(13.333)
    prs.slide_height = Inches(7.5)

    # 1. Cover
    slide1 = prs.slides.add_slide(prs.slide_layouts[6])  # blank
    add_header(slide1, "신상품 소개", signature_path)
    add_title_band(slide1, "운전자 보험 리뉴얼", chapter_cue="2026 신상품", title_size_px=72)
    # ... cover의 우측 hero image, 좌측 intro body 추가 ...

    # 2. Two-column
    slide2 = prs.slides.add_slide(prs.slide_layouts[6])
    add_header(slide2, "신상품 소개", signature_path)
    add_title_band(slide2, "안녕하세요", subtitle="한화손해보험입니다", title_size_px=56)
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
        signature_path=str(Path.home() / ".claude/skills/hw-ppt/assets/logo/hanwha-signature.png"),
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

  /* Header strip — 모든 콘텐츠 슬라이드 동일 (height 80, 시그니처 이미지 64 px) */
  .hw-header {
    position: absolute; inset: 0 0 auto 0;
    height: 80px;
    background: var(--hw-orange-tint);
    border-bottom: 2px solid var(--hw-orange);
    display: flex; align-items: center; justify-content: space-between;
    padding: 0 40px;
  }
  .hw-chapter-label {
    font-weight: 400; font-size: 14px;
    color: var(--hw-graphite); letter-spacing: 0.01em;
  }
  .hw-signature img { height: 64px; width: auto; display: block; }

  /* Title band — y = 130–270 (헤더 80 기준) */
  .chapter-cue {
    position: absolute; left: 80px; top: 130px;
    font-weight: 700; font-size: 16px; color: var(--hw-orange); margin: 0;
  }
  h1, h2, .section-title {
    position: absolute; left: 80px; top: 165px;
    margin: 0; line-height: 1.1;
  }
  h1 { font-weight: 700; font-size: 40px; color: var(--hw-ink); }
  .section-title { font-weight: 700; font-size: 48px; color: var(--hw-orange); }
  /* subtitle y = title 박스 끝(165 + font_px × 1.6) + 24. font 40 → top 253 */
  .subtitle {
    position: absolute; left: 80px; top: 253px;
    font-weight: 700; font-size: 22px; color: var(--hw-ink); margin: 0;
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
      <img src="assets/logo/hanwha-signature-ink.png" alt="한화손보" />
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

### ⚠️ PowerPoint에서 한화체 미설치 환경 대응 — subset 임베드

**문제**: 사용자 PC에 한화체 .ttf가 설치 안 되어 있으면 PowerPoint가 시스템 한국어 폰트(맑은 고딕 등)로 폴백 → 디자인 의도와 다르게 표시.

**해결**: PPTX 내부에 한화체 .ttf를 **subset 처리하여 임베드**. python-pptx 저장 후 ZIP 후처리.

```python
def embed_fonts_subset(pptx_path: Path, font_map: list):
    """font_map = [(family, style, ttf_path), ...]; style ∈ {regular, bold, italic, boldItalic}
    PPTX 내 모든 텍스트의 unicode만 남겨 subset → ppt/fonts/*.fntdata로 임베드.

    효과 (5장 데크 기준):
      - 원본 .ttf 1.27MB × 2 (R/B) = 2.5MB
      - subset 후 37KB × 2 = 74KB (3% 수준, 라이센스 fsType=4 호환)
    """
    import zipfile, shutil
    from lxml import etree as ET
    from fontTools import subset
    from fontTools.ttLib import TTFont

    # 1. PPTX 내부 텍스트의 unicode 집합 추출
    prs = Presentation(str(pptx_path))
    codepoints = set(range(0x20, 0x7F))  # ASCII printable 보강
    for slide in prs.slides:
        for shape in slide.shapes:
            if not shape.has_text_frame: continue
            for p in shape.text_frame.paragraphs:
                for r in p.runs:
                    codepoints.update(ord(c) for c in r.text)

    # 2. ZIP 풀기
    tmp = pptx_path.with_suffix(".unzip")
    if tmp.exists(): shutil.rmtree(tmp)
    with zipfile.ZipFile(pptx_path, "r") as z: z.extractall(tmp)

    # 3. ppt/fonts/fontN.fntdata 생성 (subset 적용)
    fonts_dir = tmp / "ppt" / "fonts"; fonts_dir.mkdir(parents=True, exist_ok=True)
    embedded = []
    for i, (family, style, src) in enumerate(font_map, 1):
        fname = f"font{i}.fntdata"
        opts = subset.Options(); opts.layout_features = ["*"]
        opts.glyph_names = True; opts.symbol_cmap = True
        opts.notdef_glyph = True; opts.notdef_outline = True
        sub = subset.Subsetter(options=opts)
        font = TTFont(str(src)); sub.populate(unicodes=codepoints); sub.subset(font)
        font.save(str(fonts_dir / fname))
        embedded.append((family, style, f"rId{1000+i}", fname))

    # 4. presentation.xml.rels — font relationship
    REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
    rels = ET.parse(str(tmp / "ppt/_rels/presentation.xml.rels"))
    for fam, style, rid, fname in embedded:
        r = ET.SubElement(rels.getroot(), f"{{{REL_NS}}}Relationship")
        r.set("Id", rid)
        r.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/font")
        r.set("Target", f"fonts/{fname}")
    rels.write(str(tmp / "ppt/_rels/presentation.xml.rels"),
               xml_declaration=True, encoding="UTF-8", standalone=True)

    # 5. presentation.xml — <p:embeddedFontLst>
    P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
    R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    pres = ET.parse(str(tmp / "ppt/presentation.xml"))
    root = pres.getroot()
    lst = root.find(f"{{{P_NS}}}embeddedFontLst")
    if lst is None:
        lst = ET.SubElement(root, f"{{{P_NS}}}embeddedFontLst")
        # ECMA-376: embeddedFontLst는 defaultTextStyle 앞에 위치
        ds = root.find(f"{{{P_NS}}}defaultTextStyle")
        if ds is not None:
            root.remove(lst)
            root.insert(list(root).index(ds), lst)
    by_family = {}
    for fam, style, rid, fname in embedded:
        by_family.setdefault(fam, []).append((style, rid))
    for fam, items in by_family.items():
        ef = ET.SubElement(lst, f"{{{P_NS}}}embeddedFont")
        fe = ET.SubElement(ef, f"{{{P_NS}}}font"); fe.set("typeface", fam)
        for style, rid in items:
            child = ET.SubElement(ef, f"{{{P_NS}}}{style}")
            child.set(f"{{{R_NS}}}id", rid)
    pres.write(str(tmp / "ppt/presentation.xml"),
               xml_declaration=True, encoding="UTF-8", standalone=True)

    # 6. [Content_Types].xml — .fntdata Default
    CT_NS = "http://schemas.openxmlformats.org/package/2006/content-types"
    ct = ET.parse(str(tmp / "[Content_Types].xml"))
    has = any(d.get("Extension") == "fntdata"
              for d in ct.getroot().findall(f"{{{CT_NS}}}Default"))
    if not has:
        d = ET.SubElement(ct.getroot(), f"{{{CT_NS}}}Default")
        d.set("Extension", "fntdata")
        d.set("ContentType", "application/x-fontdata")
    ct.write(str(tmp / "[Content_Types].xml"),
             xml_declaration=True, encoding="UTF-8", standalone=True)

    # 7. 재패키징
    pptx_path.unlink()
    with zipfile.ZipFile(pptx_path, "w", zipfile.ZIP_DEFLATED) as z:
        for f in tmp.rglob("*"):
            if f.is_file(): z.write(f, str(f.relative_to(tmp)))
    shutil.rmtree(tmp)


# 사용
embed_fonts_subset(Path("out.pptx"), [
    ("Hanwha", "regular", Path.home() / ".claude/skills/hw-design/assets/fonts/Hanwha/HanwhaR.ttf"),
    ("Hanwha", "bold",    Path.home() / ".claude/skills/hw-design/assets/fonts/Hanwha/HanwhaB.ttf"),
])
```

> **라이센스 주의**: 한화체 .ttf의 `OS/2.fsType=4` (preview/print only). subset 처리로 PPT 표시 전용 임베드는 허용 범위. **편집용 임베드(fsType=0/8)는 라이센스 위반 가능**, subset 권장.

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

## 5. 로고 알파 변환 + 시그니처 텍스트 ink 재페인트

### 5-1. 검정 배경 JPEG → 알파 PNG

`assets/logo/hanwha-signature.png`와 `hanwha-symbol.png`는 검정 배경 JPEG (사용자가 클로드 웹에서 사용하던 원본). 알파 PNG로 변환 권장.

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

### 5-2. 시그니처 텍스트 ink 재페인트 (헤더 가시성 확보)

알파 변환 후 `hanwha-signature.png`는 텍스트가 **흰색 outline only (fill 투명)** 상태로 남음 (원본이 검정 배경 위 흰색 텍스트였기 때문). orange-tint(#FCE6D6) 헤더 위에서 "한화손보" 텍스트가 거의 안 보임 → **흰색 픽셀을 HW_INK(#1A1A1A)로 재페인트한 `hanwha-signature-ink.png` 생성**.

```python
from PIL import Image
from pathlib import Path

src = Path("assets/logo/hanwha-signature.png")
dst = Path("assets/logo/hanwha-signature-ink.png")

img = Image.open(src).convert("RGBA")
w, h = img.size
px = img.load()

# 좌측 30%는 심볼(컬러 그대로), 우측 70%의 흰색 픽셀만 ink로 변환
SYMBOL_BOUND_X = int(w * 0.30)
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 30:
            continue
        if x >= SYMBOL_BOUND_X and r > 200 and g > 200 and b > 200:
            px[x, y] = (0x1A, 0x1A, 0x1A, a)  # ink. 알파는 유지

# 하단 검정 막대(원본 JPEG 잔존) 알파 0 처리
for y in range(int(h * 0.77), h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a > 0 and r < 80 and g < 80 and b < 80:
            px[x, y] = (0, 0, 0, 0)

img.save(dst, "PNG")
```

PPTX 헤더에서 사용:
```python
SIGNATURE_PATH = Path("assets/logo/hanwha-signature-ink.png")
slide.shapes.add_picture(str(SIGNATURE_PATH), px(1752), px(8), height=px(64))
```

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
header_h_design = 80     # → Emu(  508,000)
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
| 헤더 y=80 (끝) | 80 | 508,000 | 0.56" |
| 타이틀 밴드 y=130 | 130 | 825,500 | 0.90" |
| 타이틀 y=165 | 165 | 1,047,750 | 1.15" |
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

### ⚠️ 핵심 주의:

OOXML `ST_Angle` 범위는 `-21,600,000 ~ 21,600,000` (= -360 ~ 360°). **음수 각도(`-90` 같은 12시 표기)는 PowerPoint/Spire 모두 호환성 불안**. 반드시 **0–360 양수 범위로 정규화**하고, 한 슬라이스가 360°를 넘으면 **두 조각으로 쪼개기**.

또한 `PIE` preset의 좌표계는 **0° = 3시 (동쪽), 시계 방향 증가**. 12시부터 시작하려면 `start = 270°`.

```python
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn
from lxml import etree

def _draw_pie_slice(slide, cx_px, cy_px, radius_px,
                    start_deg: float, end_deg: float, color):
    """단일 파이 슬라이스 (start_deg, end_deg는 0–360 정규화)."""
    shape = slide.shapes.add_shape(
        MSO_SHAPE.PIE,
        px(cx_px - radius_px), px(cy_px - radius_px),
        px(radius_px * 2),     px(radius_px * 2),
    )
    # adj1/adj2 직접 설정 (degree × 60000)
    spPr = shape.element.spPr
    avLst = spPr.find(qn("a:prstGeom")).find(qn("a:avLst"))
    if avLst is None:
        avLst = etree.SubElement(spPr.find(qn("a:prstGeom")), qn("a:avLst"))
    for gd in avLst.findall(qn("a:gd")):
        avLst.remove(gd)
    for name, val in [("adj1", start_deg), ("adj2", end_deg)]:
        gd = etree.SubElement(avLst, qn("a:gd"))
        gd.set("name", name)
        gd.set("fmla", f"val {int(round(val * 60000))}")
    shape.fill.solid(); shape.fill.fore_color.rgb = color
    shape.line.color.rgb = HW_PAPER
    shape.line.width = Emu(int(2 * 9525))
    shape.shadow.inherit = False


def add_pie_chart(slide, cx_px, cy_px, radius_px,
                  data: list[tuple[float, "RGBColor"]],
                  donut_hole_radius_px: int = 0,
                  center_image_path: str = None):
    """slices = [(percent, color), ...]. 12시(270°)부터 시계방향.
    누적 각도가 360°를 넘으면 자동으로 두 조각으로 쪼개기."""
    cursor = 270.0
    for pct, color in data:
        sweep = pct * 3.6
        start = cursor % 360.0
        end = start + sweep
        if end <= 360.0:
            _draw_pie_slice(slide, cx_px, cy_px, radius_px, start, end, color)
        else:
            # 360 경계 넘으면 두 조각으로 쪼개기 (같은 색)
            _draw_pie_slice(slide, cx_px, cy_px, radius_px, start, 360.0, color)
            _draw_pie_slice(slide, cx_px, cy_px, radius_px, 0.0, end - 360.0, color)
        cursor = cursor + sweep

    # 도넛 효과: 중앙 흰 사각형 + 심볼
    # 사각형은 직경의 약 25% 비율이 시각상 적정 (예: r=220 → 사각형 100)
    if donut_hole_radius_px > 0:
        hole = slide.shapes.add_shape(
            MSO_SHAPE.RECTANGLE,
            px(cx_px - donut_hole_radius_px // 2),
            px(cy_px - donut_hole_radius_px // 2),
            px(donut_hole_radius_px), px(donut_hole_radius_px),
        )
        hole.fill.solid(); hole.fill.fore_color.rgb = HW_PAPER
        hole.line.fill.background()

    if center_image_path and donut_hole_radius_px > 0:
        img_size = int(donut_hole_radius_px * 0.72)
        slide.shapes.add_picture(
            center_image_path,
            px(cx_px - img_size // 2), px(cy_px - img_size // 2),
            height=px(img_size),
        )


# 사용 (archetype 5 Pie chart) — 60/20/10/8/2, 도넛 사각형 100, 심볼 72
add_pie_chart(
    slide, cx_px=1360, cy_px=540, radius_px=220,
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

> **❌ 안 되는 패턴**: `start_angle = -90`으로 12시 시작 + adj1/adj2에 음수 EMU. PowerPoint가 무시하거나 잘못된 각도로 표시. **항상 0–360 양수 정규화 + 360° 쪼개기**.

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
