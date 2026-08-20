import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const String currentVersion = '1.0.1';
  static const String defaultUpdateCheckUrl =
      'https://example.com/releases/fc26-conquest/version.json';
  static const String defaultDownloadUrl =
      'https://example.com/releases/fc26-conquest/FC26Conquest-Setup.exe';

  static String updateCheckUrl = defaultUpdateCheckUrl;
  static String downloadUrl = defaultDownloadUrl;

  final http.Client _client;

  static String extractVersionFromManifest(Map<String, dynamic> manifest) {
    final candidateKeys = ['version', 'latestVersion', 'tag', 'releaseVersion'];
    for (final key in candidateKeys) {
      final value = manifest[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final latest = manifest['latest'];
    if (latest is Map<String, dynamic>) {
      final nestedVersion = extractVersionFromManifest(latest);
      if (nestedVersion != currentVersion || latest.isNotEmpty) {
        return nestedVersion;
      }
    }

    return currentVersion;
  }

  static String extractDownloadUrlFromManifest(Map<String, dynamic> manifest) {
    final candidateKeys = [
      'installerUrl',
      'downloadUrl',
      'browserDownloadUrl',
      'url',
      'releaseUrl',
    ];

    for (final key in candidateKeys) {
      final value = manifest[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final latest = manifest['latest'];
    if (latest is Map<String, dynamic>) {
      final nestedUrl = extractDownloadUrlFromManifest(latest);
      if (nestedUrl != downloadUrl || latest.isNotEmpty) {
        return nestedUrl;
      }
    }

    return downloadUrl;
  }

  static String extractReleaseNotesFromManifest(Map<String, dynamic> manifest) {
    final candidateKeys = [
      'releaseNotes',
      'notes',
      'changelog',
      'whatsNew',
      'description',
    ];

    for (final key in candidateKeys) {
      final value = manifest[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final latest = manifest['latest'];
    if (latest is Map<String, dynamic>) {
      final nestedNotes = extractReleaseNotesFromManifest(latest);
      if (nestedNotes.isNotEmpty) {
        return nestedNotes;
      }
    }

    return 'Bug fixes and performance improvements.';
  }

  static bool isNewerVersion(String current, String candidate) {
    final currentParts = _parseVersion(current);
    final candidateParts = _parseVersion(candidate);

    final maxLength = currentParts.length > candidateParts.length
        ? currentParts.length
        : candidateParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final candidateValue = i < candidateParts.length ? candidateParts[i] : 0;

      if (candidateValue > currentValue) {
        return true;
      }
      if (candidateValue < currentValue) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    final cleaned = version.split('+').first;
    final segments = cleaned.split('.');
    final values = <int>[];

    for (final segment in segments) {
      final numeric = int.tryParse(segment.trim());
      if (numeric == null) {
        continue;
      }
      values.add(numeric);
    }

    return values.isEmpty ? [0] : values;
  }

  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      final response = await _client.get(Uri.parse(updateCheckUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          downloadUrl: downloadUrl,
          releaseNotes: 'Bug fixes and performance improvements.',
          reason: 'Version endpoint unavailable',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          downloadUrl: downloadUrl,
          releaseNotes: 'Bug fixes and performance improvements.',
          reason: 'Malformed version payload',
        );
      }

      final manifest = Map<String, dynamic>.from(decoded);
      final latest = extractVersionFromManifest(manifest);
      final resolvedDownloadUrl = extractDownloadUrlFromManifest(manifest);
      final releaseNotes = extractReleaseNotesFromManifest(manifest);
      final hasUpdate = isNewerVersion(currentVersion, latest);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latest,
        downloadUrl: resolvedDownloadUrl,
        releaseNotes: releaseNotes,
        reason: hasUpdate ? 'New version available' : 'Up to date',
      );
    } catch (error) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: 'Bug fixes and performance improvements.',
        reason: 'Unable to check for updates',
      );
    }
  }

  Future<void> markLastUpdateCheck(DateTime checkedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fc26_update_last_checked', checkedAt.toUtc().toIso8601String());
  }

  Future<DateTime?> lastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fc26_update_last_checked');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }
}

@immutable
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.reason,
  });

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final String reason;
}
