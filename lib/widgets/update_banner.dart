import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    super.key,
    required this.latestVersion,
    required this.releaseNotes,
    required this.onUpdate,
    required this.strings,
    this.onDismiss,
  });

  final String latestVersion;
  final String releaseNotes;
  final VoidCallback onUpdate;
  final AppStrings strings;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final lines = releaseNotes
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(3)
        .toList();

    return Material(
      color: const Color(0xFF0EA5E9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.newVersionAvailable(latestVersion),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onUpdate,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(strings.updateButton),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: strings.dismissTooltip,
                  ),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $line',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
