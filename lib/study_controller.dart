import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models/card_progress.dart';
import 'models/course.dart';
import 'services/progress_store.dart';
import 'services/scheduler.dart';
import 'services/settings_store.dart';
import 'services/study_session.dart';

/// Spojuje relaci (StudySession), ukládání, nastavení a UI.
class StudyController extends ChangeNotifier {
  StudyController(this.course, this.store, this.settings);

  final Course course;
  final ProgressStore store;
  late final StudySession session;
  final AppSettings settings; // sdílené nastavení celé aplikace

  bool showBack = false;
  final Map<int, int> _shown = {}; // kolikrát už byla karta v této relaci zodpovězena

  /// Od jaké jistoty se slovo počítá jako "pevně zvládnuté".
  static const double solidConfidence = 0.75;

  Future<void> init() async {
    await store.load(migrateLegacy: course.migratesLegacyProgress);
    session = StudySession(
      cardCount: course.length,
      cards: store.cards,
      onCardDone: store.recordDone,
    );
  }

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
      store.cards.values.where((p) => p.stage == CardStage.review).length;

  /// Slova s jistotou aspoň 75 %.
  int get solidCount => store.cards.values
      .where((p) =>
          p.stage == CardStage.review &&
          Scheduler.confidence(p.stability) >= solidConfidence)
      .length;

  int get reviewedToday => store.reviewedToday;
  int get learnedToday => store.learnedToday;

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
          if (p.streak == 0) return false; // 1. zkoušení: poznat učené slovo (snazší)
          if (p.streak == 1) return true; // 2. zkoušení: vybavit si učené slovo
        }
        // Jinak náhodně, ale stabilně pro danou kartu a její n-té zobrazení.
        final rnd = math.Random(i * 7919 + (_shown[i] ?? 0) * 104729 + 17);
        return rnd.nextDouble() < settings.nativeFrontProb;
    }
  }

  // --- akce ---
  void _changed() {
    showBack = false;
    store.scheduleSave();
    notifyListeners();
  }

  void start(StudyMode mode) {
    _shown.clear();
    session.startBlock(mode);
    _changed();
  }

  /// Další dávka ve stejném režimu (z obrazovky "Dnešní dávka hotová").
  void nextBlock() {
    session.startBlock();
    _changed();
  }

  void continueReviews() {
    session.startReviews();
    _changed();
  }

  void startLearning() {
    session.startLearning();
    _changed();
  }

  /// Zpět na domovskou stránku.
  void finish() {
    session.finish();
    _changed();
  }

  void answer(bool known) {
    final c = session.current;
    if (c != null && !session.isIntro) _shown[c] = (_shown[c] ?? 0) + 1;
    session.answer(known);
    _changed();
  }

  void ackIntro() {
    session.ackIntro();
    _changed();
  }

  /// "Už umím" při představení nového slova.
  void skipIntro() {
    session.skipIntro();
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

  Future<void> flush() => store.flush();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }
}
