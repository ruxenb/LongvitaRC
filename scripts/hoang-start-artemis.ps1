[CmdletBinding()]
param(
  [string]$ArtemisRoot = 'D:\Tools\ARTEMIS_351ca842',
  [string]$NodeRoot = 'D:\Tools\NodePortable\node-v24.15.0-win-x64',
  [int]$Port = 8000
)
$ErrorActionPreference='Stop'
$python=Join-Path $ArtemisRoot '.venv\Scripts\python.exe'
if(!(Test-Path $python)){throw 'ARTEMIS daemon virtual environment not installed.'}
$sha=(git -C $ArtemisRoot rev-parse HEAD)
if($sha -ne '351ca8422f7b5b54e80a9c1ce03a222e02415b6b'){
  throw 'ARTEMIS source does not match the version pinned by LongvitaRC.'
}
if(Test-Path (Join-Path $NodeRoot 'node.exe')){$env:PATH="$NodeRoot;$env:PATH"}
$env:ANDROID_HOME='D:\Tools\AndroidSDK'
$env:ANDROID_SDK_ROOT=$env:ANDROID_HOME
$env:PATH="$env:ANDROID_HOME\platform-tools;$env:PATH"
$env:UV_CACHE_DIR='D:\Tools\uv-cache'
$env:npm_config_cache='D:\Tools\npm-cache'
$env:ARTEMIS_KEEP_DEVICE_AWAKE='false'
$env:ARTEMIS_HELPER_AUTO_INSTALL='false'
$env:ARTEMIS_HIERARCHY_BACKEND='uiautomator'
$env:PYTHONUTF8='1'
$env:PYTHONIOENCODING='utf-8'
$uri="http://127.0.0.1:$Port/api/status"
try{
  $response=Invoke-RestMethod -UseBasicParsing -TimeoutSec 3 -Uri $uri
  if($response.status -in @('idle','running','busy')){
    Write-Output "ARTEMIS already running on localhost:$Port; not restarting."
    return
  }
}catch{}
Write-Output "Starting pinned ARTEMIS on localhost:$Port. Ctrl+C stops it."
Push-Location $ArtemisRoot
try {
  & $python -m artemis ui --host 127.0.0.1 --port $Port --no-open --no-reload
  if($LASTEXITCODE -ne 0){throw "ARTEMIS process exit code $LASTEXITCODE"}
}finally{Pop-Location}
