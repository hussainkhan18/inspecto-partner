import 'dart:convert';
import 'package:inspecto_shield_partner/models/addon_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddonsService {
  static const String _key = 'addons_json';

  static Future<void> saveAddons(Map<String, dynamic>? addons) async {
    final prefs = await SharedPreferences.getInstance();
    if (addons == null) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(addons));
  }

  static Future<Map<String, AddonInfo>> loadAddons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return {};

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          AddonInfo.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (e) {
      print('AddonsService.loadAddons error: $e');
      return {};
    }
  }
}
