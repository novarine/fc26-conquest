param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$InnoSetupExe = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
  [string]$SigningCertificateSubject = "CN=7150945d-41c7-49cb-8842-d6dc2e4c1cc6",
  [string]$SigningCertificateThumbprint = "DD4F5A6E5A24097B0307CD02CABE3C383958791F"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $InnoSetupExe)) {
  throw "Inno Setup not found at $InnoSetupExe"
}

$flutterExe = if ($env:FC26_FLUTTER_EXE) { $env:FC26_FLUTTER_EXE } else { "flutter" }
$signTool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\" -Recurse -Filter signtool.exe |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName

Push-Location $ProjectRoot
try {
  & $flutterExe build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed."
  }

  $appExe = Join-Path $ProjectRoot "build\windows\x64\runner\Release\fc26_conquest.exe"
  $installerExe = Join-Path $ProjectRoot "dist\windows\FC26Conquest-Setup.exe"

  if ($signTool -and (Test-Path $appExe)) {
    if ($SigningCertificateThumbprint) {
      Write-Host "Signing Windows app binary with certificate thumbprint: $SigningCertificateThumbprint"
      & $signTool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 $SigningCertificateThumbprint $appExe
    }
    elseif ($SigningCertificateSubject) {
      Write-Host "Signing Windows app binary with certificate subject: $SigningCertificateSubject"
      & $signTool sign /fd SHA256 /a /tr http://timestamp.digicert.com /td SHA256 /n $SigningCertificateSubject $appExe
    }

    if ($LASTEXITCODE -ne 0) {
      Write-Warning "App signing failed; continue without signing if no valid certificate is installed."
    }
  }

  $installerScript = Join-Path $ProjectRoot "installer\fc26_conquest_installer.iss"
  if (-not (Test-Path $installerScript)) {
    throw "Installer script not found: $installerScript"
  }

  $outputDir = Join-Path $ProjectRoot "dist\windows"
  if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
  }

  & $InnoSetupExe "/Q" "/O$outputDir" "$installerScript"
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed."
  }

  if ($signTool -and (Test-Path $installerExe)) {
    if ($SigningCertificateThumbprint) {
      Write-Host "Signing Windows installer with certificate thumbprint: $SigningCertificateThumbprint"
      & $signTool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 $SigningCertificateThumbprint $installerExe
    }
    elseif ($SigningCertificateSubject) {
      Write-Host "Signing Windows installer with certificate subject: $SigningCertificateSubject"
      & $signTool sign /fd SHA256 /a /tr http://timestamp.digicert.com /td SHA256 /n $SigningCertificateSubject $installerExe
    }

    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Installer signing failed; continue without signing if no valid certificate is installed."
    }
  }

  Write-Host "Created signed Inno Setup installer in $outputDir"
}
finally {
  Pop-Location
}
