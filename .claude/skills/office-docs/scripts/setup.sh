#!/usr/bin/env bash
# office-docs 스킬의 실행 환경을 확인하고, 사용자 권한으로 되는 것만 설치한다.
# 사용: bash setup.sh                 → 확인 후 필요한 것만 설치
#       bash setup.sh --check         → 확인만 하고 설치하지 않음
#       bash setup.sh --apt-packages  → 누락된 시스템 도구의 apt 패키지 이름만 한 줄로 출력 (install.sh가 모아서 설치)
#
# 설치 대상
#   - uv 가상환경 (~/.local/share/office-docs/venv): openpyxl·pandas·markitdown·pypdf·pdfplumber·reportlab 등
#   - npm 전역 패키지: pptxgenjs·docx·sharp·react-icons·react·react-dom
#   - 나눔고딕 TrueType (~/.local/share/fonts) — reportlab 한글 출력용
# 시스템 도구(LibreOffice·poppler·pandoc·qpdf)는 관리자 권한이 필요해 설치 명령만 출력한다.
set -euo pipefail

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

# 시스템 도구 → apt 패키지
apt_pkgs_for() {
  case "$1" in
    soffice)   echo "libreoffice-calc libreoffice-impress libreoffice-writer" ;;
    pdftoppm|pdftotext) echo "poppler-utils" ;;
    pandoc)    echo "pandoc" ;;
    qpdf)      echo "qpdf" ;;
    tesseract) echo "tesseract-ocr tesseract-ocr-kor" ;;
  esac
}

if [[ "${1:-}" == "--apt-packages" ]]; then
  pkgs=()
  for t in soffice pdftoppm pdftotext pandoc qpdf; do
    command -v "$t" >/dev/null 2>&1 || pkgs+=($(apt_pkgs_for "$t"))
  done
  printf '%s\n' "${pkgs[@]}" | sort -u | tr '\n' ' '; echo
  exit 0
fi

VENV="${OFFICE_DOCS_VENV:-$HOME/.local/share/office-docs/venv}"
PY_PKGS=(openpyxl pandas "markitdown[pptx,docx,xlsx]" pypdf pdfplumber reportlab pypdfium2 pdf2image pytesseract lxml defusedxml Pillow python-pptx)
PY_MODULES=(openpyxl pandas markitdown pypdf pdfplumber reportlab pypdfium2 pdf2image pytesseract lxml defusedxml PIL pptx)
NODE_PKGS=(pptxgenjs docx sharp react-icons react react-dom)
SYS_TOOLS=(soffice pdftoppm pdftotext pandoc qpdf)
OPT_TOOLS=(tesseract)

missing_py=()
if [[ -x "$VENV/bin/python" ]]; then
  for m in "${PY_MODULES[@]}"; do
    "$VENV/bin/python" -c "import $m" >/dev/null 2>&1 || missing_py+=("$m")
  done
else
  missing_py=("${PY_MODULES[@]}")
fi

missing_node=()
if command -v node >/dev/null 2>&1; then
  for p in "${NODE_PKGS[@]}"; do
    NODE_PATH="$(npm root -g)" node -e "require('$p')" >/dev/null 2>&1 || missing_node+=("$p")
  done
else
  missing_node=("${NODE_PKGS[@]}")
fi

missing_sys=()
for t in "${SYS_TOOLS[@]}"; do command -v "$t" >/dev/null 2>&1 || missing_sys+=("$t"); done
missing_opt=()
for t in "${OPT_TOOLS[@]}"; do command -v "$t" >/dev/null 2>&1 || missing_opt+=("$t"); done

# reportlab은 TrueType(.ttf)만 읽는다. 배포판의 Noto CJK는 CFF 아웃라인 .ttc라 쓸 수 없어 나눔고딕을 사용자 폰트로 둔다.
FONT_DIR="$HOME/.local/share/fonts"
KO_TTF="$FONT_DIR/NanumGothic-Regular.ttf"
have_ko_ttf=false
[[ -f "$KO_TTF" ]] && have_ko_ttf=true

echo "python venv: $([[ -x "$VENV/bin/python" ]] && echo "있음 ($VENV)" || echo '없음')"
echo "python 패키지 누락: $([[ ${#missing_py[@]} -eq 0 ]] && echo '없음' || echo "${missing_py[*]}")"
echo "node: $(command -v node >/dev/null 2>&1 && node -v || echo '없음')"
echo "npm 패키지 누락: $([[ ${#missing_node[@]} -eq 0 ]] && echo '없음' || echo "${missing_node[*]}")"
echo "시스템 도구 누락: $([[ ${#missing_sys[@]} -eq 0 ]] && echo '없음' || echo "${missing_sys[*]}")"
echo "선택 도구 누락: $([[ ${#missing_opt[@]} -eq 0 ]] && echo '없음' || echo "${missing_opt[*]} (OCR 때만 필요)")"
echo "한글 TrueType 폰트: $([[ $have_ko_ttf == true ]] && echo "있음 ($KO_TTF)" || echo '없음')"

if [[ ${#missing_py[@]} -eq 0 && ${#missing_node[@]} -eq 0 && ${#missing_sys[@]} -eq 0 && $have_ko_ttf == true ]]; then
  echo "✅ 준비 완료"
  exit 0
fi

if [[ $CHECK_ONLY == true ]]; then
  echo "설치하려면: bash $0"
  exit 1
fi

if [[ ${#missing_py[@]} -gt 0 ]]; then
  if ! command -v uv >/dev/null 2>&1; then
    echo "→ uv 설치 (~/.local/bin)"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  [[ -x "$VENV/bin/python" ]] || { echo "→ 가상환경 생성: $VENV"; uv venv "$VENV"; }
  echo "→ python 패키지 설치"
  uv pip install --python "$VENV/bin/python" "${PY_PKGS[@]}"
fi

if [[ ${#missing_node[@]} -gt 0 ]]; then
  if ! command -v node >/dev/null 2>&1; then
    echo "❌ node가 없습니다. Node.js 18 이상을 먼저 설치하세요."
    exit 1
  fi
  echo "→ npm 전역 패키지 설치: ${missing_node[*]}"
  npm install -g "${missing_node[@]}"
fi

if [[ $have_ko_ttf == false ]]; then
  echo "→ 나눔고딕 TrueType 설치: $FONT_DIR"
  mkdir -p "$FONT_DIR"
  for w in Regular Bold; do
    curl -sSL -o "$FONT_DIR/NanumGothic-$w.ttf" "https://github.com/google/fonts/raw/main/ofl/nanumgothic/NanumGothic-$w.ttf"
  done
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null
fi

if [[ ${#missing_sys[@]} -gt 0 ]]; then
  echo
  echo "⚠️ 다음 시스템 도구는 관리자 권한이 필요합니다. 아래 명령을 직접 실행하세요:"
  echo "   sudo apt update && sudo apt install -y $(bash "$0" --apt-packages)"
  echo "   (OCR이 필요하면 tesseract-ocr tesseract-ocr-kor 추가)"
fi

echo
echo "다시 확인: bash $0 --check"
