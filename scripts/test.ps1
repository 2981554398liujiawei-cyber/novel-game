. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
$python = Get-PythonCommand
Set-Location $repo

& $python -m unittest discover -s tests/python -p "test_*.py" -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

try {
    $godot = Get-GodotCommand
    & $godot --headless --path $repo --editor --quit
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $godot --headless --path $repo --script "res://tests/godot/test_game_state.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} catch {
    Write-Warning "Godot test skipped because Godot was not found. For a full completion claim, install Godot 4.6.2 and rerun."
}
