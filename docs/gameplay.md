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
