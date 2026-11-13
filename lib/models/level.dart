import 'package:flutter/painting.dart';
import '../theme.dart';

/// Jedna úroveň slovní zásoby (např. A1 od 700 naučených slov).
/// Barvy jsou součástí nastavení kurzu, takže poslední úroveň seznamu
/// může být purpurová, i když je to třeba B2.
class LevelStep {
  final String code; // 'A1', 'A2', ... (podle něj se ukládá dosažení)
  final int threshold; // kolik naučených slov je potřeba
  final Color light; // světlejší konec přechodu
  final Color dark; // sytější konec přechodu / obrys
  final Color onColor; // barva písmen na vyplněném štítu

  const LevelStep(
    this.code,
    this.threshold, {
    required this.light,
    required this.dark,
    this.onColor = const Color(0xFFFFFFFF),
  });
}

// Paleta úrovní (jen pro štíty a oslavy; stavy karet mají vlastní barvy).

LevelStep levelA1(int t) => LevelStep(
  'A1',
  t,
  light: kToneAmber.accent,
  dark: Color.fromARGB(200, 217, 140, 16),
  onColor: Color(0xFFFFFFFF),
);
LevelStep levelA2(int t) => LevelStep(
  'A2',
  t,
  light: kToneAmber.solidA,
  dark: Color.fromARGB(200, 255, 179, 0),
);
LevelStep levelB1(int t) => LevelStep(
  'B1',
  t,
  light: kToneGreen.solidA,
  dark: Color.fromARGB(200, 35, 193, 106),
);
LevelStep levelB2(int t, {bool top = false}) =>
    top
        ? LevelStep(
          'B2',
          t,
          light: kToneBlue.solidB,
          dark: Color.fromARGB(200, 106, 77, 235),
        )
        : LevelStep(
          'B2',
          t,
          light: kToneBlue.solidA,
          dark: Color.fromARGB(200, 47, 110, 237),
        );
LevelStep levelC1(int t) => LevelStep(
  'C1',
  t,
  light: kToneBlue.solidB,
  dark: Color.fromARGB(200, 106, 77, 235),
);
