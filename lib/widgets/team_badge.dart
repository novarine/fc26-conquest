import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../models/team.dart';
import '../utils/color_utils.dart';
import '../utils/team_logo_resolver.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.team,
    this.size = 56,
    this.showBanner = false,
    this.showFrame = false,
  });

  final Team team;
  final double size;
  final bool showBanner;
  final bool showFrame;

  static final Map<String, String?> _svgCache = <String, String?>{};

  @override
  Widget build(BuildContext context) {
    final baseColor = parseHexColor(team.primaryColor);
    final crest = SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: size,
          height: size,
          child: _buildLogo(baseColor),
        ),
      ),
    );

    final badge = SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.24),
              blurRadius: size * 0.18,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: crest,
      ),
    );

    if (!showBanner) {
      return badge;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamBadge(team: team, size: size),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              team.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color baseColor) {
    if (!Team.isValidLogo(team.logo)) {
      return _generatedBadge(baseColor);
    }

    final lower = team.logo.toLowerCase();
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');

    if (team.logo.startsWith('http://') || team.logo.startsWith('https://')) {
      final rasterFallback = _preferredRasterUrl(team.logo);
      if (isSvg) {
        if (kIsWeb) {
          return _networkRaster(rasterFallback ?? team.logo, baseColor, withGeneratedFallback: true);
        }

        return FutureBuilder<String?>(
          future: _loadValidatedSvg(team.logo),
          builder: (context, snapshot) {
            final svg = snapshot.data;
            if (svg != null && svg.isNotEmpty) {
              return SvgPicture.string(
                svg,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _generatedBadge(baseColor),
              );
            }

            final fallbackUrl = rasterFallback ?? _wikimediaSvgPngThumbUrl(team.logo);
            if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
              return _networkRaster(fallbackUrl, baseColor, withGeneratedFallback: true);
            }

            return _generatedBadge(baseColor);
          },
        );
      }

      return _networkRaster(rasterFallback ?? team.logo, baseColor, withGeneratedFallback: true);
    }

    if (isSvg) {
      return SvgPicture.asset(
        team.logo,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _generatedBadge(baseColor),
      );
    }

    return Image.asset(
      team.logo,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _generatedBadge(baseColor),
    );
  }

  String? _preferredRasterUrl(String url) {
    final wikimediaPng = _wikimediaSvgPngThumbUrl(url);
    if (wikimediaPng != null && wikimediaPng.isNotEmpty) {
      return wikimediaPng;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final lower = uri.path.toLowerCase();
    if (lower.endsWith('.svg')) {
      return lower.replaceFirst('.svg', '.png');
    }

    return null;
  }

  Widget _networkRaster(String url, Color baseColor, {bool withGeneratedFallback = false}) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => withGeneratedFallback ? _generatedBadge(baseColor) : _fallbackLabel(baseColor),
    );
  }

  Widget _generatedBadge(Color baseColor) {
    final argb = baseColor.toARGB32();
    final hex = '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
    final svg = TeamLogoResolver.fallbackBadgeSvg(team.name, hex);
    return SvgPicture.string(
      svg,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _fallbackLabel(baseColor),
    );
  }

  static Future<String?> _loadValidatedSvg(String url) async {
    if (_svgCache.containsKey(url)) {
      return _svgCache[url];
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _svgCache[url] = null;
        return null;
      }

      final body = response.body;
      final normalized = body.trimLeft();
      final looksLikeSvg = normalized.startsWith('<svg') || normalized.startsWith('<?xml');
      if (!looksLikeSvg || !body.contains('</svg>')) {
        _svgCache[url] = null;
        return null;
      }

      _svgCache[url] = body;
      return body;
    } catch (_) {
      _svgCache[url] = null;
      return null;
    }
  }

  String? _wikimediaSvgPngThumbUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('upload.wikimedia.org')) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      return null;
    }

    final fileName = segments.last;
    if (!fileName.toLowerCase().endsWith('.svg')) {
      return null;
    }

    if (segments.length < 3) {
      return null;
    }

    final namespacePath = segments.sublist(0, 2).join('/');
    final hashPath = segments.sublist(2, segments.length - 1).join('/');
    final encodedFile = Uri.encodeComponent(fileName);
    return 'https://upload.wikimedia.org/$namespacePath/thumb/$hashPath/$encodedFile/256px-$encodedFile.png';
  }

  Widget _fallbackLabel(Color baseColor) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: size * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: baseColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          _initials(team.name),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * 0.26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: baseColor,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'FC';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}