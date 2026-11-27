import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models/card_progress.dart';
import 'models/course.dart';
import 'models/level.dart';
import 'services/levels.dart';
import 'services/motivation.dart';
import 'services/placement.dart';
import 'services/progress_store.dart';
import 'services/reminder.dart';
import 'services/scheduler.dart';
import 'services/settings_store.dart';
import 'services/streak_store.dart';
import 'services/tips.dart';
import 'services/study_session.dart';
import 'theme.dart' show AppBrightness, AppThemeId;
import 'models/day_stat.dart';

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
  StudyController(this.course, this.store, this.settings, this.streakStore);

  final Course course;
  final ProgressStore store;
  final AppSettings settings; // sdílené nastavení celé aplikace
  final StreakStore streakStore; // série společná pro všechny kurzy

  /// Nastavení tohoto kurzu (cíle, režim nových slov, vulgární slova, směr karet).
  late final CourseSettings cs = settings.forCourse(course.id);
  late StudySession session;
  List<int> _order = const []; // viditelné klíče v pořadí učení
  Map<int, int> _posInOrder = const {}; // klíč -> pozice ve viditelném seznamu

  bool showBack = false;

  /// Požadavek otevřít slovo v seznamu (z ikonky úprav na kartě).
  final ValueNotifier<int?> openWord = ValueNotifier<int?>(null);
  void requestOpenWord(int key) => openWord.value = key;
  final Map<int, int> _shown =
      {}; // kolikrát už byla karta v této relaci zodpovězena
  final List<Achievement> _pending = [];

  /// Od jaké jistoty se slovo počítá jako "pevně zvládnuté".
  static const double solidConfidence = 0.75;

  Future<void> init() async {
    await store.load(migrateLegacy: course.migratesLegacyProgress);
    _rebuildView();
    Motivation.seedBadges(store, badgeCount);
    Motivation.seedLevels(store, course.levels, learnedCount);
    // Kdo už nějaký pokrok má, se na úvodní výběr úrovně neptá.
    if (store.cards.isNotEmpty && !store.placementDone) {
      store.placementDone = true;
      store.scheduleSave();
    }
    // Série se mohla dostat přes hranici (např. po převzetí ze starých kurzů).
    Motivation.creditStreak(streakStore, DateTime.now());
    await syncReminder();
  }

  // --- úvodní výběr úrovně / test ---
  /// Ukázat úvodní výběr? (jen jednou, u kurzu bez pokroku)
  bool get needsPlacement => !store.placementDone && store.cards.isEmpty;

  /// "Začít od nuly": jen se zapamatuje, že se uživatel už ptát nemá.
  void skipPlacement() {
    if (store.placementDone) return;
    store.placementDone = true;
    store.scheduleSave();
    notifyListeners();
  }

  /// Kolik karet vzniklo z úvodního výběru a uživatel je ještě sám neprocvičil.
  int get placementCardCount =>
      store.cards.values.where((p) => p.fromPlacement).length;

  /// Zapíše výsledek testu nebo ručního výběru: prvních [known] slov (v pořadí
  /// učení) se označí jako známá. Slova, která už mají pokrok, se nemění.
  void applyPlacement({
    required int known,
    List<PlacementAnswer> answers = const [],
    bool resetAbove = false,
  }) {
    // Slova z dřívějšího výběru nad novou úrovní se vrátí mezi nová; pod ní
    // zůstanou, jak jsou (i s postupem). Při [resetAbove] se smaže i všechen
    // vlastní pokrok nad novou úrovní. Plán se pak doplní (nahoru i dolů).
    int rankOf(int key) => _posInOrder[key] ?? -1;
    store.cards.removeWhere((k, p) {
      final r = rankOf(k);
      if (resetAbove && r >= known) return true;
      return p.fromPlacement && (r < 0 || r >= known);
    });
    final plan = PlacementPlan.build(
      order: _order,
      known: known,
      answers: answers,
      existing: store.cards.keys.toSet(),
      perDay: PlacementPlan.perDayFor(cs.dailyGoal),
      now: DateTime.now(),
    );
    store.cards.addAll(plan);
    store.prioritized.removeAll(plan.keys);
    store.placementDone = true;
    // po snížení úrovně se přepočítají štíty a odznaky nad novým počtem slov
    store.levelCodes.clear();
    store.badgeBase =
        store.cards.values
            .where((p) => p.fromPlacement && p.stage == CardStage.review)
            .length;
    store.badges.removeWhere((m) => m > badgeCount);
    Motivation.syncSilently(store, course.levels, learnedCount);
    store.scheduleSave();
    _rebuildView();
    notifyListeners();
  }

  /// Počet všech karet s pokrokem (0 = čistý začátek).
  int get cardCount => store.cards.length;

  /// Kolik slov nad úrovní [known] má vlastní pokrok (neoznačené z testu).
  int practicedAbove(int known) =>
      store.cards.entries
          .where(
            (e) =>
                !e.value.fromPlacement && (_posInOrder[e.key] ?? -1) >= known,
          )
          .length;

  // --- filtr vulgarit a číslování ---
  bool _hiddenBase(int key) =>
      !course.has(key) || (cs.hideVulgar && course.isVulgar(key));

  /// Skrytá slova (vulgarity a slova vyřazená tlačítkem „Neučit“). Vyřazená
  /// zůstávají v seznamu slov (jde je vrátit), ale session je nenabízí a
  /// nepočítají se do pokroku.
  bool _hidden(int key) => _hiddenBase(key) || store.excluded.contains(key);

  /// Přepočítá viditelný seznam a založí novou relaci (postup v úložišti zůstává).
  void _rebuildView() {
    _order = [
      for (final k in course.keys)
        if (!_hiddenBase(k)) k,
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
      onCardDone:
          (learned, wasDue) {
            store.recordDone(learned, wasDue: wasDue);
            streakStore.recordCard();
          },
      newWordsGoal: () => cs.newWordsGoal,
      recallNew: () => cs.newWordMode == NewWordMode.recall,
      learnedToday:
          () =>
              store.history[Scheduler.studyDayNumber(DateTime.now())]?[1] ?? 0,
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

  /// Slova naučená uživatelem pro odznaky (bez slov z úvodního testu).
  int get badgeCount => math.max(0, learnedCount - store.badgeBase);

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

  /// Jmenovatel statistiky "zopakováno X / Y": dnešní opakování po termínu
  /// plus karty, které na opakování ještě čekají. Předčasná opakování ho
  /// nezvyšují (čitatel [reviewedToday] je ale počítá).
  int get dueTotalToday => store.reviewedDueToday + session.dueCount;
  int get learnedToday => store.learnedToday;

  // --- motivace ---
  int get doneToday => store.doneToday;
  int get dailyGoal => cs.dailyGoal;
  int get newWordsGoal => cs.newWordsGoal;
  int get streak => Motivation.streakNow(streakStore, DateTime.now());
  int get bestStreak => streakStore.bestStreak;
  Set<int> get badges => store.badges;

  List<DayStat> lastDays(int count, {int endOffset = 0}) {
    final today = Scheduler.studyDayNumber(DateTime.now());
    final base = DateTime.utc(2020, 1, 1);
    final out = <DayStat>[];
    for (var i = count - 1; i >= 0; i--) {
      final day = today - endOffset - i;
      final h = store.history[day] ?? const [0, 0];
      out.add(DayStat(day, base.add(Duration(days: day)), h[0], h[1]));
    }
    return out;
  }

  // --- úrovně slovní zásoby ---
  /// Úrovně, kterých lze v tomto seznamu dosáhnout.
  List<LevelStep> get levels => Levels.reachable(course.levels, totalWords);
  LevelStep? get currentLevel => Levels.current(levels, learnedCount);
  LevelStep? get nextLevel => Levels.next(levels, learnedCount);
  Set<String> get levelCodes => store.levelCodes;

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
        streakStore: streakStore,
        goal: cs.dailyGoal,
        learnedCount: learnedCount,
        badgeCount: badgeCount,
        now: DateTime.now(),
        levels: course.levels,
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

  // --- vyřazená slova („Neučit“) ---
  bool isExcluded(int key) => store.excluded.contains(key);

  /// Při představení lze vyřadit jen nové (ještě nezačaté) slovo.
  bool canExclude(int key) =>
      !store.cards.containsKey(key) && !store.excluded.contains(key);

  /// Vyřazení nového slova při představení / prvním pokusu.
  void excludeNew(int key) {
    if (!canExclude(key)) return;
    store.excluded.add(key);
    store.prioritized.remove(key);
    session.dropNew(key);
    _undo.clear();
    _afterProgress();
    _changed();
  }

  /// Vyřazení libovolného slova ze seznamu (smaže i jeho pokrok).
  void excludeWord(int key) {
    store.excluded.add(key);
    store.prioritized.remove(key);
    store.cards.remove(key);
    session.forget(key);
    _undo.clear();
    _afterProgress();
    _changed();
  }

  /// Vrátí vyřazené slovo mezi nová.
  void restoreWord(int key) {
    if (!store.excluded.remove(key)) return;
    _undo.clear();
    _afterProgress();
    _changed();
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
    switch (cs.directionMode) {
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
        return rnd.nextDouble() < cs.nativeFrontProb;
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
        streakStore.snapshot(),
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
    streakStore.restore(u.streak);
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
    // Série se dnes právě započítala (nebo se to vzalo zpět): přeplánovat připomínku.
    if (streakStore.lastActiveDay != _reminderDay) syncReminder();
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
    cs.directionMode = m;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setNativeFrontProb(double v) {
    cs.nativeFrontProb = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setDailyGoal(int v) {
    cs.dailyGoal = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setNewWordsGoal(int v) {
    cs.newWordsGoal = v.clamp(1, 50);
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setHideVulgar(bool v) {
    if (cs.hideVulgar == v) return;
    cs.hideVulgar = v;
    SettingsStore.save(settings);
    store.scheduleSave();
    _rebuildView(); // rozpracovaná relace se zahodí, postup zůstává
    notifyListeners();
  }

  /// Ruční změna stavu slova (nové / učím se / umím) z detailu slova.
  void setWordKind(int key, CardKind kind) {
    store.excluded.remove(key);
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    switch (kind) {
      case CardKind.newCard:
        store.cards.remove(key);
      case CardKind.learning:
        store.cards[key] = CardProgress.learning(ms);
        store.prioritized.remove(key);
      case CardKind.review:
        store.cards[key] = CardProgress(
          stage: CardStage.review,
          stability: Scheduler.skipStabilityDays,
          lastReviewMs: ms,
          dueMs: Scheduler.dueFor(now, Scheduler.skipStabilityDays),
        );
        store.prioritized.remove(key);
    }
    session.forget(key);
    _undo.clear();
    _afterProgress();
    _changed();
  }

  void markExcludeHelpSeen() {
    if (settings.seenExcludeHelp) return;
    settings.seenExcludeHelp = true;
    SettingsStore.save(settings);
  }

  void markTipsHelpSeen() {
    if (settings.seenTipsHelp) return;
    settings.seenTipsHelp = true;
    SettingsStore.save(settings);
  }

  void setNewWordMode(NewWordMode m) {
    cs.newWordMode = m;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setShowTips(bool v) {
    settings.showTips = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  /// Denní tip (stejný celý studijní den): k učení slov, k aplikaci nebo k úrovni.
  Tip get dailyTip => Tips.forDay(
    course: course,
    current: currentLevel,
    next: nextLevel,
    learned: learnedCount,
    now: DateTime.now(),
  );

  void setHaptics(bool v) {
    settings.haptics = v;
    SettingsStore.save(settings);
    notifyListeners();
  }

  // --- připomínka série (Android) ---
  int _reminderDay = -1; // lastActiveDay série, pro který je připomínka naplánovaná

  /// Naplánuje (nebo zruší) připomínku podle nastavení a toho, jestli už je
  /// dnešek do série započítaný.
  Future<void> syncReminder() {
    _reminderDay = streakStore.lastActiveDay;
    return Reminder.sync(
      enabled: settings.reminderEnabled,
      minutes: settings.reminderMinutes,
      lastActiveDay: streakStore.lastActiveDay,
      streak: Motivation.streakNow(streakStore, DateTime.now()),
    );
  }

  /// Zapnutí vyžádá povolení oznámení; vrací false, když ho uživatel odmítl.
  Future<bool> setReminderEnabled(bool v) async {
    if (v && !await Reminder.requestPermission()) return false;
    settings.reminderEnabled = v;
    SettingsStore.save(settings);
    await syncReminder();
    notifyListeners();
    return true;
  }

  void setReminderTime(int minutes) {
    settings.reminderMinutes = minutes.clamp(0, 1439);
    SettingsStore.save(settings);
    syncReminder();
    notifyListeners();
  }

  void setAppearance(AppBrightness b) {
    if (settings.appearance == b) return;
    settings.appearance = b;
    SettingsStore.save(settings);
    notifyListeners();
  }

  void setTheme(AppThemeId t) {
    if (settings.theme == t) return;
    settings.theme = t;
    SettingsStore.save(settings);
    notifyListeners();
  }

  Future<void> flush() => Future.wait([store.flush(), streakStore.flush()]);

  @override
  void dispose() {
    openWord.dispose();
    store.dispose();
    super.dispose();
  }
}

class _Undo {
  final SessionSnapshot session;
  final StatsSnapshot stats;
  final StreakSnapshot streak;
  final int pendingLen;
  final int? shownKey;
  const _Undo(
    this.session,
    this.stats,
    this.streak,
    this.pendingLen,
    this.shownKey,
  );
}
