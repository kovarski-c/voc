import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Jak se volí strana karty, která se ukáže jako první.
enum DirectionMode { auto, nativeFront, learnedFront }

class AppSettings {
  DirectionMode directionMode;

  /// V automatickém režimu: pravděpodobnost, že se při opakování ukáže jako první rodné slovo.
  double nativeFrontProb;

  /// Naposledy zvolený kurz (jazyk); null = ještě nezvolen (první spuštění).
  String? courseId;

  AppSettings({
    this.directionMode = DirectionMode.auto,
    this.nativeFrontProb = 0.65,
    this.courseId,
  });

  Map<String, dynamic> toJson() => {
        'dir': directionMode.index,
        'p': nativeFrontProb,
        'course': courseId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> m) => AppSettings(
        directionMode: DirectionMode
            .values[((m['dir'] as num?)?.toInt() ?? 0).clamp(0, 2)],
        nativeFrontProb:
            ((m['p'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0),
        courseId: m['course'] as String?,
      );
}

class SettingsStore {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }

  static Future<AppSettings> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return AppSettings();
      return AppSettings.fromJson(
          jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Načtení nastavení selhalo: $e');
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings s) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(s.toJson()), flush: true);
    } catch (e) {
      debugPrint('Uložení nastavení selhalo: $e');
    }
  }
}
