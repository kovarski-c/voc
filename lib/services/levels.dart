import '../models/level.dart';

/// Úrovně slovní zásoby. Čistá logika, nic si neukládá.
class Levels {
  /// Úrovně, kterých se v seznamu o [total] slovech dá dosáhnout.
  static List<LevelStep> reachable(List<LevelStep> all, int total) => [
    for (final l in all)
      if (l.threshold <= total) l,
  ];

  /// Nejvyšší dosažená úroveň (null = ještě žádná).
  static LevelStep? current(List<LevelStep> steps, int learned) {
    LevelStep? out;
    for (final l in steps) {
      if (learned >= l.threshold) out = l;
    }
    return out;
  }

  /// Nejbližší úroveň, které ještě nebylo dosaženo (null = všechny hotové).
  static LevelStep? next(List<LevelStep> steps, int learned) {
    for (final l in steps) {
      if (learned < l.threshold) return l;
    }
    return null;
  }
}
