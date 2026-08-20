# Architecture

## Overview

The app is built as a local Flutter MVP that separates model, logic, persistence, and UI.

## Layers

1. Models
   - Directory: [../lib/models](../lib/models)
   - Contains data objects such as `CampaignState`, `Region`, `Player`, `Team`, `TeamStats`.

2. Services
   - Directory: [../lib/services](../lib/services)
   - `conquest_service.dart`: game rules, pairings, region capture, statistics.
   - `seed_data_service.dart`: loading seed data from assets.
   - `storage_service.dart`: persistence (SharedPreferences), including campaign state and custom wheel presets.
   - `app_logger.dart`: unified logging.
   - `../utils/team_filter.dart`: pure filter function for league/country/rating in campaign setup.

3. Controller
   - File: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)
   - `ChangeNotifier` orchestration for page flow and campaign state.

4. UI
   - Directories: [../lib/screens](../lib/screens), [../lib/widgets](../lib/widgets)
   - `main.dart` wires up theme, routing (`AppPage`), and the controller.

## Navigation and State Flow

- Entry point in [../lib/main.dart](../lib/main.dart)
- Page state via `AppPage`:
  - `home`
  - `map`
  - `battle`
  - `stats`
- `CampaignController` drives transitions and surfaces errors to the UI.
- The custom wheel tool ([../lib/screens/custom_wheel_screen.dart](../lib/screens/custom_wheel_screen.dart)) is wired as a local overlay in `_Fc26ConquestAppState` and is independent of `AppPage`/`CampaignController`, so the Conquest flow stays unchanged.

## Data Sources

- Seed assets: [../assets/data](../assets/data)
- Configuration in [../pubspec.yaml](../pubspec.yaml)

## Design Decisions

- Minimal stack: no complex state-management frameworks.
- Local persistence instead of a backend.
- Game rules live centrally in services, not in widgets.
