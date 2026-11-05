#!/usr/bin/env bash
# Playwright와 Chromium 준비 상태를 확인하고, 없으면 설치한다.
# 사용: bash setup.sh                 → 확인 후 필요한 것만 설치
#       bash setup.sh --check         → 확인만 하고 설치하지 않음
#       bash setup.sh --apt-packages  → Chromium이 요구하는 시스템 라이브러리·한글 폰트 중 없는 것의 apt 패키지 이름 (install.sh가 모아서 설치)
set -euo pipefail

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

if [[ "${1:-}" == "--apt-packages" ]]; then
  pkgs=()
  ldconfig -p 2>/dev/null | grep -q 'libasound\.so\.2' || pkgs+=(libasound2t64)
  [[ $(fc-list :lang=ko 2>/dev/null | wc -l) -gt 0 ]] || pkgs+=(fonts-noto-cjk)
  echo "${pkgs[*]:-}"
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  echo "❌ node가 없습니다. Node.js 18 이상을 먼저 설치하세요."
  exit 1
fi

have_pw=false
if npm ls -g playwright --depth=0 >/dev/null 2>&1; then
  have_pw=true
fi

have_browser=false
cache_dir="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
if compgen -G "$cache_dir/chromium*" >/dev/null 2>&1; then
  have_browser=true
fi

echo "node: $(node -v)"
echo "playwright 패키지: $([[ $have_pw == true ]] && echo '있음' || echo '없음')"
echo "chromium: $([[ $have_browser == true ]] && echo "있음 ($cache_dir)" || echo '없음')"

if [[ $have_pw == true && $have_browser == true ]]; then
  echo "✅ 준비 완료"
  exit 0
fi

if [[ $CHECK_ONLY == true ]]; then
  echo "설치하려면: bash $0"
  exit 1
fi

if [[ $have_pw == false ]]; then
  echo "▶ npm i -g playwright"
  npm i -g playwright
fi
if [[ $have_browser == false ]]; then
  echo "▶ npx playwright install chromium"
  npx playwright install chromium
fi
echo "✅ 설치 완료"
