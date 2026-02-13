$ErrorActionPreference = 'Stop'

$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'SlipstreamDashboardService'

if (Test-Path -LiteralPath $runKey) {
  Remove-ItemProperty -Path $runKey -Name $runValueName -ErrorAction SilentlyContinue
  Write-Host "Removed startup entry: $runValueName"
}
