Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-PythonCommand {
    $repo = Get-RepoRoot
    $venvPython = Join-Path $repo ".venv\Scripts\python.exe"
    if (Test-Path $venvPython) { return $venvPython }
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $py) { return $py.Source }
    throw "Python not found. Run scripts/setup.ps1 after installing Python 3.13.x."
}

function Get-GodotCommand {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) { return $env:GODOT_BIN }
    foreach ($name in @("godot", "godot4")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $cmd) { return $cmd.Source }
    }
    throw "Godot not found. Install Godot 4.6.2 Standard or set `$env:GODOT_BIN."
}
