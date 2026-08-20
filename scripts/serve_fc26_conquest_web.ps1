param(
  [int]$Port = 8765,
  [string]$Root = "$(Split-Path -Parent $PSScriptRoot)\build\web"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Root)) {
  throw "Web build not found: $Root"
}

function Get-ContentType([string]$path) {
  switch ([IO.Path]::GetExtension($path).ToLowerInvariant()) {
    '.html' { 'text/html; charset=utf-8'; break }
    '.js' { 'application/javascript; charset=utf-8'; break }
    '.json' { 'application/json; charset=utf-8'; break }
    '.css' { 'text/css; charset=utf-8'; break }
    '.png' { 'image/png'; break }
    '.jpg' { 'image/jpeg'; break }
    '.jpeg' { 'image/jpeg'; break }
    '.svg' { 'image/svg+xml'; break }
    '.wasm' { 'application/wasm'; break }
    '.ico' { 'image/x-icon'; break }
    '.ttf' { 'font/ttf'; break }
    '.otf' { 'font/otf'; break }
    '.woff' { 'font/woff'; break }
    '.woff2' { 'font/woff2'; break }
    default { 'application/octet-stream'; break }
  }
}

$rootFull = [IO.Path]::GetFullPath($Root)
function Start-ListenerWithFallback {
  param(
    [int]$RequestedPort,
    [int]$MaxAttempts = 20
  )

  for ($i = 0; $i -lt $MaxAttempts; $i++) {
    $candidatePort = $RequestedPort + $i
    $prefix = "http://localhost:$candidatePort/"
    $candidateListener = [System.Net.HttpListener]::new()
    $candidateListener.Prefixes.Add($prefix)

    try {
      $candidateListener.Start()
      return @{
        Listener = $candidateListener
        Prefix = $prefix
      }
    }
    catch [System.Net.HttpListenerException] {
      $candidateListener.Close()
      continue
    }
  }

  throw "Unable to start local web server. Tried ports $RequestedPort to $($RequestedPort + $MaxAttempts - 1)."
}

$listenerInfo = Start-ListenerWithFallback -RequestedPort $Port
$listener = $listenerInfo.Listener
$prefix = $listenerInfo.Prefix

Write-Host "FC26 Conquest Web läuft auf $prefix"
Write-Host "Zum Beenden dieses Fenster schließen oder Strg+C drücken."
Start-Process $prefix | Out-Null

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $requestPath = $context.Request.Url.AbsolutePath
    if ([string]::IsNullOrWhiteSpace($requestPath) -or $requestPath -eq '/') {
      $requestPath = '/index.html'
    }

    $relativePath = $requestPath.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $candidatePath = [IO.Path]::GetFullPath((Join-Path $rootFull $relativePath))

    if (-not $candidatePath.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      $context.Response.StatusCode = 403
      $context.Response.Close()
      continue
    }

    if (-not (Test-Path $candidatePath) -and -not [IO.Path]::GetExtension($candidatePath)) {
      $candidatePath = Join-Path $candidatePath 'index.html'
    }

    if (-not (Test-Path $candidatePath)) {
      $candidatePath = Join-Path $rootFull 'index.html'
    }

    $bytes = [IO.File]::ReadAllBytes($candidatePath)
    $context.Response.StatusCode = 200
    $context.Response.ContentType = Get-ContentType $candidatePath
    $context.Response.ContentLength64 = $bytes.LongLength
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.OutputStream.Close()
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
