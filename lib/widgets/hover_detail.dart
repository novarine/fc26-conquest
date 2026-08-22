import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../models/player.dart';
import '../models/team.dart';
import '../utils/color_utils.dart';
import '../utils/rating_color.dart';
import 'team_badge.dart';

class HoverDetail extends StatefulWidget {
  const HoverDetail({super.key, required this.child, required this.builder});

  final Widget child;
  final WidgetBuilder builder;

  @override
  State<HoverDetail> createState() => _HoverDetailState();
}

class _HoverDetailState extends State<HoverDetail> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _show(PointerEnterEvent event) {
    if (_entry != null) {
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) {
      return;
    }
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    const popupWidth = 244.0;
    final maxLeft = (overlay.size.width - popupWidth - 8).clamp(8.0, double.infinity);
    final rightPosition = topLeft.dx + size.width + 10;
    final leftPosition = rightPosition <= maxLeft
      ? rightPosition
      : (topLeft.dx - popupWidth - 10).clamp(8.0, maxLeft);
    final maxTop = (overlay.size.height - 220).clamp(8.0, double.infinity);
    _entry = OverlayEntry(
      builder: (context) => Positioned(
      left: leftPosition,
      top: (topLeft.dy - 8).clamp(8.0, maxTop),
        child: IgnorePointer(child: widget.builder(context)),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _show,
      onExit: (_) => _hide(),
      child: widget.child,
    );
  }
}

class TeamHoverDetail extends StatelessWidget {
  const TeamHoverDetail({super.key, required this.team, required this.child});

  final Team team;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HoverDetail(
      child: child,
      builder: (context) => _HoverPanel(
        accent: parseHexColor(team.primaryColor),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeamBadge(team: team, size: 58),
            const SizedBox(width: 10),
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(team.league ?? team.type.name,
                      style: const TextStyle(color: Color(0xFFBFDBFE))),
                  Text('Rating ${team.rating}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _ColorDot(parseHexColor(team.primaryColor)),
                    if (team.secondaryColor != null) ...[
                      const SizedBox(width: 5),
                      _ColorDot(parseHexColor(team.secondaryColor!)),
                    ],
                    const SizedBox(width: 7),
                    Text(team.country ?? '-',
                        style: const TextStyle(
                            color: Color(0xFFBFDBFE), fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerHoverDetail extends StatelessWidget {
  const PlayerHoverDetail({super.key, required this.player, required this.child});

  final Player player;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stats = <String, int?>{
      'PAC': player.pace,
      'SHO': player.shooting,
      'PAS': player.passing,
      'DRI': player.dribbling,
      'DEF': player.defending,
      'PHY': player.physical,
    };
    return HoverDetail(
      child: child,
      builder: (context) => _HoverPanel(
        accent: ratingColor(player.rating),
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(player.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                ),
                Text('${player.rating}',
                    style: TextStyle(
                        color: ratingColor(player.rating),
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 3),
              Text('${player.position}  •  ${player.nation ?? '-'}',
                  style: const TextStyle(color: Color(0xFFBFDBFE))),
              const SizedBox(height: 12),
              if (player.subAttributes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('DETAILS',
                    style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 3.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final entry in player.subAttributes.entries)
                      Row(children: [
                        Expanded(
                            child: Text(entry.key,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11))),
                        Text('${entry.value}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                      ]),
                  ],
                ),
              ],
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3.3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final entry in stats.entries)
                    Row(children: [
                      SizedBox(
                          width: 34,
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 11))),
                      Text('${entry.value ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900)),
                    ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverPanel extends StatelessWidget {
  const _HoverPanel({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10253A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x88000000),
                blurRadius: 18,
                offset: Offset(0, 8)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54),
      ),
    );
  }
}