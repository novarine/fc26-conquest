import 'dart:math';

import 'package:flutter/material.dart';

import '../models/team.dart';
import '../utils/color_utils.dart';

class FortuneWheelPreview extends StatelessWidget {
  const FortuneWheelPreview({
    super.key,
    required this.teams,
    this.highlightTeamId,
    this.title,
  });

  final List<Team> teams;
  final int? highlightTeamId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6D8), Color(0xFFFFE3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(210),
                    painter: _WheelPainter(
                      teams: teams,
                      highlightTeamId: highlightTeamId,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 42,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.flag_circle_rounded, size: 30),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teams.take(8).map((team) {
              final isHighlight = team.id == highlightTeamId;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? parseHexColor(team.primaryColor).withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isHighlight
                        ? parseHexColor(team.primaryColor)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  team.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.teams,
    required this.highlightTeamId,
  });

  final List<Team> teams;
  final int? highlightTeamId;

  @override
  void paint(Canvas canvas, Size size) {
    if (teams.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (pi * 2) / teams.length;
    var start = -pi / 2;

    for (final team in teams) {
      final color = parseHexColor(team.primaryColor);
      final isHighlight = team.id == highlightTeamId;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isHighlight
            ? Color.lerp(color, Colors.white, 0.12) ?? color
            : color.withValues(alpha: 0.9);

      canvas.drawArc(rect, start, sweep, true, paint);

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlight ? 4 : 2
        ..color = Colors.white;
      canvas.drawArc(rect, start, sweep, true, border);

      final angle = start + sweep / 2;
      final labelOffset = Offset(
        center.dx + cos(angle) * radius * 0.62,
        center.dy + sin(angle) * radius * 0.62,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: _shortName(team.name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 48);
      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(angle + pi / 2);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.teams != teams ||
        oldDelegate.highlightTeamId != highlightTeamId;
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 6));
    }
    return parts.last.substring(0, parts.last.length.clamp(0, 6));
  }
}
