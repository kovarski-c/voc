/// Stav karty v úložišti. Karta, která v úložišti není, je "nová" (nikdy neviděná).
enum CardStage { learning, review }

/// Jak se karta zobrazuje (štítek "nová" / "učení" / "opakování").
enum CardKind { newCard, learning, review }

class CardInfo {
  final CardKind kind;
  final int streak; // správné odpovědi v řadě (jen učení)
  final int target; // kolik jich je potřeba (3, po chybě 2)
  final double confidence; // 0..1 (jen opakování)

  const CardInfo({
    required this.kind,
    this.streak = 0,
    this.target = 3,
    this.confidence = 0,
  });
}

class CardProgress {
  final CardStage stage;
  final int streak; // správně v řadě během učení
  final bool relearn; // karta se vrátila do učení po chybě
  final double stability; // dny; z ní se počítá jistota
  final int lastReviewMs;
  final int dueMs; // kdy je splatné opakování
  final int lapses; // kolikrát bylo slovo zapomenuto

  const CardProgress({
    required this.stage,
    this.streak = 0,
    this.relearn = false,
    this.stability = 1.0,
    required this.lastReviewMs,
    required this.dueMs,
    this.lapses = 0,
  });

  factory CardProgress.learning(int nowMs) =>
      CardProgress(stage: CardStage.learning, lastReviewMs: nowMs, dueMs: nowMs);

  CardProgress copyWith({
    CardStage? stage,
    int? streak,
    bool? relearn,
    double? stability,
    int? lastReviewMs,
    int? dueMs,
    int? lapses,
  }) =>
      CardProgress(
        stage: stage ?? this.stage,
        streak: streak ?? this.streak,
        relearn: relearn ?? this.relearn,
        stability: stability ?? this.stability,
        lastReviewMs: lastReviewMs ?? this.lastReviewMs,
        dueMs: dueMs ?? this.dueMs,
        lapses: lapses ?? this.lapses,
      );

  Map<String, dynamic> toJson() => {
        'g': stage.index,
        'k': streak,
        'r': relearn ? 1 : 0,
        's': stability,
        'l': lastReviewMs,
        'd': dueMs,
        'x': lapses,
      };

  factory CardProgress.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return CardProgress(
      stage: CardStage.values[m['g'] as int],
      streak: m['k'] as int,
      relearn: (m['r'] as int) == 1,
      stability: (m['s'] as num).toDouble(),
      lastReviewMs: m['l'] as int,
      dueMs: m['d'] as int,
      lapses: m['x'] as int,
    );
  }
}
