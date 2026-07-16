. "$PSScriptRoot\common.ps1"
$repo = Get-RepoRoot
$python = Get-PythonCommand
Set-Location $repo

& $python -B -m tools.story_pipeline scan "docs/story/scripts" --project-root $repo
exit $LASTEXITCODE
