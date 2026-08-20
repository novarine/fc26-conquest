import 'dart:math';

import 'package:flutter/material.dart';

import '../models/team.dart';
import '../utils/color_utils.dart';
import 'team_badge.dart';

Future<Team?> showTeamWheelDialog({
  required BuildContext context,
  required List<Team> teams,
  required String title,
  String? subtitle,
}) {
  return showDialog<Team>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _TeamWheelDialog(
        teams: teams,
        title: title,
        subtitle: subtitle,
      );
    },
  );
}

class _TeamWheelDialog extends StatefulWidget {
  const _TeamWheelDialog({
    required this.teams,
    required this.title,
    this.subtitle,
  });

  final List<Team> teams;
  final String title;
  final String? subtitle;

  @override
  State<_TeamWheelDialog> createState() => _TeamWheelDialogState();
}

class _TeamWheelDialogState extends State<_TeamWheelDialog>
    with SingleTickerProviderStateMixin {
  static const _pointerAngle = pi;

  late final AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  double _rotation = 0;
  int? _selectedIndex;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _animation = AlwaysStoppedAnimation(_rotation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width;
    final dialogWidth = min(1120.0, availableWidth - 28);
    final wheelSize = availableWidth > 1500 ? 460.0 : 420.0;
    final selectedTeam = _selectedIndex == null ? null : widget.teams[_selectedIndex!];

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF081A32), Color(0xFF0B2B54), Color(0xFF0E3C73)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: wheelSize,
                height: wheelSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: _LeftWheelPointer(size: wheelSize),
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _animation.value,
                          child: _WheelDisk(
                            teams: widget.teams,
                            selectedIndex: _selectedIndex,
                            wheelSize: wheelSize,
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0F2FE),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 42,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedTeam != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeamBadge(team: selectedTeam, size: 52, showFrame: true),
                      const SizedBox(width: 10),
                      Text(
                        selectedTeam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _spinning ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Abbrechen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFFD1EAFE),
                      side: const BorderSide(color: Color(0xFF7DD3FC)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _spinning ? null : _spin,
                    icon: const Icon(Icons.rotate_right),
                    label: Text(_selectedIndex == null ? 'Drehen' : 'Nochmal drehen'),
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: const Color(0xFF1D4F77),
                      disabledForegroundColor: const Color(0xFFD1EAFE),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _selectedIndex == null || _spinning
                        ? null
                        : () => Navigator.of(context).pop(selectedTeam),
                    icon: const Icon(Icons.check),
                    label: const Text('Team bestaetigen'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      disabledBackgroundColor: const Color(0xFF2E6D47),
                      disabledForegroundColor: const Color(0xFFE2FBEA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _spin() async {
    if (widget.teams.isEmpty || _spinning) {
      return;
    }

    setState(() {
      _spinning = true;
    });

    final sweep = (pi * 2) / widget.teams.length;
    final winner = _random.nextInt(widget.teams.length);
    final winnerCenterAngle = (-pi / 2) + (winner * sweep) + (sweep / 2);
    final targetRotationNorm = _normalizeAngle(_pointerAngle - winnerCenterAngle);
    final currentRotationNorm = _normalizeAngle(_rotation);
    final deltaToTarget = _normalizeAngle(targetRotationNorm - currentRotationNorm);
    final turns = (pi * 2 * (5 + _random.nextInt(3))) + deltaToTarget;

    final begin = _rotation;
    final end = _rotation + turns;

    _animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    await _controller.forward(from: 0);

    setState(() {
      _rotation = _normalizeAngle(end);
      _selectedIndex = _indexAtPointer(_rotation);
      _spinning = false;
    });
  }

  double _normalizeAngle(double angle) {
    final normalized = angle % (pi * 2);
    return normalized < 0 ? normalized + (pi * 2) : normalized;
  }

  int _indexAtPointer(double rotation) {
    final sweep = (pi * 2) / widget.teams.length;
    final localPointer = _normalizeAngle(_pointerAngle - rotation);
    final angleFromStart = _normalizeAngle(localPointer + (pi / 2));
    final index = (angleFromStart / sweep).floor() % widget.teams.length;
    return index;
  }
}

class _WheelDisk extends StatelessWidget {
  const _WheelDisk({
    required this.teams,
    required this.selectedIndex,
    required this.wheelSize,
  });

  final List<Team> teams;
  final int? selectedIndex;
  final double wheelSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(wheelSize),
            painter: _WheelPainter(teams: teams, selectedIndex: selectedIndex),
          ),
          ..._buildLogoNodes(),
        ],
      ),
    );
  }

  List<Widget> _buildLogoNodes() {
    if (teams.isEmpty) {
      return const [];
    }

    final radius = (wheelSize / 2) - 28;
    final step = (pi * 2) / teams.length;
    final widgets = <Widget>[];

    for (var index = 0; index < teams.length; index++) {
      final angle = -pi / 2 + (step * index) + (step / 2);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      widgets.add(
        Transform.translate(
          offset: Offset(x, y),
          child: TeamBadge(team: teams[index], size: widgetBadgeSize()),
        ),
      );
    }

    return widgets;
  }

  double widgetBadgeSize() {
    if (teams.length >= 24) {
      return wheelSize >= 450 ? 42 : 36;
    }
    if (teams.length >= 16) {
      return wheelSize >= 450 ? 48 : 40;
    }
    return wheelSize >= 450 ? 54 : 46;
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.teams,
    required this.selectedIndex,
  });

  final List<Team> teams;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (teams.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (pi * 2) / teams.length;
    var start = -pi / 2;

    for (var i = 0; i < teams.length; i++) {
      final team = teams[i];
      final highlight = i == selectedIndex;
      final color = parseHexColor(team.primaryColor);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = highlight
            ? Color.lerp(color, Colors.white, 0.2) ?? color
            : color.withValues(alpha: 0.95);

      canvas.drawArc(rect, start, sweep, true, paint);

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 4 : 2
        ..color = Colors.black;
      canvas.drawArc(rect, start, sweep, true, border);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.teams != teams || oldDelegate.selectedIndex != selectedIndex;
  }
}

class _LeftWheelPointer extends StatelessWidget {
  const _LeftWheelPointer({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: size,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 46,
              color: Colors.orange.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
