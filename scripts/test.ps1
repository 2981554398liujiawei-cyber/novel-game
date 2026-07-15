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
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $gameStateOutput = & $godot --headless --path $repo --script "res://tests/godot/test_game_state.gd" 2>&1
    $gameStateExitCode = $LASTEXITCODE
    $storyRunnerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_story_runner.gd" 2>&1
    $storyRunnerExitCode = $LASTEXITCODE
    $saveManagerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_save_manager.gd" 2>&1
    $saveManagerExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $gameStateOutput | Write-Output
    $storyRunnerOutput | Write-Output
    $saveManagerOutput | Write-Output
    if ($gameStateExitCode -ne 0 -or ($gameStateOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($storyRunnerExitCode -ne 0 -or ($storyRunnerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($saveManagerExitCode -ne 0 -or ($saveManagerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    & $godot --headless --path $repo --scene "res://tests/godot/story_runner_fixture_demo.tscn" --quit-after 1
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} catch {
    Write-Warning "Godot test skipped because Godot was not found. For a full completion claim, install Godot 4.6.2 and rerun."
}
