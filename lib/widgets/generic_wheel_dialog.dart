import 'dart:math';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// Generic weighted-equal wheel for arbitrary text entries (challenges, rules,
/// formations, etc.), independent from the Team-based conquest wheel.
Future<String?> showGenericWheelDialog({
  required BuildContext context,
  required List<String> entries,
  required String title,
  required AppStrings strings,
  String? subtitle,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _GenericWheelDialog(
        entries: entries,
        title: title,
        subtitle: subtitle,
        strings: strings,
      );
    },
  );
}

const _wheelPalette = [
  Color(0xFF38BDF8),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFEC4899),
  Color(0xFFA855F7),
  Color(0xFFEAB308),
  Color(0xFFEF4444),
  Color(0xFF14B8A6),
];

class _GenericWheelDialog extends StatefulWidget {
  const _GenericWheelDialog({
    required this.entries,
    required this.title,
    required this.strings,
    this.subtitle,
  });

  final List<String> entries;
  final String title;
  final String? subtitle;
  final AppStrings strings;

  @override
  State<_GenericWheelDialog> createState() => _GenericWheelDialogState();
}

class _GenericWheelDialogState extends State<_GenericWheelDialog>
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
    final selectedEntry = _selectedIndex == null ? null : widget.entries[_selectedIndex!];

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
                      child: _LeftPointer(size: wheelSize),
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _animation.value,
                          child: _GenericWheelDisk(
                            entries: widget.entries,
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
                        Icons.casino,
                        size: 42,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedEntry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    selectedEntry,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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
                    label: Text(widget.strings.cancelButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFFD1EAFE),
                      side: const BorderSide(color: Color(0xFF7DD3FC)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _spinning ? null : _spin,
                    icon: const Icon(Icons.rotate_right),
                    label: Text(_selectedIndex == null ? widget.strings.spinButton : widget.strings.spinAgainButton),
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: const Color(0xFF1D4F77),
                      disabledForegroundColor: const Color(0xFFD1EAFE),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _selectedIndex == null || _spinning
                        ? null
                        : () => Navigator.of(context).pop(selectedEntry),
                    icon: const Icon(Icons.check),
                    label: Text(widget.strings.confirmButton),
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
    if (widget.entries.isEmpty || _spinning) {
      return;
    }

    setState(() {
      _spinning = true;
    });

    final sweep = (pi * 2) / widget.entries.length;
    final winner = _random.nextInt(widget.entries.length);
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
    final sweep = (pi * 2) / widget.entries.length;
    final localPointer = _normalizeAngle(_pointerAngle - rotation);
    final angleFromStart = _normalizeAngle(localPointer + (pi / 2));
    final index = (angleFromStart / sweep).floor() % widget.entries.length;
    return index;
  }
}

class _GenericWheelDisk extends StatelessWidget {
  const _GenericWheelDisk({
    required this.entries,
    required this.selectedIndex,
    required this.wheelSize,
  });

  final List<String> entries;
  final int? selectedIndex;
  final double wheelSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        size: Size.square(wheelSize),
        painter: _GenericWheelPainter(entries: entries, selectedIndex: selectedIndex),
      ),
    );
  }
}

class _GenericWheelPainter extends CustomPainter {
  const _GenericWheelPainter({
    required this.entries,
    required this.selectedIndex,
  });

  final List<String> entries;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (pi * 2) / entries.length;
    var start = -pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final highlight = i == selectedIndex;
      final color = _wheelPalette[i % _wheelPalette.length];
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

      final labelAngle = start + (sweep / 2);
      final labelRadius = radius * 0.62;
      final labelOffset = center +
          Offset(cos(labelAngle) * labelRadius, sin(labelAngle) * labelRadius);

      final textPainter = TextPainter(
        text: TextSpan(
          text: entries[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.7);

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(labelAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _GenericWheelPainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.selectedIndex != selectedIndex;
  }
}

class _LeftPointer extends StatelessWidget {
  const _LeftPointer({required this.size});

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
