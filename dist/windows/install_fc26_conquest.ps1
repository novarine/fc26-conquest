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
