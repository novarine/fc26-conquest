import '../utils/team_logo_resolver.dart';

enum TeamType { club, nation }

class Team {
  const Team({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.logo,
    required this.primaryColor,
    this.secondaryColor,
    this.league,
    this.country,
  });

  final int id;
  final String name;
  final TeamType type;
  final int rating;
  final String logo;
  final String primaryColor;
  final String? secondaryColor;
  final String? league;
  final String? country;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      type: _teamTypeFromString(json['type'] as String? ?? 'club'),
      rating: json['rating'] as int,
      logo: normalizeLogo(json['logo'] as String?),
      primaryColor: json['primaryColor'] as String? ?? '#666666',
      secondaryColor: json['secondaryColor'] as String?,
      league: json['league'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rating': rating,
      'logo': logo,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'league': league,
      'country': country,
    };
  }

  static TeamType _teamTypeFromString(String value) {
    return TeamType.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => TeamType.club,
    );
  }

  static String normalizeLogo(String? value) {
    return TeamLogoResolver.normalizeLogo(value);
  }

  static bool isValidLogo(String? value) {
    return TeamLogoResolver.isValidLogo(value);
  }
}
