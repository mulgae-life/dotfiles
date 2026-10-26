# Codex SessionStart(compact) 훅의 Windows판 — config.toml의 command_windows가 호출한다
# 리마인더 문구는 compact-reminder.sh의 heredoc 하나만 정본으로 두고, 여기서는 그 JSON을 꺼내 낸다.
# 비ASCII 문자는 JSON 이스케이프(\uXXXX)로 바꿔 순수 ASCII로 낸다. 이 스크립트는 Codex가 띄운 PowerShell 안에서
# 자식 프로세스로 돌기 때문에, 바깥 PowerShell이 출력을 시스템 코드 페이지로 다시 인코딩하면 UTF-8 한글이 깨질 수 있다

$ErrorActionPreference = 'Stop'
$sh = Join-Path $PSScriptRoot 'compact-reminder.sh'
$text = [IO.File]::ReadAllText($sh, [Text.Encoding]::UTF8)
$m = [regex]::Match($text, "(?s)<<'JSONEOF'\r?\n(.*?)\r?\nJSONEOF")
if (-not $m.Success) { [Console]::Error.WriteLine("compact-reminder: $sh 에서 JSON 본문을 찾지 못했습니다"); exit 1 }
$json = [regex]::Replace($m.Groups[1].Value, '[^\x00-\x7F]', { param($c) '\u{0:x4}' -f [int][char]$c.Value })
[Console]::Out.Write($json)
exit 0
