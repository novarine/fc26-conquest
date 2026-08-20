param(
  [string]$FlutterExe = "C:\Users\marti\flutter-clean\bin\flutter.bat",
  [string]$ProjectRoot = "C:\Users\marti\fc26-conquest"
)

$ErrorActionPreference = "Stop"

Push-Location $ProjectRoot
try {
  $doctorOutput = & $FlutterExe doctor -v 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    Write-Host $doctorOutput
    throw "Flutter doctor reported problems. Resolve them before packaging."
  }

  if ($doctorOutput -match "Visual Studio not installed") {
    throw @"
Visual Studio C++ toolchain is missing.

Install Visual Studio 2022 Community or Build Tools with workload:
- Desktop development with C++

Then run this script again.
"@
  }

  & $FlutterExe clean
  & $FlutterExe build windows --release

  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed. See output above."
  }

  $releaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
  if (-not (Test-Path $releaseDir)) {
    throw @"
Release output not found at:
$releaseDir

Possible cause:
- Visual Studio C++ workload is missing
- Windows desktop toolchain is incomplete
- Build stopped early
"@
  }

  $distRoot = Join-Path $ProjectRoot "dist\windows"
  if (-not (Test-Path $distRoot)) {
    New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
  }

  $bundleDir = Join-Path $distRoot "FC26Conquest-Windows"
  if (Test-Path $bundleDir) {
    Remove-Item $bundleDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $bundleDir | Out-Null

  Copy-Item (Join-Path $releaseDir "*") -Destination $bundleDir -Recurse -Force

  $installerScript = @'
param(
  [string]$InstallDir = "$env:ProgramFiles\FC26 Conquest"
)

$ErrorActionPreference = "Stop"

$resolvedInstallDir = [System.IO.Path]::GetFullPath($InstallDir)
Write-Host "Installing FC26 Conquest to $resolvedInstallDir"
New-Item -ItemType Directory -Path $resolvedInstallDir -Force | Out-Null
Copy-Item "$PSScriptRoot\FC26Conquest-Windows\*" -Destination $resolvedInstallDir -Recurse -Force

$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "FC26 Conquest.lnk"
$targetPath = Join-Path $resolvedInstallDir "FC26Conquest.exe"

if (-not (Test-Path $targetPath)) {
  throw "Expected executable not found at $targetPath"
}

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $resolvedInstallDir
$shortcut.IconLocation = "$targetPath,0"
$shortcut.Save()

Write-Host "Installation complete. Shortcut created: $shortcutPath"
'@

  Set-Content -Path (Join-Path $distRoot "install_fc26_conquest.ps1") -Value $installerScript -Encoding UTF8

  $zipPath = Join-Path $distRoot "FC26Conquest-Windows-Release.zip"
  if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
  }
  Compress-Archive -Path $bundleDir, (Join-Path $distRoot "install_fc26_conquest.ps1") -DestinationPath $zipPath -Force

  Write-Host "Created Windows package: $zipPath"
  Write-Host "Install using: powershell -ExecutionPolicy Bypass -File .\install_fc26_conquest.ps1"
}
finally {
  Pop-Location
}
