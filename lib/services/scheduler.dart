import 'dart:math' as math;
import '../models/card_progress.dart';

/// Čistá logika plánování (bez UI a bez ukládání). Všechna čísla na jednom místě.
class Scheduler {
  /// Stabilita (ve dnech), od které je jistota 100 %.
  static const double confidenceFullDays = 90;

  /// Studijní den začíná ve 4:00, aby opakování "na dnes" bylo splatné celý den.
  static const int dayStartHour = 4;

  static const double _msPerDay = 86400000;

  /// Stabilita (dny) slova, které uživatel přeskočil jako "už umím".
  /// První ověření proběhne až za tuto dobu.
  static const double skipStabilityDays = 14;

  /// Kolik správných odpovědí v řadě potřebuje karta v učení.
  static int target(CardProgress p) => p.relearn ? 2 : 3;

  /// Odhad pravděpodobnosti vybavení po t dnech při stabilitě s (90 % při t == s).
  static double retrievability(double t, double s) =>
      math.pow(0.9, t / s).toDouble();

  /// Nová stabilita po správné odpovědi po t dnech od posledního opakování.
  /// Čím později (nižší retrievability), tím větší růst; nikdy méně než prokázaná mezera t.
  static double onSuccess(double s, double t) {
    final r = retrievability(t, s);
    final f = math.min(3.5, 1.1 + 8 * (1 - r));
    return math.max(s * f, t);
  }

  /// Stabilita po zapomenutí: desetina, ale 1 až 7 dní.
  static double onLapse(double s) => math.max(1.0, math.min(7.0, 0.1 * s));

  /// Jistota 0..1 (15 % při 1 dni, 100 % od confidenceFullDays).
  static double confidence(double s) {
    final c = 0.15 +
        0.85 * math.log(math.max(s, 1.0)) / math.log(confidenceFullDays);
    return math.min(1.0, c);
  }

  static DateTime studyDate(DateTime now) {
    final d = now.subtract(const Duration(hours: dayStartHour));
    return DateTime(d.year, d.month, d.day);
  }

  /// Pořadové číslo studijního dne (pro série a historii).
  static int studyDayNumber(DateTime now) {
    final d = studyDate(now);
    return DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2020, 1, 1))
        .inDays;
  }

  static int dueAfterDays(DateTime now, int days) {
    final b = studyDate(now);
    return DateTime(b.year, b.month, b.day + days, dayStartHour)
        .millisecondsSinceEpoch;
  }

  static int dueFor(DateTime now, double stability) =>
      dueAfterDays(now, math.max(1, stability.round()));

  static double daysBetween(int fromMs, int toMs) =>
      math.max(0.0, (toMs - fromMs) / _msPerDay);

  /// Převod starého pokroku (skill 0..18) na nový model.
  /// skill 0 = karta už byla viděna, takže zůstává v "učení" (prázdné bublinky).
  static CardProgress fromLegacySkill(int index, int skill, DateTime now) {
    final nowMs = now.millisecondsSinceEpoch;
    if (skill <= 0) return CardProgress.learning(nowMs);
    final s = math.min(30.0, math.pow(1.4, skill).toDouble());
    final spread = math.max(1, s.ceil());
    final b = studyDate(now);
    final due = DateTime(b.year, b.month, b.day + (index % spread), dayStartHour)
        .millisecondsSinceEpoch;
    return CardProgress(
      stage: CardStage.review,
      stability: s,
      lastReviewMs: nowMs,
      dueMs: due,
    );
  }
}
