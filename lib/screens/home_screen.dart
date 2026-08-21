import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/campaign_setup.dart';
import '../models/team.dart';
import '../utils/team_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.hasCampaign,
    required this.onNewCampaign,
    required this.onContinue,
    required this.availableClubTeams,
    required this.availableNationTeams,
    required this.teams,
    required this.strings,
    required this.onOpenCustomWheel,
  });

  final bool hasCampaign;
  final Future<void> Function(CampaignSetup setup) onNewCampaign;
  final VoidCallback onContinue;
  final int availableClubTeams;
  final int availableNationTeams;
  final List<Team> teams;
  final AppStrings strings;
  final VoidCallback onOpenCustomWheel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TeamType _mode = TeamType.club;
  int _teamCount = 8;
  String? _league;
  String? _country;
  RangeValues? _ratingRange;
  bool _licensedOnly = false;

  List<Team> get _teamsForMode =>
      widget.teams.where((team) => team.type == _mode).toList();

  ({int min, int max}) get _ratingBounds {
    final pool = _teamsForMode;
    if (pool.isEmpty) {
      return (min: 0, max: 99);
    }
    final ratings = pool.map((team) => team.rating);
    return (
      min: ratings.reduce((a, b) => a < b ? a : b),
      max: ratings.reduce((a, b) => a > b ? a : b)
    );
  }

  List<Team> get _filteredTeams {
    final bounds = _ratingBounds;
    final range = _ratingRange ??
        RangeValues(bounds.min.toDouble(), bounds.max.toDouble());
    return filterTeams(
      _teamsForMode,
      league: _mode == TeamType.club ? _league : null,
      country: _mode == TeamType.club ? _country : null,
      minRating: range.start.round(),
      maxRating: range.end.round(),
      licensedOnly: _licensedOnly,
    );
  }

  void _resetFilters() {
    _league = null;
    _country = null;
    _ratingRange = null;
    _licensedOnly = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = widget.strings;
    final bounds = _ratingBounds;
    final ratingRange = _ratingRange ??
        RangeValues(bounds.min.toDouble(), bounds.max.toDouble());
    final filteredTeams = _filteredTeams;
    final safeMax = filteredTeams.length < 2 ? 2 : filteredTeams.length;
    final effectiveTeamCount = _teamCount.clamp(2, safeMax).toInt();
    final leagues = _mode == TeamType.club
        ? {
            for (final team in _teamsForMode)
              if (team.league != null) team.league!
          }.toList()
        : <String>[];
    final countries = _mode == TeamType.club
        ? {
            for (final team in _teamsForMode)
              if (team.country != null) team.country!
          }.toList()
        : <String>[];
    leagues.sort();
    countries.sort();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8BD3FF), Color(0xFFFFF0B8), Color(0xFFFFB8D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          // Tighter padding on narrow phone screens so more content width
          // is available before the card edges.
          final isCompact = constraints.maxWidth < 480;
          final outerPadding = isCompact ? 12.0 : 24.0;
          final cardPadding = isCompact ? 16.0 : 28.0;
          return Stack(
            children: [
              Positioned(
                left: -20,
                top: 70,
                child: _cloud(const Size(140, 70)),
              ),
              Positioned(
                right: 12,
                top: 110,
                child: _cloud(const Size(90, 52)),
              ),
              Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.all(outerPadding),
                      child: Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 24,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                strings.homeBadge,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text('FC 26 Conquest',
                                style: theme.textTheme.displaySmall),
                            const SizedBox(height: 10),
                            Text(
                              strings.homeHeadline,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.homeDescription,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MiniFeature(
                                    icon: Icons.casino_rounded,
                                    label: strings.featureWheel),
                                _MiniFeature(
                                    icon: Icons.flag_circle,
                                    label: strings.featureBadges),
                                _MiniFeature(
                                    icon: Icons.map_rounded,
                                    label: strings.featureMap),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.setupHeading,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      ChoiceChip(
                                        label: Text(strings.clubsChip(
                                            widget.availableClubTeams)),
                                        selected: _mode == TeamType.club,
                                        onSelected: (_) => setState(() {
                                          _mode = TeamType.club;
                                          _resetFilters();
                                        }),
                                      ),
                                      ChoiceChip(
                                        label: Text(strings.nationsChip(
                                            widget.availableNationTeams)),
                                        selected: _mode == TeamType.nation,
                                        onSelected: (_) => setState(() {
                                          _mode = TeamType.nation;
                                          _resetFilters();
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (_mode == TeamType.club) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        DropdownButton<String?>(
                                          value: _league,
                                          items: [
                                            DropdownMenuItem<String?>(
                                                value: null,
                                                child:
                                                    Text(strings.allLeagues)),
                                            ...leagues.map((value) =>
                                                DropdownMenuItem<String?>(
                                                    value: value,
                                                    child: Text(value))),
                                          ],
                                          onChanged: (value) => setState(() {
                                            _league = value;
                                          }),
                                        ),
                                        DropdownButton<String?>(
                                          value: _country,
                                          items: [
                                            DropdownMenuItem<String?>(
                                                value: null,
                                                child:
                                                    Text(strings.allCountries)),
                                            ...countries.map((value) =>
                                                DropdownMenuItem<String?>(
                                                    value: value,
                                                    child: Text(value))),
                                          ],
                                          onChanged: (value) => setState(() {
                                            _country = value;
                                          }),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text(
                                    strings.ratingRangeLabel(
                                        ratingRange.start.round(),
                                        ratingRange.end.round()),
                                  ),
                                  RangeSlider(
                                    values: ratingRange,
                                    min: bounds.min.toDouble(),
                                    max: bounds.max.toDouble(),
                                    divisions: (bounds.max - bounds.min) > 0
                                        ? bounds.max - bounds.min
                                        : null,
                                    labels: RangeLabels(
                                      ratingRange.start.round().toString(),
                                      ratingRange.end.round().toString(),
                                    ),
                                    onChanged: (value) => setState(() {
                                      _ratingRange = value;
                                    }),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _licensedOnly = !_licensedOnly;
                                    }),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: _licensedOnly,
                                          onChanged: (value) => setState(() {
                                            _licensedOnly = value ?? false;
                                          }),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(strings.licensedOnlyTitle),
                                                Text(
                                                  strings.licensedOnlySubtitle,
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(strings.teamCountLabel(
                                      effectiveTeamCount,
                                      filteredTeams.length)),
                                  Slider(
                                    value: effectiveTeamCount.toDouble(),
                                    min: 2,
                                    max: safeMax.toDouble(),
                                    divisions: safeMax > 2 ? safeMax - 2 : null,
                                    label: '$effectiveTeamCount',
                                    onChanged: (value) {
                                      setState(() {
                                        _teamCount = value.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: filteredTeams.length < 2
                                  ? null
                                  : () => widget.onNewCampaign(
                                        CampaignSetup(
                                          mode: _mode,
                                          teamCount: effectiveTeamCount,
                                          league: _mode == TeamType.club
                                              ? _league
                                              : null,
                                          country: _mode == TeamType.club
                                              ? _country
                                              : null,
                                          minRating: ratingRange.start.round(),
                                          maxRating: ratingRange.end.round(),
                                          licensedOnly: _licensedOnly,
                                        ),
                                      ),
                              icon: const Icon(Icons.auto_awesome),
                              label: Text(strings.newCampaignButton),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed:
                                  widget.hasCampaign ? widget.onContinue : null,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(strings.continueCampaignButton),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: widget.onOpenCustomWheel,
                              icon: const Icon(Icons.casino_outlined),
                              label: Text(strings.customWheelToolButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _cloud(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
