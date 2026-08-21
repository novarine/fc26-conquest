import 'dart:math';

import '../models/bracket_state.dart';
import '../models/team.dart';

/// Generates and advances single-elimination "cup" brackets: a random draw
/// (padded with byes so any team count works), then winner-takes-all rounds
/// until a champion remains. Kept independent from ConquestService/
/// CampaignController on purpose (different, simpler tournament format).
class BracketService {
  BracketService({Random? random}) : _random = random ?? Random();

  final Random _random;

  BracketState generate({
    required List<Team> teams,
    required String mode,
    required String id,
  }) {
    if (teams.length < 2) {
      throw ArgumentError('A bracket needs at least 2 teams');
    }

    final shuffled = [...teams]..shuffle(_random);
    final teamCount = shuffled.length;
    final bracketSize = _nextPowerOfTwo(teamCount);
    final round0MatchCount = bracketSize ~/ 2;
    final byeCount = bracketSize - teamCount;

    var teamIndex = 0;
    final round0 = <BracketMatch>[];
    for (var m = 0; m < round0MatchCount; m++) {
      final teamAId = shuffled[teamIndex++].id;
      final isBye = m < byeCount;
      final teamBId = isBye ? null : shuffled[teamIndex++].id;
      round0.add(BracketMatch(
        round: 0,
        matchIndex: m,
        teamAId: teamAId,
        teamBId: teamBId,
        winnerId: isBye ? teamAId : null,
        isBye: isBye,
      ));
    }

    final rounds = <List<BracketMatch>>[round0];
    var roundSize = round0MatchCount;
    var roundIndex = 1;
    while (roundSize > 1) {
      roundSize ~/= 2;
      rounds.add(List.generate(
        roundSize,
        (m) => BracketMatch(round: roundIndex, matchIndex: m),
      ));
      roundIndex++;
    }

    var state = BracketState(
      id: id,
      mode: mode,
      seededTeamIds: shuffled.map((team) => team.id).toList(),
      rounds: rounds,
    );

    // Byes auto-advance immediately so round 1 already shows their winner.
    for (final match in round0) {
      if (match.isBye && match.winnerId != null) {
        state =
            _propagate(state, match.round, match.matchIndex, match.winnerId!);
      }
    }

    return state;
  }

  BracketState applyResult(
    BracketState state, {
    required int round,
    required int matchIndex,
    required int winnerId,
    String? score,
  }) {
    final match = state.rounds[round][matchIndex];
    if (match.teamAId != winnerId && match.teamBId != winnerId) {
      throw ArgumentError('Winner must be one of the two teams in the match');
    }

    final updatedRounds = [
      for (final r in state.rounds) [...r]
    ];
    updatedRounds[round][matchIndex] =
        match.copyWith(winnerId: winnerId, score: score);

    var newState = state.copyWith(rounds: updatedRounds);
    newState = _propagate(newState, round, matchIndex, winnerId);

    final finalRound = newState.rounds.last;
    final championId =
        finalRound.length == 1 ? finalRound.single.winnerId : null;
    return newState.copyWith(championId: championId);
  }

  BracketState _propagate(
    BracketState state,
    int round,
    int matchIndex,
    int winnerId,
  ) {
    if (round + 1 >= state.rounds.length) {
      return state;
    }

    final nextMatchIndex = matchIndex ~/ 2;
    final isTeamASlot = matchIndex.isEven;
    final updatedRounds = [
      for (final r in state.rounds) [...r]
    ];
    final nextMatch = updatedRounds[round + 1][nextMatchIndex];
    updatedRounds[round + 1][nextMatchIndex] = isTeamASlot
        ? nextMatch.copyWith(teamAId: winnerId)
        : nextMatch.copyWith(teamBId: winnerId);

    return state.copyWith(rounds: updatedRounds);
  }

  int _nextPowerOfTwo(int n) {
    var p = 1;
    while (p < n) {
      p *= 2;
    }
    return p;
  }
}
