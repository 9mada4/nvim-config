param(
  [Parameter(Mandatory = $true)]
  [string]$LiteralPath
)

$ErrorActionPreference = 'Stop'
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
  $stream = [System.IO.File]::OpenRead($LiteralPath)
  try {
    $hash = $sha256.ComputeHash($stream)
    [Console]::Out.WriteLine([BitConverter]::ToString($hash).Replace('-', '').ToLowerInvariant())
  } finally {
    $stream.Dispose()
  }
} finally {
  $sha256.Dispose()
}
