import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fc26_conquest/localization/app_strings.dart';
import 'package:fc26_conquest/models/campaign_state.dart';
import 'package:fc26_conquest/models/player.dart';
import 'package:fc26_conquest/models/region.dart';
import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/screens/map_screen.dart';

const _champion = Team(
  id: 1,
  name: 'Champion FC',
  type: TeamType.club,
  rating: 88,
  logo: '',
  primaryColor: '#123456',
  league: 'Test League',
  country: 'Testland',
);

void main() {
  testWidgets(
    'champion side panel scrolls instead of overflowing on a narrow phone screen',
    (WidgetTester tester) async {
      // Small, narrow phone-sized viewport so the map screen picks the
      // compact/mobile column layout (see MapScreen's `compact` breakpoint).
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final squad = List.generate(
        6,
        (i) => Player(
          id: 100 + i,
          name: 'Hero Player Number $i',
          position: 'ST',
          rating: 85,
          originTeamId: 1,
          currentTeamId: 1,
        ),
      );

      final campaign = CampaignState(
        id: 'test',
        mode: 'club',
        turn: 5,
        matchesPlayed: 5,
        regions: const [
          Region(id: 1, label: 'A', ownerId: 1, neighbors: []),
        ],
        players: squad,
        history: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(
            campaign: campaign,
            teams: const [_champion],
            remainingTeams: 1,
            champion: _champion,
            playerById: (id) => squad.where((p) => p.id == id).firstOrNull,
            attackableTeams: () => const [],
            defenderCandidates: (attackerId) => const [],
            strings: const AppStrings(AppLanguage.de),
            onSetBattlePairing: (attackerId, defenderId) async {},
            onOpenStats: () {},
            onResetCampaign: () async {},
          ),
        ),
      );

      // Let the champion celebration overlay dialog appear and dismiss it so
      // the persistent side panel underneath is what's under test. It has
      // repeating (confetti/glow) animations, so pump fixed durations instead
      // of pumpAndSettle (which would never settle).
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 2));
      final celebrateMore =
          find.text(const AppStrings(AppLanguage.de).celebrateMore);
      if (celebrateMore.evaluate().isNotEmpty) {
        await tester.tap(celebrateMore);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // No RenderFlex overflow (or any other) exception should have been thrown.
      expect(tester.takeException(), isNull);

      // The panel's own scroll view should let us reach content, regardless of
      // how little vertical space the compact layout's flex allotment gives it.
      final resetButtonFinder =
          find.text(const AppStrings(AppLanguage.de).startNewCampaignButton);
      expect(resetButtonFinder, findsWidgets);
      await tester.scrollUntilVisible(
        resetButtonFinder.first,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
