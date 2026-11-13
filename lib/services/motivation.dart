import 'dart:math' as math;

import '../models/level.dart';
import 'progress_store.dart';
import 'scheduler.dart';

enum AchievementType { goal, streak, milestone, level }

class Achievement {
  final AchievementType type;
  final int value;
  final String? code; // u úrovně např. 'A1'
  const Achievement(this.type, this.value, [this.code]);
}

/// Série dní, denní cíl a milníky. Čistá logika nad ProgressStore.
class Motivation {
  /// Kolik karet za den stačí, aby se den započítal do série.
  static const int streakMinCards = 5;

  /// Nejvíc ochranných dnů (použijí se samy, když jeden den vynecháš).
  static const int maxFreezes = 2;

  static const List<int> milestones = [
    10, 50, 100, 250, 500, 1000, 1500, 2000, 3000, 4000, 5000, 7500, 10000,
  ];
  static const List<int> streakMarks = [3, 7, 14, 30, 50, 100, 200, 365];

  /// Při prvním načtení se už dosažené milníky zapíšou potichu (bez oslav).
  static void seedBadges(ProgressStore s, int learned) {
    if (s.badgesSeeded) return;
    for (final m in milestones) {
      if (learned >= m) s.badges.add(m);
    }
    s.badgesSeeded = true;
    s.scheduleSave();
  }

  /// Už dosažené úrovně se při prvním načtení zapíšou potichu (bez oslav).
  static void seedLevels(
      ProgressStore s, List<LevelStep> levels, int learned) {
    if (s.levelsSeeded) return;
    for (final l in levels) {
      if (learned >= l.threshold) s.levelCodes.add(l.code);
    }
    s.levelsSeeded = true;
    s.scheduleSave();
  }

  /// Po úvodním výběru úrovně: dosažené úrovně a milníky se zapíšou potichu.
  static void syncSilently(
      ProgressStore s, List<LevelStep> levels, int learned) {
    for (final l in levels) {
      if (learned >= l.threshold) s.levelCodes.add(l.code);
    }
    for (final m in milestones) {
      if (learned >= m) s.badges.add(m);
    }
    s.scheduleSave();
  }

  /// Aktuální série (0, pokud už by byla přerušená).
  static int streakNow(ProgressStore s, DateTime now) {
    if (s.lastActiveDay == 0) return 0;
    final gap = Scheduler.studyDayNumber(now) - s.lastActiveDay;
    if (gap <= 1) return s.streak;
    if (gap - 1 <= s.freezes) return s.streak;
    return 0;
  }

  /// Volá se po každé zodpovězené kartě. Vrací nové úspěchy k oslavě.
  static List<Achievement> update({
    required ProgressStore store,
    required int goal,
    required int learnedCount,
    required DateTime now,
    List<LevelStep> levels = const [],
  }) {
    final out = <Achievement>[];
    final today = Scheduler.studyDayNumber(now);
    final done = store.doneToday;

    if (done >= streakMinCards &&
        store.lastActiveDay != today &&
        store.lastActiveDay <= today) {
      final last = store.lastActiveDay;
      if (last == 0) {
        store.streak = 1;
      } else {
        final gap = today - last;
        if (gap == 1) {
          store.streak++;
        } else {
          final missed = gap - 1;
          if (store.freezes >= missed) {
            store.freezes -= missed;
            store.streak++;
          } else {
            store.streak = 1;
          }
        }
      }
      if (store.streak % 7 == 0 && store.freezes < maxFreezes) store.freezes++;
      store.bestStreak = math.max(store.bestStreak, store.streak);
      store.lastActiveDay = today;
      if (streakMarks.contains(store.streak)) {
        out.add(Achievement(AchievementType.streak, store.streak));
      }
      store.scheduleSave();
    }

    if (done >= goal && store.goalCelebratedDay != today) {
      store.goalCelebratedDay = today;
      out.add(Achievement(AchievementType.goal, goal));
      store.scheduleSave();
    }

    // Úrovně slovní zásoby: oslava je pro všechny stejná.
    var levelUp = false;
    for (final l in levels) {
      if (learnedCount >= l.threshold && !store.levelCodes.contains(l.code)) {
        store.levelCodes.add(l.code);
        out.add(Achievement(AchievementType.level, l.threshold, l.code));
        levelUp = true;
        store.scheduleSave();
      }
    }

    // Číselný milník se při současném posunu úrovně zapíše jen tiše.
    for (final m in milestones) {
      if (learnedCount >= m && !store.badges.contains(m)) {
        store.badges.add(m);
        if (!levelUp) out.add(Achievement(AchievementType.milestone, m));
        store.scheduleSave();
      }
    }
    return out;
  }
}
