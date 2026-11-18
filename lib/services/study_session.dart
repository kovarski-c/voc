import 'dart:math' as math;

import '../models/card_progress.dart';
import 'scheduler.dart';

enum Phase { idle, reviewing, learning, interlude }

enum InterludeKind { reviewsDone, groupDone, blockDone, allDone }

/// Režim procvičování zvolený na domovské stránce.
enum StudyMode { both, reviewOnly, learnOnly }

/// Stav relace před jednou akcí (pro tlačítko Zpět).
class SessionSnapshot {
  final int? key; // karta, které se akce týkala
  final CardProgress?
  prev; // její pokrok před akcí (null = ještě nebyla v úložišti)
  final StudyMode mode;
  final Phase phase;
  final InterludeKind? interlude;
  final List<int> intro;
  final List<int> queue;
  final Set<int> midNew;
  final int newCursor;
  final int phaseDone,
      phaseTotal,
      newInBlock,
      reviewedInBlock,
      learnedInBlock,
      skippedInBlock,
      answeredInBlock,
      correctInBlock,
      backlog;
  final Map<int, int> wrong;
  final bool prio; // karta měla značku "učit přednostně"

  const SessionSnapshot({
    required this.key,
    required this.prev,
    required this.mode,
    required this.phase,
    required this.interlude,
    required this.intro,
    required this.queue,
    required this.midNew,
    required this.newCursor,
    required this.phaseDone,
    required this.phaseTotal,
    required this.newInBlock,
    required this.reviewedInBlock,
    required this.learnedInBlock,
    required this.skippedInBlock,
    required this.answeredInBlock,
    required this.correctInBlock,
    required this.backlog,
    required this.wrong,
    required this.prio,
  });
}

/// Logika jedné studijní relace: opakování -> skupiny po pěti novinkách.
/// "Blok" = až 40 splatných opakování + až 20 nových slov. Po bloku lze pokračovat dalším.
class StudySession {
  StudySession({
    required this.order,
    required this.isHidden,
    required this.cards,
    Set<int>? prioritized,
    DateTime Function()? clock,
    this.onCardDone,
    this.newWordsGoal,
    this.learnedToday,
  }) : prioritized = prioritized ?? <int>{},
       _clock = clock ?? DateTime.now;

  static const int groupSize = 5;
  static const int newPerBlock = 20;
  static const int reviewBatch = 40;
  static const int earlyBatch = 20; // předčasné opakování nesplatných karet

  /// Viditelné klíče karet v pořadí učení (bez skrytých).
  final List<int> order;

  /// Skrytá karta (vulgární při zapnutém filtru, neznámý klíč): nikde se neobjeví.
  final bool Function(int key) isHidden;
  final Map<int, CardProgress> cards; // sdílená mapa s ProgressStore

  /// Nová slova označená "učit přednostně" (sdílená množina s ProgressStore).
  final Set<int> prioritized;
  final DateTime Function() _clock;

  /// Karta definitivně opustila frontu: true = nově naučena, false = zopakována.
  final void Function(bool learned)? onCardDone;

  /// Cíl nových slov za den a kolik jich je dnes hotových (pro vkládání mezi opakování).
  final int Function()? newWordsGoal;
  final int Function()? learnedToday;
  final math.Random _rng = math.Random();

  StudyMode mode = StudyMode.both;
  Phase phase = Phase.idle;
  InterludeKind? interlude;

  final List<int> _intro = []; // karty, které se nejdřív jen představí
  final List<int> _queue = []; // fronta zkoušení
  // Nová slova vložená doprostřed opakování; dokud nejsou představená, nemají postup.
  final Set<int> _midNew = {};
  int _newCursor = 0;

  int serial = 0; // zvyšuje se při každé změně karty nahoře (pro klíče widgetů)
  int phaseDone = 0;
  int phaseTotal = 0;
  int newInBlock = 0;
  int reviewedInBlock = 0;
  int learnedInBlock = 0;
  int skippedInBlock = 0;
  int answeredInBlock = 0;
  int correctInBlock = 0;
  final Map<int, int> _wrongInBlock = {};

  /// Karta, která se v dávce nejvíc pletla (aspoň 2 chyby), jinak null.
  int? get hardestInBlock {
    int? best;
    var n = 1;
    _wrongInBlock.forEach((k, v) {
      if (v > n) {
        n = v;
        best = k;
      }
    });
    return best;
  }

  int backlog = 0; // splatná opakování po dokončení dávky

  int? get current =>
      _intro.isNotEmpty
          ? _intro.first
          : (_queue.isNotEmpty ? _queue.first : null);
  int? get next =>
      (_intro.isNotEmpty || _frontIsMidNew)
          ? null
          : (_queue.length > 1 && !_midNew.contains(_queue[1])
              ? _queue[1]
              : null);
  bool get _frontIsMidNew => _queue.isNotEmpty && _midNew.contains(_queue.first);
  bool get isIntro => _intro.isNotEmpty || _frontIsMidNew;

