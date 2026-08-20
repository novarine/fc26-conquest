---
name: fc26-conquest-workflow
description: "Use when: working on the FC 26 Conquest Flutter MVP, updating the campaign flow, models, screens, services, or validating app behavior before merging."
---

# FC 26 Conquest workflow

## When to use

- onboarding to the repository
- changing gameplay rules or campaign state
- editing screens, services, or data models
- validating a Flutter change before a PR or merge

## Project map

- App entry and route flow: [lib/main.dart](lib/main.dart)
- Central controller and campaign flow: [lib/controllers/campaign_controller.dart](lib/controllers/campaign_controller.dart)
- Core rules and battle logic: [lib/services/conquest_service.dart](lib/services/conquest_service.dart)
- Storage and seed data: [lib/services/storage_service.dart](lib/services/storage_service.dart), [lib/services/seed_data_service.dart](lib/services/seed_data_service.dart)
- UI screens: [lib/screens](lib/screens)
- Models: [lib/models](lib/models)
- Static data: [assets/data](assets/data)

## Working rules

- Prefer small, local edits and keep the repo’s existing architecture intact.
- Keep state logic in the central `ChangeNotifier` controller and avoid introducing a new state framework.
- If a model or flow changes, update the affected call sites in [lib/main.dart](lib/main.dart) and the relevant screens.
- Seed data changes need to be reflected in [pubspec.yaml](pubspec.yaml).
- Use the logger in [lib/services/app_logger.dart](lib/services/app_logger.dart) instead of ad hoc `print` debugging.

## Validation

1. Run `flutter analyze` after changes.
2. Run `flutter test` for logic, data, or service updates.
3. For UI changes, run `flutter run -d chrome` and confirm the flow still looks correct.
4. If the workspace is missing platform files, run `flutter create .` and then `flutter pub get`.

## Documentation

- Project overview: [README.md](README.md)
- Setup and runbook: [docs/setup.md](docs/setup.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- Gameplay and data model: [docs/gameplay.md](docs/gameplay.md)
- Logging: [docs/logging.md](docs/logging.md)
