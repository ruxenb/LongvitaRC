[CmdletBinding()]
param()

$toolPaths = [ordered]@{
    Flutter = 'T:\Flutter\flutter\bin'
    Java = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.7.6-hotspot'
    AndroidSdk = 'T:\Android\Sdk'
    AndroidHome = 'T:\Android\user-home'
    GradleCache = 'T:\Tools\GradleHome'
    PubCache = 'T:\Tools\PubCache'
    NpmPrefix = 'T:\Tools\npm-global'
    NpmCache = 'T:\Tools\npm-cache'
    Python = 'T:\Tools\uv-python\cpython-3.12.16-windows-x86_64-none'
    UvScripts = 'T:\Tools\PythonUser\Python314\Scripts'
    UvCache = 'T:\Tools\uv-cache'
    UvPython = 'T:\Tools\uv-python'
    PipCache = 'T:\Tools\pip-cache'
}

foreach ($entry in $toolPaths.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) {
        throw "Missing $($entry.Key) path: $($entry.Value)"
    }
}

$env:JAVA_HOME = $toolPaths.Java
$env:ANDROID_HOME = $toolPaths.AndroidSdk
$env:ANDROID_SDK_ROOT = $toolPaths.AndroidSdk
$env:ANDROID_USER_HOME = $toolPaths.AndroidHome
$env:GRADLE_USER_HOME = $toolPaths.GradleCache
$env:PUB_CACHE = $toolPaths.PubCache
$env:NPM_CONFIG_PREFIX = $toolPaths.NpmPrefix
$env:NPM_CONFIG_CACHE = $toolPaths.NpmCache
$env:UV_CACHE_DIR = $toolPaths.UvCache
$env:UV_PYTHON_INSTALL_DIR = $toolPaths.UvPython
$env:PIP_CACHE_DIR = $toolPaths.PipCache

$prepend = @(
    $toolPaths.Flutter
    (Join-Path $toolPaths.Java 'bin')
    (Join-Path $toolPaths.AndroidSdk 'platform-tools')
    (Join-Path $toolPaths.AndroidSdk 'emulator')
    (Join-Path $toolPaths.AndroidSdk 'cmdline-tools\latest\bin')
    $toolPaths.NpmPrefix
    (Join-Path $toolPaths.PubCache 'bin')
    $toolPaths.Python
    $toolPaths.UvScripts
)

$existing = $env:Path -split ';' | Where-Object { $_ }
$env:Path = (@($prepend) + @($existing) | Select-Object -Unique) -join ';'

Write-Host 'Longvita environment loaded for this PowerShell session.' -ForegroundColor Green
Write-Host "Android SDK: $env:ANDROID_SDK_ROOT"
Write-Host "Pub cache:   $env:PUB_CACHE"
Write-Host "Gradle home: $env:GRADLE_USER_HOME"
Write-Host 'Run scripts\verify-setup.ps1 to validate the toolchain.'
