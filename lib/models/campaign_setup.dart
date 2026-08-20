import 'team.dart';

class CampaignSetup {
  const CampaignSetup({
    required this.mode,
    required this.teamCount,
  });

  final TeamType mode;
  final int teamCount;
}
