param(
  [string]$InstallRoot = ''
)

$ErrorActionPreference = 'Stop'

$raw = & pnputil.exe /enum-drivers 2>$null | Out-String
if (-not $raw) {
  Write-Host 'Unable to enumerate drivers; skipping driver uninstall.'
  exit 0
}

$blocks = $raw -split "(\r?\n){2,}"
$published = New-Object System.Collections.Generic.List[string]

foreach ($block in $blocks) {
  if ($block -match 'Provider Name\s*:\s*(.+)') {
    $provider = $Matches[1].Trim()
    if ($provider -match '(?i)slipstream') {
      if ($block -match 'Published Name\s*:\s*(\S+)') {
        $published.Add($Matches[1].Trim())
      }
    }
  }
}

if ($published.Count -eq 0) {
  Write-Host 'No Slipstream driver packages found to uninstall.'
  exit 0
}

foreach ($oemInf in $published) {
  Write-Host "Removing driver package: $oemInf"
  $proc = Start-Process -FilePath 'pnputil.exe' -ArgumentList @('/delete-driver', $oemInf, '/uninstall', '/force') -Wait -PassThru -NoNewWindow
  if ($proc.ExitCode -ne 0) {
    Write-Warning "Failed to remove $oemInf (exit $($proc.ExitCode))."
  }
}
