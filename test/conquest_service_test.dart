import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:fc26_conquest/models/campaign_state.dart';
import 'package:fc26_conquest/models/player.dart';
import 'package:fc26_conquest/models/region.dart';
import 'package:fc26_conquest/services/conquest_service.dart';

void main() {
  group('ConquestService', () {
    final service = ConquestService(random: Random(1));

    CampaignState buildState() {
      return CampaignState(
        id: 'test',
        mode: 'club',
        turn: 1,
        matchesPlayed: 0,
        regions: const [
          Region(id: 1, label: 'A', ownerId: 1, neighbors: [2, 3]),
          Region(id: 2, label: 'B', ownerId: 2, neighbors: [1, 4]),
          Region(id: 3, label: 'C', ownerId: 1, neighbors: [1, 4]),
          Region(id: 4, label: 'D', ownerId: 2, neighbors: [2, 3]),
        ],
        players: const [
          Player(
            id: 11,
            name: 'Alpha Keeper',
            position: 'GK',
            rating: 80,
            originTeamId: 1,
            currentTeamId: 1,
          ),
          Player(
            id: 21,
            name: 'Beta Striker',
            position: 'ST',
            rating: 82,
            originTeamId: 2,
            currentTeamId: 2,
          ),
        ],
        history: const [],
      );
    }

    test('collects valid defender options from frontier regions', () {
      final options = service.defenderOptions(buildState(), 1);
      expect(options, [2]);
    });

    test('winner eliminates losing team', () {
      final result = service.applyBattle(
        state: buildState(),
        attackerId: 1,
        defenderId: 2,
        winnerId: 1,
        score: '2:0',
      );

      final ownedByWinner = result.state.regions
          .where((region) => region.ownerId == 1)
          .length;

      expect(ownedByWinner, 4);
      expect(result.state.matchesPlayed, 1);
      expect(result.state.history.single.winner, 1);
    });

    test('winner can transfer one player from the losing team', () {
      final result = service.applyBattle(
        state: buildState(),
        attackerId: 1,
        defenderId: 2,
        winnerId: 1,
        transferredPlayerId: 21,
      );

      final transferred = result.state.players
          .firstWhere((player) => player.id == 21);

      expect(transferred.currentTeamId, 1);
      expect(result.state.history.single.transferredPlayerId, 21);
      expect(result.transferredPlayer?.name, 'Beta Striker');
    });
  });
}
