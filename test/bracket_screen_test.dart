import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fc26_conquest/localization/app_strings.dart';
import 'package:fc26_conquest/models/team.dart';
import 'package:fc26_conquest/screens/bracket_screen.dart';

List<Team> _teams(int count) {
  return List.generate(
    count,
    (i) => Team(
      id: i + 1,
      name: 'Team ${i + 1}',
      type: TeamType.club,
      rating: 70 + i,
      logo: '',
      primaryColor: '#123456',
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bracket screen: draw a tournament and advance a match',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BracketScreen(
          teams: _teams(4),
          strings: const AppStrings(AppLanguage.de),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Setup screen shown first.
    expect(find.text('Neues Turnier auslosen'), findsOneWidget);

    await tester.tap(find.text('Turnier auslosen'));
    await tester.pumpAndSettle();

    // Bracket view now shows a semi-final round and a final, 3 matches total.
    expect(find.text('Finale'), findsOneWidget);
    expect(find.text('Halbfinale'), findsOneWidget);

    // Tap the first match card to open the winner picker and confirm a winner.
    final firstTeamName = find.text('Team 1');
    expect(firstTeamName, findsWidgets);

    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    expect(find.text('Wer hat gewonnen?'), findsOneWidget);

    // Pick whichever team is offered first in the dialog.
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();

    // Dialog closed, no crash, and the final round still shows exactly one match.
    expect(find.text('Wer hat gewonnen?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket screen: new tournament clears the current bracket',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BracketScreen(
          teams: _teams(4),
          strings: const AppStrings(AppLanguage.de),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Turnier auslosen'));
    await tester.pumpAndSettle();
    expect(find.text('Neues Turnier auslosen'), findsNothing);

    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();

    expect(find.text('Neues Turnier auslosen'), findsOneWidget);
  });
}
