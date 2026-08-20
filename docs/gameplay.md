# Gameplay und Datenmodell

## Kampagnen-Loop

1. Neue Kampagne starten (`home`)
2. Teams und Regionen initialisieren (`CampaignController.startNewCampaign`)
3. Battle-Paarung erzeugen (manuell ueber Wheel oder zufaellig)
4. Sieger eintragen (`battle`)
5. Region uebernehmen, optional Spielertransfer
6. Zurueck auf Karte (`map`) und Stats verfolgen (`stats`)

## Zentrale Regeln

- Nur gueltige Nachbar-Paarungen sind erlaubt.
- Sieger erobert eine grenzende Region des Verlierers.
- Optionaler Transfer: Sieger kann einen Spieler des Verlierers uebernehmen.
- Ende: Champion, wenn alle Regionen einem Team gehoeren.

## Kampagnen-Setup-Filter

- Beim Anlegen einer neuen Kampagne koennen Liga, Land und Rating-Bereich gefiltert werden, bevor Teams ausgewaehlt werden.
- Liga-/Land-Filter stehen nur im Club-Modus zur Verfuegung (Nationen haben keine sinnvollen Liga-/Land-Gruppen in den Seed-Daten).
- Der Rating-Bereich funktioniert in beiden Modi (Club und Nation).
- "Neue Kampagne" ist deaktiviert, wenn der gefilterte Team-Pool weniger als 2 Teams enthaelt.
- Reine Filterlogik: [../lib/utils/team_filter.dart](../lib/utils/team_filter.dart)
- Abgedeckte Ligen/Laender (Stand zuletzt erweitert): Premier League, Bundesliga, LaLiga, Serie A, Ligue 1, Eredivisie, Primeira Liga, Super Lig, Serie A Brazil, Primera Division, Austrian Bundesliga, Belgian Pro League, Swiss Super League, Scottish Premiership, Saudi Pro League, MLS.

## Zufallsrad-Werkzeug

- Eigenstaendiges Werkzeug (erreichbar ueber den Home-Screen-Button "Zufallsrad-Werkzeug"), unabhaengig vom laufenden Conquest-Flow.
- Nutzer koennen frei benannte Zufallsraeder mit eigenen Texteintraegen anlegen, drehen und wieder loeschen (z. B. Herausforderungen, Formationen, Regel-Modifikatoren).
- Presets werden lokal per SharedPreferences gespeichert, getrennt vom Kampagnenstand.
- Implementierung: [../lib/screens/custom_wheel_screen.dart](../lib/screens/custom_wheel_screen.dart), [../lib/widgets/generic_wheel_dialog.dart](../lib/widgets/generic_wheel_dialog.dart), [../lib/models/wheel_preset.dart](../lib/models/wheel_preset.dart)

## Wichtige Strukturen

- `CampaignState`
  - turn, matchesPlayed
  - regions, players, history
- `Region`
  - id, label, ownerId, neighbors
- `MatchRecord`
  - teamA, teamB, winner, capturedRegionId, transferredPlayerId, score

## Relevante Implementierung

- Regeln: [../lib/services/conquest_service.dart](../lib/services/conquest_service.dart)
- Orchestrierung: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)
- Kartenansicht: [../lib/widgets/world_map_board.dart](../lib/widgets/world_map_board.dart)
- Wheel: [../lib/widgets/team_wheel_dialog.dart](../lib/widgets/team_wheel_dialog.dart)