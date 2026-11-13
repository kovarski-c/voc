import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Úložiště pro mobil a desktop: soubory v dokumentech aplikace.
class Storage {
  static Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  /// Obsah souboru, nebo null, když neexistuje.
  static Future<String?> read(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  /// Zapíše přes dočasný soubor, aby se při pádu nepoškodil původní.
  static Future<void> write(String name, String text) async {
    final f = await _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(f.path);
  }

  static Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }

  /// Jména všech uložených souborů.
  static Future<List<String>> names() async {
    final dir = await getApplicationDocumentsDirectory();
    final out = <String>[];
    await for (final e in dir.list()) {
      if (e is File) out.add(e.uri.pathSegments.last);
    }
    return out;
  }
}
