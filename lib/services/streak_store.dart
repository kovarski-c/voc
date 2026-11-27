import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'scheduler.dart';
import 'storage.dart';

/// Stav série před jednou akcí (pro tlačítko Zpět).
class StreakSnapshot {
  final int streak, bestStreak, lastActiveDay, freezes, countDay, countToday;
  const StreakSnapshot(
    this.streak,
    this.bestStreak,
    this.lastActiveDay,
    this.freezes,
    this.countDay,
    this.countToday,
  );
}

/// Série dní společná pro všechny kurzy (streak.json). Do série se počítá
/// součet karet za den napříč kurzy: stačí [Motivation.streakMinCards]
/// karet v jakémkoli jazyce.
class StreakStore {
  static const _name = 'streak.json';

  int streak = 0;
  int bestStreak = 0;
  int lastActiveDay = 0;
  int freezes = 0;

  /// Studijní den, pro který platí [countToday] (počet karet za den).
  int countDay = 0;
  int countToday = 0;

  /// Kolik karet je dnes hotových (ve všech kurzech dohromady).
  int cardsToday(int today) => countDay == today ? countToday : 0;

  /// Volá se, když karta definitivně opustí frontu (v jakémkoli kurzu).
  void recordCard() {
    final today = Scheduler.studyDayNumber(DateTime.now());
    if (countDay != today) {
      countDay = today;
      countToday = 0;
    }
    countToday++;
    scheduleSave();
  }

  StreakSnapshot snapshot() => StreakSnapshot(
    streak,
    bestStreak,
    lastActiveDay,
    freezes,
    countDay,
    countToday,
  );

  void restore(StreakSnapshot s) {
    streak = s.streak;
    bestStreak = s.bestStreak;
    lastActiveDay = s.lastActiveDay;
    freezes = s.freezes;
    countDay = s.countDay;
    countToday = s.countToday;
    scheduleSave();
  }

  // --- načtení a uložení ---

  /// Načte streak.json. Když neexistuje (první spuštění po přechodu na
  /// společnou sérii), převezme sérii z kurzů [courseIds].
  static Future<StreakStore> load(Iterable<String> courseIds) async {
    final s = StreakStore();
    String? raw;
    try {
      raw = await Storage.read(_name);
    } catch (e) {
      debugPrint('Čtení série selhalo: $e');
    }
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        s.streak = (m['s'] as num?)?.toInt() ?? 0;
        s.bestStreak = (m['b'] as num?)?.toInt() ?? 0;
        s.lastActiveDay = (m['l'] as num?)?.toInt() ?? 0;
        s.freezes = (m['f'] as num?)?.toInt() ?? 0;
        s.countDay = (m['cd'] as num?)?.toInt() ?? 0;
        s.countToday = (m['cn'] as num?)?.toInt() ?? 0;
        return s;
      } catch (e) {
        debugPrint('Poškozený soubor se sérií: $e');
        try {
          await Storage.write('$_name.corrupt', raw);
        } catch (_) {}
      }
    }
    await s._migrate(courseIds);
    await s.flush();
    return s;
  }

  /// Převzetí ze starých statistik jednotlivých kurzů: vezme se kurz s nejdelší
  /// aktuálně platnou sérií, nejdelší série je maximum ze všech a dnešní karty
  /// se sečtou.
  Future<void> _migrate(Iterable<String> ids) async {
    final today = Scheduler.studyDayNumber(DateTime.now());
    var bestEffective = -1;
    var sum = 0;
    for (final id in ids) {
      try {
        final raw = await Storage.read('progress_$id.json');
        if (raw == null) continue;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final m = data['stats'] as Map<String, dynamic>?;
        if (m == null) continue;
        final st = (m['s'] as num?)?.toInt() ?? 0;
        final b = (m['b'] as num?)?.toInt() ?? 0;
        final l = (m['l'] as num?)?.toInt() ?? 0;
        final f = (m['f'] as num?)?.toInt() ?? 0;
        bestStreak = math.max(bestStreak, math.max(b, st));
        final h = (m['h'] as Map<String, dynamic>?)?['$today'];
        if (h is List && h.length >= 2) {
          sum += (h[0] as num).toInt() + (h[1] as num).toInt();
        }
        final gap = today - l;
        final effective =
            l == 0 ? 0 : (gap <= 1 || gap - 1 <= f ? st : 0);
        if (effective > bestEffective) {
          bestEffective = effective;
          streak = st;
          lastActiveDay = l;
          freezes = f;
        }
      } catch (e) {
        debugPrint('Převzetí série z kurzu $id selhalo: $e');
      }
    }
    countDay = today;
    countToday = sum;
  }

  Timer? _timer;
  Future<void> _writing = Future.value();
  bool _frozen = false;

  /// Po zavolání se už nic neukládá (import zálohy).
  void freeze() {
    _frozen = true;
    _timer?.cancel();
    _timer = null;
  }

  void scheduleSave() {
    if (_frozen) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), flush);
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_frozen) return _writing;
    _writing = _writing.then((_) => _write());
    return _writing;
  }

  Future<void> _write() async {
    try {
      await Storage.write(
        _name,
        jsonEncode({
          's': streak,
          'b': bestStreak,
          'l': lastActiveDay,
          'f': freezes,
          'cd': countDay,
          'cn': countToday,
        }),
      );
    } catch (e) {
      debugPrint('Uložení série selhalo: $e');
    }
  }
}
