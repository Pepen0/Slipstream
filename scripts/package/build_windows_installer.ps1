param(
  [string]$Version = '',
  [string]$AppBuildDir = 'Software-code/App/build/windows/x64/runner/Release',
  [string]$OutputDir = 'dist/windows',
  [string]$InnoSetupScript = 'packaging/windows/Slipstream.iss',
  [string]$DashboardServerBin = '',
  [string]$DriverInf = '',
  [string]$AppExeName = 'client.exe',
  [switch]$SkipIscc
)

$ErrorActionPreference = 'Stop'

if (-not $Version) {
  if ($env:SLIPSTREAM_VERSION) {
    $Version = $env:SLIPSTREAM_VERSION
  } else {
    $Version = '0.0.0-dev'
  }
}

if (-not $DashboardServerBin -and $env:SLIPSTREAM_DASHBOARD_SERVER_BIN) {
  $DashboardServerBin = $env:SLIPSTREAM_DASHBOARD_SERVER_BIN
}
if (-not $DriverInf -and $env:SLIPSTREAM_DRIVER_INF) {
  $DriverInf = $env:SLIPSTREAM_DRIVER_INF
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$appBuildPath = Join-Path $repoRoot $AppBuildDir
$outputPath = Join-Path $repoRoot $OutputDir
$stageDir = Join-Path $outputPath 'stage'
$installerDir = Join-Path $outputPath 'installer'
$scriptPath = Join-Path $repoRoot $InnoSetupScript

if (-not (Test-Path -LiteralPath $scriptPath)) {
  throw "Inno Setup script not found: $scriptPath"
}
if (-not (Test-Path -LiteralPath $appBuildPath)) {
  throw "Flutter Windows build directory not found: $appBuildPath"
}

$appExePath = Join-Path $appBuildPath $AppExeName
if (-not (Test-Path -LiteralPath $appExePath)) {
  throw "App executable not found: $appExePath"
}

Remove-Item -LiteralPath $stageDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installerDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
New-Item -ItemType Directory -Path $installerDir -Force | Out-Null

Copy-Item -Path (Join-Path $appBuildPath '*') -Destination $stageDir -Recurse -Force

$winScriptSrc = Join-Path $repoRoot 'packaging/windows'
$winScriptDst = Join-Path $stageDir 'scripts/windows'
New-Item -ItemType Directory -Path $winScriptDst -Force | Out-Null
Copy-Item -Path (Join-Path $winScriptSrc '*.ps1') -Destination $winScriptDst -Force

if ($DashboardServerBin -and (Test-Path -LiteralPath $DashboardServerBin)) {
  $serviceDir = Join-Path $stageDir 'services'
  New-Item -ItemType Directory -Path $serviceDir -Force | Out-Null
  Copy-Item -LiteralPath $DashboardServerBin -Destination (Join-Path $serviceDir 'dashboard_server.exe') -Force
}

if ($DriverInf -and (Test-Path -LiteralPath $DriverInf)) {
  $driverDir = Join-Path $stageDir 'drivers'
  New-Item -ItemType Directory -Path $driverDir -Force | Out-Null
  Copy-Item -LiteralPath $DriverInf -Destination (Join-Path $driverDir 'slipstream.inf') -Force
}

$manifestPath = Join-Path $outputPath 'bundle-manifest.txt'
$manifest = @()
$manifest += "version=$Version"
$manifest += "app_build_dir=$appBuildPath"
$manifest += "stage_dir=$stageDir"
$manifest += "app_exe=$AppExeName"
$manifest += "dashboard_server_bundled=$([bool](Test-Path -LiteralPath (Join-Path $stageDir 'services/dashboard_server.exe')))"
$manifest += "driver_inf_bundled=$([bool](Test-Path -LiteralPath (Join-Path $stageDir 'drivers/slipstream.inf')))"
$manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Staged Windows bundle at $stageDir"
Write-Host "Manifest: $manifestPath"

if ($SkipIscc) {
  Write-Host 'SkipIscc requested; not building installer executable.'
  exit 0
}

$iscc = (Get-Command 'iscc' -ErrorAction SilentlyContinue)?.Source
if (-not $iscc) {
  $fallback = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  if (Test-Path -LiteralPath $fallback) {
    $iscc = $fallback
  }
}
if (-not $iscc) {
  throw 'ISCC not found. Install Inno Setup 6 or pass -SkipIscc for staging-only runs.'
}

$isccArgs = @(
  "/DMyAppVersion=$Version"
  "/DMyStageDir=$stageDir"
  "/DMyAppExe=$AppExeName"
  "/O$installerDir"
  "$scriptPath"
)

& $iscc @isccArgs
if ($LASTEXITCODE -ne 0) {
  throw "ISCC failed with exit code $LASTEXITCODE"
}

Write-Host "Windows installer generated in $installerDir"
Get-ChildItem -LiteralPath $installerDir -Filter '*.exe' | ForEach-Object {
  Write-Host " - $($_.FullName)"
}
