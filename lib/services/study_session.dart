import 'dart:math' as math;

import '../models/card_progress.dart';
import 'scheduler.dart';

enum Phase { idle, reviewing, learning, interlude }

enum InterludeKind { reviewsDone, groupDone, blockDone, allDone }

/// Režim procvičování zvolený na domovské stránce.
enum StudyMode { both, reviewOnly, learnOnly }

/// Logika jedné studijní relace: opakování -> skupiny po pěti novinkách.
/// "Blok" = až 40 splatných opakování + až 20 nových slov. Po bloku lze pokračovat dalším.
class StudySession {
  StudySession({
    required this.cardCount,
    required this.cards,
    DateTime Function()? clock,
    this.onCardDone,
  }) : _clock = clock ?? DateTime.now;

  static const int groupSize = 5;
  static const int newPerBlock = 20;
  static const int reviewBatch = 40;
  static const int earlyBatch = 20; // předčasné opakování nesplatných karet

  final int cardCount;
  final Map<int, CardProgress> cards; // sdílená mapa s ProgressStore
  final DateTime Function() _clock;

  /// Karta definitivně opustila frontu: true = nově naučena, false = zopakována.
  final void Function(bool learned)? onCardDone;
  final math.Random _rng = math.Random();

  StudyMode mode = StudyMode.both;
  Phase phase = Phase.idle;
  InterludeKind? interlude;

  final List<int> _intro = []; // karty, které se nejdřív jen představí
  final List<int> _queue = []; // fronta zkoušení
  int _newCursor = 0;

  int serial = 0; // zvyšuje se při každé změně karty nahoře (pro klíče widgetů)
  int phaseDone = 0;
  int phaseTotal = 0;
  int newInBlock = 0;
  int reviewedInBlock = 0;
  int learnedInBlock = 0;
  int skippedInBlock = 0;
  int backlog = 0; // splatná opakování po dokončení dávky

  int? get current => _intro.isNotEmpty
      ? _intro.first
      : (_queue.isNotEmpty ? _queue.first : null);
  int? get next => _intro.isNotEmpty ? null : (_queue.length > 1 ? _queue[1] : null);
  bool get isIntro => _intro.isNotEmpty;

  int get dueCount {
    final now = _clock().millisecondsSinceEpoch;
    var n = 0;
    for (final p in cards.values) {
      if (p.stage == CardStage.review && p.dueMs <= now) n++;
    }
    return n;
  }

  int get learningCount =>
      cards.values.where((p) => p.stage == CardStage.learning).length;

  int get unseenCount => math.max(0, cardCount - cards.length);

  int? _nextUnseen() {
    while (_newCursor < cardCount && cards.containsKey(_newCursor)) {
      _newCursor++;
    }
    return _newCursor < cardCount ? _newCursor : null;
  }

  // ---- spouštění fází ----

  void startBlock([StudyMode? m]) {
    if (m != null) mode = m;
    newInBlock = 0;
    reviewedInBlock = 0;
    learnedInBlock = 0;
    skippedInBlock = 0;
    switch (mode) {
      case StudyMode.learnOnly:
        startLearning();
      case StudyMode.reviewOnly:
        // Když nic není splatné, procvičí se předčasně karty s nejbližším termínem.
        startReviews(early: dueCount == 0);
      case StudyMode.both:
        if (dueCount > 0) {
          startReviews();
        } else {
          startLearning();
        }
    }
  }

  void startReviews({bool early = false}) {
    final now = _clock().millisecondsSinceEpoch;
    final due = cards.entries
        .where((e) =>
            e.value.stage == CardStage.review &&
            (early ? e.value.dueMs > now : e.value.dueMs <= now))
        .toList()
      ..sort((a, b) => a.value.dueMs.compareTo(b.value.dueMs));
    _intro.clear();
    _queue
      ..clear()
      ..addAll(due.take(early ? earlyBatch : reviewBatch).map((e) => e.key));
    if (_queue.isEmpty) {
      _finishReviews();
      return;
    }
    phase = Phase.reviewing;
    interlude = null;
    phaseDone = 0;
    phaseTotal = _queue.length;
    serial++;
  }

  void startLearning() {
    final learning = cards.entries
        .where((e) => e.value.stage == CardStage.learning)
        .map((e) => e.key)
        .toList()
      ..sort();
    final group = learning.take(groupSize).toList();
    final room = math.min(groupSize - group.length, newPerBlock - newInBlock);
    for (var k = 0; k < room; k++) {
      final i = _nextUnseen();
      if (i == null) break;
      group.add(i);
      _newCursor = i + 1;
      newInBlock++;
    }
    if (group.isEmpty) {
      _setInterlude(_nextUnseen() != null
          ? InterludeKind.blockDone
          : InterludeKind.allDone);
      return;
    }
    _queue
      ..clear()
      ..addAll(group);
    _intro
      ..clear()
      ..addAll(group.where((i) {
        final p = cards[i];
        return p == null || (p.streak == 0 && !p.relearn);
      }));
    if (_intro.isEmpty) _queue.shuffle(_rng);
    phase = Phase.learning;
    interlude = null;
    phaseDone = 0;
    phaseTotal = group.length;
    serial++;
  }

