import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/campaign_setup.dart';
import '../models/campaign_state.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/team_stats.dart';
import '../services/app_logger.dart';
import '../services/conquest_service.dart';
import '../services/seed_data_service.dart';
import '../services/storage_service.dart';

enum AppPage { home, map, battle, stats }

class CampaignController extends ChangeNotifier {
  CampaignController({
    required SeedDataService seedDataService,
    required StorageService storageService,
    required ConquestService conquestService,
  })  : _seedDataService = seedDataService,
        _storageService = storageService,
        _conquestService = conquestService;

  final SeedDataService _seedDataService;
  final StorageService _storageService;
  final ConquestService _conquestService;

  AppPage _page = AppPage.home;
  bool _isLoading = true;
  String? _error;
  List<Team> _teams = const [];
  CampaignState? _campaign;
  BattlePairing? _pendingBattle;

  AppPage get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Team> get teams => _teams;
  CampaignState? get campaign => _campaign;
  BattlePairing? get pendingBattle => _pendingBattle;
  bool get hasCampaign => _campaign != null;

  Map<int, TeamStats> get stats {
    final current = _campaign;
    if (current == null) {
      return const {};
    }
    return _conquestService.buildStats(current);
  }

  Future<void> initialize() async {
    await AppLogger.instance.info('CampaignController', 'initialize() started');
    _setLoading(true);
    try {
      await _seedDataService.clearTeamCache();
      _teams = await _seedDataService.loadTeams();
      _campaign = await _storageService.loadCampaign();
      if (_campaign != null) {
        final teamIds = _campaign!.regions.map((region) => region.ownerId).toSet();
        final teamNameById = {
          for (final team in _teams) team.id: team.name,
        };
        final migrated = _conquestService.topUpMissingSquads(
          state: _campaign!,
          teamIds: teamIds,
          teamNamesById: teamNameById,
        );
        if (migrated.players.length != _campaign!.players.length) {
          _campaign = migrated;
          await _storageService.saveCampaign(_campaign!);
        }
      }
      _page = AppPage.home;
      _error = null;
      await AppLogger.instance.info(
        'CampaignController',
        'initialize() finished: teams=${_teams.length}, hasCampaign=${_campaign != null}',
      );
    } catch (exception) {
      _error = 'Initialisierung fehlgeschlagen: $exception';
      await AppLogger.instance.error(
        'CampaignController',
        'initialize() failed',
        error: exception,
      );
    }
    _setLoading(false);
  }

  List<Team> teamsForMode(TeamType mode) {
    return _teams.where((team) => team.type == mode).toList();
  }

  Future<void> startNewCampaign({
    required CampaignSetup setup,
  }) async {
    await AppLogger.instance.info(
      'CampaignController',
      'startNewCampaign(mode=${setup.mode.name}, teamCount=${setup.teamCount})',
    );
    _setLoading(true);
    try {
      final availableTeams = teamsForMode(setup.mode);
      if (availableTeams.length < 2) {
        throw StateError('Nicht genug Teams fuer den gewaehlten Modus vorhanden.');
      }

      final selectedTeams = availableTeams.take(setup.teamCount).toList();
      final teamNameById = {
        for (final team in selectedTeams) team.id: team.name,
      };

      final regions = await _seedDataService.loadRegions();
      final players = await _seedDataService.loadPlayers();

      _campaign = _conquestService.createCampaign(
        mode: setup.mode.name,
        seedRegions: regions,
        seedPlayers: players,
        selectedTeamIds: selectedTeams.map((team) => team.id).toList(),
        teamNamesById: teamNameById,
      );
      _pendingBattle = null;
      await _storageService.saveCampaign(_campaign!);
      _page = AppPage.map;
      _error = null;
      await AppLogger.instance.info('CampaignController', 'startNewCampaign() success');
    } catch (exception) {
      _error = 'Neue Kampagne konnte nicht erstellt werden: $exception';
      await AppLogger.instance.error(
        'CampaignController',
        'startNewCampaign() failed',
        error: exception,
      );
    }
    _setLoading(false);
  }

  void continueCampaign() {
    if (_campaign == null) {
      _error = 'Es ist keine gespeicherte Kampagne vorhanden.';
      unawaited(
        AppLogger.instance.warning('CampaignController', 'continueCampaign() without campaign'),
      );
      notifyListeners();
      return;
    }
    _page = AppPage.map;
    _error = null;
    unawaited(AppLogger.instance.info('CampaignController', 'continueCampaign() -> map'));
    notifyListeners();
  }

