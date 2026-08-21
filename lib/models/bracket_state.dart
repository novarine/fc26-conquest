/// A single match slot in a single-elimination bracket. `teamAId`/`teamBId`
/// are null until the previous round's winner is known (or, for round 0,
/// until the initial random draw fills them). `isBye` marks a round-0 match
/// where `teamAId` had no opponent and was auto-advanced.
class BracketMatch {
  const BracketMatch({
    required this.round,
    required this.matchIndex,
    this.teamAId,
    this.teamBId,
    this.winnerId,
    this.score,
    this.isBye = false,
  });

  final int round;
  final int matchIndex;
  final int? teamAId;
  final int? teamBId;
  final int? winnerId;
  final String? score;
  final bool isBye;

  bool get isReady => teamAId != null && teamBId != null && winnerId == null;

  BracketMatch copyWith({
    int? teamAId,
    int? teamBId,
    int? winnerId,
    String? score,
    bool? isBye,
  }) {
    return BracketMatch(
      round: round,
      matchIndex: matchIndex,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      winnerId: winnerId ?? this.winnerId,
      score: score ?? this.score,
      isBye: isBye ?? this.isBye,
    );
  }

  factory BracketMatch.fromJson(Map<String, dynamic> json) {
    return BracketMatch(
      round: json['round'] as int,
      matchIndex: json['matchIndex'] as int,
      teamAId: json['teamAId'] as int?,
      teamBId: json['teamBId'] as int?,
      winnerId: json['winnerId'] as int?,
      score: json['score'] as String?,
      isBye: json['isBye'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'matchIndex': matchIndex,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'winnerId': winnerId,
      'score': score,
      'isBye': isBye,
    };
  }
}

/// Single-elimination knockout tournament ("World Cup" style), independent
/// from the region-conquest campaign flow.
class BracketState {
  const BracketState({
    required this.id,
    required this.mode,
    required this.seededTeamIds,
    required this.rounds,
    this.championId,
  });

  final String id;
  final String mode;
  final List<int> seededTeamIds;
  final List<List<BracketMatch>> rounds;
  final int? championId;

  BracketState copyWith({
    List<List<BracketMatch>>? rounds,
    int? championId,
  }) {
    return BracketState(
      id: id,
      mode: mode,
      seededTeamIds: seededTeamIds,
      rounds: rounds ?? this.rounds,
      championId: championId ?? this.championId,
    );
  }

  factory BracketState.fromJson(Map<String, dynamic> json) {
    return BracketState(
      id: json['id'] as String,
      mode: json['mode'] as String,
      seededTeamIds: (json['seededTeamIds'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      rounds: (json['rounds'] as List<dynamic>)
          .map((round) => (round as List<dynamic>)
              .map((match) =>
                  BracketMatch.fromJson(match as Map<String, dynamic>))
              .toList())
          .toList(),
      championId: json['championId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'seededTeamIds': seededTeamIds,
      'rounds': rounds
          .map((round) => round.map((match) => match.toJson()).toList())
          .toList(),
      'championId': championId,
    };
  }
}