  void finish() {
    phase = Phase.idle;
    interlude = null;
    _intro.clear();
    _queue.clear();
    serial++;
  }

  // ---- odpovědi ----

  /// Konec představení nové karty: karta se zapíše do úložiště jako "učení".
  void ackIntro() {
    if (_intro.isEmpty) return;
    final i = _intro.removeAt(0);
    cards.putIfAbsent(
        i, () => CardProgress.learning(_clock().millisecondsSinceEpoch));
    if (_intro.isEmpty) _queue.shuffle(_rng);
    serial++;
  }

  /// "Už umím": karta se při představení přeskočí a rovnou jde do opakování
  /// (první ověření za Scheduler.skipStabilityDays dní). Do limitu nových slov se nepočítá.
  void skipIntro() {
    if (_intro.isEmpty) return;
    final i = _intro.removeAt(0);
    final now = _clock();
    final wasNew = !cards.containsKey(i);
    cards[i] = CardProgress(
      stage: CardStage.review,
      stability: Scheduler.skipStabilityDays,
      lastReviewMs: now.millisecondsSinceEpoch,
      dueMs: Scheduler.dueFor(now, Scheduler.skipStabilityDays),
    );
    _queue.remove(i);
    if (wasNew && newInBlock > 0) newInBlock--;
    skippedInBlock++;
    phaseTotal = math.max(0, phaseTotal - 1);
    serial++;
    if (_queue.isEmpty) {
      _finishLearning();
    } else if (_intro.isEmpty) {
      _queue.shuffle(_rng);
    }
  }

  void answer(bool known) {
    if (_intro.isNotEmpty || _queue.isEmpty) return;
    final c = _queue.removeAt(0);
    final p = cards[c];
    if (p == null) return;
    final now = _clock();
    final nowMs = now.millisecondsSinceEpoch;

    if (p.stage == CardStage.review) {
      if (known) {
        final t = Scheduler.daysBetween(p.lastReviewMs, nowMs);
        final s = Scheduler.onSuccess(p.stability, t);
        cards[c] = p.copyWith(
          stability: s,
          lastReviewMs: nowMs,
          dueMs: Scheduler.dueFor(now, s),
        );
        reviewedInBlock++;
        onCardDone?.call(false);
        phaseDone++;
      } else {
        // Zapomenuté slovo: zpět do učení (2 správně v řadě), dnes se vrátí brzy.
        cards[c] = CardProgress(
          stage: CardStage.learning,
          streak: 0,
          relearn: true,
          stability: Scheduler.onLapse(p.stability),
          lastReviewMs: nowMs,
          dueMs: nowMs,
          lapses: p.lapses + 1,
        );
        _insert(c, 2);
      }
    } else if (known) {
      final streak = p.streak + 1;
      if (streak >= Scheduler.target(p)) {
        // Hotovo: do opakování, první kontrola zítra.
        cards[c] = p.copyWith(
          stage: CardStage.review,
          streak: 0,
          relearn: false,
          stability: p.relearn ? p.stability : 1.0,
          lastReviewMs: nowMs,
          dueMs: Scheduler.dueFor(now, 1.0),
        );
        if (p.relearn) {
          reviewedInBlock++;
        onCardDone?.call(false);
        } else {
          learnedInBlock++;
          onCardDone?.call(true);
        }
        phaseDone++;
      } else {
        cards[c] = p.copyWith(streak: streak);
        _insert(c, 4);
      }
    } else {
      cards[c] = p.copyWith(streak: 0);
      _insert(c, 2);
    }

    serial++;
    if (_queue.isEmpty) {
      if (phase == Phase.reviewing) {
        _finishReviews();
      } else {
        _finishLearning();
      }
    }
  }

  void _insert(int c, int pos) => _queue.insert(math.min(pos, _queue.length), c);

  void _finishReviews() {
    backlog = dueCount;
    _setInterlude(InterludeKind.reviewsDone);
  }

  void _finishLearning() {
    final more = _nextUnseen() != null || learningCount > 0;
    if (!more) {
      _setInterlude(InterludeKind.allDone);
    } else if (newInBlock >= newPerBlock) {
      _setInterlude(InterludeKind.blockDone);
    } else {
      _setInterlude(InterludeKind.groupDone);
    }
  }

  void _setInterlude(InterludeKind kind) {
    phase = Phase.interlude;
    interlude = kind;
    serial++;
  }
}
