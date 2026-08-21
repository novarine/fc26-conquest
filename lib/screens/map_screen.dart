import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/campaign_state.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../widgets/team_badge.dart';
import '../widgets/team_wheel_dialog.dart';
import '../widgets/world_map_board.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.campaign,
    required this.teams,
    required this.remainingTeams,
    required this.champion,
    required this.playerById,
    required this.attackableTeams,
    required this.defenderCandidates,
    required this.strings,
    required this.onSetBattlePairing,
    required this.onOpenStats,
    required this.onResetCampaign,
  });

  final CampaignState campaign;
  final List<Team> teams;
  final int remainingTeams;
  final Team? champion;
  final Player? Function(int id) playerById;
  final List<Team> Function() attackableTeams;
  final List<Team> Function(int attackerId) defenderCandidates;
  final AppStrings strings;
  final Future<void> Function(int attackerId, int defenderId)
      onSetBattlePairing;
  final VoidCallback onOpenStats;
  final Future<void> Function() onResetCampaign;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _wheelBusy = false;
  int? _shownChampionId;
  bool _showingChampionOverlay = false;

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final champion = widget.champion;
    if (champion != null &&
        champion.id != _shownChampionId &&
        !_showingChampionOverlay) {
      _showingChampionOverlay = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await _showChampionOverlay(champion);
        if (!mounted) {
          return;
        }
        setState(() {
          _shownChampionId = champion.id;
          _showingChampionOverlay = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTeamIds =
        widget.campaign.regions.map((region) => region.ownerId).toSet();
    final activeTeams =
        widget.teams.where((team) => activeTeamIds.contains(team.id)).toList();
    final lastMatch =
        widget.campaign.history.isEmpty ? null : widget.campaign.history.last;
    final transferredPlayer = lastMatch?.transferredPlayerId == null
        ? null
        : widget.playerById(lastMatch!.transferredPlayerId!);
    final lastWinner = lastMatch == null ? null : _teamById(lastMatch.winner);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FC Conquest Arena'),
        actions: [
          IconButton(
            onPressed: widget.onOpenStats,
            tooltip: widget.strings.statsTooltip,
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: widget.onResetCampaign,
            tooltip: widget.strings.resetCampaignTooltip,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071726), Color(0xFF0A1F35), Color(0xFF0B1730)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1160;
                final dashboardHeight =
                    math.max(560.0, constraints.maxHeight - 90);

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _TopStrip(
                          champion: widget.champion,
                          lastWinner: lastWinner,
                          lastTransfer: transferredPlayer,
                          remainingTeams: widget.remainingTeams,
                          matchesPlayed: widget.campaign.matchesPlayed,
                          strings: widget.strings,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: dashboardHeight,
                          child: compact
                              ? Column(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: WorldMapBoard(
                                        campaign: widget.campaign,
                                        teams: widget.teams,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      flex: 4,
                                      child: widget.champion != null
                                          ? _ChampionSidePanel(
                                              champion: widget.champion!,
                                              squad: widget.campaign.players
                                                  .where((player) =>
                                                      player.currentTeamId ==
                                                      widget.champion!.id)
                                                  .take(6)
                                                  .toList(),
                                              onResetCampaign:
                                                  widget.onResetCampaign,
                                              strings: widget.strings,
                                            )
                                          : _RightPanel(
                                              teams: activeTeams,
                                              wheelBusy: _wheelBusy,
                                              onSpin: _openWheelFlow,
                                              strings: widget.strings,
                                            ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: WorldMapBoard(
                                        campaign: widget.campaign,
                                        teams: widget.teams,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: widget.champion != null
                                          ? _ChampionSidePanel(
                                              champion: widget.champion!,
                                              squad: widget.campaign.players
                                                  .where((player) =>
                                                      player.currentTeamId ==
                                                      widget.champion!.id)
                                                  .take(6)
                                                  .toList(),
                                              onResetCampaign:
                                                  widget.onResetCampaign,
                                              strings: widget.strings,
                                            )
                                          : _RightPanel(
                                              teams: activeTeams,
                                              wheelBusy: _wheelBusy,
                                              onSpin: _openWheelFlow,
                                              strings: widget.strings,
                                            ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Team? _teamById(int id) {
    for (final team in widget.teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  Future<void> _openWheelFlow() async {
    if (_wheelBusy) {
      return;
    }

    setState(() {
      _wheelBusy = true;
    });

    try {
      final attackers = widget.attackableTeams();
      if (!mounted || attackers.isEmpty) {
        return;
      }

      if (attackers.length == 2) {
        await _showFinalsOverlay(attackers[0], attackers[1]);
        if (!mounted) {
          return;
        }
        final defenderForA = widget.defenderCandidates(attackers[0].id);
        if (defenderForA.any((team) => team.id == attackers[1].id)) {
          await widget.onSetBattlePairing(attackers[0].id, attackers[1].id);
        } else {
          await widget.onSetBattlePairing(attackers[1].id, attackers[0].id);
        }
        return;
      }

      final attacker = await showTeamWheelDialog(
        context: context,
        teams: attackers,
        title: widget.strings.wheelStep1Title,
        subtitle: widget.strings.wheelStep1Subtitle,
        strings: widget.strings,
      );
      if (!mounted || attacker == null) {
        return;
      }

      final defenders = widget.defenderCandidates(attacker.id);
      if (defenders.isEmpty) {
        return;
      }

      final defender = await showTeamWheelDialog(
        context: context,
        teams: defenders,
        title: widget.strings.wheelStep2Title,
        subtitle: widget.strings.wheelStep2Subtitle,
        strings: widget.strings,
      );
      if (!mounted || defender == null) {
        return;
      }

      await widget.onSetBattlePairing(attacker.id, defender.id);
    } finally {
      if (mounted) {
        setState(() {
          _wheelBusy = false;
        });
      }
    }
  }

  Future<void> _showFinalsOverlay(Team teamA, Team teamB) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final navigator = Navigator.of(context);
        Future<void>.delayed(const Duration(milliseconds: 1700), () {
          if (navigator.canPop()) {
            navigator.pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1F35), Color(0xFF0B2B54)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FINALS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TeamBadge(team: teamA, size: 58),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('VS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                    ),
                    TeamBadge(team: teamB, size: 58),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${teamA.name} vs ${teamB.name}',
                  style: const TextStyle(
                      color: Color(0xFFBFDBFE), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChampionOverlay(Team champion) {
    final squad = widget.campaign.players
        .where((player) => player.currentTeamId == champion.id)
        .take(5)
        .toList();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ChampionCelebrationDialog(
          champion: champion,
          squad: squad,
          strings: widget.strings,
        );
      },
    );
  }
}

class _ChampionCelebrationDialog extends StatefulWidget {
  const _ChampionCelebrationDialog({
    required this.champion,
    required this.squad,
    required this.strings,
  });

  final Team champion;
  final List<Player> squad;
  final AppStrings strings;

  @override
  State<_ChampionCelebrationDialog> createState() =>
      _ChampionCelebrationDialogState();
}

class _ChampionCelebrationDialogState extends State<_ChampionCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _introController;
  late final Animation<double> _stageScale;
  late final Animation<double> _trophyScale;
  late final Animation<double> _glintX;
  late final Animation<double> _introOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _stageScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.68, end: 1.16), weight: 55),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.16, end: 1.0), weight: 45),
    ]).animate(
        CurvedAnimation(parent: _introController, curve: Curves.easeOut));
    _glintX = Tween<double>(begin: -120, end: 120).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.28, 0.92, curve: Curves.easeInOut)),
    );
    _introOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.15, 0.85, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.34),
      child: Center(
        child: AnimatedBuilder(
          animation: _introController,
          builder: (context, _) {
            return Transform.scale(
              scale: _stageScale.value,
              child: Opacity(
                opacity: _introOpacity.value,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 940),
                  margin: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border:
                        Border.all(color: const Color(0xFF7DD3FC), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A1C2F),
                                Color(0xFF153A5B),
                                Color(0xFF1B6B3A)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return CustomPaint(
                              painter:
                                  _ConfettiPainter(progress: _controller.value),
                              size: Size.infinite,
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.strings.worldChampion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: _trophyScale.value,
                                    child: const Icon(Icons.emoji_events,
                                        size: 76, color: Color(0xFFFACC15)),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Transform.translate(
                                      offset: Offset(_glintX.value, 0),
                                      child: Container(
                                        width: 48,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0),
                                              Colors.white
                                                  .withValues(alpha: 0.65),
                                              Colors.white.withValues(alpha: 0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TeamBadge(team: widget.champion, size: 96),
                              const SizedBox(height: 10),
                              Text(
                                widget.champion.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    for (final player in widget.squad)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          player.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.celebration),
                                label: Text(widget.strings.celebrateMore),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 110,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0C4A27), Color(0xFF14532D)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(26);
    final colors = [
      const Color(0xFFFACC15),
      const Color(0xFF22D3EE),
      const Color(0xFFF43F5E),
      const Color(0xFF22C55E),
      const Color(0xFFE5E7EB),
    ];

    for (var i = 0; i < 120; i++) {
      final startX = random.nextDouble() * size.width;
      final drift = (random.nextDouble() - 0.5) * 120;
      final yBase =
          (random.nextDouble() * size.height * 0.3) + (size.height * progress);
      final y = (yBase + (i * 7)) % (size.height + 30) - 30;
      final x = startX + (drift * progress);
      final rect = Rect.fromLTWH(
          x, y, 5 + random.nextDouble() * 4, 10 + random.nextDouble() * 6);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate((progress * math.pi * 2) + i);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: rect.width, height: rect.height),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TopStrip extends StatelessWidget {
  const _TopStrip({
    required this.champion,
    required this.lastWinner,
    required this.lastTransfer,
    required this.remainingTeams,
    required this.matchesPlayed,
    required this.strings,
  });

  final Team? champion;
  final Team? lastWinner;
  final Player? lastTransfer;
  final int remainingTeams;
  final int matchesPlayed;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC0F2238),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF294768)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _tile(strings.statTeams, '$remainingTeams'),
          _tile(strings.statMatches, '$matchesPlayed'),
          _tile(
              strings.statChampion, champion?.name ?? strings.championPending),
          _tile(strings.statLastWinner, lastWinner?.name ?? strings.noneYet),
          _tile(strings.statPlayerTransfer,
              lastTransfer?.name ?? strings.noneLabel),
        ],
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFFB6D3F5), fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.teams,
    required this.wheelBusy,
    required this.onSpin,
    required this.strings,
  });

  final List<Team> teams;
  final bool wheelBusy;
  final Future<void> Function() onSpin;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC0F2238),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF294768)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.matchDrawTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.matchDrawDescription,
            style: const TextStyle(color: Color(0xFFB6D3F5)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: wheelBusy ? null : onSpin,
              icon: wheelBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.casino_rounded),
              label: Text(
                  wheelBusy ? strings.wheelSpinning : strings.startWheelButton),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: const Color(0xFF06213A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.activeTeams,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      TeamBadge(team: team, size: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampionSidePanel extends StatefulWidget {
  const _ChampionSidePanel({
    required this.champion,
    required this.squad,
    required this.onResetCampaign,
    required this.strings,
  });

  final Team champion;
  final List<Player> squad;
  final Future<void> Function() onResetCampaign;
  final AppStrings strings;

  @override
  State<_ChampionSidePanel> createState() => _ChampionSidePanelState();
}

class _ChampionSidePanelState extends State<_ChampionSidePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2238), Color(0xFF15304E), Color(0xFF3A2E10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFACC15), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55111627),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFACC15), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.strings.tournamentEnded,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.strings.championSubtitle(widget.champion.name),
            style: const TextStyle(
              color: Color(0xFFF8E7A1),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final glow = 0.75 + (_glowController.value * 0.45);
                final spread = 3.0 + (_glowController.value * 6.0);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0x66FACC15).withValues(alpha: glow),
                        const Color(0x00FACC15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFACC15).withValues(
                            alpha: 0.26 + (_glowController.value * 0.24)),
                        blurRadius: 24 + (_glowController.value * 18),
                        spreadRadius: spread,
                      ),
                    ],
                  ),
                  child: TeamBadge(team: widget.champion, size: 124),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.champion.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              widget.strings.championCrowned,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFBFDBFE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.strings.finalHeroes,
            style: const TextStyle(
              color: Color(0xFFFFF3C4),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final player in widget.squad)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x33FACC15),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onResetCampaign,
              icon: const Icon(Icons.restart_alt),
              label: Text(widget.strings.startNewCampaignButton),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: const Color(0xFF10253A),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