  int get dueCount {
    final now = _clock().millisecondsSinceEpoch;
    var n = 0;
    for (final e in cards.entries) {
      if (e.value.stage == CardStage.review &&
          e.value.dueMs <= now &&
          !isHidden(e.key)) {
        n++;
      }
    }
    return n;
  }

  int get learningCount =>
      cards.entries
          .where((e) => e.value.stage == CardStage.learning && !isHidden(e.key))
          .length;

  int get unseenCount => order.where((k) => !cards.containsKey(k)).length;

  /// Další nová karta v pořadí (kurzor je POZICE v `order`, ne klíč).
  int? _nextUnseen() {
    while (_newCursor < order.length && cards.containsKey(order[_newCursor])) {
      _newCursor++;
    }
    return _newCursor < order.length ? order[_newCursor] : null;
  }

  // ---- zpět ----

  /// Uloží stav před akcí (odpověď, "dál", "už umím").
  SessionSnapshot snapshot() {
    final k = current;
    return SessionSnapshot(
      key: k,
      prev: k == null ? null : cards[k],
      mode: mode,
      phase: phase,
      interlude: interlude,
      intro: List.of(_intro),
      queue: List.of(_queue),
      midNew: Set.of(_midNew),
      newCursor: _newCursor,
      phaseDone: phaseDone,
      phaseTotal: phaseTotal,
      newInBlock: newInBlock,
      reviewedInBlock: reviewedInBlock,
      learnedInBlock: learnedInBlock,
      skippedInBlock: skippedInBlock,
      answeredInBlock: answeredInBlock,
      correctInBlock: correctInBlock,
      backlog: backlog,
      wrong: Map.of(_wrongInBlock),
      prio: k != null && prioritized.contains(k),
    );
  }

  /// Vrátí stav relace i pokrok karty do podoby před akcí.
  void restore(SessionSnapshot s) {
    mode = s.mode;
    phase = s.phase;
    interlude = s.interlude;
    _intro
      ..clear()
      ..addAll(s.intro);
    _queue
      ..clear()
      ..addAll(s.queue);
    _midNew
      ..clear()
      ..addAll(s.midNew);
    _newCursor = s.newCursor;
    phaseDone = s.phaseDone;
    phaseTotal = s.phaseTotal;
    newInBlock = s.newInBlock;
    reviewedInBlock = s.reviewedInBlock;
    learnedInBlock = s.learnedInBlock;
    skippedInBlock = s.skippedInBlock;
    answeredInBlock = s.answeredInBlock;
    correctInBlock = s.correctInBlock;
    backlog = s.backlog;
    _wrongInBlock
      ..clear()
      ..addAll(s.wrong);
    final k = s.key;
    if (k != null) {
      if (s.prio) prioritized.add(k);
      if (s.prev == null) {
        cards.remove(k);
      } else {
        cards[k] = s.prev!;
      }
    }
    serial++;
  }

  // ---- spouštění fází ----

  void startBlock([StudyMode? m]) {
    if (m != null) mode = m;
    newInBlock = 0;
    reviewedInBlock = 0;
    learnedInBlock = 0;
    skippedInBlock = 0;
    answeredInBlock = 0;
    correctInBlock = 0;
    _wrongInBlock.clear();
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
    final due =
        cards.entries
            .where(
              (e) =>
                  e.value.stage == CardStage.review &&
                  !isHidden(e.key) &&
                  (early ? e.value.dueMs > now : e.value.dueMs <= now),
            )
            .toList()
          ..sort((a, b) => a.value.dueMs.compareTo(b.value.dueMs));
    _intro.clear();
    _midNew.clear();
    _queue
      ..clear()
      ..addAll(due.take(early ? earlyBatch : reviewBatch).map((e) => e.key));
    // Výběr dávky jde podle termínu, ale uvnitř dávky se slova promíchají,
    // aby nešla podle frekvence.
    _queue.shuffle(_rng);
    if (!early && mode == StudyMode.both) _weaveNewWords();
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
    _midNew.clear();
    _newCursor =
        0; // kurzor se počítá znovu z úložiště (neuložené karty se vrátí)
    final learning =
        cards.entries
            .where(
              (e) => e.value.stage == CardStage.learning && !isHidden(e.key),
            )
            .map((e) => e.key)
            .toList()
          ..sort();
    final group = learning.take(groupSize).toList();
    var room = math.min(groupSize - group.length, newPerBlock - newInBlock);
    // Nejdřív nová slova označená "učit přednostně" (v pořadí učení).
    if (room > 0 && prioritized.isNotEmpty) {
      for (final k in order) {
        if (room == 0) break;
        if (prioritized.contains(k) &&
            !cards.containsKey(k) &&
            !group.contains(k)) {
          group.add(k);
          newInBlock++;
          room--;
        }
      }
    }
    // Zbytek skupiny: další nová slova v pořadí (už vybraná přeskočí).
    for (; room > 0; room--) {
      var i = _nextUnseen();
      while (i != null && group.contains(i)) {
        _newCursor++;
        i = _nextUnseen();
      }
      if (i == null) break;
      group.add(i);
      _newCursor++;
      newInBlock++;
    }
    if (group.isEmpty) {
      _setInterlude(
        _nextUnseen() != null ? InterludeKind.blockDone : InterludeKind.allDone,
      );
      return;
    }
    _queue
      ..clear()
      ..addAll(group);
    _intro
      ..clear()
      ..addAll(
        group.where((i) {
          final p = cards[i];
          return p == null || (p.streak == 0 && !p.relearn);
        }),
      );
    if (_intro.isEmpty) _queue.shuffle(_rng);
    phase = Phase.learning;
    interlude = null;
    phaseDone = 0;
    phaseTotal = group.length;
    serial++;
  }

