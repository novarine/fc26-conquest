# Setup and runbook

## Requirements

- Windows 10/11
- Git installed
- Flutter SDK, recommended path: `C:\Users\marti\flutter-clean`
- Visual Studio 2022 Build Tools for Windows desktop builds

## Initial setup

1. Clone the repository and change into the project folder.
2. If the platform files are missing, run:
   - `flutter create .`
3. Install dependencies:
   - `flutter pub get`

## Stable Windows workflow

Use the explicit Flutter binary to avoid `.puro` path issues:

1. `C:\Users\marti\flutter-clean\bin\flutter.bat analyze`
2. `C:\Users\marti\flutter-clean\bin\flutter.bat test`
3. `C:\Users\marti\flutter-clean\bin\flutter.bat run -d chrome`
4. `C:\Users\marti\flutter-clean\bin\flutter.bat build windows --release`

## Required Windows desktop toolchain

For the Windows desktop release build, install the C++ workload and required components in Visual Studio 2022 Build Tools:

- Desktop development with C++
- MSVC v142 - VS 2019 C++ x64/x86 build tools
- C++ CMake tools for Windows
- Windows 10 SDK

## VS Code

- SDK path: [../.vscode/settings.json](../.vscode/settings.json)
- Reusable tasks: [../.vscode/tasks.json](../.vscode/tasks.json)

Recommended VS Code validation:

- Run the task `Flutter: Verify + Run Chrome (flutter-clean)` for quick web checks.
- Use the Release Windows build for installation packaging.

## Packaging flow

To generate a Windows installer bundle:

1. `C:\Users\marti\flutter-clean\bin\flutter.bat build windows --release`
2. `powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_installer_iss.ps1`

This creates a distributable installer in `dist/windows` and registers the app with Windows uninstall support through the Inno Setup package.

## Update release flow

The desktop app performs a lightweight remote version check at startup. It calls the manifest URL configured in [../lib/services/update_service.dart](../lib/services/update_service.dart) and expects a JSON document that includes a semantic version and an installer/download URL.

The recommended deployment pattern is to publish a static file such as [../release/version.json](../release/version.json) on your release host (for example: GitHub Pages, a CDN, or a static file bucket) and point the app at that URL. The file should be updated for every new installer release.

Supported manifest fields:

- `version`, `latestVersion`, `tag`, `releaseVersion`
- `installerUrl`, `downloadUrl`, `browserDownloadUrl`, `url`, `releaseUrl`
- `releaseNotes`, `notes`, `changelog`, `whatsNew`, `description`

If a newer version is found, the app shows the update banner and opens the resolved installer URL in the default browser. The release notes are displayed directly in the banner so users can see what changed before downloading the new installer.

## Trusted publisher / code signing

For a production release on Windows, sign the built app and the final `.exe` installer with a valid code-signing certificate before distribution. The packaging script [../scripts/build_windows_installer_iss.ps1](../scripts/build_windows_installer_iss.ps1) automatically detects `signtool.exe` from the Windows SDK and signs both binaries when the configured certificate subject is installed. This reduces SmartScreen warnings and makes the installation experience closer to a trusted publisher flow.

## Definition of done

1. `flutter analyze` returns no issues.
2. `flutter test` passes.
3. The app starts correctly in Chrome or the Windows desktop build.
4. Core flow is checked: Home -> Map -> Battle -> Stats.
