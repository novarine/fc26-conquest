import 'package:flutter_test/flutter_test.dart';

import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/utils/team_filter.dart';

const _teams = [
  Team(
    id: 1,
    name: 'Alpha FC',
    type: TeamType.club,
    rating: 90,
    logo: '',
    primaryColor: '#000000',
    league: 'Premier League',
    country: 'England',
  ),
  Team(
    id: 2,
    name: 'Beta FC',
    type: TeamType.club,
    rating: 70,
    logo: '',
    primaryColor: '#000000',
    league: 'Bundesliga',
    country: 'Germany',
  ),
  Team(
    id: 3,
    name: 'Gamma FC',
    type: TeamType.club,
    rating: 60,
    logo: '',
    primaryColor: '#000000',
    league: 'Premier League',
    country: 'England',
  ),
  Team(
    id: 4,
    name: 'Delta FC',
    type: TeamType.club,
    rating: 88,
    logo: '',
    primaryColor: '#000000',
    league: 'Ligue 1',
    country: 'France',
    licensedInFc26: false,
  ),
];

void main() {
  group('filterTeams', () {
    test('returns all teams when no filters are set', () {
      expect(filterTeams(_teams).length, 4);
    });

    test('filters by league', () {
      final result = filterTeams(_teams, league: 'Premier League');
      expect(result.map((team) => team.id), containsAll([1, 3]));
      expect(result.length, 2);
    });

    test('filters by country', () {
      final result = filterTeams(_teams, country: 'Germany');
      expect(result.single.id, 2);
    });

    test('filters by rating range', () {
      final result = filterTeams(_teams, minRating: 65, maxRating: 95);
      expect(result.map((team) => team.id), containsAll([1, 2, 4]));
      expect(result.length, 3);
    });

    test('combines filters and can return an empty list', () {
      final result = filterTeams(_teams, league: 'Bundesliga', minRating: 80);
      expect(result, isEmpty);
    });

    test('licensedOnly excludes teams not licensed in FC 26', () {
      final result = filterTeams(_teams, licensedOnly: true);
      expect(result.map((team) => team.id), containsAll([1, 2, 3]));
      expect(result.any((team) => team.id == 4), isFalse);
    });
  });
}
