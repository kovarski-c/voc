import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voc_autumn_2026/models/card_progress.dart';
import 'package:voc_autumn_2026/services/placement.dart';

/// Simulace člověka, který zná prvních [trueKnown] slov a ostatní ne.
int simulate(int total, int trueKnown, int seed) {
  final t = PlacementTest(total: total, rng: Random(seed));
  var guard = 0;
  while (!t.done && guard++ < 200) {
    t.answer(t.currentRank! < trueKnown);
  }
  expect(t.done, isTrue);
  expect(t.answers.length, lessThanOrEqualTo(25));
  return t.estimate;
}

void main() {
  test('test najde hranici přibližně a ptá se na málo slov', () {
    for (final known in [0, 700, 3000, 6000, 10000]) {
      final est = simulate(10000, known, 7);
      expect((est - known).abs(), lessThan(10000 * 0.2),
          reason: 'known=$known est=$est');
    }
  });

  test('stabilita klesá od frekventovaných slov k hranici', () {
    expect(PlacementPlan.stabilityAt(0), closeTo(365, 0.5));
    expect(PlacementPlan.stabilityAt(1), closeTo(14, 0.5));
    expect(PlacementPlan.stabilityAt(0.5), lessThan(PlacementPlan.stabilityAt(0.2)));
  });

  test('plán: nejvýš perDay slov denně, neznámá a existující se přeskočí', () {
    final order = List<int>.generate(2000, (i) => i + 1);
    final now = DateTime(2026, 11, 13, 10);
    final plan = PlacementPlan.build(
      order: order,
      known: 1000,
      answers: const [
        PlacementAnswer(990, false), // neznal: zůstane nové
        PlacementAnswer(500, true), // znal: ověřené
      ],
      existing: {1},
      perDay: 4,
      now: now,
    );
    expect(plan.containsKey(1), isFalse); // už mělo pokrok
    expect(plan.containsKey(order[990]), isFalse); // neznal
    expect(plan.containsKey(order[1500]), isFalse); // nad odhadem, bez odpovědi
    expect(plan[order[500]]!.stability, greaterThanOrEqualTo(30));
    expect(plan.values.every((c) => c.stage == CardStage.review), isTrue);

    final perDue = <int, int>{};
    for (final e in plan.entries) {
      if (e.key == order[500]) continue; // ověřené slovo má vlastní termín
      perDue[e.value.dueMs] = (perDue[e.value.dueMs] ?? 0) + 1;
    }
    expect(perDue.values.every((n) => n <= 4), isTrue);
    // nejdřív přijdou na řadu slova u hranice
    expect(plan[order[998]]!.dueMs, lessThan(plan[order[10]]!.dueMs));
  });
}
