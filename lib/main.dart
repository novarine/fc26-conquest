import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/campaign_controller.dart';
import 'models/campaign_setup.dart';
import 'models/team.dart';
import 'screens/battle_screen.dart';
import 'screens/custom_wheel_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'services/app_logger.dart';
import 'services/conquest_service.dart';
import 'services/seed_data_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'widgets/update_banner.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        AppLogger.instance.error(
          'FlutterError',
          'Unhandled Flutter framework exception',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.instance.error(
          'PlatformDispatcher',
          'Unhandled root isolate exception',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      AppLogger.instance.info('Bootstrap', 'Starting FC 26 Conquest app');
      runApp(const Fc26ConquestApp());
    },
    (error, stack) {
      AppLogger.instance.error(
        'Zone',
        'Unhandled zoned exception',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

class Fc26ConquestApp extends StatefulWidget {
  const Fc26ConquestApp({super.key});

  @override
  State<Fc26ConquestApp> createState() => _Fc26ConquestAppState();
}

class _Fc26ConquestAppState extends State<Fc26ConquestApp> {
  late final CampaignController _controller;
  late final UpdateService _updateService;
  UpdateCheckResult? _updateCheckResult;
  bool _updateBannerDismissed = false;
  bool _showCustomWheel = false;

  @override
  void initState() {
    super.initState();
    _updateService = UpdateService();
    _controller = CampaignController(
      seedDataService: const SeedDataService(),
      storageService: StorageService(),
      conquestService: ConquestService(),
    )..initialize();
    unawaited(_checkForUpdates());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    final result = await _updateService.checkForUpdates();
    if (!mounted) {
      return;
    }
    setState(() {
      _updateCheckResult = result;
    });
  }

  Future<void> _openUpdateLink() async {
    final targetUrl = _updateCheckResult?.downloadUrl ?? UpdateService.downloadUrl;
    final url = Uri.parse(targetUrl);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      unawaited(
        AppLogger.instance.warning(
          'Update',
          'Unable to open update URL: $targetUrl',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC 26 Conquest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          primary: const Color(0xFF0EA5E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
        ),
        chipTheme: const ChipThemeData(
          side: BorderSide.none,
          shape: StadiumBorder(),
        ),
      ),
      home: _showCustomWheel
          ? CustomWheelScreen(
              onBack: () => setState(() => _showCustomWheel = false),
            )
          : AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final error = _controller.error;
          return Stack(
            children: [
              if (_updateCheckResult != null &&
                  _updateCheckResult!.hasUpdate &&
                  !_updateBannerDismissed)
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: UpdateBanner(
                        latestVersion: _updateCheckResult!.latestVersion,
                        releaseNotes: _updateCheckResult!.releaseNotes,
                        onUpdate: _openUpdateLink,
                        onDismiss: () {
                          setState(() {
                            _updateBannerDismissed = true;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              _buildPage(),
              if (error != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPage() {
    switch (_controller.page) {
      case AppPage.home:
        final clubCount = _controller.teamsForMode(TeamType.club).length;
        final nationCount = _controller.teamsForMode(TeamType.nation).length;
        return HomeScreen(
          hasCampaign: _controller.hasCampaign,
          availableClubTeams: clubCount,
          availableNationTeams: nationCount,
          onNewCampaign: (CampaignSetup setup) => _controller.startNewCampaign(
            setup: setup,
          ),
          onContinue: _controller.continueCampaign,
          onOpenCustomWheel: () => setState(() => _showCustomWheel = true),
        );
      case AppPage.map:
        final campaign = _controller.campaign!;
        return MapScreen(
          campaign: campaign,
          teams: _controller.teams,
          remainingTeams: _controller.remainingTeams(),
          champion: _controller.champion(),
          playerById: _controller.playerById,
          attackableTeams: _controller.attackableTeams,
          defenderCandidates: _controller.defenderCandidates,
          onSetBattlePairing: (attackerId, defenderId) => _controller.setManualBattlePairing(
            attackerId: attackerId,
            defenderId: defenderId,
          ),
          onOpenStats: _controller.openStats,
          onResetCampaign: _controller.resetCampaign,
        );
      case AppPage.battle:
        final battle = _controller.pendingBattle!;
        final campaign = _controller.campaign!;
        final counts = ConquestService().regionCounts(campaign);
        final attacker = _controller.teamById(battle.attackerId)!;
        final defender = _controller.teamById(battle.defenderId)!;
        return BattleScreen(
          battle: battle,
          attacker: attacker,
          defender: defender,
          attackerSquad: _controller.squadForTeam(attacker.id),
          defenderSquad: _controller.squadForTeam(defender.id),
          attackerRegions: counts[battle.attackerId] ?? 0,
          defenderRegions: counts[battle.defenderId] ?? 0,
          onSubmit: (winnerId, transferredPlayerId, score) => _controller
              .submitBattleResult(
                winnerId: winnerId,
                transferredPlayerId: transferredPlayerId,
                score: score,
              ),
          onCancel: _controller.backToMap,
        );
      case AppPage.stats:
        return StatsScreen(
          teams: _controller.teams,
          stats: _controller.stats,
          onBack: _controller.backToMap,
        );
    }
  }
}
