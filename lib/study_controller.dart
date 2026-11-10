import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models/card_progress.dart';
import 'models/course.dart';
import 'services/motivation.dart';
import 'services/progress_store.dart';
import 'services/scheduler.dart';
import 'services/settings_store.dart';
import 'services/study_session.dart';

/// Souhrn jedné "stovky" slov pro mapu slov.
class BandStat {
  final int start; // index prvního slova (od 0)
  final int total;
  int unseen;
  int learning = 0;
  int review = 0;
  int solid = 0;
  double _scoreSum = 0;

  BandStat(this.start, this.total) : unseen = total;

  int get end => start + total; // exkluzivně
  double get score => total == 0 ? 0 : _scoreSum / total;
}

/// Spojuje relaci (StudySession), ukládání, nastavení a UI.
class StudyController extends ChangeNotifier {
  StudyController(this.course, this.store, this.settings);

  final Course course;
  final ProgressStore store;
  final AppSettings settings; // sdílené nastavení celé aplikace
  late StudySession session;
  List<int> _order = const []; // viditelné klíče v pořadí učení
  Map<int, int> _posInOrder = const {}; // klíč -> pozice ve viditelném seznamu

  bool showBack = false;
  final Map<int, int> _shown =
      {}; // kolikrát už byla karta v této relaci zodpovězena
  final List<Achievement> _pending = [];

  /// Od jaké jistoty se slovo počítá jako "pevně zvládnuté".
  static const double solidConfidence = 0.75;

  Future<void> init() async {
    await store.load(migrateLegacy: course.migratesLegacyProgress);
    _rebuildView();
    Motivation.seedBadges(store, learnedCount);
  }

  // --- filtr vulgarit a číslování ---
  bool _hidden(int key) =>
      !course.has(key) || (settings.hideVulgar && course.isVulgar(key));

  /// Přepočítá viditelný seznam a založí novou relaci (postup v úložišti zůstává).
  void _rebuildView() {
    _order = [
      for (final k in course.keys)
        if (!_hidden(k)) k,
    ];
    _posInOrder = {for (var i = 0; i < _order.length; i++) _order[i]: i};
    _undo.clear();
    _shown.clear();
    showBack = false;
    session = StudySession(
      order: _order,
      isHidden: _hidden,
      cards: store.cards,
      prioritized: store.prioritized,
      onCardDone: store.recordDone,
    );
  }

  /// Viditelná slova v pořadí učení (klíče).
  List<int> get order => _order;

  /// Počet viditelných slov (pro "slovo X z N").
  int get totalWords => _order.length;

  /// Číslo slova v UI: pozice ve vyfiltrovaném seznamu + 1.
  int numberOf(int key) => (_posInOrder[key] ?? 0) + 1;

  // --- čtení stavu ---
  Phase get phase => session.phase;
  InterludeKind? get interlude => session.interlude;
  int? get current => session.current;
  int? get next => session.next;
  bool get isIntro => session.isIntro;
  int get serial => session.serial;

  double get phaseProgress =>
      session.phaseTotal == 0 ? 0 : session.phaseDone / session.phaseTotal;

  /// Slova v opakování (= už naučená).
  int get learnedCount =>
      store.cards.entries
          .where((e) => e.value.stage == CardStage.review && !_hidden(e.key))
          .length;

  /// Slova s jistotou aspoň 75 %.
  int get solidCount =>
      store.cards.entries
          .where(
            (e) =>
                e.value.stage == CardStage.review &&
                !_hidden(e.key) &&
                Scheduler.confidence(e.value.stability) >= solidConfidence,
          )
          .length;

  int get reviewedToday => store.reviewedToday;
  int get learnedToday => store.learnedToday;

  // --- motivace ---
  int get doneToday => store.doneToday;
  int get dailyGoal => settings.dailyGoal;
  int get streak => Motivation.streakNow(store, DateTime.now());
  int get bestStreak => store.bestStreak;
  Set<int> get badges => store.badges;

  bool get hasAchievements => _pending.isNotEmpty;

  List<Achievement> takeAchievements() {
    final l = List<Achievement>.of(_pending);
    _pending.clear();
    return l;
  }

  void _afterProgress() {
    _pending.addAll(
      Motivation.update(
        store: store,
        goal: settings.dailyGoal,
        learnedCount: learnedCount,
        now: DateTime.now(),
      ),
    );
  }

  // --- mapa slov ---
  int get bandSize => _order.length <= 600 ? 50 : 100;

  List<BandStat> bandStats() {
    final size = bandSize;
    final n = _order.length;
    final bands = <BandStat>[
      for (var s = 0; s < n; s += size) BandStat(s, math.min(size, n - s)),
    ];
    store.cards.forEach((key, p) {
      final i = _posInOrder[key];
      if (i == null) return; // skryté nebo neznámé slovo
      final b = bands[i ~/ size];
      b.unseen--;
      if (p.stage == CardStage.learning) {
        b.learning++;
        b._scoreSum += 0.15;
      } else {
        b.review++;
        final conf = Scheduler.confidence(p.stability);
        if (conf >= solidConfidence) b.solid++;
        b._scoreSum += 0.4 + 0.6 * conf;
      }
    });
    return bands;
  }

