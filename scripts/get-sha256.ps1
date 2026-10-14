param(
  [Parameter(Mandatory = $true)]
  [string]$LiteralPath
)

$ErrorActionPreference = 'Stop'
$hash = Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256
[Console]::Out.WriteLine($hash.Hash.ToLowerInvariant())
