import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../theme.dart' show AppBrightness, AppThemeId;
import 'storage.dart';

/// Jak se volí strana karty, která se ukáže jako první.
enum DirectionMode { auto, nativeFront, learnedFront }

/// Jak se představují nová slova: ukázat s překladem, nebo se nejdřív zkusit vybavit.
enum NewWordMode { introduce, recall }

/// Nastavení jednoho kurzu (jazyka). Každý kurz má své vlastní.
class CourseSettings {
  DirectionMode directionMode;

  /// V automatickém režimu: pravděpodobnost, že se při opakování ukáže jako první rodné slovo.
  double nativeFrontProb;

  /// Denní cíl v kartách (zopakované + naučené).
  int dailyGoal;

  /// Cíl nových slov za den (dokončená 3 učící kola). Neovlivňuje sérii, jen graf.
  int newWordsGoal;

  /// Představit nové slovo s překladem, nebo hned zkusit vybavit (flashcard).
  NewWordMode newWordMode;

  /// Skrýt vulgární slova (vulgar=1). Výchozí je zapnuto.
  bool hideVulgar;

  CourseSettings({
    this.directionMode = DirectionMode.auto,
    this.nativeFrontProb = 0.65,
    this.dailyGoal = 20,
    this.newWordsGoal = 5,
    this.newWordMode = NewWordMode.introduce,
    this.hideVulgar = true,
  });

  CourseSettings copy() => CourseSettings.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'dir': directionMode.index,
        'p': nativeFrontProb,
        'goal': dailyGoal,
        'ngoal': newWordsGoal,
        'nwm': newWordMode.index,
        'vul': hideVulgar ? 1 : 0,
      };

  factory CourseSettings.fromJson(Map<String, dynamic> m) => CourseSettings(
        directionMode: DirectionMode
            .values[((m['dir'] as num?)?.toInt() ?? 0).clamp(0, 2)],
        nativeFrontProb:
            ((m['p'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0),
        dailyGoal: ((m['goal'] as num?)?.toInt() ?? 20).clamp(5, 100),
        newWordsGoal: ((m['ngoal'] as num?)?.toInt() ?? 5).clamp(1, 50),
        newWordMode: NewWordMode
            .values[((m['nwm'] as num?)?.toInt() ?? 0).clamp(0, 1)],
        hideVulgar: ((m['vul'] as num?)?.toInt() ?? 1) == 1,
      );
}

/// Nastavení celé aplikace. Věci, které se liší podle jazyka (cíle, režim
/// nových slov, vulgární slova, směr karet), jsou v [CourseSettings].
class AppSettings {
  /// Naposledy zvolený kurz (jazyk); null = ještě nezvolen (první spuštění).
  String? courseId;

  /// Nastavení jednotlivých kurzů (klíč = id kurzu).
  final Map<String, CourseSettings> courses;

  /// Jen při přechodu ze starého souboru (jedno společné nastavení): z něj se
  /// naplní kurzy, které ještě své nastavení nemají. Neukládá se.
  final CourseSettings? _legacy;

  /// Lehké vibrace při swipu.
  bool haptics;

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

  /// Jednorázová vysvětlení: tlačítko "Neučit" a žárovka s tipy při učení.
  bool seenExcludeHelp;
  bool seenTipsHelp;

  AppSettings({
    this.courseId,
    Map<String, CourseSettings>? courses,
    CourseSettings? legacy,
    this.haptics = true,
    this.theme = AppThemeId.classic,
    this.appearance = AppBrightness.system,
    this.showTips = true,
    this.reminderEnabled = false,
    this.reminderMinutes = 20 * 60,
    this.seenExcludeHelp = false,
    this.seenTipsHelp = false,
  })  : courses = courses ?? {},
        _legacy = legacy;

  /// Nastavení kurzu [id]. Pokud ještě neexistuje, vznikne (ze starého
  /// společného nastavení, jinak z výchozích hodnot).
  CourseSettings forCourse(String id) =>
      courses.putIfAbsent(id, () => _legacy?.copy() ?? CourseSettings());

  /// Založí nastavení všem kurzům (při prvním spuštění po přechodu).
  void ensureCourses(Iterable<String> ids) {
    for (final id in ids) {
      forCourse(id);
    }
  }

  Map<String, dynamic> toJson() => {
        'course': courseId,
        'cs': {for (final e in courses.entries) e.key: e.value.toJson()},
        'hap': haptics ? 1 : 0,
        'thm': theme.index,
        'app': appearance.index,
        'tips': showTips ? 1 : 0,
        'rem': reminderEnabled ? 1 : 0,
        'remt': reminderMinutes,
        'sxh': seenExcludeHelp ? 1 : 0,
        'sth': seenTipsHelp ? 1 : 0,
      };

  factory AppSettings.fromJson(Map<String, dynamic> m) {
    final cs = m['cs'];
    final courses = <String, CourseSettings>{};
    if (cs is Map) {
      cs.forEach((k, v) {
        if (k is String && v is Map) {
          courses[k] = CourseSettings.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }
    return AppSettings(
      courseId: m['course'] as String?,
      courses: courses,
      // starý soubor: společné hodnoty ve stejných klíčích na nejvyšší úrovni
      legacy: cs == null ? CourseSettings.fromJson(m) : null,
      haptics: ((m['hap'] as num?)?.toInt() ?? 1) == 1,
      theme: AppThemeId
          .values[((m['thm'] as num?)?.toInt() ?? 0).clamp(0, AppThemeId.values.length - 1)],
      appearance: AppBrightness
          .values[((m['app'] as num?)?.toInt() ?? 0).clamp(0, AppBrightness.values.length - 1)],
      showTips: ((m['tips'] as num?)?.toInt() ?? 1) == 1,
      reminderEnabled: ((m['rem'] as num?)?.toInt() ?? 0) == 1,
      reminderMinutes:
          ((m['remt'] as num?)?.toInt() ?? 20 * 60).clamp(0, 1439),
      seenExcludeHelp: ((m['sxh'] as num?)?.toInt() ?? 0) == 1,
      seenTipsHelp: ((m['sth'] as num?)?.toInt() ?? 0) == 1,
    );
  }
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
