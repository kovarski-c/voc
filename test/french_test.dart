import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voc_autumn_2026/models/card_progress.dart';
import 'package:voc_autumn_2026/models/course.dart';
import 'package:voc_autumn_2026/services/study_session.dart';
import 'package:voc_autumn_2026/services/word_loader.dart';

void main() {
  test('french.tsv: 3000 slov, 28 vulgárních, id jsou klíče', () {
    final raw = File('assets/words/french/french.tsv').readAsStringSync();
    final words = WordLoader.parse(raw);
    expect(words.length, 3000);
    expect(words.where((w) => w.vulgar).length, 28);

    final course = Course.fromWords(
      id: 'french',
      frontLabel: 'Čeština',
      backLabel: 'Francouzština',
      words: words,
    );
    expect(course.keys.first, words.first.id);
    expect(course.front(words[10].id), words[10].translation);
    expect(course.back(words[10].id), words[10].front);
    final visible = course.keys.where((k) => !course.isVulgar(k)).length;
    expect(visible, 2972);
  });

  test('parser přeskočí vadný řádek a ponechá prázdný poslední sloupec', () {
    const raw = 'h\n1\ta\tb\tc\tVER\t\t0\t5\t\n2\tbroken\n3\tx\ty\tz\tNOM\t\t1\t7\t8\r\n';
    final w = WordLoader.parse(raw);
    expect(w.map((e) => e.id), [1, 3]);
    expect(w[1].vulgar, true);
  });

  test('snapshot/restore vrátí kartu i stav relace', () {
    final cards = <int, CardProgress>{};
    final s = StudySession(
      order: List.generate(20, (i) => i),
      isHidden: (_) => false,
      cards: cards,
    );
    s.startBlock(StudyMode.learnOnly);
    final snap = s.snapshot();
    final first = s.current!;
    s.ackIntro();
    expect(cards.containsKey(first), true);
    s.restore(snap);
    expect(cards.containsKey(first), false);
    expect(s.current, first);
    expect(s.isIntro, true);
  });
}
