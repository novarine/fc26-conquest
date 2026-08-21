import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/services/seed_data_service.dart';
import 'package:fc26_conquest/widgets/team_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('team logo regression', () {
    test('valid logo URLs are preserved and malformed ones are rejected', () {
      expect(
        Team.normalizeLogo(
            'https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/250px-Liverpool_FC.svg.png'),
        isNotEmpty,
      );
      expect(
        Team.normalizeLogo('https://example.com/not-a-logo-file'),
        isEmpty,
      );
      expect(Team.normalizeLogo(''), isEmpty);
      expect(Team.normalizeLogo(null), isEmpty);
    });

    test(
        'stale cached team data is rejected and reloaded from the fresh seed set',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'fc26_catalog_teams',
        jsonEncode([
          {
            'id': 1,
            'name': 'Old Club',
            'type': 'club',
            'rating': 70,
            'logo': 'https://example.com/old-club.png',
            'primaryColor': '#ff0000'
          },
        ]),
      );
      await prefs.setInt('fc26_catalog_teams_version', 7);

      final teams = await const SeedDataService().loadTeams();

      expect(teams, isNotEmpty);
      expect(teams.any((team) => team.name == 'Old Club'), isFalse);
      expect(teams.every((team) => Team.isValidLogo(team.logo)), isTrue);
    });

    test('seed data contains usable club logo URLs for every team', () async {
      final teams = await const SeedDataService().loadTeams();

      expect(teams, isNotEmpty);

      for (final team in teams) {
        expect(team.logo, isNotEmpty, reason: '${team.name} has no logo URL');
        expect(
          Team.isValidLogo(team.logo),
          isTrue,
          reason:
              '${team.name} has an invalid or unsafe logo URL: ${team.logo}',
        );
      }
    });

    test('club mode supports all 40 club teams in a campaign', () async {
      final teams = await const SeedDataService().loadTeams();
      final clubs = teams.where((team) => team.type == TeamType.club).toList();

      expect(clubs.length, 40,
          reason:
              'The club seed must contain all 40 clubs for the full-size campaign mode.');
      expect(clubs.every((team) => Team.isValidLogo(team.logo)), isTrue,
          reason:
              'Every club logo must be valid when selecting the full 40-club set.');
    });

    test('every club logo is a bundled local asset, never a live remote URL',
        () async {
      final teams = await const SeedDataService().loadTeams();
      final clubs = teams.where((team) => team.type == TeamType.club).toList();

      expect(clubs.length, 40,
          reason: 'Expected all 40 clubs to be present in the seed data.');

      for (final team in clubs) {
        expect(
          team.logo.startsWith('assets/logos/'),
          isTrue,
          reason:
              '${team.name} must use a locally bundled asset logo (found "${team.logo}"). '
              'Live remote URLs (e.g. Wikimedia) are unreliable at runtime and must not be used for club badges.',
        );

        final file = File(team.logo);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${team.name} references "${team.logo}" but that file does not exist under assets/logos/.',
        );
        expect(
          file.lengthSync(),
          greaterThan(500),
          reason:
              '${team.name} logo asset "${team.logo}" is empty or corrupted.',
        );
      }
    });

    testWidgets(
        'invalid external logo renders a deterministic local fallback badge',
        (tester) async {
      final team = Team(
        id: 999,
        name: 'Manchester City',
        type: TeamType.club,
        rating: 90,
        logo: 'https://example.com/not-real-logo.svg',
        primaryColor: '#6CABDD',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TeamBadge(team: team, size: 64),
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });
}
