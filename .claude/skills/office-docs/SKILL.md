---
name: office-docs
description: PDF·Word(.docx)·PowerPoint(.pptx)·Excel(.xlsx/.csv) 파일을 만들고, 읽고, 고칩니다. 새 파일은 docx-js·pptxgenjs·openpyxl·reportlab로 생성하고 기존 파일은 OOXML을 직접 편집하며, 스키마 검증·수식 재계산·렌더링 검수 스크립트를 포함합니다. 산출물이나 입력이 이 파일 형식일 때 쓰고, HTML 리포트·슬라이드 아티팩트·마크다운 문서에는 쓰지 않습니다.
when_to_use: "PPT 만들어줘, 엑셀로 정리해줘, 워드 문서로 뽑아줘, PDF 합쳐줘, 이 pptx 내용 읽어줘, 템플릿 채워줘, PDF 폼 채워줘 요청 시. .pdf·.docx·.pptx·.xlsx·.csv 파일이 입력이나 산출물로 얽히면 명시적 요청이 없어도 참조한다. 브랜드 디자인 스킬(hw-ppt·hw-design)이 적용된 프로젝트에서는 디자인은 그 스킬이 정하고 파일 생성만 이 스킬이 맡는다."
allowed-tools:
  - "Bash"
  - "Read"
  - "Write"
  - "Edit"
  - "Glob"
  - "Grep"
---

# 문서 파일 작업

PDF·Word·PowerPoint·Excel 파일을 다루는 방법은 포맷마다 다르고 함정도 다릅니다. 이 파일은 포맷을 판별해 해당 참조 하나를 읽게 하는 진입점이고, 실제 절차는 `references/`에 있습니다. **작업에 필요한 포맷의 참조만 읽습니다.** 네 개를 한꺼번에 읽지 않습니다.

## 1. 포맷 판별

| 포맷 | 읽을 참조 | 생성 도구 | 딸린 스크립트 |
|------|-----------|-----------|---------------|
| `.pdf` 읽기·병합·분할·워터마크·암호·OCR | `references/pdf.md` | pypdf · pdfplumber · reportlab | `convert_pdf_to_images.py` |
| PDF 폼 채우기 | `references/pdf-forms.md` (먼저 `pdf.md`) | pypdf · reportlab | `check_fillable_fields.py` `extract_form_*.py` `fill_*.py` `check_bounding_boxes.py` `create_validation_image.py` |
| PDF 심화(pypdfium2, pdf-lib, 문제 해결) | `references/pdf-reference.md` | | |
| `.docx` `.dotx` `.doc` | `references/docx.md` | docx-js(생성) · OOXML 편집 · pandoc(읽기) | `merge_runs.py` `comment.py` `accept_changes.py` |
| `.pptx` `.potx` `.ppt` | `references/pptx.md` | pptxgenjs(생성) · OOXML 편집 · markitdown(읽기) | `add_slide.py` `clean.py` `thumbnail.py` |
| `.xlsx` `.xlsm` `.csv` `.tsv` | `references/xlsx.md` | openpyxl · pandas · markitdown(읽기) | `recalc.py` |
| docx·pptx 공통 검증 | 각 참조의 검증 절 | | `office/validate.py` `office/soffice.py` |

- 사용자가 파일 형식을 말하지 않고 "슬라이드", "문서"라고만 했고 이 세션에 슬라이드 아티팩트 타입이나 Claude Docs 커넥터가 있으면 그쪽이 우선입니다. 이 스킬은 **파일**이 산출물일 때 씁니다.
- PDF를 읽기만 할 때는 Read 도구가 페이지 단위로 직접 읽습니다. 표 추출·병합처럼 파일을 다뤄야 할 때만 참조를 폅니다.

## 2. 실행 환경

참조 파일은 Anthropic 샌드박스 기준으로 쓰여 있어 "미리 설치돼 있다"는 전제가 있습니다. 이 환경에서는 전용 가상환경과 전역 npm 패키지를 씁니다.

```bash
bash ~/.claude/skills/office-docs/scripts/setup.sh --check   # 상태만 확인
bash ~/.claude/skills/office-docs/scripts/setup.sh           # 없는 것만 설치 (uv 가상환경 + npm 전역 패키지)
```

