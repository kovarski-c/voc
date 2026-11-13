import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'storage.dart';

/// Jak se volí strana karty, která se ukáže jako první.
enum DirectionMode { auto, nativeFront, learnedFront }

class AppSettings {
  DirectionMode directionMode;

  /// V automatickém režimu: pravděpodobnost, že se při opakování ukáže jako první rodné slovo.
  double nativeFrontProb;

  /// Naposledy zvolený kurz (jazyk); null = ještě nezvolen (první spuštění).
  String? courseId;

  /// Denní cíl v kartách (zopakované + naučené).
  int dailyGoal;

  /// Lehké vibrace při swipu.
  bool haptics;

  /// Skrýt vulgární slova (vulgar=1). Výchozí je zapnuto.
  bool hideVulgar;

  AppSettings({
    this.directionMode = DirectionMode.auto,
    this.nativeFrontProb = 0.65,
    this.courseId,
    this.dailyGoal = 20,
    this.haptics = true,
    this.hideVulgar = true,
  });

  Map<String, dynamic> toJson() => {
        'dir': directionMode.index,
        'p': nativeFrontProb,
        'course': courseId,
        'goal': dailyGoal,
        'hap': haptics ? 1 : 0,
        'vul': hideVulgar ? 1 : 0,
      };

  factory AppSettings.fromJson(Map<String, dynamic> m) => AppSettings(
        directionMode: DirectionMode
            .values[((m['dir'] as num?)?.toInt() ?? 0).clamp(0, 2)],
        nativeFrontProb:
            ((m['p'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0),
        courseId: m['course'] as String?,
        dailyGoal: ((m['goal'] as num?)?.toInt() ?? 20).clamp(5, 100),
        haptics: ((m['hap'] as num?)?.toInt() ?? 1) == 1,
        hideVulgar: ((m['vul'] as num?)?.toInt() ?? 1) == 1,
      );
}

class SettingsStore {
  static const _name = 'settings.json';

  static Future<AppSettings> load() async {
    try {
      final text = await Storage.read(_name);
      if (text == null) return AppSettings();
      return AppSettings.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Načtení nastavení selhalo: $e');
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings s) async {
    try {
      await Storage.write(_name, jsonEncode(s.toJson()));
    } catch (e) {
      debugPrint('Uložení nastavení selhalo: $e');
    }
  }
}
