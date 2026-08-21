import 'package:flutter_test/flutter_test.dart';

import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/services/bracket_service.dart';

List<Team> _teams(int count) {
  return List.generate(
    count,
    (i) => Team(
      id: i + 1,
      name: 'Team ${i + 1}',
      type: TeamType.club,
      rating: 70 + i,
      logo: '',
      primaryColor: '#123456',
    ),
  );
}

void main() {
  group('BracketService', () {
    test('power-of-two team count produces no byes', () {
      final service = BracketService();
      final state = service.generate(teams: _teams(4), mode: 'club', id: 'b1');

      expect(state.rounds.length, 2); // round of 4, final
      expect(state.rounds[0].length, 2);
      expect(state.rounds[1].length, 1);
      expect(state.rounds[0].every((m) => !m.isBye), isTrue);
      expect(
          state.rounds[0].every((m) => m.teamAId != null && m.teamBId != null),
          isTrue);
    });

    test('non-power-of-two team count pads with byes that auto-advance', () {
      final service = BracketService();
      final state = service.generate(teams: _teams(5), mode: 'club', id: 'b2');

      // 5 teams -> bracket of 8 -> 4 round-0 matches, 3 byes.
      expect(state.rounds[0].length, 4);
      final byeMatches = state.rounds[0].where((m) => m.isBye).toList();
      expect(byeMatches.length, 3);
      for (final match in byeMatches) {
        expect(match.winnerId, match.teamAId);
        expect(match.teamBId, isNull);
      }
      // No bye-vs-bye matches: every match has at least one real team.
      expect(state.rounds[0].every((m) => m.teamAId != null), isTrue);

      // Byes must already be propagated into round 1.
      final filledSlots = state.rounds[1]
          .expand((m) => [m.teamAId, m.teamBId])
          .where((id) => id != null)
          .length;
      expect(filledSlots, 3);
    });

    test('applyResult advances winner into next round slot', () {
      final service = BracketService();
      var state = service.generate(teams: _teams(4), mode: 'club', id: 'b3');
      final firstMatch = state.rounds[0][0];

      state = service.applyResult(
        state,
        round: 0,
        matchIndex: 0,
        winnerId: firstMatch.teamAId!,
        score: '2:1',
      );

      expect(state.rounds[0][0].winnerId, firstMatch.teamAId);
      expect(state.rounds[0][0].score, '2:1');
      expect(state.rounds[1][0].teamAId, firstMatch.teamAId);
      expect(state.championId, isNull);
    });

    test('rejects a winner that is not part of the match', () {
      final service = BracketService();
      final state = service.generate(teams: _teams(2), mode: 'club', id: 'b4');

      expect(
        () =>
            service.applyResult(state, round: 0, matchIndex: 0, winnerId: 9999),
        throwsArgumentError,
      );
    });

    test('final round winner is recorded as champion', () {
      final service = BracketService();
      var state = service.generate(teams: _teams(2), mode: 'club', id: 'b5');
      final match = state.rounds[0][0];

      state = service.applyResult(
        state,
        round: 0,
        matchIndex: 0,
        winnerId: match.teamAId!,
      );

      expect(state.rounds.length, 1);
      expect(state.championId, match.teamAId);
    });

    test('full 5-team bracket eventually crowns a champion', () {
      final service = BracketService();
      var state = service.generate(teams: _teams(5), mode: 'club', id: 'b6');

      while (state.championId == null) {
        var advanced = false;
        for (var r = 0; r < state.rounds.length; r++) {
          for (final match in state.rounds[r]) {
            if (match.isReady) {
              state = service.applyResult(
                state,
                round: r,
                matchIndex: match.matchIndex,
                winnerId: match.teamAId!,
              );
              advanced = true;
            }
          }
        }
        expect(advanced, isTrue, reason: 'must always make progress');
      }

      expect(state.championId, isNotNull);
    });

    test('throws when fewer than 2 teams are given', () {
      final service = BracketService();
      expect(
        () => service.generate(teams: _teams(1), mode: 'club', id: 'b7'),
        throwsArgumentError,
      );
    });
  });
}
