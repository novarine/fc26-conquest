import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';
import '../models/bracket_state.dart';
import '../models/campaign_state.dart';
import '../models/wheel_preset.dart';
import 'app_logger.dart';

class StorageService {
  static const _campaignKey = 'fc26_conquest_campaign';
  static const _bracketKey = 'fc26_conquest_bracket';
  static const _wheelPresetsKey = 'custom_wheel_presets_v1';
  static const _wheelPresetsSeededKey = 'custom_wheel_presets_seeded_v1';
  static const _languageKey = 'fc26_ui_language';

  Future<void> saveCampaign(CampaignState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_campaignKey, jsonEncode(state.toJson()));
  }

  Future<CampaignState?> loadCampaign() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_campaignKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return CampaignState.fromJson(decoded);
  }

  Future<void> clearCampaign() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_campaignKey);
  }

  Future<void> saveBracket(BracketState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_bracketKey, jsonEncode(state.toJson()));
  }

  Future<BracketState?> loadBracket() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_bracketKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return BracketState.fromJson(decoded);
    } catch (exception, stackTrace) {
      await AppLogger.instance.error(
        'StorageService',
        'Failed to decode stored bracket; leaving raw data untouched',
        error: exception,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clearBracket() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_bracketKey);
  }

  Future<List<WheelPreset>> loadWheelPresets() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_wheelPresetsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => WheelPreset.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (exception, stackTrace) {
      // Never overwrite unreadable data here: surface it as empty for this
      // read, but leave the raw value in SharedPreferences untouched so a
      // future app version (or manual recovery) can still read it back.
      await AppLogger.instance.error(
        'StorageService',
        'Failed to decode stored custom wheel presets; leaving raw data untouched',
        error: exception,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<void> saveWheelPresets(List<WheelPreset> presets) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(presets.map((preset) => preset.toJson()).toList());
    await preferences.setString(_wheelPresetsKey, encoded);
  }

  /// Whether the one-time example wheel presets have already been seeded.
  /// Used so a legitimately empty list (user deleted everything) is never
  /// mistaken for "first run" and re-seeded, which would risk clobbering
  /// data if this were ever checked instead of a dedicated flag.
  Future<bool> hasSeededWheelPresets() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_wheelPresetsSeededKey) ?? false;
  }

  Future<void> markWheelPresetsSeeded() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_wheelPresetsSeededKey, true);
  }

  Future<AppLanguage> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_languageKey);
    return raw == 'en' ? AppLanguage.en : AppLanguage.de;
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language.name);
  }
}
