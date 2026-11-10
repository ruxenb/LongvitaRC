[CmdletBinding()]
param(
    [string]$Flutter = 'flutter',
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot

function Invoke-MemberFlutter {
    param([string]$Member, [string[]]$FlutterArguments)
    Push-Location (Join-Path $workspaceRoot $Member)
    try {
        & $Flutter @FlutterArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter $($FlutterArguments -join ' ') failed in $Member"
        }
    }
    finally { Pop-Location }
}

Invoke-MemberFlutter '.' @('pub', 'get', '--enforce-lockfile')
& python (Join-Path $PSScriptRoot 'check-monorepo.py')
if ($LASTEXITCODE -ne 0) { throw 'Workspace boundary validation failed' }
foreach ($member in @('packages/core', 'mobile', 'web')) {
    Invoke-MemberFlutter $member @('analyze', '--no-pub', 'lib', 'test')
    Invoke-MemberFlutter $member @('test', '--no-pub')
}
if ($Build) {
    Invoke-MemberFlutter 'mobile' @('build', 'apk', '--debug', '--no-pub')
    Invoke-MemberFlutter 'web' @('build', 'web', '--release', '--no-pub')
}