  // --- učit přednostně ---
  /// Označit lze jen nové slovo (naučená a rozpracovaná se řídí rozvrhem).
  bool canPrioritize(int key) => !store.cards.containsKey(key);
  bool isPrioritized(int key) => store.prioritized.contains(key);

  void togglePriority(int key) {
    if (!canPrioritize(key)) return;
    if (!store.prioritized.add(key)) store.prioritized.remove(key);
    store.scheduleSave();
    notifyListeners();
  }

  CardInfo infoOf(int i) {
    final p = store.cards[i];
    if (p == null) return const CardInfo(kind: CardKind.newCard);
    if (p.stage == CardStage.learning) {
      // Vždy 3 bublinky; karta po chybě má první už vyplněnou.
      return CardInfo(
        kind: CardKind.learning,
        streak: p.streak + (p.relearn ? 1 : 0),
        target: 3,
      );
    }
    return CardInfo(
      kind: CardKind.review,
      confidence: Scheduler.confidence(p.stability),
    );
  }

  /// Která strana karty se ukáže jako první: true = rodné slovo (course.front).
  bool nativeFrontFor(int i) {
    switch (settings.directionMode) {
      case DirectionMode.nativeFront:
        return true;
      case DirectionMode.learnedFront:
        return false;
      case DirectionMode.auto:
        final p = store.cards[i];
        if (p != null && p.stage == CardStage.learning) {
          if (p.streak == 0)
            return false; // 1. zkoušení: poznat učené slovo (snazší)
          if (p.streak == 1) return true; // 2. zkoušení: vybavit si učené slovo
        }
        final rnd = math.Random(i * 7919 + (_shown[i] ?? 0) * 104729 + 17);
        return rnd.nextDouble() < settings.nativeFrontProb;
    }
  }

  // --- zpět ---
  /// Kolik posledních akcí jde vzít zpět (v rámci aktuálního procvičování).
  static const int undoDepth = 5;
  final List<_Undo> _undo = [];

  bool get canUndo => _undo.isNotEmpty && phase != Phase.idle;

  void _pushUndo({int? shownKey}) {
    _undo.add(
      _Undo(
        session.snapshot(),
        store.snapshotStats(),
        _pending.length,
        shownKey,
      ),
    );
    if (_undo.length > undoDepth) _undo.removeAt(0);
  }

  /// Vrátí poslední kartu (i když skončila fáze a je vidět mezi-obrazovka).
  void undo() {
    if (_undo.isEmpty) return;
    final u = _undo.removeLast();
    session.restore(u.session);
    store.restoreStats(u.stats);
    final k = u.shownKey;
    if (k != null) {
      final n = (_shown[k] ?? 0) - 1;
      if (n <= 0) {
        _shown.remove(k);
      } else {
        _shown[k] = n;
      }
    }
    while (_pending.length > u.pendingLen) {
      _pending.removeLast();
    }
    _changed();
  }

  // --- akce ---
  void _changed() {
    showBack = false;
    store.scheduleSave();
    notifyListeners();
  }

  void start(StudyMode mode) {
    _undo.clear();
    _shown.clear();
    session.startBlock(mode);
    _changed();
  }

  /// Další dávka ve stejném režimu (z obrazovky "Dnešní dávka hotová").
  void nextBlock() {
    _undo.clear();
    session.startBlock();
    _changed();
  }

  void continueReviews() {
    _undo.clear();
    session.startReviews();
    _changed();
  }

  void startLearning() {
    _undo.clear();
    session.startLearning();
    _changed();
  }

  /// Zpět na domovskou stránku.
  void finish() {
    _undo.clear();
    session.finish();
    _changed();
  }

  void answer(bool known) {
    final c = session.current;
    final counted = c != null && !session.isIntro;
    if (c == null || session.isIntro) return;
    _pushUndo(shownKey: counted ? c : null);
    _shown[c] = (_shown[c] ?? 0) + 1;
    session.answer(known);
    _afterProgress();
    _changed();
  }

  void ackIntro() {
    if (!session.isIntro) return;
    _pushUndo();
    session.ackIntro();
    _changed();
  }

  /// "Už umím" při představení nového slova.
  void skipIntro() {
    if (!session.isIntro) return;
    _pushUndo();
    session.skipIntro();
    _afterProgress();
    _changed();
  }

  void flip() {
    showBack = !showBack;
    notifyListeners();
  }

  void setDirectionMode(DirectionMode m) {
    settings.directionMode = m;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setNativeFrontProb(double v) {
    settings.nativeFrontProb = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setDailyGoal(int v) {
    settings.dailyGoal = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setHideVulgar(bool v) {
    if (settings.hideVulgar == v) return;
    settings.hideVulgar = v;
    SettingsStore.save(settings);
    store.scheduleSave();
    _rebuildView(); // rozpracovaná relace se zahodí, postup zůstává
    notifyListeners();
  }

  void setHaptics(bool v) {
    settings.haptics = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  Future<void> flush() => store.flush();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }
}

class _Undo {
  final SessionSnapshot session;
  final StatsSnapshot stats;
  final int pendingLen;
  final int? shownKey;
  const _Undo(this.session, this.stats, this.pendingLen, this.shownKey);
}
