# Architektur

## Uebersicht

Die App ist als lokaler Flutter-MVP aufgebaut und trennt Modell, Logik, Persistenz und UI.

## Schichten

1. Models
   - Verzeichnis: [../lib/models](../lib/models)
   - Enthalten Datenobjekte wie `CampaignState`, `Region`, `Player`, `Team`, `TeamStats`.

2. Services
   - Verzeichnis: [../lib/services](../lib/services)
   - `conquest_service.dart`: Spielregeln, Paarungen, Gebietseroberung, Statistiken.
   - `seed_data_service.dart`: Laden der Seed-Daten aus Assets.
   - `storage_service.dart`: Persistenz (SharedPreferences).
   - `app_logger.dart`: Einheitliches Logging.

3. Controller
   - Datei: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)
   - `ChangeNotifier`-Orchestrierung fuer Seitenfluss und Kampagnenzustand.

4. UI
   - Verzeichnisse: [../lib/screens](../lib/screens), [../lib/widgets](../lib/widgets)
   - `main.dart` verdrahtet Theme, Routing (AppPage) und Controller.

## Navigation und Stateflow

- Einstieg in [../lib/main.dart](../lib/main.dart)
- Seitenzustand per `AppPage`:
  - `home`
  - `map`
  - `battle`
  - `stats`
- `CampaignController` steuert Übergaenge und benennt Fehler fuer die UI.

## Datenquellen

- Seed-Assets: [../assets/data](../assets/data)
- Konfiguration in [../pubspec.yaml](../pubspec.yaml)

## Designentscheidungen

- Minimaler Stack: keine komplexen Frameworks fuer State-Management.
- Lokale Persistenz statt Backend.
- Spielregeln zentral im Service, nicht in Widgets.
