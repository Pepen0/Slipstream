param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'

$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'SlipstreamDashboardService'

$serviceExe = Join-Path $InstallRoot 'services\dashboard_server.exe'
$appExe = Join-Path $InstallRoot 'client.exe'

$command = $null
if (Test-Path -LiteralPath $serviceExe) {
  $command = '"{0}" 127.0.0.1:50060' -f $serviceExe
} elseif (Test-Path -LiteralPath $appExe) {
  $command = '"{0}"' -f $appExe
}

if (-not $command) {
  Write-Host 'No dashboard service or app executable found; startup entry was not created.'
  exit 0
}

if (-not (Test-Path -LiteralPath $runKey)) {
  New-Item -Path $runKey -Force | Out-Null
}

New-ItemProperty -Path $runKey -Name $runValueName -Value $command -PropertyType String -Force | Out-Null
Write-Host "Configured startup entry: $runValueName"
