param(
  [Parameter(Mandatory = $true)]
  [string]$InstallerPath,
  [Parameter(Mandatory = $true)]
  [string]$CertBase64,
  [Parameter(Mandatory = $true)]
  [string]$CertPassword,
  [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InstallerPath)) {
  throw "Installer not found: $InstallerPath"
}
if ([string]::IsNullOrWhiteSpace($CertBase64) -or [string]::IsNullOrWhiteSpace($CertPassword)) {
  throw 'Signing certificate content or password is empty.'
}

function Find-SignTool {
  $cmd = Get-Command 'signtool.exe' -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  if (-not (Test-Path -LiteralPath $kitsRoot)) {
    return $null
  }

  $candidate = Get-ChildItem -Path $kitsRoot -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1
  if ($candidate) {
    return $candidate.FullName
  }

  return $null
}

$signtool = Find-SignTool
if (-not $signtool) {
  throw 'signtool.exe not found. Install Windows SDK signing tools.'
}

$workDir = Join-Path $env:RUNNER_TEMP 'slipstream-signing'
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
$pfxPath = Join-Path $workDir 'codesign.pfx'

try {
  $bytes = [Convert]::FromBase64String($CertBase64)
  [IO.File]::WriteAllBytes($pfxPath, $bytes)

  $signArgs = @(
    'sign',
    '/fd', 'SHA256',
    '/td', 'SHA256',
    '/tr', $TimestampUrl,
    '/f', $pfxPath,
    '/p', $CertPassword,
    $InstallerPath
  )

  & $signtool @signArgs
  if ($LASTEXITCODE -ne 0) {
    throw "signtool sign failed with exit code $LASTEXITCODE"
  }

  & $signtool verify /pa /v $InstallerPath
  if ($LASTEXITCODE -ne 0) {
    throw "signtool verify failed with exit code $LASTEXITCODE"
  }

  Write-Host "Successfully signed installer: $InstallerPath"
} finally {
  Remove-Item -LiteralPath $pfxPath -Force -ErrorAction SilentlyContinue
}
