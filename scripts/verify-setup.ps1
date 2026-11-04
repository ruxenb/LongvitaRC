[CmdletBinding()]
param(
    [switch]$RestoreDependencies
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'project-env.ps1')

function Invoke-Check {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [scriptblock]$Action
    )

    Write-Host "`n[$Name]" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Push-Location $repoRoot
try {
    Invoke-Check 'Flutter' { flutter --version }
    Invoke-Check 'Java' { java -version }
    Invoke-Check 'ADB' { adb version }
    Invoke-Check 'Firebase CLI' { firebase --version }
    Invoke-Check 'FlutterFire CLI' { flutterfire --version }
    Invoke-Check 'uv' { uv --version }
    Invoke-Check 'Python 3.12 for ARTEMIS' { uv run --python 3.12 python --version }

    if ($RestoreDependencies) {
        Invoke-Check 'Flutter dependencies' { flutter pub get }
        Push-Location (Join-Path $repoRoot 'e2e_test')
        try {
            Invoke-Check 'ARTEMIS dependencies' { uv sync --python 3.12 }
        }
        finally {
            Pop-Location
        }
    }

    $requiredFiles = @(
        'android\app\google-services.json'
        'firebase\storage.rules'
        'firebase\remote-config-defaults.json'
        'e2e_test\pyproject.toml'
    )
    foreach ($relativePath in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath))) {
            throw "Required project file is missing: $relativePath"
        }
    }

    Write-Host "`nSetup verification passed." -ForegroundColor Green
    Write-Host 'Cloud runtime checks still require Firebase access, registered SHA fingerprints, and an ARTEMIS daemon.'
}
finally {
    Pop-Location
}
