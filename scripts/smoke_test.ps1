. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
$godot = Get-GodotCommand
Set-Location $repo
& $godot --headless --path $repo -- --smoke-test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