  /// V kombinované relaci vloží chybějící nová slova (do cíle nových slov)
  /// rovnoměrně mezi splatná opakování. Slovo se představí uprostřed fronty
  /// a jeho další kola přijdou s odstupem v kartách (viz ackIntro, answer).
  void _weaveNewWords() {
    final goal = newWordsGoal?.call() ?? 0;
    final missing = goal - (learnedToday?.call() ?? 0);
    var want = math.min(missing, newPerBlock - newInBlock);
    if (want <= 0 || _queue.isEmpty) return;
    final picked = <int>[];
    // Nejdřív nová slova označená "učit přednostně", pak další v pořadí.
    for (final k in order) {
      if (picked.length >= want) break;
      if (prioritized.contains(k) && !cards.containsKey(k)) picked.add(k);
    }
    for (final k in order) {
      if (picked.length >= want) break;
      if (!cards.containsKey(k) && !picked.contains(k)) picked.add(k);
    }
    if (picked.isEmpty) return;
    final n = _queue.length;
    final k = picked.length;
    // Od konce, ať se dřívější vložení neposouvají.
    for (var j = k - 1; j >= 0; j--) {
      final pos = math.max(1, ((j + 1) * n / (k + 1)).round());
      _queue.insert(math.min(pos, _queue.length), picked[j]);
      _midNew.add(picked[j]);
    }
    newInBlock += k;
    phaseTotal += k;
  }

  void finish() {
    phase = Phase.idle;
    interlude = null;
    _intro.clear();
    _midNew.clear();
    _queue.clear();
    _newCursor = 0;
    serial++;
  }

  // ---- odpovědi ----

  /// Konec představení nové karty: karta se zapíše do úložiště jako "učení".
  void ackIntro() {
    if (_intro.isEmpty && _frontIsMidNew) {
      final i = _queue.removeAt(0);
      _midNew.remove(i);
      prioritized.remove(i);
      cards.putIfAbsent(
        i,
        () => CardProgress.learning(_clock().millisecondsSinceEpoch),
      );
      // První ověření po 3-5 kartách; další kola řeší answer().
      _insert(i, 3 + _rng.nextInt(3));
      serial++;
      return;
    }
    if (_intro.isEmpty) return;
    final i = _intro.removeAt(0);
    prioritized.remove(i);
    cards.putIfAbsent(
      i,
      () => CardProgress.learning(_clock().millisecondsSinceEpoch),
    );
    if (_intro.isEmpty) _queue.shuffle(_rng);
    serial++;
  }

  /// "Už umím": karta se při představení přeskočí a rovnou jde do opakování
  /// (první ověření za Scheduler.skipStabilityDays dní). Do limitu nových slov se nepočítá.
  void skipIntro() {
    if (_intro.isEmpty && _frontIsMidNew) {
      final i = _queue.removeAt(0);
      _midNew.remove(i);
      prioritized.remove(i);
      final now = _clock();
      cards[i] = CardProgress(
        stage: CardStage.review,
        stability: Scheduler.skipStabilityDays,
        lastReviewMs: now.millisecondsSinceEpoch,
        dueMs: Scheduler.dueFor(now, Scheduler.skipStabilityDays),
      );
      if (newInBlock > 0) newInBlock--;
      skippedInBlock++;
      phaseTotal = math.max(0, phaseTotal - 1);
      serial++;
      if (_queue.isEmpty) _finishReviews();
      return;
    }
    if (_intro.isEmpty) return;
    final i = _intro.removeAt(0);
    prioritized.remove(i);
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
    if (_intro.isNotEmpty || _queue.isEmpty || _frontIsMidNew) return;
    final c = _queue.removeAt(0);
    final p = cards[c];
    if (p == null) return;
    final now = _clock();
    final nowMs = now.millisecondsSinceEpoch;

    answeredInBlock++;
    if (known) {
      correctInBlock++;
    } else {
      _wrongInBlock[c] = (_wrongInBlock[c] ?? 0) + 1;
    }

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

  void _insert(int c, int pos) =>
      _queue.insert(math.min(pos, _queue.length), c);

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
