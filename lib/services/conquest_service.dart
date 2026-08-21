import 'dart:math';

import '../models/campaign_state.dart';
import '../models/match_record.dart';
import '../models/player.dart';
import '../models/region.dart';
import '../models/team_stats.dart';

class BattlePairing {
  const BattlePairing({
    required this.attackerId,
    required this.defenderId,
  });

  final int attackerId;
  final int defenderId;
}

class ConquestResult {
  const ConquestResult({
    required this.state,
    required this.capturedRegion,
    this.transferredPlayer,
  });

  final CampaignState state;
  final Region capturedRegion;
  final Player? transferredPlayer;
}

class ConquestService {
  ConquestService({Random? random}) : _random = random ?? Random();

  final Random _random;

  CampaignState createCampaign({
    required String mode,
    required List<Region> seedRegions,
    required List<Player> seedPlayers,
    required List<int> selectedTeamIds,
    Map<int, String> teamNamesById = const {},
  }) {
    final randomizedTeamIds = [...selectedTeamIds]..shuffle(_random);
    final regionCount = min(seedRegions.length, randomizedTeamIds.length);
    final selectedRegions = seedRegions.take(regionCount).toList();
    final recalculatedNeighbors = _buildNeighbors(regionCount);
    final reassignedRegions = <Region>[];

    for (var index = 0; index < selectedRegions.length; index++) {
      final ownerId = randomizedTeamIds[index];
      reassignedRegions.add(
        selectedRegions[index].copyWith(
          ownerId: ownerId,
          neighbors: recalculatedNeighbors[index + 1] ?? const [],
        ),
      );
    }

    final normalizedPlayers = seedPlayers
        .where((player) => selectedTeamIds.contains(player.originTeamId))
        .map((player) => player.copyWith(currentTeamId: player.originTeamId))
        .toList();

    final playersByTeam = <int, int>{};
    for (final player in normalizedPlayers) {
      playersByTeam.update(player.originTeamId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    final missingTeamIds = selectedTeamIds
        .where((teamId) => (playersByTeam[teamId] ?? 0) == 0)
        .toList();

    var nextGeneratedId = normalizedPlayers.isEmpty
        ? 900000
        : normalizedPlayers.map((player) => player.id).reduce(max) + 1;

    for (final teamId in missingTeamIds) {
      final fallback = _buildFallbackSquad(
        teamId: teamId,
        teamName: teamNamesById[teamId],
        startingId: nextGeneratedId,
      );
      normalizedPlayers.addAll(fallback);
      nextGeneratedId += fallback.length;
    }

    return CampaignState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: mode,
      turn: 1,
      matchesPlayed: 0,
      regions: reassignedRegions,
      players: normalizedPlayers,
      history: const [],
    );
  }

  CampaignState topUpMissingSquads({
    required CampaignState state,
    required Iterable<int> teamIds,
    Map<int, String> teamNamesById = const {},
  }) {
    final players = state.players.map((player) {
      final teamName = teamNamesById[player.currentTeamId];
      if (teamName == null || teamName.isEmpty) {
        return player;
      }

      final normalizedName = player.name.trim();
      final profile = _fallbackProfiles[teamName.toLowerCase()];
      final match = RegExp(r'^Team\s+\d+\s+(.+)$', caseSensitive: false)
          .firstMatch(normalizedName);
      if (match != null) {
        final role = match.group(1) ?? normalizedName;
        return player.copyWith(
            name: _profileNameOrFallback(teamName, role, profile));
      }

      final directRole = _extractGeneratedRole(normalizedName, teamName);
      if (directRole == null) {
        return player;
      }

      return player.copyWith(
        name: _profileNameOrFallback(teamName, directRole, profile),
      );
    }).toList();
    final playersByTeam = <int, int>{};
    for (final player in players) {
      playersByTeam.update(player.currentTeamId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    var nextGeneratedId = players.isEmpty
        ? 900000
        : players.map((player) => player.id).reduce(max) + 1;

    var changed = false;
    for (final teamId in teamIds) {
      if ((playersByTeam[teamId] ?? 0) > 0) {
        continue;
      }

      final fallback = _buildFallbackSquad(
        teamId: teamId,
        teamName: teamNamesById[teamId],
        startingId: nextGeneratedId,
      );
      players.addAll(fallback);
      nextGeneratedId += fallback.length;
      changed = true;
    }

    if (!changed && _sameNames(players, state.players)) {
      return state;
    }

    return state.copyWith(players: players);
  }

  bool _sameNames(List<Player> left, List<Player> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      if (left[i].name != right[i].name) {
        return false;
      }
    }
    return true;
  }

  List<int> attackableTeamIds(CampaignState state) {
    return _attackableTeamIds(state);
  }

  BattlePairing createManualPairing({
    required CampaignState state,
    required int attackerId,
    required int defenderId,
  }) {
    final attackers = _attackableTeamIds(state);
    if (!attackers.contains(attackerId)) {
      throw StateError('Selected attacker has no valid frontier battle.');
    }

    final defenders = defenderOptions(state, attackerId);
    if (!defenders.contains(defenderId)) {
      throw StateError(
          'Selected defender is not a valid neighboring opponent.');
    }

    return BattlePairing(attackerId: attackerId, defenderId: defenderId);
  }

  List<Player> playersForTeam(CampaignState state, int teamId) {
    final players =
        state.players.where((player) => player.currentTeamId == teamId).toList()
          ..sort((left, right) {
            final ratingCompare = right.rating.compareTo(left.rating);
            if (ratingCompare != 0) {
              return ratingCompare;
            }
            return left.name.compareTo(right.name);
          });
    return players;
  }

  BattlePairing? rollBattle(CampaignState state) {
    final attackers = _attackableTeamIds(state);
    if (attackers.isEmpty) {
      return null;
    }

    final attackerId = attackers[_random.nextInt(attackers.length)];
    final defenders = defenderOptions(state, attackerId);
    if (defenders.isEmpty) {
      return null;
    }

    final defenderId = defenders[_random.nextInt(defenders.length)];
    return BattlePairing(attackerId: attackerId, defenderId: defenderId);
  }

  List<int> defenderOptions(CampaignState state, int attackerId) {
    final regionById = {for (final region in state.regions) region.id: region};
    final defenders = <int>{};

    for (final region
        in state.regions.where((entry) => entry.ownerId == attackerId)) {
      for (final neighborId in region.neighbors) {
        final neighbor = regionById[neighborId];
        if (neighbor == null || neighbor.ownerId == attackerId) {
          continue;
        }
        defenders.add(neighbor.ownerId);
      }
    }

    return defenders.toList()..sort();
  }

  ConquestResult applyBattle({
    required CampaignState state,
    required int attackerId,
    required int defenderId,
    required int winnerId,
    int? transferredPlayerId,
    String? score,
  }) {
    final loserId = winnerId == attackerId ? defenderId : attackerId;
    final targetRegion = _pickFrontierRegion(
      state: state,
      winnerId: winnerId,
      loserId: loserId,
    );

    if (targetRegion == null) {
      throw StateError('No capturable frontier region found for this battle.');
    }

    Player? transferredPlayer;
    if (transferredPlayerId != null) {
      Player? candidate;
      for (final player in state.players) {
        if (player.id == transferredPlayerId) {
          candidate = player;
          break;
        }
      }
      if (candidate == null) {
        throw StateError('Selected transfer player does not exist.');
      }
      if (candidate.currentTeamId != loserId) {
        throw StateError(
            'Selected transfer player no longer belongs to the losing team.');
      }
      transferredPlayer = candidate.copyWith(currentTeamId: winnerId);
    }

    final updatedRegions = state.regions.map(
      (region) {
        final shouldTransfer = region.ownerId == loserId;
        return shouldTransfer ? region.copyWith(ownerId: winnerId) : region;
      },
    ).toList();

    final updatedPlayers = state.players
        .map((player) => player.id == transferredPlayerId
            ? player.copyWith(currentTeamId: winnerId)
            : player)
        .toList();

    final match = MatchRecord(
      teamA: attackerId,
      teamB: defenderId,
      winner: winnerId,
      capturedRegionId: targetRegion.id,
      dateIso: DateTime.now().toIso8601String(),
      transferredPlayerId: transferredPlayerId,
      score: score,
    );

    final updatedState = state.copyWith(
      turn: state.turn + 1,
      matchesPlayed: state.matchesPlayed + 1,
      regions: updatedRegions,
      players: updatedPlayers,
      history: [...state.history, match],
    );

    return ConquestResult(
      state: updatedState,
      capturedRegion: targetRegion.copyWith(ownerId: winnerId),
      transferredPlayer: transferredPlayer,
    );
  }

  int remainingTeams(CampaignState state) {
    return state.regions.map((region) => region.ownerId).toSet().length;
  }

  int? championId(CampaignState state) {
    final owners = state.regions.map((region) => region.ownerId).toSet();
    if (owners.length != 1) {
      return null;
    }
    return owners.first;
  }

  Map<int, int> regionCounts(CampaignState state) {
    final counts = <int, int>{};
    for (final region in state.regions) {
      counts.update(region.ownerId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Map<int, TeamStats> buildStats(CampaignState state) {
    final currentCounts = regionCounts(state);
    final squadCounts = <int, int>{};
    final wins = <int, int>{};
    final losses = <int, int>{};
    final transfersIn = <int, int>{};
    final biggestExtent = <int, int>{
      for (final entry in currentCounts.entries) entry.key: entry.value,
    };

    for (final player in state.players) {
      squadCounts.update(player.currentTeamId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    for (final match in state.history) {
      wins.update(match.winner, (value) => value + 1, ifAbsent: () => 1);
      final loser = match.winner == match.teamA ? match.teamB : match.teamA;
      losses.update(loser, (value) => value + 1, ifAbsent: () => 1);
      if (match.transferredPlayerId != null) {
        transfersIn.update(match.winner, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    final teamIds = {
      ...currentCounts.keys,
      ...squadCounts.keys,
      ...wins.keys,
      ...losses.keys,
      ...transfersIn.keys,
      ...biggestExtent.keys,
    };

    return {
      for (final teamId in teamIds)
        teamId: TeamStats(
          teamId: teamId,
          wins: wins[teamId] ?? 0,
          losses: losses[teamId] ?? 0,
          currentRegions: currentCounts[teamId] ?? 0,
          biggestExtent: biggestExtent[teamId] ?? (currentCounts[teamId] ?? 0),
          squadSize: squadCounts[teamId] ?? 0,
          transfersIn: transfersIn[teamId] ?? 0,
        ),
    };
  }

  List<int> _attackableTeamIds(CampaignState state) {
    final attackers = <int>{};
    final regionById = {for (final region in state.regions) region.id: region};

    for (final region in state.regions) {
      for (final neighborId in region.neighbors) {
        final neighbor = regionById[neighborId];
        if (neighbor == null || neighbor.ownerId == region.ownerId) {
          continue;
        }
        attackers.add(region.ownerId);
        break;
      }
    }

    return attackers.toList()..sort();
  }

  Region? _pickFrontierRegion({
    required CampaignState state,
    required int winnerId,
    required int loserId,
  }) {
    final regionById = {for (final region in state.regions) region.id: region};
    final frontier = <Region>[];

    for (final region
        in state.regions.where((entry) => entry.ownerId == loserId)) {
      final touchesWinner = region.neighbors.any((neighborId) {
        final neighbor = regionById[neighborId];
        return neighbor != null && neighbor.ownerId == winnerId;
      });

      if (touchesWinner) {
        frontier.add(region);
      }
    }

    if (frontier.isEmpty) {
      return null;
    }

    return frontier[_random.nextInt(frontier.length)];
  }

  List<Player> _buildFallbackSquad({
    required int teamId,
    String? teamName,
    required int startingId,
  }) {
    const positions = ['ST', 'CM', 'CB'];
    const namePrefixes = ['Captain', 'Engine', 'Anchor'];

    final safeTeamName = (teamName == null || teamName.trim().isEmpty)
        ? 'Club'
        : teamName.trim();
    final profile = _fallbackProfiles[safeTeamName.toLowerCase()];

    return List.generate(3, (index) {
      final rating = 74 + _random.nextInt(13);
      final fallbackName = profile == null || profile.length <= index
          ? '$safeTeamName ${namePrefixes[index]}'
          : profile[index];
      return Player(
        id: startingId + index,
        name: fallbackName,
        position: positions[index],
        rating: rating,
        originTeamId: teamId,
        currentTeamId: teamId,
        age: 21 + _random.nextInt(11),
        nation: 'International',
        value: '€${18 + (index * 6)}M',
        wage: '€${45 + (index * 10)}K',
        pace: 68 + _random.nextInt(24),
        shooting: 64 + _random.nextInt(26),
        passing: 64 + _random.nextInt(26),
        dribbling: 64 + _random.nextInt(26),
        defending: 58 + _random.nextInt(28),
        physical: 62 + _random.nextInt(24),
        face:
            'https://api.dicebear.com/9.x/adventurer/png?seed=team-$teamId-$index',
      );
    });
  }

  String _profileNameOrFallback(
    String teamName,
    String role,
    List<String>? profile,
  ) {
    if (profile == null || profile.isEmpty) {
      return '$teamName $role';
    }

    final lowerRole = role.toLowerCase();
    if (lowerRole.contains('captain') && profile.isNotEmpty) {
      return profile[0];
    }
    if (lowerRole.contains('engine') && profile.length >= 2) {
      return profile[1];
    }
    if (lowerRole.contains('anchor') && profile.length >= 3) {
      return profile[2];
    }
    return '$teamName $role';
  }

  String? _extractGeneratedRole(String playerName, String teamName) {
    if (!playerName.toLowerCase().startsWith(teamName.toLowerCase())) {
      return null;
    }

    final suffix = playerName.substring(teamName.length).trimLeft();
    if (suffix == 'Captain' || suffix == 'Engine' || suffix == 'Anchor') {
      return suffix;
    }
    return null;
  }

  Map<int, List<int>> _buildNeighbors(int regionCount) {
    final cols = max(2, sqrt(regionCount).ceil());
    final rows = (regionCount / cols).ceil();
    final result = <int, List<int>>{};

    for (var index = 0; index < regionCount; index++) {
      final id = index + 1;
      final row = index ~/ cols;
      final col = index % cols;
      final neighbors = <int>{};

      for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
        for (var colOffset = -1; colOffset <= 1; colOffset++) {
          if (rowOffset == 0 && colOffset == 0) {
            continue;
          }

          final nextRow = row + rowOffset;
          final nextCol = col + colOffset;
          if (nextRow < 0 ||
              nextCol < 0 ||
              nextRow >= rows ||
              nextCol >= cols) {
            continue;
          }

          final neighborIndex = (nextRow * cols) + nextCol;
          if (neighborIndex < 0 || neighborIndex >= regionCount) {
            continue;
          }
          neighbors.add(neighborIndex + 1);
        }
      }

      result[id] = neighbors.toList()..sort();
    }

    return result;
  }

  static const Map<String, List<String>> _fallbackProfiles = {
    'manchester city': ['Erling Haaland', 'Rodri', 'Phil Foden'],
    'manchester united': ['Bruno Fernandes', 'Rasmus Hojlund', 'Kobbie Mainoo'],
    'barcelona': ['Lamine Yamal', 'Pedri', 'Robert Lewandowski'],
    'atletico madrid': ['Julian Alvarez', 'Antoine Griezmann', 'Jan Oblak'],
    'juventus': ['Dusan Vlahovic', 'Kenan Yildiz', 'Bremer'],
    'ac milan': ['Rafael Leao', 'Christian Pulisic', 'Mike Maignan'],
    'napoli': ['Romelu Lukaku', 'Stanislav Lobotka', 'Giovanni Di Lorenzo'],
    'paris saint-germain': ['Ousmane Dembele', 'Desire Doue', 'Marquinhos'],
    'marseille': ['Adrien Rabiot', 'Mason Greenwood', 'Pierre-Emile Hojbjerg'],
    'rb leipzig': ['Xavi Simons', 'Benjamin Sesko', 'Lois Openda'],
    'bayer leverkusen': ['Florian Wirtz', 'Granit Xhaka', 'Patrik Schick'],
    'benfica': ['Vangelis Pavlidis', 'Orkun Kokcu', 'Nicolas Otamendi'],
    'porto': ['Diogo Costa', 'Samu Aghehowa', 'Alan Varela'],
    'sporting cp': ['Viktor Gyokeres', 'Pedro Goncalves', 'Goncalo Inacio'],
    'feyenoord': ['Quinten Timber', 'Igor Paixao', 'David Hancko'],
    'psv': ['Luuk de Jong', 'Noa Lang', 'Joey Veerman'],
    'galatasaray': ['Mauro Icardi', 'Dries Mertens', 'Lucas Torreira'],
    'fenerbahce': ['Edin Dzeko', 'Dusan Tadic', 'Fred'],
    'flamengo': ['Pedro', 'Giorgian de Arrascaeta', 'Gerson'],
    'palmeiras': ['Estevao', 'Raphael Veiga', 'Gustavo Gomez'],
    'boca juniors': ['Edinson Cavani', 'Miguel Merentiel', 'Marcos Rojo'],
    'senegal': ['Sadio Mane', 'Kalidou Koulibaly', 'Ismaila Sarr'],
    'italy': ['Gianluigi Donnarumma', 'Nicolo Barella', 'Alessandro Bastoni'],
    'belgium': ['Kevin De Bruyne', 'Romelu Lukaku', 'Jeremy Doku'],
    'croatia': ['Luka Modric', 'Josko Gvardiol', 'Mateo Kovacic'],
    'uruguay': ['Darwin Nunez', 'Federico Valverde', 'Ronald Araujo'],
    'japan': ['Kaoru Mitoma', 'Takefusa Kubo', 'Wataru Endo'],
    'switzerland': ['Granit Xhaka', 'Manuel Akanji', 'Breel Embolo'],
    'chile': ['Alexis Sanchez', 'Erick Pulgar', 'Ben Brereton Diaz'],
    'south korea': ['Son Heung-min', 'Kim Min-jae', 'Lee Kang-in'],
    'morocco': ['Achraf Hakimi', 'Sofyan Amrabat', 'Youssef En-Nesyri'],
    'nigeria': ['Victor Osimhen', 'Ademola Lookman', 'Victor Boniface'],
    'norway': ['Erling Haaland', 'Martin Odegaard', 'Alexander Sorloth'],
    'sweden': ['Alexander Isak', 'Dejan Kulusevski', 'Viktor Gyokeres'],
    'denmark': ['Christian Eriksen', 'Rasmus Hojlund', 'Pierre-Emile Hojbjerg'],
    'austria': ['David Alaba', 'Marcel Sabitzer', 'Christoph Baumgartner'],
    'poland': ['Robert Lewandowski', 'Piotr Zielinski', 'Jakub Kiwior'],
    'czechia': ['Patrik Schick', 'Tomas Soucek', 'Vladimir Coufal'],
    'turkey': ['Hakan Calhanoglu', 'Arda Guler', 'Caglar Soyuncu'],
    'usa': ['Christian Pulisic', 'Weston McKennie', 'Tim Weah'],
    'mexico': ['Santiago Gimenez', 'Edson Alvarez', 'Hirving Lozano'],
    'colombia': ['Luis Diaz', 'James Rodriguez', 'Davinson Sanchez'],
    'canada': ['Alphonso Davies', 'Jonathan David', 'Tajon Buchanan'],
    'river plate': ['Franco Mastantuono', 'Miguel Borja', 'Paulo Diaz'],
  };
}
