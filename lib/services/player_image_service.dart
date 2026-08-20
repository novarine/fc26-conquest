import 'dart:convert';

import 'package:http/http.dart' as http;

class PlayerImageService {
  PlayerImageService._();

  static final Map<String, String?> _cache = <String, String?>{};

  static Future<String?> resolveImage({
    required String playerName,
    String? preferredUrl,
  }) async {
    final key = playerName.trim().toLowerCase();
    if (key.isEmpty) {
      return null;
    }

    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    if (_isUsablePreferred(preferredUrl)) {
      _cache[key] = preferredUrl;
      return preferredUrl;
    }

    final candidates = _queryCandidates(playerName);

    for (final candidate in candidates) {
      final imageFromSportsDb = await _fetchSportsDbImage(candidate);
      if (imageFromSportsDb != null) {
        _cache[key] = imageFromSportsDb;
        return imageFromSportsDb;
      }

      final imageFromWikipedia = await _fetchWikipediaImage(candidate);
      if (imageFromWikipedia != null) {
        _cache[key] = imageFromWikipedia;
        return imageFromWikipedia;
      }
    }

    _cache[key] = null;
    return null;
  }

  static bool _isUsablePreferred(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final lower = url.toLowerCase();
    return !lower.contains('robohash') && !lower.contains('dicebear');
  }

  static Future<String?> _fetchSportsDbImage(String playerName) async {
    final uri = Uri.parse(
      'https://www.thesportsdb.com/api/v1/json/3/searchplayers.php?p=${Uri.encodeComponent(playerName)}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final players = decoded['player'] as List<dynamic>?;
      if (players == null || players.isEmpty) {
        return null;
      }

      for (final entry in players) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }

        final image = _firstNotEmpty([
          entry['strCutout'] as String?,
          entry['strRender'] as String?,
          entry['strThumb'] as String?,
        ]);

        if (image != null) {
          return image;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<String?> _fetchWikipediaImage(String playerName) async {
    final normalized = playerName.trim().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isEmpty) {
      return null;
    }

    final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$normalized');

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = decoded['thumbnail'] as Map<String, dynamic>?;
      final source = thumbnail == null ? null : thumbnail['source'] as String?;
      if (source == null || source.trim().isEmpty) {
        return null;
      }
      return source.trim();
    } catch (_) {
      return null;
    }
  }

  static List<String> _queryCandidates(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'\bJr\.?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final values = <String>{};
    if (name.trim().isNotEmpty) {
      values.add(name.trim());
    }
    if (cleaned.isNotEmpty) {
      values.add(cleaned);
    }

    final parts = cleaned.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      values.add('${parts.first} ${parts.last}');
      values.add(parts.last);
    }

    return values.toList();
  }

  static String? _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
