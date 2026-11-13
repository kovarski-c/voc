import 'dart:math' as math;

import '../models/card_progress.dart';
import 'scheduler.dart';

/// Odpověď v testu: pozice slova v pořadí učení (0 = nejfrekventovanější)
/// a zda ho člověk zná.
class PlacementAnswer {
  final int rank;
  final bool known;
  const PlacementAnswer(this.rank, this.known);
}

/// Adaptivní test slovní zásoby: půlení intervalu v pořadí podle frekvence.
/// V každém bodě se zeptá na 2 až 3 slova z okolí; bod "projde", když
/// člověk zná aspoň dvě. Pak se hledá dál nahoru nebo dolů s menším krokem.
class PlacementTest {
  PlacementTest({required this.total, math.Random? rng, this.maxProbes = 7})
    : _rng = rng ?? math.Random(),
      _hi = total {
    _nextProbe();
  }

  final int total;
  final int maxProbes;
  final math.Random _rng;

  int _lo = 0;
  int _hi;
  int _probes = 0;
  int _mid = 0;
  int _asked = 0;
  int _known = 0;
  int? _current;
  final Set<int> _used = {};
  final List<PlacementAnswer> answers = [];

  bool get done => _current == null;

  /// Pozice právě zkoušeného slova (null = test skončil).
  int? get currentRank => _current;

  /// Orientační postup 0..1: hotové body plus rozpracovaný bod (každá odpověď
  /// posune ukazatel, ne až každá druhá).
  double get progress =>
      done ? 1 : ((_probes + _asked / 3) / maxProbes).clamp(0.0, 1.0);

  /// Odhad: kolik prvních slov seznamu člověk zná (konzervativně dolní mez).
  int get estimate => _lo;

  void answer(bool known) {
    final r = _current;
    if (r == null) return;
    answers.add(PlacementAnswer(r, known));
    _asked++;
    if (known) _known++;
    final unknown = _asked - _known;
    if (_known >= 2 || unknown >= 2) {
      _finishProbe(passed: _known >= 2);
    } else {
      _pickWord(); // ještě se zeptá na třetí slovo
    }
  }

  void _finishProbe({required bool passed}) {
    if (passed) {
      _lo = _mid;
    } else {
      _hi = _mid;
    }
    _probes++;
    _nextProbe();
  }

  void _nextProbe() {
    if (total <= 0 || _probes >= maxProbes || _hi - _lo <= 20) {
      _current = null;
      return;
    }
    _mid = (_lo + _hi) ~/ 2;
    _asked = 0;
    _known = 0;
    _pickWord();
  }

  void _pickWord() {
    final span = _hi - _lo;
    final w = math.max(5, span ~/ 6);
    final from = math.max(0, _mid - w);
    final to = math.min(total - 1, _mid + w);
    for (var i = 0; i < 30; i++) {
      final r = from + _rng.nextInt(to - from + 1);
      if (_used.add(r)) {
        _current = r;
        return;
      }
    }
    for (var r = from; r <= to; r++) {
      if (_used.add(r)) {
        _current = r;
        return;
      }
    }
    // v okolí už není co zkoušet: bod se uzavře podle dosavadních odpovědí
    _finishProbe(passed: _known * 2 >= _asked && _asked > 0);
  }
}

/// Z odhadu (nebo ručního výběru) vyrobí pokrok karet známých slov.
class PlacementPlan {
  /// Stabilita (dny) nejfrekventovanějších známých slov.
  static const double maxStability = 365;

  /// Stabilita (dny) slov hned pod hranicí odhadu.
  static const double minStability = 14;

  /// Stabilita slov, na která se test přímo ptal a člověk je znal.
  static const double evidenceStability = 30;

  static const double _msPerDay = 86400000;

  /// Kolik známých slov denně smí poprvé přijít na opakování:
  /// asi 10 % denního cíle, nejméně 3.
  static int perDayFor(int dailyGoal) => math.max(3, (dailyGoal * 0.1).round());

  /// Stabilita podle polohy slova: 0 = nejfrekventovanější, 1 = hranice odhadu.
  /// Geometrická interpolace mezi [maxStability] a [minStability].
  static double stabilityAt(double relative) {
    final r = relative.clamp(0.0, 1.0);
    return math.pow(maxStability, 1 - r).toDouble() *
        math.pow(minStability, r).toDouble();
  }

  static Map<int, CardProgress> build({
    required List<int> order,
    required int known,
    required List<PlacementAnswer> answers,
    required Set<int> existing,
    required int perDay,
    required DateTime now,
  }) {
    final n = known.clamp(0, order.length);
    final evidence = <int, bool>{for (final a in answers) a.rank: a.known};
    final nowMs = now.millisecondsSinceEpoch;
    final out = <int, CardProgress>{};

    // 1) slova, na která se test ptal a člověk je znal: ověřená, normální interval
    for (final e in evidence.entries) {
      final rank = e.key;
      if (!e.value || rank < 0 || rank >= order.length) continue;
      final key = order[rank];
      if (existing.contains(key)) continue;
      final base = rank < n ? stabilityAt(rank / n) : 0.0;
      final s = math.max(evidenceStability, base);
      out[key] = CardProgress(
        stage: CardStage.review,
        stability: s,
        lastReviewMs: nowMs,
        dueMs: Scheduler.dueFor(now, s),
        fromPlacement: true,
      );
    }

    // 2) ostatní slova pod odhadem: fronta od hranice dolů, nejvýš perDay za den
    var i = 0;
    for (var rank = n - 1; rank >= 0; rank--) {
      final key = order[rank];
      if (existing.contains(key) || out.containsKey(key)) continue;
      if (evidence[rank] == false)
        continue; // slovo, které neznal, zůstane nové
      final s = stabilityAt(rank / n);
      final dueMs = Scheduler.dueAfterDays(now, 1 + i ~/ perDay);
      // poslední opakování tak, aby při splatnosti uplynula právě stabilita
      final last = math.min(nowMs, dueMs - (s * _msPerDay).round());
      out[key] = CardProgress(
        stage: CardStage.review,
        stability: s,
        lastReviewMs: last,
        dueMs: dueMs,
        fromPlacement: true,
      );
      i++;
    }
    return out;
  }
}
