import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:fc26_conquest/localization/app_strings.dart';
import 'package:fc26_conquest/models/campaign_setup.dart';
import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/screens/home_screen.dart';

const _sampleTeams = [
  Team(
    id: 1,
    name: 'Test FC',
    type: TeamType.club,
    rating: 80,
    logo: '',
    primaryColor: '#123456',
    league: 'Test League',
    country: 'Testland',
  ),
  Team(
    id: 2,
    name: 'Other FC',
    type: TeamType.club,
    rating: 75,
    logo: '',
    primaryColor: '#654321',
    league: 'Test League',
    country: 'Testland',
  ),
  Team(
    id: 101,
    name: 'Testnation',
    type: TeamType.nation,
    rating: 82,
    logo: '',
    primaryColor: '#111111',
  ),
  Team(
    id: 102,
    name: 'Otherland',
    type: TeamType.nation,
    rating: 78,
    logo: '',
    primaryColor: '#222222',
  ),
];

void main() {
  testWidgets('home screen shows campaign actions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          hasCampaign: false,
          availableClubTeams: 10,
          availableNationTeams: 8,
          teams: _sampleTeams,
          strings: const AppStrings(AppLanguage.de),
          onNewCampaign: (CampaignSetup setup) async {},
          onContinue: () {},
          onOpenCustomWheel: () {},
          onOpenBracketMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FC 26 Conquest'), findsOneWidget);
    expect(find.text('Neue Kampagne'), findsOneWidget);
    expect(find.text('Kampagne fortsetzen'), findsOneWidget);
    expect(find.text('Zufallsrad-Werkzeug'), findsOneWidget);
  });
}
