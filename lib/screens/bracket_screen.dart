import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/bracket_state.dart';
import '../models/team.dart';
import '../services/bracket_service.dart';
import '../services/storage_service.dart';
import '../widgets/team_badge.dart';

/// Single-elimination "cup"/"World Cup" style tournament mode, independent
/// from the region-conquest campaign flow (see BracketService for the rules).
class BracketScreen extends StatefulWidget {
  const BracketScreen({
    super.key,
    required this.teams,
    required this.strings,
    required this.onBack,
  });

  final List<Team> teams;
  final AppStrings strings;
  final VoidCallback onBack;

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  final StorageService _storage = StorageService();
  final BracketService _service = BracketService();

  bool _loading = true;
  BracketState? _bracket;
  TeamType _mode = TeamType.club;
  int _teamCount = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.loadBracket();
    if (!mounted) {
      return;
    }
    setState(() {
      _bracket = loaded;
      _loading = false;
    });
  }

  List<Team> get _poolForMode =>
      widget.teams.where((team) => team.type == _mode).toList();

  Future<void> _draw() async {
    final pool = [..._poolForMode]..shuffle();
    final maxCount = pool.length < 2 ? 2 : pool.length;
    final count = _teamCount.clamp(2, maxCount);
    final chosen = pool.take(count).toList();

    final bracket = _service.generate(
      teams: chosen,
      mode: _mode.name,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await _storage.saveBracket(bracket);
    if (!mounted) {
      return;
    }
    setState(() => _bracket = bracket);
  }

  Future<void> _newTournament() async {
    await _storage.clearBracket();
    if (!mounted) {
      return;
    }
    setState(() => _bracket = null);
  }

  Team? _teamById(int? id) {
    if (id == null) {
      return null;
    }
    for (final team in widget.teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  Future<void> _pickWinner(BracketMatch match) async {
    final teamA = _teamById(match.teamAId);
    final teamB = _teamById(match.teamBId);
    if (teamA == null || teamB == null) {
      return;
    }
    final strings = widget.strings;
    final scoreController = TextEditingController();

    final winnerId = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.pickWinnerTitle),
          content: SizedBox(
            width: (MediaQuery.of(dialogContext).size.width - 64)
                .clamp(0.0, 420.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scoreController,
                  decoration: InputDecoration(
                    labelText: strings.optionalScoreLabel,
                    hintText: strings.scoreHint,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _WinnerChoiceButton(
                      team: teamA,
                      onTap: () => Navigator.of(dialogContext).pop(teamA.id),
                    ),
                    _WinnerChoiceButton(
                      team: teamB,
                      onTap: () => Navigator.of(dialogContext).pop(teamB.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelButton),
            ),
          ],
        );
      },
    );

    if (winnerId != null && _bracket != null) {
      final score = scoreController.text.trim().isEmpty
          ? null
          : scoreController.text.trim();
      final updated = _service.applyResult(
        _bracket!,
        round: match.round,
        matchIndex: match.matchIndex,
        winnerId: winnerId,
        score: score,
      );
      await _storage.saveBracket(updated);
      if (mounted) {
        setState(() => _bracket = updated);
      }
    }
    scoreController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final bracket = _bracket;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.bracketTitle),
        leading: IconButton(
          onPressed: widget.onBack,
          tooltip: strings.bracketBackTooltip,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (bracket != null)
            IconButton(
              onPressed: _newTournament,
              tooltip: strings.newBracketButton,
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : bracket == null
              ? _buildSetup(strings)
              : _buildBracket(strings, bracket),
    );
  }

  Widget _buildSetup(AppStrings strings) {
    final pool = _poolForMode;
    final maxCount = pool.length < 2 ? 2 : pool.length;
    final count = _teamCount.clamp(2, maxCount);
    final clubCount = widget.teams.where((t) => t.type == TeamType.club).length;
    final nationCount =
        widget.teams.where((t) => t.type == TeamType.nation).length;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.bracketSetupHeading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(strings.bracketSetupDescription),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(strings.clubsChip(clubCount)),
                          selected: _mode == TeamType.club,
                          onSelected: (_) =>
                              setState(() => _mode = TeamType.club),
                        ),
                        ChoiceChip(
                          label: Text(strings.nationsChip(nationCount)),
                          selected: _mode == TeamType.nation,
                          onSelected: (_) =>
                              setState(() => _mode = TeamType.nation),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(strings.bracketTeamCountLabel(count)),
                    Slider(
                      value: count.toDouble(),
                      min: 2,
                      max: maxCount.toDouble(),
                      divisions: maxCount > 2 ? maxCount - 2 : null,
                      label: '$count',
                      onChanged: (value) =>
                          setState(() => _teamCount = value.round()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: pool.length < 2 ? null : _draw,
                        icon: const Icon(Icons.emoji_events),
                        label: Text(strings.drawBracketButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBracket(AppStrings strings, BracketState bracket) {
    final champion = _teamById(bracket.championId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (champion != null)
          _ChampionBanner(champion: champion, strings: strings),
        for (var r = 0; r < bracket.rounds.length; r++) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 10, top: r == 0 ? 0 : 12),
            child: Text(
              _roundLabel(strings, bracket, r),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final match in bracket.rounds[r])
            _MatchCard(
              match: match,
              teamA: _teamById(match.teamAId),
              teamB: _teamById(match.teamBId),
              winner: _teamById(match.winnerId),
              strings: strings,
              onTap: match.isReady ? () => _pickWinner(match) : null,
            ),
        ],
      ],
    );
  }

  String _roundLabel(AppStrings strings, BracketState bracket, int roundIndex) {
    final matchCount = bracket.rounds[roundIndex].length;
    if (matchCount == 1) {
      return strings.bracketFinal;
    }
    if (matchCount == 2) {
      return strings.bracketSemiFinal;
    }
    if (matchCount == 4) {
      return strings.bracketQuarterFinal;
    }
    return strings.bracketRoundOf(matchCount * 2);
  }
}

class _WinnerChoiceButton extends StatelessWidget {
  const _WinnerChoiceButton({required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamBadge(team: team, size: 28),
          const SizedBox(width: 8),
          Text(team.name),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.winner,
    required this.strings,
    required this.onTap,
  });

  final BracketMatch match;
  final Team? teamA;
  final Team? teamB;
  final Team? winner;
  final AppStrings strings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _teamSlot(teamA)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Text('VS', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Expanded(child: _teamSlot(teamB)),
              if (match.score != null) ...[
                const SizedBox(width: 10),
                Text(match.score!,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
              if (match.isBye) ...[
                const SizedBox(width: 10),
                Chip(label: Text(strings.byeLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSlot(Team? team) {
    if (team == null) {
      return Row(
        children: [
          const SizedBox(width: 28, height: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      );
    }

    final isWinner = winner?.id == team.id;
    return Row(
      children: [
        TeamBadge(team: team, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.w500,
              color: isWinner ? const Color(0xFF16A34A) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChampionBanner extends StatelessWidget {
  const _ChampionBanner({required this.champion, required this.strings});

  final Team champion;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          TeamBadge(team: champion, size: 56, showFrame: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.bracketChampionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                  ),
                ),
                Text(
                  champion.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events, size: 32, color: Color(0xFF78350F)),
        ],
      ),
    );
  }
}
