. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
$python = Get-PythonCommand
Set-Location $repo
& $python tools/validate_repository.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
