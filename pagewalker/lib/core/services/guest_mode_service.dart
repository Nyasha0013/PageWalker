import 'package:shared_preferences/shared_preferences.dart';

class GuestModeService {
  GuestModeService._();

  static const _guestKey = 'guest_mode_enabled';

  static Future<void> setGuestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, enabled);
  }

  static Future<bool> isGuestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestKey) ?? false;
  }
}
