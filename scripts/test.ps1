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
    $questManagerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_quest_manager.gd" 2>&1
    $questManagerExitCode = $LASTEXITCODE
    $inventoryManagerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_inventory_manager.gd" 2>&1
    $inventoryManagerExitCode = $LASTEXITCODE
    $inventoryIntegrationOutput = & $godot --headless --path $repo --script "res://tests/godot/test_inventory_quest_save_integration.gd" 2>&1
    $inventoryIntegrationExitCode = $LASTEXITCODE
    $combatRunnerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_combat_runner.gd" 2>&1
    $combatRunnerExitCode = $LASTEXITCODE
    $relationshipManagerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_relationship_manager.gd" 2>&1
    $relationshipManagerExitCode = $LASTEXITCODE
    $saveManagerOutput = & $godot --headless --path $repo --script "res://tests/godot/test_save_manager.gd" 2>&1
    $saveManagerExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $gameStateOutput | Write-Output
    $storyRunnerOutput | Write-Output
    $questManagerOutput | Write-Output
    $inventoryManagerOutput | Write-Output
    $inventoryIntegrationOutput | Write-Output
    $combatRunnerOutput | Write-Output
    $relationshipManagerOutput | Write-Output
    $saveManagerOutput | Write-Output
    if ($gameStateExitCode -ne 0 -or ($gameStateOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($storyRunnerExitCode -ne 0 -or ($storyRunnerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($questManagerExitCode -ne 0 -or ($questManagerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($inventoryManagerExitCode -ne 0 -or ($inventoryManagerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($inventoryIntegrationExitCode -ne 0 -or ($inventoryIntegrationOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($combatRunnerExitCode -ne 0 -or ($combatRunnerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($relationshipManagerExitCode -ne 0 -or ($relationshipManagerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    if ($saveManagerExitCode -ne 0 -or ($saveManagerOutput -join "`n") -match "SCRIPT ERROR") { exit 1 }
    & $godot --headless --path $repo --scene "res://tests/godot/story_runner_fixture_demo.tscn" --quit-after 1
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} catch {
    Write-Warning "Godot test skipped because Godot was not found. For a full completion claim, install Godot 4.6.2 and rerun."
}
