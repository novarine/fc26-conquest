class MatchRecord {
  const MatchRecord({
    required this.teamA,
    required this.teamB,
    required this.winner,
    required this.capturedRegionId,
    required this.dateIso,
    this.transferredPlayerId,
    this.score,
  });

  final int teamA;
  final int teamB;
  final int winner;
  final int capturedRegionId;
  final String dateIso;
  final int? transferredPlayerId;
  final String? score;

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      teamA: json['teamA'] as int,
      teamB: json['teamB'] as int,
      winner: json['winner'] as int,
      capturedRegionId: json['capturedRegionId'] as int,
      dateIso: json['dateIso'] as String,
      transferredPlayerId: json['transferredPlayerId'] as int?,
      score: json['score'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamA': teamA,
      'teamB': teamB,
      'winner': winner,
      'capturedRegionId': capturedRegionId,
      'dateIso': dateIso,
      'transferredPlayerId': transferredPlayerId,
      'score': score,
    };
  }
}
