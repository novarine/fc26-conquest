class TeamLogoResolver {
  static const Set<String> _allowedHosts = {
    'upload.wikimedia.org',
    'commons.wikimedia.org',
    'flagcdn.com',
  };

  static String normalizeLogo(String? value) {
    if (value == null) {
      return '';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return '';
    }

    final host = uri.host.toLowerCase();
    if (!_allowedHosts.contains(host)) {
      return '';
    }

    final lowerPath = uri.path.toLowerCase();
    final hasImageExtension = lowerPath.contains('.png') ||
        lowerPath.contains('.svg') ||
        lowerPath.contains('.jpg') ||
        lowerPath.contains('.jpeg');
    if (!hasImageExtension) {
      return '';
    }

    return trimmed;
  }

  static bool isValidLogo(String? value) {
    return normalizeLogo(value).isNotEmpty;
  }

  static List<String> candidateUrls(String? value) {
    final normalized = normalizeLogo(value);
    if (normalized.isEmpty) {
      return const [];
    }

    final candidates = <String>{normalized};
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return candidates.toList();
    }

    final path = uri.path;
    if (path.toLowerCase().endsWith('.svg')) {
      final pngThumb = _wikimediaSvgThumbToPng(normalized);
      if (pngThumb != null && pngThumb.isNotEmpty) {
        candidates.add(pngThumb);
      }
    }

    return candidates.toList();
  }

  static String fallbackBadgeSvg(String teamName, String primaryColorHex) {
    final initials = _initials(teamName);
    final safeColor = _safeHexColor(primaryColorHex);
    return '''
      <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
        <defs>
          <clipPath id="crestClip">
            <circle cx="64" cy="64" r="52" />
          </clipPath>
        </defs>
        <circle cx="64" cy="64" r="52" fill="$safeColor" />
        <circle cx="64" cy="64" r="44" fill="rgba(255,255,255,0.12)"/>
        <g clip-path="url(#crestClip)">
          <rect x="12" y="12" width="104" height="104" fill="rgba(255,255,255,0.08)"/>
        </g>
        <text x="64" y="74" text-anchor="middle" font-size="36" font-weight="900" fill="#ffffff" font-family="Arial, sans-serif">$initials</text>
      </svg>
    ''';
  }

  static String _safeHexColor(String? value) {
    final color = (value ?? '#0EA5E9').trim();
    if (color.startsWith('#') && color.length == 7) {
      return color;
    }
    return '#0EA5E9';
  }

  static String _initials(String teamName) {
    final parts = teamName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'FC';
    }

    if (parts.length == 1) {
      final value = parts.first;
      if (value.length <= 2) {
        return value.substring(0, value.length).toUpperCase();
      }
      return value.substring(0, 2).toUpperCase();
    }

    final first = parts.first.trim();
    final last = parts.last.trim();
    return '${first[0]}${last[0]}'.toUpperCase();
  }

  static String? _wikimediaSvgThumbToPng(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('wikimedia.org')) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty || !segments.last.toLowerCase().endsWith('.svg')) {
      return null;
    }

    final fileName = segments.last;
    if (segments.length < 3) {
      return null;
    }

    final namespacePath = segments.sublist(0, 2).join('/');
    final hashPath = segments.sublist(2, segments.length - 1).join('/');
    final encodedFile = Uri.encodeComponent(fileName);
    return 'https://upload.wikimedia.org/$namespacePath/thumb/$hashPath/$encodedFile/256px-$encodedFile.png';
  }
}
