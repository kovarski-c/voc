import 'dart:convert';

import 'storage.dart';

/// Obsah načtené zálohy.
class BackupData {
  final DateTime? exportedAt;
  final Map<String, Map<String, dynamic>> files;
  const BackupData(this.exportedAt, this.files);

  /// Kolik kurzů záloha obsahuje.
  int get courseCount => files.keys.where((k) => k.startsWith('progress_')).length;
}

/// Záloha = jeden JSON se všemi soubory aplikace (nastavení a postup kurzů).
class BackupService {
  static const _app = 'voc';
  static final _nameRe = RegExp(r'^(settings|progress_[A-Za-z0-9_\-]+)\.json$');

  static String fileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'voc-zaloha-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Poskládá zálohu ze všech uložených souborů aplikace.
  static Future<String> export() async {
    final files = <String, dynamic>{};
    for (final n in await Storage.names()) {
      if (!_nameRe.hasMatch(n)) continue;
      final text = await Storage.read(n);
      if (text == null) continue;
      try {
        files[n] = jsonDecode(text);
      } catch (_) {
        // poškozený soubor se do zálohy nedává
      }
    }
    return jsonEncode({
      'app': _app,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'files': files,
    });
  }

  /// Zkontroluje text zálohy. Při chybě vyhodí FormatException s českou zprávou.
  static BackupData parse(String text) {
    final Object? data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      throw const FormatException('Soubor není platná záloha.');
    }
    if (data is! Map || data['app'] != _app || data['files'] is! Map) {
      throw const FormatException('Tohle není záloha této aplikace.');
    }
    final files = <String, Map<String, dynamic>>{};
    (data['files'] as Map).forEach((k, v) {
      if (k is String && _nameRe.hasMatch(k) && v is Map) {
        files[k] = Map<String, dynamic>.from(v);
      }
    });
    if (!files.keys.any((k) => k.startsWith('progress_'))) {
      throw const FormatException('Záloha neobsahuje žádný postup.');
    }
    final at = DateTime.tryParse('${data['exportedAt']}');
    return BackupData(at, files);
  }

  /// Zapíše soubory ze zálohy (přepíše stávající stejného jména).
  static Future<void> restore(BackupData backup) async {
    for (final e in backup.files.entries) {
      await Storage.write(e.key, jsonEncode(e.value));
    }
  }
}
