import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fc26_conquest/localization/app_strings.dart';
import 'package:fc26_conquest/models/wheel_preset.dart';
import 'package:fc26_conquest/services/storage_service.dart';

void main() {
  group('WheelPreset', () {
    test('round-trips through JSON', () {
      const preset = WheelPreset(
        id: 'p1',
        name: 'Formationen',
        entries: ['4-3-3', '4-4-2'],
      );

      final decoded = WheelPreset.fromJson(preset.toJson());

      expect(decoded.id, preset.id);
      expect(decoded.name, preset.name);
      expect(decoded.entries, preset.entries);
    });
  });

  group('StorageService wheel presets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns an empty list when nothing is stored', () async {
      final storage = StorageService();
      final presets = await storage.loadWheelPresets();
      expect(presets, isEmpty);
    });

    test('persists and reloads presets without affecting campaign storage', () async {
      final storage = StorageService();
      const presets = [
        WheelPreset(id: 'a', name: 'Rad A', entries: ['1', '2']),
        WheelPreset(id: 'b', name: 'Rad B', entries: ['x', 'y', 'z']),
      ];

      await storage.saveWheelPresets(presets);
      final reloaded = await storage.loadWheelPresets();

      expect(reloaded.length, 2);
      expect(reloaded[0].name, 'Rad A');
      expect(reloaded[1].entries, ['x', 'y', 'z']);
      expect(await storage.loadCampaign(), isNull);
    });
  });

  group('StorageService language', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to German when nothing is stored', () async {
      final storage = StorageService();
      expect(await storage.loadLanguage(), AppLanguage.de);
    });

    test('persists and reloads the selected language', () async {
      final storage = StorageService();
      await storage.saveLanguage(AppLanguage.en);
      expect(await storage.loadLanguage(), AppLanguage.en);
    });
  });
}
