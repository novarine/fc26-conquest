# Gameplay and Data Model

## Campaign Loop

1. Start a new campaign (`home`)
2. Initialize teams and regions (`CampaignController.startNewCampaign`)
3. Generate a battle pairing (manually via the wheel, or randomly)
4. Record the winner (`battle`)
5. Capture the region, optional player transfer
6. Back to the map (`map`) and track stats (`stats`)

## Core Rules

- Only valid neighbor pairings are allowed.
- The winner captures one bordering region of the loser.
- Optional transfer: the winner can take over one player from the loser.
- End: champion when all regions belong to a single team.

## Campaign Setup Filters

- When creating a new campaign, league, country, and rating range can be filtered before teams are selected.
- League/country filters are only available in club mode (nations have no meaningful league/country groups in the seed data).
- The rating range works in both modes (club and nation).
- "New campaign" is disabled when the filtered team pool has fewer than 2 teams.
- Pure filter logic: [../lib/utils/team_filter.dart](../lib/utils/team_filter.dart)
- Covered leagues/countries (as of the last expansion): Premier League, Bundesliga, LaLiga, Serie A, Ligue 1, Eredivisie, Primeira Liga, Super Lig, Serie A Brazil, Primera Division, Austrian Bundesliga, Belgian Pro League, Swiss Super League, Scottish Premiership, Saudi Pro League, MLS.
- Additional toggle "FC 26 licensed teams only" (`Team.licensedInFc26`, default `true`): hides teams that are not available under their real name/crest in official EA Sports FC 26 (currently known: Paris Saint-Germain, since Konami has held the exclusive PSG rights since 2023).
- IMPORTANT: this list is manually maintained based on publicly known licensing information and is not automatically synced with current FC 26 patches (no official, programmatically accessible source exists for that). When licensing changes, `licensedInFc26` must be updated manually in [../assets/data/teams_seed.json](../assets/data/teams_seed.json).

## Custom Wheel Tool

- Standalone tool (reachable via the "Custom Wheel Tool" button on the home screen), independent of the running Conquest flow.
- Users can create freely named wheels with custom text entries, spin them, and delete them again (e.g. challenges, formations, rule modifiers).
- Presets are stored locally via SharedPreferences, separate from the campaign state.
- Implementation: [../lib/screens/custom_wheel_screen.dart](../lib/screens/custom_wheel_screen.dart), [../lib/widgets/generic_wheel_dialog.dart](../lib/widgets/generic_wheel_dialog.dart), [../lib/models/wheel_preset.dart](../lib/models/wheel_preset.dart)

## Key Structures

- `CampaignState`
  - turn, matchesPlayed
  - regions, players, history
- `Region`
  - id, label, ownerId, neighbors
- `MatchRecord`
  - teamA, teamB, winner, capturedRegionId, transferredPlayerId, score

## Relevant Implementation

- Rules: [../lib/services/conquest_service.dart](../lib/services/conquest_service.dart)
- Orchestration: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)
- Map view: [../lib/widgets/world_map_board.dart](../lib/widgets/world_map_board.dart)
- Wheel: [../lib/widgets/team_wheel_dialog.dart](../lib/widgets/team_wheel_dialog.dart)