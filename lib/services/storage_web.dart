import 'package:shared_preferences/shared_preferences.dart';

/// Úložiště pro web: localStorage prohlížeče. Jméno souboru je klíč.
class Storage {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String?> read(String name) async =>
      (await _prefs).getString(name);

  static Future<void> write(String name, String text) async {
    await (await _prefs).setString(name, text);
  }

  static Future<void> delete(String name) async {
    await (await _prefs).remove(name);
  }

  static Future<List<String>> names() async =>
      (await _prefs).getKeys().toList();
}
