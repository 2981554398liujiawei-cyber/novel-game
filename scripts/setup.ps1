. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
Set-Location $repo

$python = Get-PythonCommand
if (-not (Test-Path ".venv")) {
    & $python -m venv .venv
}
$venvPython = Join-Path $repo ".venv\Scripts\python.exe"
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements-dev.txt

Write-Host "Python environment ready."
try {
    $godot = Get-GodotCommand
    & $godot --version
    Write-Host "Godot detected. Expected baseline: 4.6.2 stable."
} catch {
    Write-Warning $_.Exception.Message
    Write-Warning "Python setup succeeded, but Godot is still required for smoke tests and builds."
}
