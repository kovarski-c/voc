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
  final Set<int> firstTry;

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
    required this.firstTry,
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
    this.recallNew,
  }) : prioritized = prioritized ?? <int>{},
       _clock = clock ?? DateTime.now;

  static const int groupSize = 5;
  static const int newPerBlock = 20;
  static const int reviewBatch = 40;
  static const int earlyBatch = 20; // předčasné opakování nesplatných karet

  /// Skupina menší než [minGroup] karet se doplní splatnými opakováními:
  /// [fillerPerMissing] opakování za každou chybějící kartu, aby se slova
  /// nevracela hned za sebou.
  static const int minGroup = 3;
  static const int fillerPerMissing = 3;

  /// Viditelné klíče karet v pořadí učení (bez skrytých).
  final List<int> order;

  /// Skrytá karta (vulgární při zapnutém filtru, neznámý klíč): nikde se neobjeví.
  final bool Function(int key) isHidden;
  final Map<int, CardProgress> cards; // sdílená mapa s ProgressStore

  /// Nová slova označená "učit přednostně" (sdílená množina s ProgressStore).
  final Set<int> prioritized;
  final DateTime Function() _clock;

  /// Karta definitivně opustila frontu: true = nově naučena, false = zopakována.
  final void Function(bool learned, bool wasDue)? onCardDone;

  /// Cíl nových slov za den a kolik jich je dnes hotových (pro vkládání mezi opakování).
  final int Function()? newWordsGoal;
  final int Function()? learnedToday;

  /// true = nová slova se neukazují s překladem, ale rovnou se zkouší (flashcard).
  final bool Function()? recallNew;
  final math.Random _rng = math.Random();

  StudyMode mode = StudyMode.both;
  Phase phase = Phase.idle;
  InterludeKind? interlude;

  final List<int> _intro = []; // karty, které se nejdřív jen představí
  final List<int> _queue = []; // fronta zkoušení
  // Nová slova vložená doprostřed opakování; dokud nejsou představená, nemají postup.
  final Set<int> _midNew = {};
  // Nová slova zkoušená bez představení; první správná odpověď = "už umím".
  final Set<int> _firstTry = {};
  bool _recallGroup = false;
  int _newCursor = 0;
  // Kolik nových slov (newInBlock) smí skupina nejvýš mít; hlídá doplňování.
  int _newLimit = newPerBlock;

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
  /// Nové slovo zkoušené bez představení (první pokus).
  bool get isFirstTry => current != null && _firstTry.contains(current);
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

  List<int> _learningKeys() =>
      cards.entries
          .where((e) => e.value.stage == CardStage.learning && !isHidden(e.key))
          .map((e) => e.key)
          .toList()
        ..sort();

  /// Kolik zbývá do dnešního cíle nových slov (0 = splněn). V režimu
  /// "Jen učení" se cíl nehlídá.
  int get goalRemaining {
    if (mode == StudyMode.learnOnly || newWordsGoal == null) return 1 << 20;
    return math.max(0, newWordsGoal!() - (learnedToday?.call() ?? 0));
  }

  /// Cíl nových slov na dnes je splněný (další učení je navíc).
  bool get goalReached =>
      mode != StudyMode.learnOnly &&
      newWordsGoal != null &&
      goalRemaining == 0;

  /// Kolik nových slov se přidá ke skupině [group] (rozpracovaná slova).
  /// Rozpracovaná slova (kromě vrácených po chybě) se do cíle započítají,
  /// až je dokončíš, proto zabírají zbývající cíl.
  int _newRoomFor(List<int> group) {
    var room = groupSize - group.length;
    final remaining = goalRemaining;
    if (remaining > 0 && remaining < (1 << 20)) {
      final inGoal = group.where((k) => !(cards[k]?.relearn ?? false)).length;
      room = math.min(room, remaining - inGoal);
    }
    return math.max(0, math.min(room, newPerBlock - newInBlock));
  }

  /// Kolik karet bude mít příští skupina učení (pro text tlačítka).
  int get nextGroupCount {
    final g = _learningKeys().take(groupSize).toList();
    return g.length + math.min(_newRoomFor(g), unseenCount);
  }

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
      firstTry: Set.of(_firstTry),
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
    _firstTry
      ..clear()
      ..addAll(s.firstTry);
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
    _firstTry.clear();
    _recallGroup = recallNew?.call() ?? false;
    _newCursor =
        0; // kurzor se počítá znovu z úložiště (neuložené karty se vrátí)
    final learning = _learningKeys();
    final group = learning.take(groupSize).toList();
    var room = _newRoomFor(group);
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
    _newLimit = newInBlock;
    if (group.isEmpty) {
      _setInterlude(
        _nextUnseen() != null ? InterludeKind.blockDone : InterludeKind.allDone,
      );
      return;
    }
    _queue
      ..clear()
      ..addAll(group);
    _intro.clear();
    if (_recallGroup) {
      // Bez představení: nová slova se rovnou zkouší, rozpracovaná také.
      _firstTry.addAll(group.where((i) => !cards.containsKey(i)));
      // Nejdřív se rozhodne u všech nových slov (Umím / Naučit), teprve pak
      // se začne učit: nová slova jdou na začátek fronty.
      _queue
        ..clear()
        ..addAll(group.where(_firstTry.contains))
        ..addAll(group.where((i) => !_firstTry.contains(i)));
    } else {
      _intro.addAll(
        group.where((i) {
          final p = cards[i];
          return p == null || (p.streak == 0 && !p.relearn);
        }),
      );
    }
    // Malá skupina: doplní se splatnými opakováními (jen mimo "Jen učení").
    var fillerCount = 0;
    if (mode != StudyMode.learnOnly && group.length < minGroup) {
      final now = _clock().millisecondsSinceEpoch;
      final fillers =
          cards.entries
              .where(
                (e) =>
                    e.value.stage == CardStage.review &&
                    e.value.dueMs <= now &&
                    !isHidden(e.key) &&
                    !group.contains(e.key),
              )
              .toList()
            ..sort((a, b) => a.value.dueMs.compareTo(b.value.dueMs));
      final take = (minGroup - group.length) * fillerPerMissing;
      for (final e in fillers.take(take)) {
        _queue.add(e.key);
        fillerCount++;
      }
    }
    if (_intro.isEmpty && _firstTry.isEmpty) _queue.shuffle(_rng);
    phase = Phase.learning;
    interlude = null;
    phaseDone = 0;
    phaseTotal = group.length + fillerCount;
    serial++;
  }

  /// Další úplně nové slovo mimo aktuální skupinu (přednostní první).
  int? _refillWord() {
    for (final k in order) {
      if (prioritized.contains(k) &&
          !cards.containsKey(k) &&
          !_queue.contains(k)) {
        return k;
      }
    }
    var i = _nextUnseen();
    while (i != null && _queue.contains(i)) {
      _newCursor++;
      i = _nextUnseen();
    }
    if (i != null) _newCursor++;
    return i;
  }

  /// Když člověk slovo zahodí jako známé, doplní se skupina novým slovem,
  /// aby se vždy učila celá pětice skutečně nových slov.
  void _refill() {
    if (phase != Phase.learning || newInBlock >= _newLimit) return;
    final k = _refillWord();
    if (k == null) return;
    newInBlock++;
    phaseTotal++;
    if (_recallGroup) {
      // Za poslední dosud nerozhodnuté nové slovo.
      _queue.insert(_queue.where(_firstTry.contains).length, k);
      _firstTry.add(k);
    } else {
      _queue.add(k);
      _intro.add(k);
    }
  }

  /// Slovo se změnilo mimo relaci (ruční změna stavu): vypadne z fronty.
  void forget(int key) {
    final inSession = _queue.contains(key) || _intro.contains(key);
    _intro.remove(key);
    _queue.remove(key);
    _midNew.remove(key);
    _firstTry.remove(key);
    if (!inSession) return;
    phaseTotal = math.max(0, phaseTotal - 1);
    serial++;
    if (_queue.isEmpty) {
      if (phase == Phase.reviewing) {
        _finishReviews();
      } else if (phase == Phase.learning) {
        _finishLearning();
      }
    }
  }

  void finish() {
    phase = Phase.idle;
    interlude = null;
    _intro.clear();
    _midNew.clear();
    _firstTry.clear();
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
    _refill();
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
    final first = _firstTry.remove(c);
    final p = cards[c];
    final now = _clock();
    final nowMs = now.millisecondsSinceEpoch;

    if (first && p == null) {
      // První zkoušení nového slova bez představení.
      answeredInBlock++;
      if (known) {
        // Slovo už umí: rovnou do opakování, do cíle nových slov se nepočítá.
        correctInBlock++;
        cards[c] = CardProgress(
          stage: CardStage.review,
          stability: Scheduler.skipStabilityDays,
          lastReviewMs: nowMs,
          dueMs: Scheduler.dueFor(now, Scheduler.skipStabilityDays),
        );
        prioritized.remove(c);
        if (newInBlock > 0) newInBlock--;
        skippedInBlock++;
        phaseTotal = math.max(0, phaseTotal - 1);
        _refill();
      } else {
        _wrongInBlock[c] = (_wrongInBlock[c] ?? 0) + 1;
        prioritized.remove(c);
        cards[c] = CardProgress.learning(nowMs);
        // Řadí se až za slova, o kterých se ještě nerozhodlo; učení začne,
        // až jsou rozhodnutá všechna nová slova.
        _insert(c, _queue.where(_firstTry.contains).length);
      }
      if (_firstTry.isEmpty && _queue.length > 1) _queue.shuffle(_rng);
      serial++;
      if (_queue.isEmpty) _finishLearning();
      return;
    }
    if (p == null) return;

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
        onCardDone?.call(false, p.dueMs <= nowMs);
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
          onCardDone?.call(false, true); // zapomenutá karta po termínu
        } else {
          learnedInBlock++;
          onCardDone?.call(true, false);
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
