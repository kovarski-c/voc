import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/card_progress.dart';
import 'scheduler.dart';

/// Ukládá pokrok jednoho kurzu do progress_<courseId>.json (verze 3).
/// Ukládají se jen karty, které už uživatel viděl (řídký formát).
/// Starší formáty (verze 2 a původní skills.json) se při načtení převedou.
class ProgressStore {
  ProgressStore(this.courseId);

  final String courseId;
  final Map<int, CardProgress> cards = {};

  // Denní statistika (studijní den začíná ve 4:00).
  int _dayId = 0;
  int _reviewed = 0;
  int _learned = 0;

  int get _today {
    final d = Scheduler.studyDate(DateTime.now());
    return d.year * 10000 + d.month * 100 + d.day;
  }

  int get reviewedToday => _dayId == _today ? _reviewed : 0;
  int get learnedToday => _dayId == _today ? _learned : 0;

  /// Volá se, když karta definitivně opustí frontu (zopakována / naučena).
  void recordDone(bool learned) {
    if (_dayId != _today) {
      _dayId = _today;
      _reviewed = 0;
      _learned = 0;
    }
    if (learned) {
      _learned++;
    } else {
      _reviewed++;
    }
    scheduleSave();
  }

  Timer? _timer;
  Future<void> _writing = Future.value();

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<void> load({bool migrateLegacy = false}) async {
    final file = await _file('progress_$courseId.json');
    if (await file.exists()) {
      try {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final version = (data['version'] as num?)?.toInt() ?? 2;
        final raw = (data['cards'] as Map<String, dynamic>?) ?? {};
        final daily = data['daily'] as Map<String, dynamic>?;
        if (daily != null) {
          _dayId = (daily['d'] as num?)?.toInt() ?? 0;
          _reviewed = (daily['r'] as num?)?.toInt() ?? 0;
          _learned = (daily['l'] as num?)?.toInt() ?? 0;
        }
        final now = DateTime.now();
        raw.forEach((k, v) {
          final i = int.parse(k);
          cards[i] = version >= 3
              ? CardProgress.fromJson(v)
              : Scheduler.fromLegacySkill(i, (v as List)[0] as int, now);
        });
        if (version < 3) {
          // záloha verze 2 a zápis nového formátu
          await file.copy('${file.path}.v2.bak');
          await flush();
        }
        return;
      } catch (e) {
        debugPrint('Poškozený soubor s pokrokem: $e');
        await file.rename('${file.path}.corrupt');
        cards.clear();
      }
    }
    if (migrateLegacy) await _migrateLegacy();
  }

  /// Převod z úplně starého skills.json (dva dlouhé seznamy skills a activations).
  Future<void> _migrateLegacy() async {
    try {
      final old = await _file('skills.json');
      if (!await old.exists()) return;
      final data = jsonDecode(await old.readAsString());
      final skills = List<int>.from(data['skills'] ?? const []);
      final acts = List<int>.from(data['activations'] ?? const []);
      if (skills.isEmpty || acts.isEmpty) return;

      final counts = <int, int>{};
      for (final a in acts) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
      final initial =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final now = DateTime.now();
      final n = skills.length < acts.length ? skills.length : acts.length;
      for (var i = 0; i < n; i++) {
        if (skills[i] > 0 || acts[i] != initial) {
          cards[i] = Scheduler.fromLegacySkill(i, skills[i], now);
        }
      }
      await flush();
    } catch (e) {
      debugPrint('Migrace starého pokroku selhala: $e');
    }
  }

  void scheduleSave() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), flush);
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    _writing = _writing.then((_) => _write());
    return _writing;
  }

  Future<void> _write() async {
    try {
      final file = await _file('progress_$courseId.json');
      final tmp = File('${file.path}.tmp');
      final json = jsonEncode({
        'version': 3,
        'daily': {'d': _dayId, 'r': _reviewed, 'l': _learned},
        'cards': {for (final e in cards.entries) '${e.key}': e.value.toJson()},
      });
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('Uložení pokroku selhalo: $e');
    }
  }

  void dispose() => _timer?.cancel();
}
