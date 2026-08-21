import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/team.dart';
import '../models/team_stats.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.teams,
    required this.stats,
    required this.strings,
    required this.onBack,
  });

  final List<Team> teams;
  final Map<int, TeamStats> stats;
  final AppStrings strings;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ordered = stats.values.toList()
      ..sort((left, right) {
        final regionCompare =
            right.currentRegions.compareTo(left.currentRegions);
        if (regionCompare != 0) {
          return regionCompare;
        }
        return right.wins.compareTo(left.wins);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.statsTitle),
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stat = ordered[index];
          final team = _teamById(stat.teamId);

          return Card(
            child: ListTile(
              title: Text(team?.name ?? strings.teamFallback(stat.teamId)),
              subtitle: Text(
                strings.statsSubtitle(
                  wins: stat.wins,
                  losses: stat.losses,
                  regions: stat.currentRegions,
                  squad: stat.squadSize,
                  transfers: stat.transfersIn,
                  winRate: (stat.winRate * 100).toStringAsFixed(0),
                ),
              ),
              trailing: Text(strings.peakLabel(stat.biggestExtent)),
            ),
          );
        },
      ),
    );
  }

  Team? _teamById(int id) {
    for (final team in teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }
}
