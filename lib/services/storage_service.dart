import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign_state.dart';

class StorageService {
  static const _campaignKey = 'fc26_conquest_campaign';

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
}
