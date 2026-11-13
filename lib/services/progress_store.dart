import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/card_progress.dart';
import 'scheduler.dart';
import 'storage.dart';

/// Statistiky před jednou akcí (pro tlačítko Zpět). Odznaky se nevracejí.
class StatsSnapshot {
  final int day;
  final List<int>? today;
  final int streak, bestStreak, lastActiveDay, freezes, goalCelebratedDay;
  const StatsSnapshot(
    this.day,
    this.today,
    this.streak,
    this.bestStreak,
    this.lastActiveDay,
    this.freezes,
    this.goalCelebratedDay,
  );
}

/// Ukládá pokrok jednoho kurzu do progress_<courseId>.json (verze 3).
/// Ukládají se jen karty, které už uživatel viděl (řídký formát),
/// plus statistiky: historie po dnech, série, odznaky.
/// Starší formáty (verze 2 a původní skills.json) se při načtení převedou.
class ProgressStore {
  ProgressStore(this.courseId);

  final String courseId;
  final Map<int, CardProgress> cards = {};

  /// Nová slova, která uživatel označil "učit přednostně" (klíče karet).
  /// Značka se zruší, jakmile se slovo poprvé představí.
  final Set<int> prioritized = {};

  // --- statistiky ---
  /// číslo studijního dne -> [zopakováno, naučeno]
  final Map<int, List<int>> history = {};
  int streak = 0;
  int bestStreak = 0;
  int lastActiveDay = 0;
  int freezes = 0;
  int goalCelebratedDay = 0;
  final Set<int> badges = {};
  bool badgesSeeded = false;

  /// Kódy dosažených úrovní slovní zásoby ('A1', ...).
  final Set<String> levelCodes = {};
  bool levelsSeeded = false;

  /// Úvodní výběr úrovně už proběhl (nebo ho uživatel přeskočil).
  bool placementDone = false;

  List<int> get _todayCounts =>
      history[Scheduler.studyDayNumber(DateTime.now())] ?? const [0, 0];
  int get reviewedToday => _todayCounts[0];
  int get learnedToday => _todayCounts[1];
  int get doneToday => reviewedToday + learnedToday;

  /// Volá se, když karta definitivně opustí frontu (zopakována / naučena).
  void recordDone(bool learned) {
    final day = Scheduler.studyDayNumber(DateTime.now());
    final h = history.putIfAbsent(day, () => [0, 0]);
    h[learned ? 1 : 0]++;
    scheduleSave();
  }

  StatsSnapshot snapshotStats() {
    final day = Scheduler.studyDayNumber(DateTime.now());
    final h = history[day];
    return StatsSnapshot(
      day,
      h == null ? null : List.of(h),
      streak,
      bestStreak,
      lastActiveDay,
      freezes,
      goalCelebratedDay,
    );
  }

  void restoreStats(StatsSnapshot s) {
    if (s.today == null) {
      history.remove(s.day);
    } else {
      history[s.day] = List.of(s.today!);
    }
    streak = s.streak;
    bestStreak = s.bestStreak;
    lastActiveDay = s.lastActiveDay;
    freezes = s.freezes;
    goalCelebratedDay = s.goalCelebratedDay;
    scheduleSave();
  }

  Timer? _timer;
  Future<void> _writing = Future.value();

  String get _name => 'progress_$courseId.json';

  Future<void> load({bool migrateLegacy = false}) async {
    final name = _name;
    String? raw;
    try {
      raw = await Storage.read(name);
    } catch (e) {
      debugPrint('Čtení pokroku selhalo: $e');
    }
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final version = (data['version'] as num?)?.toInt() ?? 2;
        final rawCards = (data['cards'] as Map<String, dynamic>?) ?? {};
        _loadStats(data['stats'] as Map<String, dynamic>?);
        prioritized
          ..clear()
          ..addAll(List<int>.from((data['prio'] as List?) ?? const []));
        final now = DateTime.now();
        rawCards.forEach((k, v) {
          final i = int.parse(k);
          cards[i] =
              version >= 3
                  ? CardProgress.fromJson(v)
                  : Scheduler.fromLegacySkill(i, (v as List)[0] as int, now);
        });
        prioritized.removeWhere(
          cards.containsKey,
        ); // už viděná slova značku nemají
        if (version < 3) {
          await Storage.write('$name.v2.bak', raw);
          await flush();
        }
        return;
      } catch (e) {
        debugPrint('Poškozený soubor s pokrokem: $e');
        try {
          await Storage.write('$name.corrupt', raw);
          await Storage.delete(name);
        } catch (_) {}
        cards.clear();
        history.clear();
        prioritized.clear();
      }
    }
    if (migrateLegacy) await _migrateLegacy();
  }

  void _loadStats(Map<String, dynamic>? m) {
    if (m == null) return;
    final h = (m['h'] as Map<String, dynamic>?) ?? {};
    h.forEach((k, v) {
      final l = List<int>.from(v as List);
      history[int.parse(k)] = [l[0], l[1]];
    });
    streak = (m['s'] as num?)?.toInt() ?? 0;
    bestStreak = (m['b'] as num?)?.toInt() ?? 0;
    lastActiveDay = (m['l'] as num?)?.toInt() ?? 0;
    freezes = (m['f'] as num?)?.toInt() ?? 0;
    goalCelebratedDay = (m['g'] as num?)?.toInt() ?? 0;
    badges.addAll(List<int>.from((m['badges'] as List?) ?? const []));
    badgesSeeded = ((m['seeded'] as num?)?.toInt() ?? 0) == 1;
    levelCodes.addAll(List<String>.from((m['lv'] as List?) ?? const []));
    levelsSeeded = ((m['lvSeeded'] as num?)?.toInt() ?? 0) == 1;
    placementDone = ((m['pl'] as num?)?.toInt() ?? 0) == 1;
  }

  Map<String, dynamic> _statsJson() {
    final today = Scheduler.studyDayNumber(DateTime.now());
    history.removeWhere((day, _) => day < today - 180);
    return {
      'h': {for (final e in history.entries) '${e.key}': e.value},
      's': streak,
      'b': bestStreak,
      'l': lastActiveDay,
      'f': freezes,
      'g': goalCelebratedDay,
      'badges': badges.toList()..sort(),
      'seeded': badgesSeeded ? 1 : 0,
      'lv': levelCodes.toList()..sort(),
      'lvSeeded': levelsSeeded ? 1 : 0,
      'pl': placementDone ? 1 : 0,
    };
  }

  /// Převod z úplně starého skills.json (dva dlouhé seznamy skills a activations).
  Future<void> _migrateLegacy() async {
    try {
      final text = await Storage.read('skills.json');
      if (text == null) return;
      final data = jsonDecode(text);
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

  bool _frozen = false;

  /// Po zavolání se už nic neukládá (používá se při importu zálohy, aby staré
  /// údaje v paměti nepřepsaly nově nahrané).
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
      final json = jsonEncode({
        'version': 3,
        'stats': _statsJson(),
        'prio': prioritized.toList()..sort(),
        'cards': {for (final e in cards.entries) '${e.key}': e.value.toJson()},
      });
      await Storage.write(_name, json);
    } catch (e) {
      debugPrint('Uložení pokroku selhalo: $e');
    }
  }

  void dispose() => _timer?.cancel();
}
