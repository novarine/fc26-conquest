# FC 26 Conquest

Local Flutter MVP for a conquest campaign based on FC 26 matches.

## Documentation

Full project documentation is in [docs/README.md](docs/README.md).

- Setup and runbook: [docs/setup.md](docs/setup.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- Gameplay and data model: [docs/gameplay.md](docs/gameplay.md)
- Logging and diagnostics: [docs/logging.md](docs/logging.md)
- Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md)

## Current status

The project is working as a local Flutter app and can be built for Windows desktop. The verified validation commands are:

1. `C:\Users\marti\flutter-clean\bin\flutter.bat analyze`
2. `C:\Users\marti\flutter-clean\bin\flutter.bat test`
3. `C:\Users\marti\flutter-clean\bin\flutter.bat build windows --release`
4. `powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_installer.ps1`

## Windows setup

Use the explicit Flutter SDK path to avoid `.puro` path issues:

- `C:\Users\marti\flutter-clean\bin\flutter.bat`

If the Windows desktop toolchain is missing, install Visual Studio 2022 Build Tools and include:

- Desktop development with C++
- MSVC v142 - VS 2019 C++ x64/x86 build tools
- C++ CMake tools for Windows
- Windows 10 SDK

## Project scripts

- [scripts/build_windows_installer.ps1](scripts/build_windows_installer.ps1): builds the Release desktop app and creates a ZIP-based Windows install package
- [scripts/build_windows_installer_iss.ps1](scripts/build_windows_installer_iss.ps1): builds the same app as a proper Inno Setup installer with standard Windows uninstall support
- [scripts/serve_fc26_conquest_web.ps1](scripts/serve_fc26_conquest_web.ps1): serves the web build locally
- [scripts/launch_fc26_conquest_web.bat](scripts/launch_fc26_conquest_web.bat): launches the last built web bundle

## Windows installer quality

The Inno Setup installer is the preferred option for user-facing installs because it creates a standard Windows app entry, desktop shortcut, and proper uninstall entry in Apps & Features. The release flow is now paired with a version manifest fetch in the app so each build can compare the installed version to a remote release payload before opening the installer download.

## Update manifest contract

The app expects a JSON manifest that contains at least one version key and one installer/download URL key. The supported field names are:

- version, latestVersion, tag, releaseVersion
- installerUrl, downloadUrl, browserDownloadUrl, url, releaseUrl
- releaseNotes, notes, changelog, whatsNew, description

The canonical release manifest is hosted as a static file and should be published alongside each release package. A ready-to-host example is in [release/version.json](release/version.json).

Example payload:

```json
{
  "version": "1.2.0",
  "installerUrl": "https://example.com/releases/fc26-conquest-setup.exe",
  "releaseNotes": "- fixed missing club logos\n- improved Windows installer flow"
}
```

Update the values in [lib/services/update_service.dart](lib/services/update_service.dart) to match the real hosted endpoint before publishing a new Windows release. The release version is then compared to the app’s current version and the resolved installer URL is opened when a newer version is available.

## Trusted publisher signing

For a production Windows install, sign the app binary and the generated Inno Setup installer with a valid code-signing certificate. The packaging script in [scripts/build_windows_installer_iss.ps1](scripts/build_windows_installer_iss.ps1) looks for the Windows SDK `signtool.exe` and signs both outputs when a matching certificate subject is available. If no certificate is installed, the script continues with an unsigned build but the release should be signed before distribution to avoid Windows SmartScreen warnings.

## App behavior

- Local campaign state is stored and restored without a backend
- Teams, regions, and player data are loaded from seeded JSON files
- Battle outcomes are resolved by the conquest rules in [lib/services/conquest_service.dart](lib/services/conquest_service.dart)
- Runtime and error logging are routed through [lib/services/app_logger.dart](lib/services/app_logger.dart)

## MVP scope

- Start a new campaign
- Save a campaign locally
- Draw attackers and neighboring opponents
- Record winners
- Capture a frontier region
- View basic stats

## Project structure

- `lib/models`: data models
- `lib/services`: seed loading, persistence, conquest logic
- `lib/controllers`: campaign state and UI flow
- `lib/screens`: main screens
- `assets/data`: seed data for the initial prototype
