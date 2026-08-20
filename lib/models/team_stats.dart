class TeamStats {
  const TeamStats({
    required this.teamId,
    required this.wins,
    required this.losses,
    required this.currentRegions,
    required this.biggestExtent,
    required this.squadSize,
    required this.transfersIn,
  });

  final int teamId;
  final int wins;
  final int losses;
  final int currentRegions;
  final int biggestExtent;
  final int squadSize;
  final int transfersIn;

  double get winRate {
    final total = wins + losses;
    if (total == 0) {
      return 0;
    }
    return wins / total;
  }
}
