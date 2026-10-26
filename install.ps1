# ─────────────────────────────────────────────
# dotfiles Windows 설치기 — install.sh의 Windows 네이티브판 (Windows PowerShell 5.1 / PowerShell 7)
# AI 에이전트 전역 설정을 정션(폴더)과 복사(파일)로 연결한다.
#
# 실행은 install.cmd로 한다 (더블클릭·CMD·PowerShell 공용, 실행 정책 우회 포함).
# 이 파일은 UTF-8 BOM으로 저장한다 — Windows PowerShell 5.1은 BOM 없는 파일을 시스템 코드 페이지로 읽어 한글이 깨진다.
# 같은 이유로 `irm | iex` 한 줄 설치는 지원하지 않는다 (iex가 BOM 문자를 명령 이름으로 읽는다).
# ─────────────────────────────────────────────

[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Help
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# ── 출력 ────────────────────────────────────

function info([string]$m) { Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function ok([string]$m)   { Write-Host "[OK]    $m" -ForegroundColor Green }
function warn([string]$m) { Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function err([string]$m)  { Write-Host "[ERROR] $m" -ForegroundColor Red }

if ($Help) {
  Write-Host @"
사용법: install.cmd [-DryRun]

AI 에이전트 전역 설정을 정션(폴더)과 복사(파일)로 연결합니다. Windows 네이티브 전용이며, WSL에서는 install.sh를 쓰세요.

옵션:
  -DryRun   실제 변경 없이 수행할 작업만 표시
  -Help     이 도움말 표시
"@
  exit 0
}

# ── 경로 ────────────────────────────────────

function PathOf { [IO.Path]::Combine([string[]]$args) }

$IsWin = $env:OS -eq 'Windows_NT'
$DotfilesDir = $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
# 설치기가 만든 파일 사본의 해시 기록 — 다음 실행에서 "이 설치기가 만든 사본"과 "사용자 파일"을 구분한다
$StateFile = PathOf $DotfilesDir '.install-state.json'
$State = @{}

# ── 링크 ────────────────────────────────────
# 폴더는 정션으로 연결한다. 정션은 관리자 권한·개발자 모드 없이 만들 수 있다.
# Windows 밖(로컬 검증용 pwsh)에는 정션이 없어 심볼릭 링크로 대신한다.

function Get-LinkTarget([string]$path) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($null -eq $item -or -not $item.LinkType -or $item.LinkType -eq 'HardLink') { return $null }
  $target = [string](@($item.Target)[0])
  if ($target.StartsWith('\??\')) { $target = $target.Substring(4) }
  return $target
}

function Test-SamePath([string]$a, [string]$b) {
  $na = [IO.Path]::GetFullPath($a).TrimEnd('\', '/')
  $nb = [IO.Path]::GetFullPath($b).TrimEnd('\', '/')
  return [string]::Equals($na, $nb, [StringComparison]::OrdinalIgnoreCase)
}

# 링크 자체만 지운다. Remove-Item -Recurse는 5.1에서 정션 대상의 내용까지 지우므로 쓰지 않는다
function Remove-LinkOnly([string]$path) {
  $item = Get-Item -LiteralPath $path -Force
  if ($item.PSIsContainer) { [IO.Directory]::Delete($path, $false) } else { [IO.File]::Delete($path) }
}

function New-DirLink([string]$src, [string]$dst) {
  if ($IsWin) { New-Item -ItemType Junction -Path $dst -Value $src | Out-Null }
  else { New-Item -ItemType SymbolicLink -Path $dst -Value $src | Out-Null }
}

function Get-Stamp { Get-Date -Format 'yyyyMMdd-HHmmss' }

# install.sh의 safe_link와 같은 규칙: 같은 링크 [SKIP], 다른 링크 교체 [UPDATE], 실제 폴더는 백업 후 연결 [BACKUP]
function Link-Dir([string]$src, [string]$dst) {
  $current = Get-LinkTarget $dst
  if ($current) {
    if (Test-SamePath $current $src) { ok "[SKIP]   $dst → $src"; return }
    if ($DryRun) { warn "[UPDATE] $dst → $src (현재: $current) (dry-run)"; return }
    Remove-LinkOnly $dst
    New-DirLink $src $dst
    ok "[UPDATE] $dst → $src (이전: $current)"
  } elseif (Test-Path -LiteralPath $dst) {
    $backup = "$dst.backup.$(Get-Stamp)"
    if ($DryRun) { warn "[BACKUP] $dst → $backup (dry-run)"; warn "[CREATE] $dst → $src (dry-run)"; return }
    Move-Item -LiteralPath $dst -Destination $backup
    warn "[BACKUP] $dst → $backup"
    New-DirLink $src $dst
    ok "[CREATE] $dst → $src"
  } else {
    if ($DryRun) { info "[CREATE] $dst → $src (dry-run)"; return }
    New-DirLink $src $dst
    ok "[CREATE] $dst → $src"
  }
}

# ── 파일 사본 ───────────────────────────────
# install.sh가 링크하는 파일. Windows의 파일 심볼릭 링크는 개발자 모드나 관리자 권한이 있어야 해서 복사로 둔다.
# 레포를 갱신하면 install.cmd를 다시 실행해야 반영된다.
# 이 설치기가 만든 사본(해시가 상태 기록과 같음)은 그대로 덮어쓰고, 그 밖의 기존 파일은 safe_link처럼 백업한다.

function Get-Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

function Copy-Linked([string]$src, [string]$dst) {
  $srcHash = Get-Hash $src
  $current = Get-LinkTarget $dst
  if ($current) {
    if (Test-SamePath $current $src) { ok "[SKIP]   $dst → $src (링크)"; return }
    if ($DryRun) { warn "[COPY]   $dst ← $src (기존 링크 → 사본, 현재: $current) (dry-run)"; return }
    Remove-LinkOnly $dst
  } elseif (Test-Path -LiteralPath $dst -PathType Leaf) {
    $dstHash = Get-Hash $dst
    if ($dstHash -eq $srcHash) {
      $State[$dst] = $srcHash
      ok "[SKIP]   $dst ← $src (동일)"
      return
    }
    $ours = $State.ContainsKey($dst) -and $State[$dst] -eq $dstHash
    if (-not $ours) {
      $backup = "$dst.backup.$(Get-Stamp)"
      if ($DryRun) { warn "[BACKUP] $dst → $backup (dry-run)"; warn "[COPY]   $dst ← $src (dry-run)"; return }
      Move-Item -LiteralPath $dst -Destination $backup
      warn "[BACKUP] $dst → $backup"
    }
  } elseif (Test-Path -LiteralPath $dst) {
    err "$dst 가 폴더입니다 — 파일 자리에 폴더가 있어 건너뜁니다"
    $script:HasError = $true
    return
  }
  if ($DryRun) { info "[COPY]   $dst ← $src (dry-run)"; return }
  Copy-Item -LiteralPath $src -Destination $dst -Force
  $State[$dst] = $srcHash
  ok "[COPY]   $dst ← $src"
}

# install.sh의 safe_copy와 같은 규칙: 런타임에 도구가 고치는 파일은 레포 버전으로 덮어쓴다 (레포가 정본)
function Copy-Over([string]$src, [string]$dst) {
  if (Get-LinkTarget $dst) {
    if ($DryRun) { info "[COPY]   $dst ← $src (링크→복사 전환) (dry-run)"; return }
    Remove-LinkOnly $dst
  }
  if ((Test-Path -LiteralPath $dst -PathType Leaf) -and (Get-Hash $dst) -eq (Get-Hash $src)) {
    ok "[SKIP]   $dst ← $src (동일)"
    return
  }
  if ($DryRun) { info "[COPY]   $dst ← $src (dry-run)"; return }
  Copy-Item -LiteralPath $src -Destination $dst -Force
  ok "[COPY]   $dst ← $src"
}

function Ensure-Dir([string]$dir) {
  if (Test-Path -LiteralPath $dir -PathType Container) { return }
  if ($DryRun) { info "[MKDIR]  $dir (dry-run)"; return }
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  ok "[MKDIR]  $dir"
}

# ── 외부 명령 ───────────────────────────────
# Windows PowerShell 5.1은 $ErrorActionPreference='Stop'에서 외부 명령의 stderr 한 줄도 예외로 바꾸므로,
# 외부 명령은 이 함수로 감싸 실행하고 종료 코드($LASTEXITCODE)로 판정한다

function Invoke-Native([scriptblock]$block) {
  $saved = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & $block } finally { $ErrorActionPreference = $saved }
}

# ── merge_agy_settings ──────────────────────
# install.sh의 merge_agy_settings와 같은 계약을 같은 jq 식으로 따른다:
#   - 레포 최상위 키(_doc 제외)는 레포 우선, permissions는 통째 교체. 레포에 없는 키(model 등 런타임 값)는 보존
#   - jq 부재·JSON 파싱 실패 → 대상 무변경 + 오류 + $false. 결과가 같으면 [SKIP] (희소 저장·deny 순서 차이는 동일 취급)
#   - 대상이 링크면 내용이 같아도 일반 파일로 바꾼다 — 남겨 두면 agy가 링크 대상에 되쓴다 (링크 대상 파일은 건드리지 않음)
# jq 식에는 큰따옴표를 쓰지 않는다 — Windows PowerShell 5.1이 외부 명령 인자 속 큰따옴표를 지운다

function Invoke-Jq([string[]]$jqArgs) {
  $out = Invoke-Native { & jq @jqArgs 2>$null }
  return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Text = ((@($out) -join "`n") + "`n") }
}

# 링크 자체의 이름만 바꾼다 (대상은 따라가지 않음)
function Move-LinkOnly([string]$from, [string]$to) {
  if ((Get-Item -LiteralPath $from -Force).PSIsContainer) { [IO.Directory]::Move($from, $to) } else { [IO.File]::Move($from, $to) }
}

# 결과를 임시 파일에 쓰고 jq로 재파싱한 뒤 대상과 바꾼다. 대상이 링크면 일반 파일로 바꾼다.
# 링크는 옆 이름으로 비켜 두었다가 교체가 끝나면 지우고, 교체가 실패하면 되돌려 설치 전 상태를 지킨다
function Write-Verified([string]$text, [string]$dst) {
  $tmp = "$dst.tmp.$PID"
  $held = $null
  try {
    [IO.File]::WriteAllText($tmp, $text, $Utf8NoBom)
    if (-not (Invoke-Jq @('-e', 'objects|true', $tmp)).Ok) { return $false }
    if (Get-LinkTarget $dst) { $held = "$dst.link.$PID"; Move-LinkOnly $dst $held }
    try { Move-Item -LiteralPath $tmp -Destination $dst -Force }
    catch {
      err "교체 실패: $($_.Exception.Message)"
      if ($held) { Move-LinkOnly $held $dst; $held = $null }
      return $false
    }
    if ($held) { Remove-LinkOnly $held; $held = $null }
    return $true
  } finally {
    if (Test-Path -LiteralPath $tmp) { [IO.File]::Delete($tmp) }
  }
}

function Merge-AgySettings([string]$src, [string]$dst) {
  if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { err "jq 없음 — $dst 병합 불가 (대상 무변경)"; return $false }
  if (-not (Invoke-Jq @('-e', 'objects|true', $src)).Ok) { err "레포 파일이 JSON 객체가 아님: $src"; return $false }
  # Windows의 agy는 상태줄을 cmd /c로 실행해 레포의 bash 명령($HOME 확장)이 동작하지 않으므로 statusLine은 빼고 적용한다
  $repoFilter = 'del(._doc)'
  if ($IsWin) { $repoFilter = 'del(._doc, .statusLine)' }
  $linkTarget = Get-LinkTarget $dst
  $isLink = [bool]$linkTarget
  if (-not $isLink -and (Test-Path -LiteralPath $dst -PathType Container)) { err "$dst 가 폴더입니다 — 대상 무변경"; return $false }
  # 끊긴 링크는 읽을 내용이 없으므로 신규 생성으로 간다 (Write-Verified가 링크 자체를 바꾼다).
  # pwsh 7의 Test-Path는 끊긴 링크도 있다고 보므로 링크는 가리키는 대상으로 판정한다
  $hasContent = Test-Path -LiteralPath $dst -PathType Leaf
  if ($isLink) { $hasContent = Test-Path -LiteralPath ([IO.Path]::Combine((Split-Path -Parent $dst), $linkTarget)) -PathType Leaf }

  if (-not $hasContent) {
    if ($DryRun) { info "[COPY]   $dst ← $src (dry-run)"; return $true }
    $new = Invoke-Jq @($repoFilter, $src)
    if (-not $new.Ok -or -not (Write-Verified $new.Text $dst)) { err "신규 생성 실패 — 대상 무변경: $dst"; return $false }
    ok "[COPY]   $dst ← $src"
    return $true
  }
  if (-not (Invoke-Jq @('-e', 'objects|true', $dst)).Ok) {
    err "기존 파일이 유효한 JSON 객체가 아님 — 수동 확인 필요 (대상 무변경): $dst"; return $false
  }

  $merge = '(.[1] | ' + $repoFilter + ') as $repo | .[0] + $repo | .permissions = $repo.permissions'
  $norm = '.permissions = ((.permissions // {}) | .allow = (.allow // []) | .ask = (.ask // []) | .deny = ((.deny // []) | sort))'
  # 비교는 jq 출력끼리 메모리에서 한다 — dry-run에서는 파일을 하나도 쓰지 않기 위해서다
  $a = Invoke-Jq @('-S', '-s', ($merge + ' | ' + $norm), $dst, $src)
  $b = Invoke-Jq @('-S', $norm, $dst)
  if (-not $a.Ok) { err "병합 실패 — 대상 무변경: $dst"; return $false }
  if (-not $isLink -and $b.Ok -and $a.Text -ceq $b.Text) { ok "[SKIP]   $dst (동일)"; return $true }
  $note = ''
  if ($isLink) { $note = ', 링크 → 일반 파일' }
  if ($DryRun) { info "[MERGE]  $dst ← $src (관리 키 적용, 런타임 키 보존$note) (dry-run)"; return $true }

  $merged = Invoke-Jq @('-s', $merge, $dst, $src)
  if (-not $merged.Ok) { err "병합 실패 — 대상 무변경: $dst"; return $false }
  Copy-Item -LiteralPath $dst -Destination "$dst.pre-merge.bak" -Force
  if (-not (Write-Verified $merged.Text $dst)) { err "병합 결과 검증 실패 — 대상 무변경: $dst"; return $false }
  ok "[MERGE]  $dst ← $src (관리 키 적용, 런타임 키 보존$note, 백업 $dst.pre-merge.bak)"
  return $true
}

# ── 사전 조건 ───────────────────────────────

function Test-Prerequisites {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) {
    err "Git for Windows가 필요합니다. 설치 후 다시 실행하세요: winget install --id Git.Git -e"
    exit 1
  }
  ok "git 있음: $($git.Source)"

  # 훅·상태줄은 Git Bash로 돈다. Git Bash가 없으면 Claude Code가 훅을 PowerShell로 실행해 .sh 훅이 동작하지 않는다
  if ($IsWin) {
    $gitBash = PathOf (Split-Path (Split-Path $git.Source)) 'bin' 'bash.exe'
    if (Test-Path -LiteralPath $gitBash) { ok "Git Bash 있음: $gitBash" }
    else { warn "Git Bash(bin\bash.exe)를 찾지 못했습니다. 찾은 위치를 사용자 환경 변수로 지정하세요: setx CLAUDE_CODE_GIT_BASH_PATH `"<bash.exe 경로>`" (settings.json은 재설치 때 레포 버전으로 덮어써집니다)" }
  }

  if (Get-Command jq -ErrorAction SilentlyContinue) { ok "jq 이미 설치됨"; return }
  info "jq가 설치되어 있지 않습니다. 설치를 시도합니다..."
  if ($DryRun) { info "winget install --id jqlang.jq (dry-run)"; return }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    warn "winget이 없어 jq를 설치하지 못했습니다. 상태줄과 agy 설정 병합에 jq가 필요합니다"
    return
  }
  Invoke-Native { winget install --id jqlang.jq -e --source winget --accept-source-agreements --accept-package-agreements } | Out-Host
  # winget이 바꾼 PATH는 현재 세션에 반영되지 않으므로 다시 읽어 덧붙인다 (이 프로세스에만 있던 항목은 유지)
  $env:Path = $env:Path + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
  if (Get-Command jq -ErrorAction SilentlyContinue) { ok "jq 설치 완료 (winget) — 열려 있는 데스크톱 앱·터미널은 다시 시작해야 jq를 찾습니다" }
  else { warn "jq 자동 설치 실패. 직접 실행하세요: winget install --id jqlang.jq -e" }
}

# .gitattributes 도입 전에 클론한 사본은 .sh가 CRLF로 남아 Git Bash가 훅을 실행하지 못한다.
# 작업 트리가 깨끗할 때만 색인에서 다시 꺼내 줄바꿈을 바로잡는다 (로컬 수정이 있으면 안내만)
function Repair-LineEndings {
  $eol = Invoke-Native { & git -C $DotfilesDir ls-files --eol 2>$null }
  if ($LASTEXITCODE -ne 0) { warn "git으로 줄바꿈을 확인하지 못했습니다 (종료 코드 $LASTEXITCODE). 클론한 레포 안의 install.cmd인지 확인하세요"; return }
  $bad = @($eol | Where-Object { $_ -match 'w/crlf' -and $_ -match 'eol=lf' })
  if ($bad.Count -eq 0) { ok "줄바꿈 정상 (LF)"; return }
  $dirty = Invoke-Native { & git -C $DotfilesDir status --porcelain 2>$null }
  if ($LASTEXITCODE -ne 0) { warn "git status 실패 (종료 코드 $LASTEXITCODE) — CRLF로 받은 파일 $($bad.Count)개를 그대로 둡니다"; return }
  if (@($dirty).Count -gt 0) {
    warn "CRLF로 받은 파일 $($bad.Count)개가 있지만 로컬 수정이 있어 그대로 둡니다. 수정분을 정리한 뒤 다시 실행하세요"
    return
  }
  if ($DryRun) { info "[EOL]    CRLF로 받은 파일 $($bad.Count)개를 LF로 다시 꺼냄 (dry-run)"; return }
  Invoke-Native { & git -C $DotfilesDir checkout-index --force --all 2>$null }
  if ($LASTEXITCODE -eq 0) { ok "[EOL]    CRLF로 받은 파일 $($bad.Count)개를 LF로 다시 꺼냄" }
  else { warn "줄바꿈 정리 실패. 레포를 지우고 다시 클론하세요" }
}

# ── 메인 ────────────────────────────────────

function Main {
  Write-Host ""
  info "dotfiles 설치를 시작합니다. (Windows)"
  if ($DryRun) { warn "dry-run 모드: 실제 변경은 수행하지 않습니다." }
  Write-Host ""

  if (-not (Test-Path -LiteralPath (PathOf $DotfilesDir '.claude' 'settings.json'))) {
    err "dotfiles 레포 안의 install.ps1이 아닙니다: $DotfilesDir"
    err "먼저 클론하세요: git clone https://github.com/mulgae-life/dotfiles.git `"$HOME\dotfiles`""
    exit 1
  }
  if (Test-Path -LiteralPath $StateFile) {
    # 키에 사용자 홈 경로가 들어가므로 UTF-8로 읽는다 (5.1의 Get-Content는 BOM 없는 파일을 시스템 코드 페이지로 읽어 한글 경로가 깨진다)
    ([IO.File]::ReadAllText($StateFile, $Utf8NoBom) | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $State[$_.Name] = [string]$_.Value }
  }

  # 0. 사전 조건 — Git for Windows(필수), jq, 줄바꿈
  Test-Prerequisites
  Repair-LineEndings

  $R = $DotfilesDir
  $H = $HOME

  # 1. Claude — 개별 항목 연결 (런타임 데이터 보존)
  Ensure-Dir (PathOf $H '.claude')
  Copy-Linked (PathOf $R '.claude' 'CLAUDE.md') (PathOf $H '.claude' 'CLAUDE.md')
  Link-Dir    (PathOf $R '.claude' 'agents')    (PathOf $H '.claude' 'agents')
  Link-Dir    (PathOf $R '.claude' 'rules')     (PathOf $H '.claude' 'rules')
  Link-Dir    (PathOf $R '.claude' 'skills')    (PathOf $H '.claude' 'skills')
  Link-Dir    (PathOf $R '.claude' 'hooks')     (PathOf $H '.claude' 'hooks')
  # settings.json은 레포 버전으로 덮어쓰기 (레포가 진실의 원천)
  Copy-Over   (PathOf $R '.claude' 'settings.json') (PathOf $H '.claude' 'settings.json')
  Copy-Linked (PathOf $R '.claude' 'statusline-command.sh') (PathOf $H '.claude' 'statusline-command.sh')

  # 2. Codex
  Ensure-Dir (PathOf $H '.codex')
  Copy-Linked (PathOf $R '.codex' 'AGENTS.md') (PathOf $H '.codex' 'AGENTS.md')
  Copy-Linked (PathOf $R '.codex' 'AGENTS.references.md') (PathOf $H '.codex' 'AGENTS.references.md')
  Link-Dir    (PathOf $R '.codex' 'rules') (PathOf $H '.codex' 'rules')
  Link-Dir    (PathOf $R '.codex' 'hooks') (PathOf $H '.codex' 'hooks')
  # config.toml은 레포 버전으로 덮어쓰기 (Codex가 실행 중 trust 등 런타임 필드를 되씀)
  Copy-Over   (PathOf $R '.codex' 'config.toml') (PathOf $H '.codex' 'config.toml')

  # 3. ~/.agents/skills → ~/.claude/skills (Codex 공용 스킬 경로)
  Ensure-Dir (PathOf $H '.agents')
  Link-Dir   (PathOf $H '.claude' 'skills') (PathOf $H '.agents' 'skills')

  # 4. Antigravity CLI — 스킬은 ~/.gemini/config/skills, 전역 지침은 ~/.gemini/GEMINI.md, 설정은 관리 키만 병합
  Ensure-Dir  (PathOf $H '.gemini' 'config')
  Link-Dir    (PathOf $R '.claude' 'skills') (PathOf $H '.gemini' 'config' 'skills')
  Copy-Linked (PathOf $R '.antigravity' 'GEMINI.md') (PathOf $H '.gemini' 'GEMINI.md')
  Ensure-Dir  (PathOf $H '.gemini' 'antigravity-cli')
  $agyOk = Merge-AgySettings (PathOf $R '.antigravity' 'cli' 'settings.json') (PathOf $H '.gemini' 'antigravity-cli' 'settings.json')

  # 5. 스킬 의존성 — Windows는 자동 설치하지 않는다 (setup.sh와 SKILL.md가 Linux 가상환경 경로를 전제)
  Write-Host ""
  $setups = @(Get-ChildItem -Path (PathOf $R '.claude' 'skills') -Filter 'setup.sh' -Recurse -ErrorAction SilentlyContinue)
  if ($setups.Count -gt 0) {
    $names = ($setups | ForEach-Object { $_.Directory.Parent.Name }) -join ', '
    info "스킬 의존성 자동 설치는 Windows에서 지원하지 않습니다 ($names). 해당 스킬은 필요한 도구를 직접 설치해야 합니다."
  }

  if (-not $DryRun) {
    [IO.File]::WriteAllText($StateFile, ($State | ConvertTo-Json), $Utf8NoBom)
  }

  # ── 검증 ──────────────────────────────────
  Write-Host ""
  info "검증 중..."

  $linkTargets = @(
    @((PathOf $H '.claude' 'agents'),            (PathOf $R '.claude' 'agents')),
    @((PathOf $H '.claude' 'rules'),             (PathOf $R '.claude' 'rules')),
    @((PathOf $H '.claude' 'skills'),            (PathOf $R '.claude' 'skills')),
    @((PathOf $H '.claude' 'hooks'),             (PathOf $R '.claude' 'hooks')),
    @((PathOf $H '.codex' 'rules'),              (PathOf $R '.codex' 'rules')),
    @((PathOf $H '.codex' 'hooks'),              (PathOf $R '.codex' 'hooks')),
    @((PathOf $H '.agents' 'skills'),            (PathOf $H '.claude' 'skills')),
    @((PathOf $H '.gemini' 'config' 'skills'),   (PathOf $R '.claude' 'skills'))
  )
  $copyTargets = @(
    @((PathOf $H '.claude' 'CLAUDE.md'),             (PathOf $R '.claude' 'CLAUDE.md')),
    @((PathOf $H '.claude' 'statusline-command.sh'), (PathOf $R '.claude' 'statusline-command.sh')),
    @((PathOf $H '.claude' 'settings.json'),         (PathOf $R '.claude' 'settings.json')),
    @((PathOf $H '.codex' 'AGENTS.md'),              (PathOf $R '.codex' 'AGENTS.md')),
    @((PathOf $H '.codex' 'AGENTS.references.md'),   (PathOf $R '.codex' 'AGENTS.references.md')),
    @((PathOf $H '.codex' 'config.toml'),            (PathOf $R '.codex' 'config.toml')),
    @((PathOf $H '.gemini' 'GEMINI.md'),             (PathOf $R '.antigravity' 'GEMINI.md'))
  )

  foreach ($pair in $linkTargets) {
    $dst = $pair[0]; $src = $pair[1]
    $current = Get-LinkTarget $dst
    if ($current -and (Test-SamePath $current $src)) { ok "$dst → $current" }
    elseif ($DryRun) { info "$dst (dry-run이므로 검증 건너뜀)" }
    else { err "$dst 링크가 $src 를 가리키지 않습니다!"; $script:HasError = $true }
  }
  foreach ($pair in $copyTargets) {
    $dst = $pair[0]; $src = $pair[1]
    if ((Test-Path -LiteralPath $dst -PathType Leaf) -and (Get-Hash $dst) -eq (Get-Hash $src)) { ok "$dst (레포와 동일)" }
    elseif ($DryRun) { info "$dst (dry-run이므로 검증 건너뜀)" }
    else { err "$dst 가 레포 버전과 다릅니다!"; $script:HasError = $true }
  }
  $agySettings = PathOf $H '.gemini' 'antigravity-cli' 'settings.json'
  if (-not $agyOk) { err "$agySettings 병합 실패 (위 로그 참조)"; $script:HasError = $true }
  elseif ($DryRun) { info "$agySettings (dry-run이므로 검증 건너뜀)" }
  elseif (Test-Path -LiteralPath $agySettings -PathType Leaf) { ok "$agySettings (병합됨)" }
  else { err "$agySettings 파일이 존재하지 않습니다!"; $script:HasError = $true }

  Write-Host ""
  if ($script:HasError) {
    err "일부 설치 단계에 실패했습니다. 위 로그를 확인하세요."
    exit 1
  }
  ok "설치 완료! 열려 있는 Claude 데스크톱 앱·터미널은 다시 시작해야 새 설정을 읽습니다."
  info "업데이트: git -C `"$DotfilesDir`" pull 후 install.cmd 재실행 (파일 사본은 재실행해야 갱신됩니다)"
}

$script:HasError = $false
# jq 출력(UTF-8)을 깨지지 않게 읽기 위해 콘솔 출력 인코딩을 잠시 UTF-8로 둔다
$savedEncoding = [Console]::OutputEncoding
try {
  [Console]::OutputEncoding = $Utf8NoBom
  Main
} finally {
  [Console]::OutputEncoding = $savedEncoding
}
