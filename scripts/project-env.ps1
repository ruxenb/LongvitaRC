[CmdletBinding()]
param()

# Support both the team's T: workspace and a checkout on another drive.
# Optional caches/tools may be absent; the core Flutter/Android toolchain is required.
$localTools = Join-Path ([System.IO.Path]::GetPathRoot($PSScriptRoot)) 'Tools'
$localJavaRoot = Join-Path $localTools 'Java21'
$localJavaHome = $null
if (Test-Path -LiteralPath $localJavaRoot) {
    $localJavaHome = Get-ChildItem -LiteralPath $localJavaRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\java.exe') } |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

function Resolve-ToolDirectory {
    param([string]$Primary, [string]$Fallback)
    if ($Primary -and (Test-Path -LiteralPath $Primary -PathType Container)) { return $Primary }
    if ($Fallback -and (Test-Path -LiteralPath $Fallback -PathType Container)) { return $Fallback }
    return $null
}

$toolPaths = [ordered]@{
    Flutter = (Resolve-ToolDirectory 'T:\Flutter\flutter\bin' (Join-Path $localTools 'flutter\bin'))
    Java = (Resolve-ToolDirectory 'C:\Program Files\Eclipse Adoptium\jdk-21.0.7.6-hotspot' $localJavaHome)
    AndroidSdk = (Resolve-ToolDirectory 'T:\Android\Sdk' (Join-Path $localTools 'AndroidSDK'))
    AndroidHome = (Resolve-ToolDirectory 'T:\Android\user-home' (Join-Path $env:USERPROFILE '.android'))
    GradleCache = (Resolve-ToolDirectory 'T:\Tools\GradleHome' (Join-Path $localTools 'GradleHome'))
    PubCache = (Resolve-ToolDirectory 'T:\Tools\PubCache' (Join-Path $localTools 'PubCache'))
    NpmPrefix = (Resolve-ToolDirectory 'T:\Tools\npm-global' (Join-Path $localTools 'npm-global'))
    NpmCache = (Resolve-ToolDirectory 'T:\Tools\npm-cache' (Join-Path $localTools 'npm-cache'))
    Python = (Resolve-ToolDirectory 'T:\Tools\uv-python\cpython-3.12.16-windows-x86_64-none' (Join-Path $localTools 'Python312'))
    UvScripts = (Resolve-ToolDirectory 'T:\Tools\PythonUser\Python314\Scripts' (Join-Path $localTools 'Python312\Scripts'))
    UvCli = (Resolve-ToolDirectory 'T:\Tools\uv' (Join-Path $localTools 'uv'))
    UvCache = (Resolve-ToolDirectory 'T:\Tools\uv-cache' (Join-Path $localTools 'uv-cache'))
    UvPython = (Resolve-ToolDirectory 'T:\Tools\uv-python' (Join-Path $localTools 'uv-python'))
    PipCache = (Resolve-ToolDirectory 'T:\Tools\pip-cache' (Join-Path $localTools 'pip-cache'))
}

foreach ($name in @('Flutter', 'Java', 'AndroidSdk', 'PubCache')) {
    if (-not $toolPaths[$name]) {
        throw "Missing required $name. Checked team workspace and $localTools."
    }
}

$env:JAVA_HOME = $toolPaths.Java
$env:ANDROID_HOME = $toolPaths.AndroidSdk
$env:ANDROID_SDK_ROOT = $toolPaths.AndroidSdk
$env:PUB_CACHE = $toolPaths.PubCache
if ($toolPaths.AndroidHome) { $env:ANDROID_USER_HOME = $toolPaths.AndroidHome }
if ($toolPaths.GradleCache) { $env:GRADLE_USER_HOME = $toolPaths.GradleCache }
if ($toolPaths.NpmPrefix) { $env:NPM_CONFIG_PREFIX = $toolPaths.NpmPrefix }
if ($toolPaths.NpmCache) { $env:NPM_CONFIG_CACHE = $toolPaths.NpmCache }
if ($toolPaths.UvCache) { $env:UV_CACHE_DIR = $toolPaths.UvCache }
if ($toolPaths.UvPython) { $env:UV_PYTHON_INSTALL_DIR = $toolPaths.UvPython }
if ($toolPaths.PipCache) { $env:PIP_CACHE_DIR = $toolPaths.PipCache }

$prepend = @(
    $toolPaths.Flutter
    (Join-Path $toolPaths.Java 'bin')
    (Join-Path $toolPaths.AndroidSdk 'platform-tools')
    (Join-Path $toolPaths.AndroidSdk 'emulator')
    (Join-Path $toolPaths.AndroidSdk 'cmdline-tools\latest\bin')
    $toolPaths.NpmPrefix
    (Join-Path $toolPaths.PubCache 'bin')
    $toolPaths.Python
    $toolPaths.UvCli
    $toolPaths.UvScripts
    (Join-Path $localTools 'LongvitaFirebase\node_modules\.bin')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) }

$existing = $env:Path -split ';' | Where-Object { $_ }
$env:Path = (@($prepend) + @($existing) | Select-Object -Unique) -join ';'

Write-Host 'Longvita environment loaded for this PowerShell session.' -ForegroundColor Green
Write-Host "Android SDK: $env:ANDROID_SDK_ROOT"
Write-Host "Pub cache:   $env:PUB_CACHE"
Write-Host "Gradle home: $env:GRADLE_USER_HOME"
Write-Host 'Run scripts\verify-setup.ps1 to validate the toolchain.'
