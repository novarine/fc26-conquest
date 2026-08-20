# AGENTS.md

Practical working instructions for coding agents in this repository.

## Scope

- This repo is a local Flutter MVP for FC 26 Conquest.
- Use the existing docs as the source of truth: [README.md](README.md), [docs/README.md](docs/README.md), [docs/architecture.md](docs/architecture.md).
- Keep changes small and local; avoid unnecessary architecture refactors or new state-management frameworks.

## Quick start

- `flutter pub get`
- `<flutter-sdk>\bin\flutter.bat analyze`
- `<flutter-sdk>\bin\flutter.bat test`
- `<flutter-sdk>\bin\flutter.bat run -d chrome`

If platform files are missing or broken:

1. `flutter create .`
2. `flutter pub get`

## Windows pitfalls

- VS Code uses a local Flutter SDK from [.vscode/settings.json](.vscode/settings.json).
- If `flutter` is not found in new terminals, explicitly use the configured SDK path.
- Prefer `-d chrome` for fast UI validation; browser-based checks are the default here.

## Architecture boundaries

- App entry and route flow: [lib/main.dart](lib/main.dart)
- Central state and page flow: [lib/controllers/campaign_controller.dart](lib/controllers/campaign_controller.dart)
- Core game rules: [lib/services/conquest_service.dart](lib/services/conquest_service.dart)
- Seed loading and persistence: [lib/services/seed_data_service.dart](lib/services/seed_data_service.dart), [lib/services/storage_service.dart](lib/services/storage_service.dart)
- UI screens: [lib/screens](lib/screens)
- Reusable widgets: [lib/widgets](lib/widgets)
- Data models: [lib/models](lib/models)

## Conventions

- Stateful logic lives in the central `ChangeNotifier` controller; do not introduce new state-management frameworks.
- Models are immutable-oriented (`copyWith`, JSON serialization) and should only be adjusted locally.
- Seed data comes from [assets/data](assets/data) and must be registered in [pubspec.yaml](pubspec.yaml).
- UI text may be German; code symbols stay consistent in English.
- If an interface or flow is changed, keep all affected call sites in [lib/main.dart](lib/main.dart) and the relevant screens in sync.

## Agent workflow

1. Before larger changes, read the relevant files: [README.md](README.md), [lib/main.dart](lib/main.dart), [lib/controllers/campaign_controller.dart](lib/controllers/campaign_controller.dart).
2. Carry signature and flow changes through the entire call graph.
3. After each change, run `flutter analyze`; for logic or data changes, also run `flutter test`.
4. For UI changes, verify with the browser run using `-d chrome` and check for visible regressions.
5. Use runtime and error logs via [lib/services/app_logger.dart](lib/services/app_logger.dart); avoid scattered `print` statements.

## Out of scope

- No cloud or backend integration.
- No external online dependency is required for the core gameplay.
- Avoid generic architecture overhauls while the MVP flow remains stable.