LibreOffice·poppler·pandoc·qpdf 같은 시스템 도구는 관리자 권한이 필요합니다. `setup.sh`가 없는 도구와 설치 명령을 출력하면 그 명령을 사용자에게 안내하고 직접 실행하지 않습니다.

참조 파일의 명령은 아래 규약으로 읽습니다.

| 참조 표기 | 실제 실행 |
|-----------|-----------|
| `python scripts/x.py` | `~/.local/share/office-docs/venv/bin/python ~/.claude/skills/office-docs/scripts/x.py` |
| `markitdown file` | `~/.local/share/office-docs/venv/bin/markitdown file` |
| 임시 파이썬 스크립트 실행 | 같은 venv의 `python`으로. 시스템 `python3`에는 라이브러리가 없다 |
| `node script.js` (`require('pptxgenjs')` 등) | `NODE_PATH=$(npm root -g) node script.js` |
| `unzip … ` / `find … -delete` | `python scripts/unpack.py file.docx unpacked/` — 심볼릭 링크 항목과 경로 탈출을 거부하며 푼다 |
| `(cd unpacked && rm -f ../out.docx && zip -Xr ../out.docx .)` | `python scripts/pack.py unpacked/ out.docx` — 매번 새 아카이브를 쓰므로 삭제가 필요 없다 |
| `rm -f slide-*.jpg` 뒤 `pdftoppm` | 렌더마다 새 디렉토리에 출력한다 (`pdftoppm -jpeg -r 150 out.pdf render-2/slide`) |

참조 본문의 `rm`·`find -delete`는 실행하지 않습니다. 위 대체 명령이 같은 목적을 삭제 없이 달성합니다.

## 3. 공통 규칙

- **우선순위**: 사용자 지시 → 프로젝트 디자인 스킬(`hw-ppt`·`hw-design`의 토큰·아키타입) → 참조 파일의 디자인 지침. 참조 `pptx.md`의 팔레트 표와 "디자인 아이디어" 절은 브랜드가 정해지지 않은 덱에만 적용합니다.
- **한국어 문서**:
  - reportlab 기본 폰트에는 한글 글리프가 없어 네모로 찍힙니다. `setup.sh`가 받아 두는 `~/.local/share/fonts/NanumGothic-Regular.ttf`(굵게는 `-Bold.ttf`)를 `pdfmetrics.registerFont(TTFont("Nanum", 경로))`로 등록하고 그 폰트를 지정합니다. 배포판의 Noto Sans CJK는 `.ttc`(CFF 아웃라인)라 reportlab이 거부합니다.
  - pptxgenjs·docx-js·openpyxl은 폰트 이름만 기록하므로 수신자 환경에 있는 폰트를 씁니다. 지정이 없으면 `맑은 고딕`을 기본으로 하고, LibreOffice 렌더링 검수에서는 대체 폰트로 그려져 폭이 달라질 수 있음을 감안합니다.
  - `xlsx.md`의 재무 모델 절은 미국 관행(`$`, Arial)입니다. 한국어 시트는 통화 `₩#,##0` 또는 `#,##0`과 한글 폰트로 바꾸고, 입력·수식·링크의 색 규약은 그대로 따릅니다.
- **검수**: 만든 파일은 LibreOffice로 PDF로 바꾸고 `pdftoppm`으로 이미지를 만들어 Read로 **직접 봅니다**. 넘침·겹침·잘림·빈 자리표시자를 확인하고 고친 뒤 바뀐 페이지만 다시 봅니다. 엑셀은 `recalc.py`가 `errors_found`를 내면 출하하지 않습니다.
- **입력 파일 보호**: 사용자의 원본을 덮어쓰지 않습니다. 산출물은 새 이름으로 프로젝트에 두고, 풀어 놓은 디렉토리·중간 렌더 이미지는 스크래치패드에 만듭니다. 작업이 끝나면 산출물 정리 원칙(`.archive/`로 이동)을 따릅니다.
- **외부에서 받은 파일**은 신뢰하지 않습니다. `unpack.py`로만 풀고, XML은 `defusedxml`로 파싱합니다.
