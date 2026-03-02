#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# dotfiles installer
# AI 에이전트 전역 설정을 심볼릭 링크로 연결한다.
# ─────────────────────────────────────────────

REPO_URL="https://github.com/mulgae-life/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN=false

# ── 색상 ────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

info()  { printf "${BLUE}[INFO]${RESET}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${RESET}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }

# ── safe_link ───────────────────────────────
# 심볼릭 링크를 안전하게 생성한다.
#   - 이미 올바른 링크  → [SKIP]
#   - 다른 링크         → ln -sfn으로 교체 [UPDATE]
#   - 실제 파일/디렉토리 → 백업 후 링크 [BACKUP]
#   - 없음              → 새로 생성 [CREATE]

safe_link() {
  local src="$1" dst="$2"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      ok "[SKIP]   $dst → $src"
      return
    fi
    if $DRY_RUN; then
      warn "[UPDATE] $dst → $src (현재: $current) (dry-run)"
      return
    fi
    ln -sfn "$src" "$dst"
    ok "[UPDATE] $dst → $src (이전: $current)"
  elif [ -e "$dst" ]; then
    local backup="${dst}.backup.$(date +%Y%m%d-%H%M%S)"
    if $DRY_RUN; then
      warn "[BACKUP] $dst → $backup (dry-run)"
      warn "[CREATE] $dst → $src (dry-run)"
      return
    fi
    mv "$dst" "$backup"
    warn "[BACKUP] $dst → $backup"
    ln -sfn "$src" "$dst"
    ok "[CREATE] $dst → $src"
  else
    if $DRY_RUN; then
      info "[CREATE] $dst → $src (dry-run)"
      return
    fi
    ln -sfn "$src" "$dst"
    ok "[CREATE] $dst → $src"
  fi
}

# ── safe_mkdir ──────────────────────────────

safe_mkdir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    return
  fi
  if $DRY_RUN; then
    info "[MKDIR]  $dir (dry-run)"
    return
  fi
  mkdir -p "$dir"
  ok "[MKDIR]  $dir"
}

# ── 부트스트랩 ──────────────────────────────
# dotfiles 디렉토리가 없으면 자동으로 clone 후 re-exec

bootstrap() {
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info "dotfiles를 $DOTFILES_DIR 에 클론합니다..."
    if $DRY_RUN; then
      info "git clone $REPO_URL $DOTFILES_DIR (dry-run)"
      return
    fi
    git clone "$REPO_URL" "$DOTFILES_DIR"
    info "클론 완료. 스크립트를 다시 실행합니다."
    exec "$DOTFILES_DIR/install.sh" "$@"
  fi
}

# ── 인자 파싱 ───────────────────────────────

usage() {
  cat <<EOF
사용법: install.sh [옵션]

AI 에이전트 전역 설정을 심볼릭 링크로 연결합니다.

옵션:
  --dry-run   실제 변경 없이 수행할 작업만 표시
  --help      이 도움말 표시

환경변수:
  DOTFILES_DIR  dotfiles 디렉토리 경로 (기본: ~/dotfiles)
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    *) error "알 수 없는 옵션: $arg"; usage; exit 1 ;;
  esac
done

# ── 메인 ────────────────────────────────────

main() {
  echo ""
  info "dotfiles 설치를 시작합니다."
  $DRY_RUN && warn "dry-run 모드: 실제 변경은 수행하지 않습니다."
  echo ""

  # 부트스트랩 (dotfiles 없으면 clone)
  bootstrap "$@"

  # 0. 필수 의존성 설치
  if ! command -v jq &>/dev/null; then
    info "jq가 설치되어 있지 않습니다. 설치를 시도합니다..."
    if $DRY_RUN; then
      info "jq 설치 (dry-run)"
    elif command -v apt-get &>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y -qq jq && ok "jq 설치 완료 (apt)"
    elif command -v yum &>/dev/null; then
      sudo yum install -y -q jq && ok "jq 설치 완료 (yum)"
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y -q jq && ok "jq 설치 완료 (dnf)"
    elif command -v brew &>/dev/null; then
      brew install jq && ok "jq 설치 완료 (brew)"
    elif command -v apk &>/dev/null; then
      sudo apk add --quiet jq && ok "jq 설치 완료 (apk)"
    else
      warn "jq 자동 설치 실패. 훅 스크립트가 python3 폴백을 사용합니다."
    fi
  else
    ok "jq 이미 설치됨"
  fi

  # 1. .claude 개별 항목 링크 (런타임 데이터 보존)
  safe_mkdir "$HOME/.claude"
  safe_link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  safe_link "$DOTFILES_DIR/.claude/agents"    "$HOME/.claude/agents"
  safe_link "$DOTFILES_DIR/.claude/commands"  "$HOME/.claude/commands"
  safe_link "$DOTFILES_DIR/.claude/rules"     "$HOME/.claude/rules"
  safe_link "$DOTFILES_DIR/.claude/skills"    "$HOME/.claude/skills"
  safe_link "$DOTFILES_DIR/.claude/hooks"    "$HOME/.claude/hooks"
  # 훅 스크립트 실행 권한 보장 (git pull 시 fileMode 설정에 따라 누락 가능)
  if [ -d "$DOTFILES_DIR/.claude/hooks" ] && ! $DRY_RUN; then
    chmod +x "$DOTFILES_DIR/.claude/hooks"/*.sh 2>/dev/null || true
  fi
  safe_link "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"

  # 2. .codex AGENTS.md만 링크 (런타임 데이터 보존)
  safe_mkdir "$HOME/.codex"
  safe_link "$DOTFILES_DIR/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

  # 3. .agents/skills → .claude/skills 연결
  safe_mkdir "$HOME/.agents"
  safe_link "$HOME/.claude/skills" "$HOME/.agents/skills"

  # 4. .gemini 전역 설정 링크 (런타임 데이터 보존)
  safe_mkdir "$HOME/.gemini"
  safe_link "$DOTFILES_DIR/.gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
  safe_mkdir "$HOME/.gemini/antigravity"
  safe_link "$DOTFILES_DIR/.gemini/global_workflows" "$HOME/.gemini/antigravity/global_workflows"

  # ── 검증 ──────────────────────────────────
  echo ""
  info "검증 중..."

  local has_error=false
  local targets=(
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.claude/agents"
    "$HOME/.claude/commands"
    "$HOME/.claude/rules"
    "$HOME/.claude/skills"
    "$HOME/.claude/hooks"
    "$HOME/.claude/settings.json"
    "$HOME/.codex/AGENTS.md"
    "$HOME/.agents/skills"
    "$HOME/.gemini/GEMINI.md"
    "$HOME/.gemini/antigravity/global_workflows"
  )

  for target in "${targets[@]}"; do
    if [ -L "$target" ]; then
      ok "$target → $(readlink "$target")"
    elif $DRY_RUN; then
      info "$target (dry-run이므로 검증 건너뜀)"
    else
      error "$target 링크가 존재하지 않습니다!"
      has_error=true
    fi
  done

  echo ""
  if $has_error; then
    error "일부 링크 설정에 실패했습니다. 위 로그를 확인하세요."
    exit 1
  else
    ok "설치 완료!"
  fi
}

main "$@"
