import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/conquest_service.dart';
import '../services/player_image_service.dart';
import '../widgets/team_badge.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.battle,
    required this.attacker,
    required this.defender,
    required this.attackerSquad,
    required this.defenderSquad,
    required this.attackerRegions,
    required this.defenderRegions,
    required this.strings,
    required this.onSubmit,
    required this.onCancel,
  });

  final BattlePairing battle;
  final Team attacker;
  final Team defender;
  final List<Player> attackerSquad;
  final List<Player> defenderSquad;
  final int attackerRegions;
  final int defenderRegions;
  final AppStrings strings;
  final Future<void> Function(
      int winnerId, int? transferredPlayerId, String? score) onSubmit;
  final VoidCallback onCancel;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int? _selectedWinnerId;
  int? _selectedTransferredPlayerId;
  final TextEditingController _scoreController = TextEditingController();

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = widget.strings;

    return Scaffold(
      backgroundColor: const Color(0xFF061425),
      appBar: AppBar(
        title: Text(strings.matchResultTitle),
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: const Color(0xFF0A213A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071B2F), Color(0xFF0E2C4A), Color(0xFF071B2F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BattleHeader(
                          attacker: widget.attacker,
                          defender: widget.defender,
                          attackerRegions: widget.attackerRegions,
                          defenderRegions: widget.defenderRegions,
                          strings: strings,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          strings.whoWonHeading,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _winnerChip(widget.attacker),
                            _winnerChip(widget.defender),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_selectedWinnerId != null) ...[
                          _buildTransferSection(theme),
                          const SizedBox(height: 18),
                        ],
                        TextField(
                          controller: _scoreController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: strings.optionalScoreLabel,
                            labelStyle:
                                const TextStyle(color: Color(0xFF93C5FD)),
                            hintText: strings.scoreHint,
                            hintStyle:
                                const TextStyle(color: Color(0xFF60A5FA)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E3A5F)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF38BDF8), width: 1.8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: widget.onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side:
                                    const BorderSide(color: Color(0xFF60A5FA)),
                              ),
                              child: Text(strings.cancelButton),
                            ),
                            FilledButton.icon(
                              onPressed: _selectedWinnerId == null
                                  ? null
                                  : () => widget.onSubmit(
                                        _selectedWinnerId!,
                                        _selectedTransferredPlayerId,
                                        _scoreController.text.trim().isEmpty
                                            ? null
                                            : _scoreController.text.trim(),
                                      ),
                              icon: const Icon(Icons.emoji_events),
                              label: Text(strings.captureRegionButton),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _winnerChip(Team team) {
    final selected = _selectedWinnerId == team.id;

    return InkWell(
      onTap: () => _selectWinner(team.id),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF38BDF8) : const Color(0xFF1E3A5B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF7DD3FC) : const Color(0xFF426489),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamBadge(team: team, size: 26),
            const SizedBox(width: 8),
            Text(
              team.name,
              style: TextStyle(
                color: selected ? const Color(0xFF03253D) : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSection(ThemeData theme) {
    final strings = widget.strings;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.transferSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: _selectedTransferredPlayerId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF38BDF8), width: 1.7),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              helperText: strings.transferHelperText,
              helperStyle: const TextStyle(color: Color(0xFF93C5FD)),
            ),
            dropdownColor: const Color(0xFF112A45),
            style: const TextStyle(color: Colors.white),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(strings.noPlayerTransferOption),
              ),
              ..._losingSquad.map(
                (player) => DropdownMenuItem<int?>(
                  value: player.id,
                  child: Text(
                      '${player.name} | ${player.position} | ${player.rating}'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTransferredPlayerId = value;
              });
            },
          ),
          if (_losingSquad.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _losingSquad.take(4).map((player) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${player.name} • ${player.position} ${player.rating}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              strings.noPlayersAvailable,
              style: const TextStyle(
                color: Color(0xFFBFDBFE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_selectedPlayer != null) ...[
            const SizedBox(height: 14),
            _TransferPlayerCard(player: _selectedPlayer!, strings: strings),
          ],
        ],
      ),
    );
  }

  void _selectWinner(int? value) {
    setState(() {
      _selectedWinnerId = value;
      _selectedTransferredPlayerId = null;
    });
  }

  List<Player> get _losingSquad {
    if (_selectedWinnerId == null) {
      return const [];
    }

    if (_selectedWinnerId == widget.attacker.id) {
      return widget.defenderSquad;
    }

    return widget.attackerSquad;
  }

  Player? get _selectedPlayer {
    final id = _selectedTransferredPlayerId;
    if (id == null) {
      return null;
    }

    for (final player in _losingSquad) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.attacker,
    required this.defender,
    required this.attackerRegions,
    required this.defenderRegions,
    required this.strings,
  });

  final Team attacker;
  final Team defender;
  final int attackerRegions;
  final int defenderRegions;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x3314B8A6), Color(0x331D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TeamShowcase(
                team: attacker, regions: attackerRegions, strings: strings),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _TeamShowcase(
                team: defender, regions: defenderRegions, strings: strings),
          ),
        ],
      ),
    );
  }
}

class _TransferPlayerCard extends StatelessWidget {
  const _TransferPlayerCard({required this.player, required this.strings});

  final Player player;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF31537A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlayerFace(face: player.face, name: player.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'OVR ${player.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.position} • ${player.nation ?? '-'} • ${player.age ?? '-'} ${strings.yearsSuffix}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBFDBFE),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.valueWageLabel(
                      player.value ?? '-', player.wage ?? '-'),
                  style:
                      const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip('PAC', player.pace),
                    _statChip('SHO', player.shooting),
                    _statChip('PAS', player.passing),
                    _statChip('DRI', player.dribbling),
                    _statChip('DEF', player.defending),
                    _statChip('PHY', player.physical),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label ${value ?? '-'}',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PlayerFace extends StatefulWidget {
  const _PlayerFace({required this.face, required this.name});

  final String? face;
  final String name;

  @override
  State<_PlayerFace> createState() => _PlayerFaceState();
}

class _PlayerFaceState extends State<_PlayerFace> {
  String? _imageUrl;
  bool _triedFallbackUrl = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _PlayerFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.face != widget.face) {
      _triedFallbackUrl = false;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final resolved = await PlayerImageService.resolveImage(
      playerName: widget.name,
      preferredUrl: widget.face,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _imageUrl = resolved ?? widget.face;
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    if (url == null || url.isEmpty) {
      return _fallbackAvatar();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (!_triedFallbackUrl) {
            _triedFallbackUrl = true;
            _imageUrl =
                'https://api.dicebear.com/9.x/adventurer/png?seed=${Uri.encodeComponent(widget.name)}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }
          return _fallbackAvatar();
        },
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initials = widget.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TeamShowcase extends StatelessWidget {
  const _TeamShowcase({
    required this.team,
    required this.regions,
    required this.strings,
  });

  final Team team;
  final int regions;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 62),
        const SizedBox(height: 8),
        Text(
          team.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.regionsLabel(regions),
          style: const TextStyle(color: Color(0xFFBFDBFE)),
        ),
      ],
    );
  }
}
