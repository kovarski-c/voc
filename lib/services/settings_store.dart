import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../theme.dart' show AppBrightness, AppThemeId;
import 'storage.dart';

/// Jak se volí strana karty, která se ukáže jako první.
enum DirectionMode { auto, nativeFront, learnedFront }

/// Jak se představují nová slova: ukázat s překladem, nebo se nejdřív zkusit vybavit.
enum NewWordMode { introduce, recall }

class AppSettings {
  DirectionMode directionMode;

  /// V automatickém režimu: pravděpodobnost, že se při opakování ukáže jako první rodné slovo.
  double nativeFrontProb;

  /// Naposledy zvolený kurz (jazyk); null = ještě nezvolen (první spuštění).
  String? courseId;

  /// Denní cíl v kartách (zopakované + naučené).
  int dailyGoal;

  /// Cíl nových slov za den (dokončená 3 učící kola). Neovlivňuje sérii, jen graf.
  int newWordsGoal;

  /// Představit nové slovo s překladem, nebo hned zkusit vybavit (flashcard).
  NewWordMode newWordMode;

  /// Lehké vibrace při swipu.
  bool haptics;

  /// Skrýt vulgární slova (vulgar=1). Výchozí je zapnuto.
  bool hideVulgar;

  /// Barevné schéma.
  AppThemeId theme;

  /// Světlý / tmavý režim (výchozí podle systému).
  AppBrightness appearance;

  /// Zobrazovat denní tip na domovské stránce.
  bool showTips;

  /// Denní připomínka, aby se neztratila série (jen Android).
  bool reminderEnabled;

  /// Čas připomínky v minutách od půlnoci (výchozí 20:00).
  int reminderMinutes;

  AppSettings({
    this.directionMode = DirectionMode.auto,
    this.nativeFrontProb = 0.65,
    this.courseId,
    this.dailyGoal = 20,
    this.newWordsGoal = 5,
    this.newWordMode = NewWordMode.introduce,
    this.haptics = true,
    this.hideVulgar = true,
    this.theme = AppThemeId.classic,
    this.appearance = AppBrightness.system,
    this.showTips = true,
    this.reminderEnabled = false,
    this.reminderMinutes = 20 * 60,
  });

  Map<String, dynamic> toJson() => {
        'dir': directionMode.index,
        'p': nativeFrontProb,
        'course': courseId,
        'goal': dailyGoal,
        'ngoal': newWordsGoal,
        'nwm': newWordMode.index,
        'hap': haptics ? 1 : 0,
        'vul': hideVulgar ? 1 : 0,
        'thm': theme.index,
        'app': appearance.index,
        'tips': showTips ? 1 : 0,
        'rem': reminderEnabled ? 1 : 0,
        'remt': reminderMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> m) => AppSettings(
        directionMode: DirectionMode
            .values[((m['dir'] as num?)?.toInt() ?? 0).clamp(0, 2)],
        nativeFrontProb:
            ((m['p'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0),
        courseId: m['course'] as String?,
        dailyGoal: ((m['goal'] as num?)?.toInt() ?? 20).clamp(5, 100),
        newWordsGoal: ((m['ngoal'] as num?)?.toInt() ?? 5).clamp(1, 50),
        newWordMode: NewWordMode
            .values[((m['nwm'] as num?)?.toInt() ?? 0).clamp(0, 1)],
        haptics: ((m['hap'] as num?)?.toInt() ?? 1) == 1,
        hideVulgar: ((m['vul'] as num?)?.toInt() ?? 1) == 1,
        theme: AppThemeId
            .values[((m['thm'] as num?)?.toInt() ?? 0).clamp(0, AppThemeId.values.length - 1)],
        appearance: AppBrightness
            .values[((m['app'] as num?)?.toInt() ?? 0).clamp(0, AppBrightness.values.length - 1)],
        showTips: ((m['tips'] as num?)?.toInt() ?? 1) == 1,
        reminderEnabled: ((m['rem'] as num?)?.toInt() ?? 0) == 1,
        reminderMinutes:
            ((m['remt'] as num?)?.toInt() ?? 20 * 60).clamp(0, 1439),
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