  Future<void> rollBattle() async {
    final current = _campaign;
    if (current == null) {
      return;
    }

    final battle = _conquestService.rollBattle(current);
    if (battle == null) {
      _error = 'Keine gueltige Paarung mehr verfuegbar.';
      unawaited(
        AppLogger.instance.warning('CampaignController', 'rollBattle() produced no battle'),
      );
      notifyListeners();
      return;
    }

    _pendingBattle = battle;
    _page = AppPage.battle;
    _error = null;
    unawaited(
      AppLogger.instance.info(
        'CampaignController',
        'rollBattle() attacker=${battle.attackerId} defender=${battle.defenderId}',
      ),
    );
    notifyListeners();
  }

  List<Team> attackableTeams() {
    final current = _campaign;
    if (current == null) {
      return const [];
    }

    final ids = _conquestService.attackableTeamIds(current);
    return _teams.where((team) => ids.contains(team.id)).toList();
  }

  List<Team> defenderCandidates(int attackerId) {
    final current = _campaign;
    if (current == null) {
      return const [];
    }

    final ids = _conquestService.defenderOptions(current, attackerId);
    return _teams.where((team) => ids.contains(team.id)).toList();
  }

  Future<void> setManualBattlePairing({
    required int attackerId,
    required int defenderId,
  }) async {
    final current = _campaign;
    if (current == null) {
      return;
    }

    try {
      final battle = _conquestService.createManualPairing(
        state: current,
        attackerId: attackerId,
        defenderId: defenderId,
      );
      _pendingBattle = battle;
      _page = AppPage.battle;
      _error = null;
      await AppLogger.instance.info(
        'CampaignController',
        'setManualBattlePairing() attacker=$attackerId defender=$defenderId',
      );
      notifyListeners();
    } catch (exception) {
      _error = 'Paarung konnte nicht erstellt werden: $exception';
      await AppLogger.instance.error(
        'CampaignController',
        'setManualBattlePairing() failed',
        error: exception,
      );
      notifyListeners();
    }
  }

  Future<void> submitBattleResult({
    required int winnerId,
    int? transferredPlayerId,
    String? score,
  }) async {
    final current = _campaign;
    final battle = _pendingBattle;
    if (current == null || battle == null) {
      return;
    }

    try {
      final result = _conquestService.applyBattle(
        state: current,
        attackerId: battle.attackerId,
        defenderId: battle.defenderId,
        winnerId: winnerId,
        transferredPlayerId: transferredPlayerId,
        score: score,
      );
      _campaign = result.state;
      _pendingBattle = null;
      await _storageService.saveCampaign(_campaign!);
      _page = AppPage.map;
      _error = null;
      await AppLogger.instance.info(
        'CampaignController',
        'submitBattleResult() winner=$winnerId transfer=$transferredPlayerId score=${score ?? '-'}',
      );
      notifyListeners();
    } catch (exception) {
      _error = 'Ergebnis konnte nicht verarbeitet werden: $exception';
      await AppLogger.instance.error(
        'CampaignController',
        'submitBattleResult() failed',
        error: exception,
      );
      notifyListeners();
    }
  }

  Future<void> resetCampaign() async {
    await AppLogger.instance.info('CampaignController', 'resetCampaign()');
    _setLoading(true);
    await _storageService.clearCampaign();
    _campaign = null;
    _pendingBattle = null;
    _page = AppPage.home;
    _error = null;
    _setLoading(false);
  }

  void openStats() {
    _page = AppPage.stats;
    unawaited(AppLogger.instance.debug('CampaignController', 'openStats()'));
    notifyListeners();
  }

  void backToMap() {
    _page = hasCampaign ? AppPage.map : AppPage.home;
    unawaited(AppLogger.instance.debug('CampaignController', 'backToMap() -> $_page'));
    notifyListeners();
  }

  Team? teamById(int id) {
    for (final team in _teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  Player? playerById(int id) {
    final current = _campaign;
    if (current == null) {
      return null;
    }

    for (final player in current.players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }

  List<Player> squadForTeam(int teamId) {
    final current = _campaign;
    if (current == null) {
      return const [];
    }
    return _conquestService.playersForTeam(current, teamId);
  }

  int remainingTeams() {
    final current = _campaign;
    if (current == null) {
      return 0;
    }
    return _conquestService.remainingTeams(current);
  }

  Team? champion() {
    final current = _campaign;
    if (current == null) {
      return null;
    }
    final id = _conquestService.championId(current);
    if (id == null) {
      return null;
    }
    return teamById(id);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
