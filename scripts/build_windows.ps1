. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
$godot = Get-GodotCommand
$outDir = Join-Path $repo "builds\windows"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Set-Location $repo

& $godot --headless --path $repo --export-release "Windows Desktop" "builds/windows/novel-game.exe"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Windows build exported to builds/windows/novel-game.exe"
