import 'package:flutter/material.dart';

import '../models/campaign_setup.dart';
import '../models/team.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.hasCampaign,
    required this.onNewCampaign,
    required this.onContinue,
    required this.availableClubTeams,
    required this.availableNationTeams,
    required this.onOpenCustomWheel,
  });

  final bool hasCampaign;
  final Future<void> Function(CampaignSetup setup) onNewCampaign;
  final VoidCallback onContinue;
  final int availableClubTeams;
  final int availableNationTeams;
  final VoidCallback onOpenCustomWheel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TeamType _mode = TeamType.club;
  int _teamCount = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTeams = _mode == TeamType.club
        ? widget.availableClubTeams
        : widget.availableNationTeams;
    final safeMax = maxTeams < 2 ? 2 : maxTeams;
    final effectiveTeamCount = _teamCount.clamp(2, safeMax).toInt();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8BD3FF), Color(0xFFFFF0B8), Color(0xFFFFB8D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Kinderfreundlicher Eroberungsmodus',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('FC 26 Conquest', style: theme.textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text(
                          'Erobere die Welt. Ein Match nach dem anderen.',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bunte Weltkarte, sichtbares Gluecksrad und Team-Badges statt trockener Tabellen. Genau richtig fuer einen verspielten Conquest-Prototyp.',
                          style: TextStyle(fontSize: 16, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const [
                            _MiniFeature(icon: Icons.casino_rounded, label: 'Gluecksrad'),
                            _MiniFeature(icon: Icons.flag_circle, label: 'Team-Badges'),
                            _MiniFeature(icon: Icons.map_rounded, label: 'Fantasy-Karte'),
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
                                'Neue Kampagne konfigurieren',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  ChoiceChip(
                                    label: Text('Clubs (${widget.availableClubTeams})'),
                                    selected: _mode == TeamType.club,
                                    onSelected: (_) => setState(() {
                                      _mode = TeamType.club;
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: Text('Nationen (${widget.availableNationTeams})'),
                                    selected: _mode == TeamType.nation,
                                    onSelected: (_) => setState(() {
                                      _mode = TeamType.nation;
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Teamanzahl: $effectiveTeamCount'),
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
                          onPressed: () => widget.onNewCampaign(
                            CampaignSetup(mode: _mode, teamCount: effectiveTeamCount),
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Neue Kampagne'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.hasCampaign ? widget.onContinue : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Kampagne fortsetzen'),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: widget.onOpenCustomWheel,
                          icon: const Icon(Icons.casino_outlined),
                          label: const Text('Zufallsrad-Werkzeug'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
