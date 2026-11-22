import 'dart:math' as math;

import '../models/card_progress.dart';
import 'scheduler.dart';

/// Odpověď na jedno slovo v testu.
enum Reply { unknown, unsure, known }

/// Odpověď předaná plánu: pozice slova v pořadí učení (0 = nejfrekventovanější)
/// a zda ho člověk skutečně zná ("Tuším" se bere jako neznámé).
class PlacementAnswer {
  final int rank;
  final bool known;
  const PlacementAnswer(this.rank, this.known);
}

enum _Kind { coarse, refine, controlEasy, controlHard }

class _Ans {
  final int rank;
  final double score; // 1 = Znám, 0.5 = Tuším, 0 = Neznám
  final _Kind kind;
  const _Ans(this.rank, this.score, this.kind);
}

class _Snap {
  final List<_Ans> answers;
  final Set<int> used;
  final List<_Q> queue;
  final int current;
  final _Kind curKind;
  final int level;
  final double lvScore;
  final int lvAsked;
  final int fails;
  final int lastPassed;

  const _Snap({
    required this.answers,
    required this.used,
    required this.queue,
    required this.current,
    required this.curKind,
    required this.level,
    required this.lvScore,
    required this.lvAsked,
    required this.fails,
    required this.lastPassed,
  });
}

class _Q {
  final int rank;
  final _Kind kind;
  const _Q(this.rank, this.kind);
}

class _Cell {
  final double m, s, ll;
  const _Cell(this.m, this.s, this.ll);
}

class _Result {
  final int est, low, high;
  final bool overclaimed, inconsistent;
  const _Result(this.est, this.low, this.high, this.overclaimed, this.inconsistent);
}

/// Test slovní zásoby, tři fáze (celkem [target] slov, u 20 000 slov 50):
///  1) hrubý odhad: žebříček úrovní rozložených logaritmicky podle pořadí,
///     na každé úrovni až 3 slova (stačí 2 ze 3), od nejlehčí nahoru,
///     konec po dvou neúspěšných úrovních za sebou;
///  2) zpřesnění: slova rovnoměrně z okolí odhadnuté úrovně;
///  3) kontrola: 3 mnohem lehčí a 3 mnohem těžší slova, promíchaná mezi
///     slova z 2. fáze. Neovlivňují průběh, jen opravují výsledek.
/// Výsledek se počítá proložením křivky "podíl známých slov podle log. pořadí".
class PlacementTest {
  PlacementTest({required this.total, math.Random? rng})
    : _rng = rng ?? math.Random(),
      levels = _levelsFor(total) {
    target = math.min(lengthFor(total), math.max(1, total ~/ 2));
    if (total < 20) return; // nic se nezeptá, test je hned hotový
    _ladder = _buildLadder();
    _pickCoarse();
  }

  final int total;
  final int levels;
  late final int target;
  final math.Random _rng;

  late final List<int> _ladder;
  final List<_Ans> _answers = [];
  final Set<int> _used = {};
  final List<_Q> _queue = [];
  int? _current;
  _Kind _curKind = _Kind.coarse;

  int _level = 0;
  double _lvScore = 0;
  int _lvAsked = 0;
  int _fails = 0;
  int _lastPassed = -1;
  _Result? _result;

  // Stav před každou odpovědí, pro krok zpět na předchozí slovo.
  final List<_Snap> _history = [];

  bool get canUndo => _history.isNotEmpty;

