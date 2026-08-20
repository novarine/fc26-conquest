import 'package:flutter/material.dart';

import '../models/team.dart';
import '../models/team_stats.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.teams,
    required this.stats,
    required this.onBack,
  });

  final List<Team> teams;
  final Map<int, TeamStats> stats;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ordered = stats.values.toList()
      ..sort((left, right) {
        final regionCompare = right.currentRegions.compareTo(left.currentRegions);
        if (regionCompare != 0) {
          return regionCompare;
        }
        return right.wins.compareTo(left.wins);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
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
              title: Text(team?.name ?? 'Team ${stat.teamId}'),
              subtitle: Text(
                'Siege ${stat.wins} | Niederlagen ${stat.losses} | Regionen ${stat.currentRegions} | Kader ${stat.squadSize} | Transfers ${stat.transfersIn} | Winrate ${(stat.winRate * 100).toStringAsFixed(0)}%',
              ),
              trailing: Text('Peak ${stat.biggestExtent}'),
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
