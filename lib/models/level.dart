import 'package:flutter/painting.dart';
import 'package:material_ui/material_ui.dart';
import '../theme.dart';

/// Jedna úroveň slovní zásoby (např. A1 od 700 naučených slov).
///
/// Barvy se nepočítají při vytvoření úrovně, ale pokaždé při čtení z právě
/// aktivní palety ([palette] v theme.dart). Díky tomu se štíty přebarví
/// hned po přepnutí tématu, i když jsou úrovně součástí kurzu načteného
/// už při startu.
class LevelStep {
  final String code; // 'A1', 'A2', ... (podle něj se ukládá dosažení)
  final int threshold; // kolik naučených slov je potřeba
  final Color Function(AppPalette) _light;
  final Color Function(AppPalette) _dark;
  final Color Function(AppPalette)? _onColor;

  /// Krátké texty "co s touto úrovní můžeš dělat". První se ukáže v oslavě
  /// nové úrovně, všechny se střídají v denním tipu.
  final List<String> tips;

  LevelStep(
    this.code,
    this.threshold, {
    required Color Function(AppPalette) light,
    required Color Function(AppPalette) dark,
    Color Function(AppPalette)? onColor,
    this.tips = const [],
  }) : _light = light,
       _dark = dark,
       _onColor = onColor;

  Color get light => _light(palette); // světlejší konec přechodu
  Color get dark => _dark(palette); // sytější konec přechodu / obrys
  Color get onColor =>
      _onColor?.call(palette) ?? const Color(0xFFFFFFFF); // písmena na štítu
}

/// Výchozí texty podle kódu úrovně. Úrovně jsou podle počtu slov, ne podle
/// zkoušky, proto "zhruba". Pro konkrétní kurz jdou přepsat parametrem `tips`
/// (např. levelA1(300, tips: [...])), třeba tam, kde pro jazyk chybí
/// knížky nebo seriály pro začátečníky.
const Map<String, List<String>> kLevelTips = {
  'A1': [
    'Máš základ nejběžnějších slov. Zkus první '
        'knížku pro začátečníky (tzv. graded readers, příběhy z jednoduchých '
        'slov). Nevadí, když nerozumíš všemu, stačí pochopit, o co jde.',
    'Naučená slova zkus hned použít: řekni nahlas pozdrav, poděkování nebo '
        'objednání v kavárně.',
  ],
  'A2': [
    'Čas na poslech. Zkus pomalé písničky se zobrazeným textem a videa pro '
        'začátečníky s titulky v učeném jazyce. Nečekej, že porozumíš všemu, '
        'sleduj, kolik známých slov uslyšíš.',
    'Zkus si každý den přečíst jednu krátkou zprávu, titulek nebo popisek '
        'v učeném jazyce.',
  ],
  'B1': [
    'Většině běžné konverzace už zhruba rozumíš. Přepni si mobil do učeného '
        'jazyka a sleduj seriál s titulky v učeném jazyce.',
    'Zkus popsat svůj den třemi větami v učeném jazyce. Klidně jen '
        'pro sebe.',
  ],
  'B2': [
    'Zvládneš články i knížky pro dospělé, občas se slovníkem. Zkus podcast, '
        'vlog nebo film a začni mluvit a psát s lidmi, i s chybami.',
    'Nahraj si krátkou hlasovou zprávu v učeném jazyce a poslechni si ji. '
        'Hned uslyšíš, kde se ti ještě zasekává jazyk.',
  ],
  'C1': [
    'Rozumíš většině autentických textů a pořadů. Zkus filmy bez titulků '
        'a knihy bez zjednodušení. Další slova už nejsou nejdůležitější, teď '
        'se vyplatí hlavně používání jazyka a idiomy.',
    'Při čtení si všímej celých slovních spojení a idiomů, ne jen '
        'jednotlivých slov.',
  ],
};

// Paleta úrovní (jen pro štíty a oslavy; stavy karet mají vlastní barvy).
// Chceš-li štítům dát jiné barvy pro nové téma, uprav jen tyto funkce.

LevelStep levelA1(int t, {List<String>? tips}) => LevelStep(
  'A1',
  t,
  tips: tips ?? kLevelTips['A1']!,
  light: (p) => Color.lerp(p.toneAmber.accent, p.toneAmber.inkSoft, 0.3)!,
  dark: (p) => p.toneAmber.accent,
);

LevelStep levelA2(int t, {List<String>? tips}) => LevelStep(
  'A2',
  t,
  tips: tips ?? kLevelTips['A2']!,
  light: (p) => Color.lerp(p.toneAmber.solidA, p.toneAmber.accent, 0.3)!,
  dark: (p) => p.toneAmber.solidA,
);

LevelStep levelB1(int t, {List<String>? tips}) => LevelStep(
  'B1',
  t,
  tips: tips ?? kLevelTips['B1']!,
  light: (p) => Color.lerp(p.toneGreen.solidA, p.toneGreen.solidB, 0.3)!,
  dark: (p) => p.toneGreen.solidA,
);

LevelStep levelB2(int t, {bool top = false, List<String>? tips}) =>
    top
        ? LevelStep(
          'B2',
          t,
          tips: tips ?? kLevelTips['B2']!,
          light: (p) => Color.lerp(p.purpleA, p.purpleB, 0.7)!,
          dark: (p) => p.purpleA,
        )
        : LevelStep(
          'B2',
          t,
          tips: tips ?? kLevelTips['B2']!,
          light: (p) => Color.lerp(p.toneBlue.solidA, p.toneBlue.accent, 0.3)!,
          dark: (p) => p.toneBlue.solidA,
        );

LevelStep levelC1(int t, {List<String>? tips}) => LevelStep(
  'C1',
  t,
  tips: tips ?? kLevelTips['C1']!,
  light: (p) => Color.lerp(p.purpleA, p.purpleB, 0.7)!,
  dark: (p) => p.purpleA,
);