  /// Vrátí test o jedno slovo zpět (odpověď se smaže, slovo se ukáže znovu).
  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    _answers
      ..clear()
      ..addAll(h.answers);
    _used
      ..clear()
      ..addAll(h.used);
    _queue
      ..clear()
      ..addAll(h.queue);
    _current = h.current;
    _curKind = h.curKind;
    _level = h.level;
    _lvScore = h.lvScore;
    _lvAsked = h.lvAsked;
    _fails = h.fails;
    _lastPassed = h.lastPassed;
    _result = null;
  }

  /// Počet úrovní hrubého odhadu: asi log2(total / 300), 3 až 6.
  static int _levelsFor(int total) {
    if (total <= 0) return 3;
    return (math.log(total / 300) / math.ln2).round().clamp(3, 6).toInt();
  }

  /// Délka testu podle velikosti seznamu (20 000 slov = 50, 2 700 slov = 35).
  static int lengthFor(int total) => 5 * _levelsFor(total) + 20;

  bool get done => _current == null;

  /// Pozice právě zkoušeného slova (null = test skončil).
  int? get currentRank => _current;

  int get answered => _answers.length;

  double get progress =>
      done ? 1.0 : (_answers.length / target).clamp(0.0, 1.0).toDouble();

  /// Odpovědi pro [PlacementPlan]: "Tuším" i těžká kontrolní slova se berou
  /// jako neznámá, aby se nezapsala jako zvládnutá.
  List<PlacementAnswer> get planAnswers => [
    for (final a in _answers)
      PlacementAnswer(a.rank, a.score >= 1 && a.kind != _Kind.controlHard),
  ];

  /// Odhad počtu známých slov (střed) a rozsah (zhruba 95% interval).
  int get estimate => _res.est;
  int get estimateLow => _res.low;
  int get estimateHigh => _res.high;

  /// U několika velmi těžkých slov odpověď "Znám": odhad byl snížen.
  bool get overclaimed => _res.overclaimed;

  /// U několika velmi lehkých slov odpověď "Neznám": odhad je nejistý.
  bool get inconsistent => _res.inconsistent;

  void answer(Reply reply) {
    final cur = _current;
    if (cur == null) return;
    _history.add(
      _Snap(
        answers: List.of(_answers),
        used: Set.of(_used),
        queue: List.of(_queue),
        current: cur,
        curKind: _curKind,
        level: _level,
        lvScore: _lvScore,
        lvAsked: _lvAsked,
        fails: _fails,
        lastPassed: _lastPassed,
      ),
    );
    final s = reply == Reply.known ? 1.0 : (reply == Reply.unsure ? 0.5 : 0.0);
    _answers.add(_Ans(cur, s, _curKind));
    _result = null;
    if (_curKind != _Kind.coarse) {
      _next();
      return;
    }
    _lvScore += s;
    _lvAsked++;
    if (_lvScore >= 2 || _lvScore + (3 - _lvAsked) < 2) {
      if (_lvScore >= 2) {
        _lastPassed = _level;
        _fails = 0;
      } else {
        _fails++;
      }
      _level++;
      _lvScore = 0;
      _lvAsked = 0;
      if (_fails >= 2 || _level >= levels) {
        _startRefine();
        return;
      }
    }
    _pickCoarse();
  }

  // ------------------------------------------------------------ výběr slov
  List<int> _buildLadder() {
    final first = math.min(300.0, total / 9);
    final last = total * 0.9;
    return [
      for (var i = 0; i < levels; i++)
        (first * math.pow(last / first, i / (levels - 1)))
            .round()
            .clamp(0, total - 1)
            .toInt(),
    ];
  }

  int? _pickIn(int lo, int hi) {
    lo = math.max(0, lo);
    hi = math.min(total - 1, hi);
    if (hi < lo) return null;
    for (var i = 0; i < 30; i++) {
      final r = lo + _rng.nextInt(hi - lo + 1);
      if (_used.add(r)) return r;
    }
    for (var r = lo; r <= hi; r++) {
      if (_used.add(r)) return r;
    }
    return null;
  }

  /// Slovo z rozsahu pořadí, rozloženo logaritmicky (jinak by převládla
  /// vzácná slova).
  int? _pickLog(int lo, int hi) {
    final a = math.log(lo + 1.0), b = math.log(hi + 1.0);
    final x = math.exp(a + _rng.nextDouble() * (b - a)) - 1;
    return _pickIn((x * 0.9).round(), (x * 1.1).round() + 1);
  }

  void _pickCoarse() {
    final c = _ladder[_level];
    final r = _pickIn((c / 1.4).round(), (c * 1.4).round());
    if (r == null) {
      _startRefine();
      return;
    }
    _current = r;
    _curKind = _Kind.coarse;
  }

  void _startRefine() {
    final lp = _lastPassed;
    final r0 = lp < 0 ? _ladder[0] ~/ 2 : _ladder[lp];
    final lo = lp < 0 ? 0 : _ladder[math.max(0, lp - 1)];
    final hi =
        lp >= levels - 1
            ? total - 1
            : _ladder[math.min(levels - 1, lp + 2)];

    // kontrolní slova; lehká jen když už člověk prošel aspoň dvě úrovně
    if (lp >= 1 && r0 ~/ 6 > 20) {
      for (var i = 0; i < 3; i++) {
        final r = _pickLog(10, r0 ~/ 6);
        if (r != null) _queue.add(_Q(r, _Kind.controlEasy));
      }
    }
    if (r0 * 4 < total * 0.95) {
      for (var i = 0; i < 3; i++) {
        final r = _pickLog(r0 * 4, total - 1);
        if (r != null) _queue.add(_Q(r, _Kind.controlHard));
      }
    }

    // zpřesnění: zbytek rozpočtu, po jednom slově z každého logaritmického pásma
    final n = math.max(0, target - _answers.length - _queue.length);
    final a = math.log(lo + 1.0), b = math.log(hi + 1.0);
    for (var i = 0; i < n; i++) {
      final from = (math.exp(a + (b - a) * i / n) - 1).round();
      final to = (math.exp(a + (b - a) * (i + 1) / n) - 1).round();
      final r = _pickIn(from, math.max(from, to));
      if (r != null) _queue.add(_Q(r, _Kind.refine));
    }
    _queue.shuffle(_rng);
    _next();
  }

  void _next() {
    if (_queue.isEmpty) {
      _current = null;
      return;
    }
    final q = _queue.removeLast();
    _current = q.rank;
    _curKind = q.kind;
  }

  // --------------------------------------------------------------- výsledek
  _Result get _res => _result ??= _fit();

  _Result _fit() {
    final pts = [
      for (final a in _answers)
        if (a.kind == _Kind.coarse || a.kind == _Kind.refine) a,
    ];
    if (pts.isEmpty || total <= 0) return const _Result(0, 0, 0, false, false);
    final xs = [for (final a in pts) math.log(a.rank + 1.0)];

    // logistická křivka p(r) = 1 / (1 + exp((ln r - m) / s)) s malou chybovostí
    // (0,02 až 0,98), takže ojedinělé přehmaty nic nezboří; hledá se mřížkou
    const ss = [0.25, 0.4, 0.6, 0.85, 1.2, 1.7];
    final mMax = math.log(total * 1.5);
    final cells = <_Cell>[];
    var best = -1e18;
    _Cell? bestCell;
    for (var m = math.log(10.0); m <= mMax; m += 0.1) {
      for (final s in ss) {
        var ll = 0.0;
        for (var i = 0; i < pts.length; i++) {
          final p = 0.02 + 0.96 / (1 + math.exp((xs[i] - m) / s));
          final y = pts[i].score;
          ll += y * math.log(p) + (1 - y) * math.log(1 - p);
        }
        final cell = _Cell(m, s, ll);
        cells.add(cell);
        if (ll > best) {
          best = ll;
          bestCell = cell;
        }
      }
    }

    final lx = [for (var r = 0; r < total; r++) math.log(r + 1.0)];
    double count(_Cell c) {
      var sum = 0.0;
      for (var r = 0; r < total; r++) {
        sum += 1 / (1 + math.exp((lx[r] - c.m) / c.s));
      }
      return sum;
    }

    final est = count(bestCell!);
    var lo = est, hi = est;
    for (final c in cells) {
      if (c.ll < best - 2) continue; // mimo ~95% interval
      final v = count(c);
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }

    // oprava podle kontrolních slov
    var hard = 0.0;
    var easyMissed = 0;
    for (final a in _answers) {
      if (a.kind == _Kind.controlHard) hard += a.score;
      if (a.kind == _Kind.controlEasy && a.score == 0) easyMissed++;
    }
    final factor = (1 - 0.1 * hard).clamp(0.7, 1.0).toDouble();
    int fin(double v) => (v * factor).round().clamp(0, total).toInt();
    return _Result(fin(est), fin(lo), fin(hi), hard >= 2, easyMissed >= 2);
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

    // 1) slova, na která se test ptal a člověk je znal: ověřená, normální interval.
    // Jen pod hranicí odhadu; slovo nad ní (osamělé "znám" mezi neznámými)
    // se neoznačí jako umím a zůstane mezi novými.
    for (final e in evidence.entries) {
      final rank = e.key;
      if (!e.value || rank < 0 || rank >= n) continue;
      final key = order[rank];
      if (existing.contains(key)) continue;
      final s = math.max(evidenceStability, stabilityAt(rank / n));
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
