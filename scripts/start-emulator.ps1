[CmdletBinding()]
param(
    [string]$AvdName = 'Longvita_API_36',
    [switch]$ColdBoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'project-env.ps1')

$adb = Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe'
$emulator = Join-Path $env:ANDROID_SDK_ROOT 'emulator\emulator.exe'
$running = & $adb devices | Select-String '^emulator-\d+\s+device$'
if ($running) {
    Write-Host 'An Android emulator is already running:' -ForegroundColor Yellow
    $running.Line
    exit 0
}

$available = & $emulator -list-avds
if ($available -notcontains $AvdName) {
    throw "AVD '$AvdName' was not found. Available AVDs: $($available -join ', ')"
}

$arguments = @('-avd', $AvdName, '-no-snapshot-save')
if ($ColdBoot) {
    $arguments += '-no-snapshot-load'
}

Start-Process -FilePath $emulator -ArgumentList $arguments -WindowStyle Hidden
Write-Host "Started $AvdName. Wait for Android to boot, then run: flutter devices" -ForegroundColor Green
