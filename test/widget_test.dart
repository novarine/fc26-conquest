import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:fc26_conquest/models/campaign_setup.dart';
import 'package:fc26_conquest/screens/home_screen.dart';

void main() {
  testWidgets('home screen shows campaign actions', (WidgetTester tester) async {
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
          onNewCampaign: (CampaignSetup setup) async {},
          onContinue: () {},
          onOpenCustomWheel: () {},
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
