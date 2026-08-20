import 'package:flutter_test/flutter_test.dart';

import 'package:fc26_conquest/localization/app_strings.dart';

void main() {
  group('AppStrings', () {
    test('returns German text by default language', () {
      const strings = AppStrings(AppLanguage.de);
      expect(strings.newCampaignButton, 'Neue Kampagne');
      expect(strings.cancelButton, 'Abbrechen');
    });

    test('returns English text when switched', () {
      const strings = AppStrings(AppLanguage.en);
      expect(strings.newCampaignButton, 'New campaign');
      expect(strings.cancelButton, 'Cancel');
    });

    test('parameterized strings interpolate correctly in both languages', () {
      const de = AppStrings(AppLanguage.de);
      const en = AppStrings(AppLanguage.en);
      expect(de.regionsLabel(3), 'Regionen: 3');
      expect(en.regionsLabel(3), 'Regions: 3');
      expect(de.teamCountLabel(4, 8), contains('4'));
      expect(en.teamCountLabel(4, 8), contains('4'));
    });
  });
}
