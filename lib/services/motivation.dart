import 'dart:math' as math;

import '../models/level.dart';
import 'progress_store.dart';
import 'scheduler.dart';
import 'streak_store.dart';

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

  /// Odznaky za slova naučená uživatelem (bez slov z úvodního testu).
  static const List<int> milestones = [
    10, 20, 50, 100, 200, 300, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500,
    4000, 4500, 5000, 6000, 7000, 8000, 9000, 10000,
  ];
  static const List<int> streakMarks = [3, 7, 14, 30, 50, 100, 200, 365];

  /// Při prvním načtení se už dosažené milníky zapíšou potichu (bez oslav).
  static void seedBadges(ProgressStore s, int badgeCount) {
    if (s.badgesSeeded) return;
    s.badges.removeWhere((m) => !milestones.contains(m));
    for (final m in milestones) {
      if (badgeCount >= m) s.badges.add(m);
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

  /// Po úvodním výběru úrovně: dosažené úrovně se zapíšou potichu.
  /// Odznaky ne, ty se počítají od nuly (jen slova naučená po testu).
  static void syncSilently(
      ProgressStore s, List<LevelStep> levels, int learned) {
    for (final l in levels) {
      if (learned >= l.threshold) s.levelCodes.add(l.code);
    }
    s.scheduleSave();
  }

  /// Aktuální série (0, pokud už by byla přerušená).
  static int streakNow(StreakStore s, DateTime now) {
    if (s.lastActiveDay == 0) return 0;
    final gap = Scheduler.studyDayNumber(now) - s.lastActiveDay;
    if (gap <= 1) return s.streak;
    if (gap - 1 <= s.freezes) return s.streak;
    return 0;
  }

  /// Započítá dnešek do série, pokud je dnes hotových aspoň [streakMinCards]
  /// karet (v součtu přes všechny kurzy). Vrací oslavu série, nebo null.
  static Achievement? creditStreak(StreakStore s, DateTime now) {
    final today = Scheduler.studyDayNumber(now);
    if (s.cardsToday(today) < streakMinCards || s.lastActiveDay >= today) {
      return null;
    }
    final last = s.lastActiveDay;
    if (last == 0) {
      s.streak = 1;
    } else {
      final gap = today - last;
      if (gap == 1) {
        s.streak++;
      } else {
        final missed = gap - 1;
        if (s.freezes >= missed) {
          s.freezes -= missed;
          s.streak++;
        } else {
          s.streak = 1;
        }
      }
    }
    if (s.streak % 7 == 0 && s.freezes < maxFreezes) s.freezes++;
    s.bestStreak = math.max(s.bestStreak, s.streak);
    s.lastActiveDay = today;
    s.scheduleSave();
    if (streakMarks.contains(s.streak)) {
      return Achievement(AchievementType.streak, s.streak);
    }
    return null;
  }

  /// Volá se po každé zodpovězené kartě. Vrací nové úspěchy k oslavě.
  static List<Achievement> update({
    required ProgressStore store,
    required StreakStore streakStore,
    required int goal,
    required int learnedCount,
    required int badgeCount,
    required DateTime now,
    List<LevelStep> levels = const [],
  }) {
    final out = <Achievement>[];
    final today = Scheduler.studyDayNumber(now);
    final done = store.doneToday;

    final streakAchievement = creditStreak(streakStore, now);
    if (streakAchievement != null) out.add(streakAchievement);

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
      if (badgeCount >= m && !store.badges.contains(m)) {
        store.badges.add(m);
        if (!levelUp) out.add(Achievement(AchievementType.milestone, m));
        store.scheduleSave();
      }
    }
    return out;
  }
}
