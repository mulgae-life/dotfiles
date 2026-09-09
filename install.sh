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

# ── safe_copy ─────────────────────────────
# 런타임에 도구가 수정하는 파일은 심볼릭 링크 대신 복사한다.
# 레포 원본이 오염되지 않도록 보호하면서, install.sh 재실행으로 최신화.
#   - 내용 동일      → [SKIP]
#   - 내용 다름/없음 → 레포 버전으로 덮어쓰기 [COPY]
#   - 기존 심볼릭 링크 → 제거 후 복사 [COPY]

safe_copy() {
  local src="$1" dst="$2"

  # 기존 심볼릭 링크가 있으면 제거 (링크→복사 전환)
  if [ -L "$dst" ]; then
    if $DRY_RUN; then
      info "[COPY]   $dst ← $src (심볼릭→복사 전환) (dry-run)"
      return
    fi
    rm "$dst"
  fi

  if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
    ok "[SKIP]   $dst ← $src (동일)"
    return
  fi

  if $DRY_RUN; then
    info "[COPY]   $dst ← $src (dry-run)"
    return
  fi
  cp "$src" "$dst"
  ok "[COPY]   $dst ← $src"
}

# ── safe_merge_json ──────────────────────
# JSON 설정 파일을 deep merge한다.
# 도구가 런타임에 추가한 필드(인증 등)를 보존하면서 레포 설정을 반영.
#   - 없음          → 레포 버전 복사 [COPY]
#   - 있음 + jq     → deep merge (레포 우선, 기존 필드 보존) [MERGE]
#   - 있음 + jq 없음 → safe_copy 폴백 [COPY]

safe_merge_json() {
  local src="$1" dst="$2"

  # 기존 심볼릭 링크가 있으면 제거
  if [ -L "$dst" ]; then
    $DRY_RUN || rm "$dst"
  fi

  # 대상 파일이 없으면 단순 복사
  if [ ! -f "$dst" ]; then
    if $DRY_RUN; then
      info "[COPY]   $dst ← $src (dry-run)"
      return
    fi
    cp "$src" "$dst"
    ok "[COPY]   $dst ← $src"
    return
  fi

  # jq로 deep merge: 기존(.[0])에 레포(.[1])를 덮어쓰기 → 기존 전용 필드 보존
  if command -v jq &>/dev/null; then
    local tmp="${dst}.tmp.$$"
    if jq -s '.[0] * .[1]' "$dst" "$src" > "$tmp" 2>/dev/null; then
      if diff -q "$tmp" "$dst" &>/dev/null; then
        rm "$tmp"
        ok "[SKIP]   $dst (동일)"
        return
      fi
      if $DRY_RUN; then
        rm "$tmp"
        info "[MERGE]  $dst ← $src (dry-run)"
        return
      fi
      mv "$tmp" "$dst"
      ok "[MERGE]  $dst ← $src (런타임 필드 보존)"
      return
    fi
    rm -f "$tmp"
  fi

  # jq 부재/병합 실패 폴백: 레포=정본 원칙대로 덮어쓰되, 이 함수의 계약(런타임 전용 필드
  # 보존 — 예: Antigravity IDE의 창 상태·인증 필드)이 깨지므로 기존 파일을 백업 후 복사
  if ! $DRY_RUN; then
    cp "$dst" "${dst}.pre-merge.bak"
    warn "JSON 병합 불가 → 덮어쓰기 폴백. 기존 파일 백업: ${dst}.pre-merge.bak (런타임 필드 필요 시 수동 병합)"
  fi
  safe_copy "$src" "$dst"
}

# ── merge_agy_settings ───────────────────
# Antigravity CLI(agy) settings.json 병합. agy가 model·trustedWorkspaces·승인 캐시 등을
# 이 파일에 되쓰므로 복사하면 런타임 값이 날아간다. 계약:
#   - 레포 파일의 최상위 키(_doc 제외)는 레포 우선. permissions는 allow/ask/deny 3배열을 통째로 교체
#     (런타임 /permissions 로 추가한 규칙은 재설치 시 초기화)
#   - 레포에 없는 키(model, trustedWorkspaces 등)는 보존. 대상이 심볼릭 링크면 링크를 그대로 둔 채
#     링크 대상 내용으로 병합·검증하고, 마지막 교체에서 링크 자체가 일반 파일이 된다 (링크 대상 파일은
#     건드리지 않음, 런타임 키 보존). 내용이 같아도 링크면 교체한다 — 남겨 두면 agy가 링크 대상에 되쓴다
#   - jq 부재·JSON 파싱 실패·생성·백업·교체 실패 → 대상 무변경 + 오류 + return 1 (폴백 복사 없음).
#     호출부는 이 실패를 설치 종료 코드에 반영한다 (호출이 || 좌항이라 함수 안에서는 set -e가 꺼지므로 실패마다 명시 처리)
#   - 신규 생성·병합 모두 임시 파일에 쓰고 jq로 재파싱 검증 후 원자 교체. 결과 동일하면 [SKIP]
#     (agy 희소 저장·deny 순서 차이는 동일 취급)

