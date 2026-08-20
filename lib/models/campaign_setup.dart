import 'team.dart';

class CampaignSetup {
  const CampaignSetup({
    required this.mode,
    required this.teamCount,
    this.league,
    this.country,
    this.minRating,
    this.maxRating,
  });

  final TeamType mode;
  final int teamCount;
  final String? league;
  final String? country;
  final int? minRating;
  final int? maxRating;
}
