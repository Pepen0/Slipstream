param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'

$driverInf = Join-Path $InstallRoot 'drivers\slipstream.inf'
if (-not (Test-Path -LiteralPath $driverInf)) {
  Write-Host 'No bundled driver found; skipping driver install.'
  exit 0
}

Write-Host "Installing driver: $driverInf"
$proc = Start-Process -FilePath 'pnputil.exe' -ArgumentList @('/add-driver', $driverInf, '/install') -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) {
  Write-Warning "Driver install returned non-zero exit code: $($proc.ExitCode)"
}