merge_agy_settings() {
  local src="$1" dst="$2"

  if ! command -v jq &>/dev/null; then
    error "jq 없음 — $dst 병합 불가 (대상 무변경)"; return 1
  fi
  if ! jq -e 'type == "object"' "$src" >/dev/null 2>&1; then
    error "레포 파일이 JSON 객체가 아님: $src"; return 1
  fi

  local tmp="${dst}.tmp.$$"
  # 댕글링 링크는 -f 검사가 거짓이라 신규 생성 경로로 간다. 결과는 별도 임시 파일에 쓰고 마지막 mv가 링크 자체를 교체하므로 미리 제거하지 않는다 (실패 시 대상 무변경)
  if [ ! -f "$dst" ]; then
    if $DRY_RUN; then
      info "[COPY]   $dst ← $src (dry-run)"
      return
    fi
    if ! jq 'del(._doc)' "$src" > "$tmp" 2>/dev/null \
       || ! jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
      rm -f "$tmp"
      error "신규 생성 실패 — 대상 무변경: $dst"; return 1
    fi
    if ! mv "$tmp" "$dst"; then
      rm -f "$tmp"
      error "신규 생성 교체 실패 — 대상 무변경: $dst"; return 1
    fi
    ok "[COPY]   $dst ← $src"
    return
  fi
  if ! jq -e 'type == "object"' "$dst" >/dev/null 2>&1; then
    error "기존 파일이 유효한 JSON 객체가 아님 — 수동 확인 필요 (대상 무변경): $dst"; return 1
  fi

  # 기존(.[0]) 위에 레포(.[1])를 얹되 permissions는 레포 것으로 통째 교체
  if ! jq -s '(.[1] | del(._doc)) as $repo | .[0] + $repo | .permissions = $repo.permissions' "$dst" "$src" > "$tmp" 2>/dev/null \
     || ! jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    error "병합 결과 검증 실패 — 대상 무변경: $dst"; return 1
  fi
  # agy는 빈 allow/ask를 빼고 희소 저장하므로 빈 배열 보충·deny 정렬로 정규화한 뒤 비교 (순서·희소 차이는 SKIP)
  local norm='.permissions = ((.permissions // {}) | .allow = (.allow // []) | .ask = (.ask // []) | .deny = ((.deny // []) | sort))'
  # 링크는 내용이 같아도 SKIP하지 않는다 — 아래 mv가 링크를 일반 파일로 바꾸는 유일한 지점
  if [ ! -L "$dst" ] && diff -q <(jq -S "$norm" "$tmp") <(jq -S "$norm" "$dst") &>/dev/null; then
    rm "$tmp"
    ok "[SKIP]   $dst (동일)"
    return
  fi
  local note=""
  [ -L "$dst" ] && note=", 링크 → 일반 파일"
  if $DRY_RUN; then
    rm "$tmp"
    info "[MERGE]  $dst ← $src (관리 키 적용, 런타임 키 보존${note}) (dry-run)"
    return
  fi
  if ! cp "$dst" "${dst}.pre-merge.bak"; then
    rm -f "$tmp"
    error "백업 실패 — 대상 무변경: ${dst}.pre-merge.bak"; return 1
  fi
  if ! mv "$tmp" "$dst"; then
    rm -f "$tmp"
    error "교체 실패 — 대상 무변경 (백업 ${dst}.pre-merge.bak 유지): $dst"; return 1
  fi
  ok "[MERGE]  $dst ← $src (관리 키 적용, 런타임 키 보존${note}, 백업 ${dst}.pre-merge.bak)"
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

AI 에이전트 전역 설정을 심볼릭 링크(일부 복사)로 연결합니다.

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
  safe_link "$DOTFILES_DIR/.claude/rules"     "$HOME/.claude/rules"
  safe_link "$DOTFILES_DIR/.claude/skills"    "$HOME/.claude/skills"
  safe_link "$DOTFILES_DIR/.claude/hooks"    "$HOME/.claude/hooks"
  # 훅 스크립트 실행 권한 보장 (git pull 시 fileMode 설정에 따라 누락 가능)
  if [ -d "$DOTFILES_DIR/.claude/hooks" ] && ! $DRY_RUN; then
    chmod +x "$DOTFILES_DIR/.claude/hooks"/*.sh 2>/dev/null || true
  fi
  # settings.json은 레포 버전으로 덮어쓰기 (레포가 진실의 원천 — 인증은 .credentials.json에 별도 관리)
  safe_copy "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
  # statusline-command.sh: 런타임에 수정되지 않으므로 심볼릭 링크로 관리
  safe_link "$DOTFILES_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

  # 2. .codex 설정 링크 (런타임 데이터 보존)
  safe_mkdir "$HOME/.codex"
  safe_link "$DOTFILES_DIR/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  safe_link "$DOTFILES_DIR/.codex/AGENTS.references.md" "$HOME/.codex/AGENTS.references.md"
  safe_link "$DOTFILES_DIR/.codex/rules" "$HOME/.codex/rules"
  safe_link "$DOTFILES_DIR/.codex/hooks" "$HOME/.codex/hooks"
  # 훅 스크립트 실행 권한 보장 (git pull 시 fileMode 설정에 따라 누락 가능)
  if [ -d "$DOTFILES_DIR/.codex/hooks" ] && ! $DRY_RUN; then
    chmod +x "$DOTFILES_DIR/.codex/hooks"/*.sh 2>/dev/null || true
  fi
  # config.toml은 레포 버전으로 덮어쓰기 (Codex가 실행 시 trust 등 런타임 필드를 자동 재작성)
  safe_copy "$DOTFILES_DIR/.codex/config.toml" "$HOME/.codex/config.toml"

  # 3. .agents/skills → .claude/skills 연결
  safe_mkdir "$HOME/.agents"
  safe_link "$HOME/.claude/skills" "$HOME/.agents/skills"

  # 4. Antigravity — 전역 커스터마이징 루트는 ~/.gemini/config/ (CLI·IDE 공용, agy 1.1.27 실측)
  safe_mkdir "$HOME/.gemini/config"
  # 스킬: agy가 처음 실행될 때 ~/.gemini/antigravity-cli/skills → ~/.gemini/config/skills 링크를 스스로 만들므로
  # config/skills 만 레포가 소유한다 (antigravity-cli/skills 는 관리 제외)
  safe_link "$DOTFILES_DIR/.claude/skills" "$HOME/.gemini/config/skills"
  # 전역 지침은 ~/.gemini/GEMINI.md 하나만 — CLI·IDE 공식 문서가 명시한 경로. config/GEMINI.md 도 로드되므로
  # 둘 다 두면 같은 지침이 두 번 주입된다 (1.1.28 마커 실측)
  safe_link "$DOTFILES_DIR/.antigravity/GEMINI.md" "$HOME/.gemini/GEMINI.md"
  # 이전 설치가 남긴 링크 정리 — Gemini CLI 층 은퇴(2026-06-18 개인 계정 지원 종료)로 ~/.gemini 바로 아래 남은 것,
  # GEMINI.md 로 통합된 AGENTS.md, 이중 로드 원인이던 config/GEMINI.md
  local stale
  for stale in agents commands policies hooks skills AGENTS.md config/AGENTS.md config/GEMINI.md; do
    if [ -L "$HOME/.gemini/$stale" ]; then
      if $DRY_RUN; then
        warn "[CLEAN]  $HOME/.gemini/$stale (레포 관리 종료) (dry-run)"
      else
        rm "$HOME/.gemini/$stale"
        warn "[CLEAN]  $HOME/.gemini/$stale (레포 관리 종료)"
      fi
    fi
  done
  # ~/.gemini/settings.json 은 레포가 관리하지 않는다 (Gemini CLI 잔재, agy 는 안 읽음)
  # Antigravity CLI settings — 관리 키만 병합 (model·trustedWorkspaces 등 런타임 키 보존).
  # 실패해도 나머지 설치는 계속하되 검증 단계에서 종료 코드 1로 반영한다
  safe_mkdir "$HOME/.gemini/antigravity-cli"
  local agy_merge_failed=false
  merge_agy_settings "$DOTFILES_DIR/.antigravity/cli/settings.json" "$HOME/.gemini/antigravity-cli/settings.json" || agy_merge_failed=true
  # Antigravity IDE: ~/.gemini/antigravity/skills/, global_workflows (IDE 층은 미검증)
  safe_mkdir "$HOME/.gemini/antigravity"
  safe_link "$DOTFILES_DIR/.antigravity/global_workflows" "$HOME/.gemini/antigravity/global_workflows"
  safe_link "$DOTFILES_DIR/.claude/skills" "$HOME/.gemini/antigravity/skills"

  # 5. .antigravity IDE 안전 정책 (추정치, 미검증 — CLI 정책은 위 4번의 cli/settings.json)
  # 본 디렉토리를 ~/.antigravity/로 노출 (워크스페이스 템플릿 + agy CLI 참조용)
  safe_link "$DOTFILES_DIR/.antigravity" "$HOME/.antigravity"
  # 훅 스크립트 실행 권한 보장 (mcp-config-guard.sh 등)
  if [ -d "$DOTFILES_DIR/.antigravity/hooks" ] && ! $DRY_RUN; then
    chmod +x "$DOTFILES_DIR/.antigravity/hooks"/*.sh 2>/dev/null || true
  fi

  # IDE 글로벌 User settings (OS별 경로) — macOS/Windows만 IDE 지원, Linux는 skip
  # 글로벌 settings에 permissions를 두면 모든 워크스페이스에 자동 상속 (VS Code 패턴)
  # → 워크스페이스마다 .antigravity/ 복사 없이 한 번 설치로 적용
  case "$(uname -s)" in
    Darwin)
      ANTIGRAVITY_USER_DIR="$HOME/Library/Application Support/Antigravity/User"
      safe_mkdir "$ANTIGRAVITY_USER_DIR"
      safe_merge_json "$DOTFILES_DIR/.antigravity/settings.json" "$ANTIGRAVITY_USER_DIR/settings.json"
      ANTIGRAVITY_IDE_SETTINGS="$ANTIGRAVITY_USER_DIR/settings.json"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash/WSL-cmd) — %APPDATA%/Antigravity IDE/User/
      if [ -n "${APPDATA:-}" ]; then
        ANTIGRAVITY_USER_DIR="$APPDATA/Antigravity IDE/User"
        safe_mkdir "$ANTIGRAVITY_USER_DIR"
        safe_merge_json "$DOTFILES_DIR/.antigravity/settings.json" "$ANTIGRAVITY_USER_DIR/settings.json"
        ANTIGRAVITY_IDE_SETTINGS="$ANTIGRAVITY_USER_DIR/settings.json"
      fi
      ;;
    *)
      info "Antigravity IDE는 Linux 공식 지원(.deb/.tar.gz/apt) — 단 이 스크립트는 IDE settings 동기화 경로(추정 ~/.config/Antigravity/User/settings.json, 미검증) 미반영. IDE 설치 시 실제 settings 경로 확인 후 동기화 추가 필요 (CLI 층은 위 4번에서 적용됨)."
      ;;
  esac

  # ── 검증 ──────────────────────────────────
  echo ""
  info "검증 중..."

  local has_error=false

  # 심볼릭 링크로 설치되는 파일
  local link_targets=(
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.claude/agents"
    "$HOME/.claude/rules"
    "$HOME/.claude/skills"
    "$HOME/.claude/hooks"
    "$HOME/.claude/statusline-command.sh"
    "$HOME/.codex/AGENTS.md"
    "$HOME/.codex/AGENTS.references.md"
    "$HOME/.codex/rules"
    "$HOME/.codex/hooks"
    "$HOME/.agents/skills"
    "$HOME/.gemini/config/skills"
    "$HOME/.gemini/GEMINI.md"
    "$HOME/.gemini/antigravity/global_workflows"
    "$HOME/.gemini/antigravity/skills"
    "$HOME/.antigravity"
  )

  # 복사·병합으로 설치되는 파일 (런타임 수정 보호)
  local copy_targets=(
    "$HOME/.claude/settings.json"
    "$HOME/.codex/config.toml"
    "$HOME/.gemini/antigravity-cli/settings.json"
  )

  # OS-conditional: Antigravity IDE 글로벌 settings (macOS/Windows만 존재)
  if [ -n "${ANTIGRAVITY_IDE_SETTINGS:-}" ]; then
    copy_targets+=("$ANTIGRAVITY_IDE_SETTINGS")
  fi

  for target in "${link_targets[@]}"; do
    if [ -L "$target" ]; then
      ok "$target → $(readlink "$target")"
    elif $DRY_RUN; then
      info "$target (dry-run이므로 검증 건너뜀)"
    else
      error "$target 링크가 존재하지 않습니다!"
      has_error=true
    fi
  done

  for target in "${copy_targets[@]}"; do
    if [ -f "$target" ]; then
      ok "$target (복사됨)"
    elif $DRY_RUN; then
      info "$target (dry-run이므로 검증 건너뜀)"
    else
      error "$target 파일이 존재하지 않습니다!"
      has_error=true
    fi
  done

  # 병합 함수는 실패 시 대상을 건드리지 않으므로 파일 존재 검사로는 잡히지 않는다 — 실패 플래그를 종료 코드에 합류
  if $agy_merge_failed; then
    error "$HOME/.gemini/antigravity-cli/settings.json 병합 실패 (위 로그 참조)"
    has_error=true
  fi

  echo ""
  if $has_error; then
    error "일부 설치 단계에 실패했습니다. 위 로그를 확인하세요."
    exit 1
  else
    ok "설치 완료!"
  fi
}

main "$@"
