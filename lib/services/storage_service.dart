import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';
import '../models/campaign_state.dart';
import '../models/wheel_preset.dart';

class StorageService {
  static const _campaignKey = 'fc26_conquest_campaign';
  static const _wheelPresetsKey = 'custom_wheel_presets_v1';
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

  Future<List<WheelPreset>> loadWheelPresets() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_wheelPresetsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => WheelPreset.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveWheelPresets(List<WheelPreset> presets) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(presets.map((preset) => preset.toJson()).toList());
    await preferences.setString(_wheelPresetsKey, encoded);
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
