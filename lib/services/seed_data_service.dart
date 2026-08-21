import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';
import '../models/region.dart';
import '../models/team.dart';

class SeedDataService {
  const SeedDataService();

  static const _teamsCacheKey = 'fc26_catalog_teams';
  static const _teamsCacheVersionKey = 'fc26_catalog_teams_version';
  static const _teamsCacheVersion = 11;
  static const _playersCacheKey = 'fc26_catalog_players';

  Future<void> clearTeamCache() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_teamsCacheKey);
    await preferences.remove(_teamsCacheVersionKey);
  }

  Future<List<Team>> loadTeams() async {
    final preferences = await SharedPreferences.getInstance();
    await clearTeamCache();
    final cached = preferences.getString(_teamsCacheKey);
    final cachedVersion = preferences.getInt(_teamsCacheVersionKey);
    final canUseCache = cached != null && cachedVersion == _teamsCacheVersion;

    final raw = canUseCache
        ? cached
        : await rootBundle.loadString('assets/data/teams_seed.json');

    if (!canUseCache) {
      await preferences.setString(_teamsCacheKey, raw);
      await preferences.setInt(_teamsCacheVersionKey, _teamsCacheVersion);
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final teams = decoded
        .map((entry) => Team.fromJson(entry as Map<String, dynamic>))
        .toList();

    for (final team in teams) {
      if (!Team.isValidLogo(team.logo)) {
        await preferences.remove(_teamsCacheKey);
        await preferences.remove(_teamsCacheVersionKey);
        throw FormatException(
          'Invalid logo URL for team ${team.name}: ${team.logo}',
        );
      }
    }

    return teams;
  }

  Future<List<Region>> loadRegions() async {
    final raw = await rootBundle.loadString('assets/data/regions_seed.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => Region.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<List<Player>> loadPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString(_playersCacheKey);
    final raw =
        cached ?? await rootBundle.loadString('assets/data/players_seed.json');
    if (cached == null) {
      await preferences.setString(_playersCacheKey, raw);
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => Player.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
