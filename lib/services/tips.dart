import '../models/course.dart';
import '../models/level.dart';
import 'motivation.dart';
import 'reminder.dart';
import 'scheduler.dart';

enum TipKind { words, app, level }

class Tip {
  final TipKind kind;
  final String title; // nadpis boxíku
  final String text;
  const Tip(this.kind, this.title, this.text);
}

/// Denní tipy na domovské stránce: k učení slov, k aplikaci a k aktuální úrovni.
/// Nic se neukládá: tip se vybere z čísla studijního dne, takže je celý den
/// stejný a každý další den se vystřídá druh i obsah.
class Tips {
  static const _wordsTitle = 'Tip k učení';
  static const _appTitle = 'Tip k aplikaci';

  static String _withExample(String base, String? example) =>
      example == null ? base : '$base Příklad: $example';

  static List<Tip> _wordTips(Course c) {
    final m = c.mnemonics;
    return [
      for (final t in [
        _withExample(
          'Zvuková asociace: najdi české slovo, které zní podobně jako cizí, '
          'a spoj ho s významem do jednoho obrazu.',
          m.sound,
        ),
        _withExample(
          'Živý obraz: čím je bizarnější, pohyblivější a smyslovější (zvuk, '
          'vůně, barva), tím lépe funguje.',
          m.image,
        ),
        _withExample(
          'Vlastní věta: slovo hned po naučení použij ve větě o sobě nebo '
          'o něčem, co dnes děláš.',
          m.sentence,
        ),
        _withExample(
          'Příbuzná slova: hledej podobnost s češtinou nebo se slovy, která '
          'už znáš.',
          m.related,
        ),
        'Řekni slovo nahlas. Zvuk se spojí s významem a zapamatuješ si ho lépe.',
        'Vlastní pomůcka funguje lépe než cizí, i když je hloupá. Ty bývají '
            'nejlepší.',
        'Slovo, které neznáš, se brzy vrátí, nic se neděje. Právě opakování ho '
            'dostane do paměti.',
        'Krátké cvičení každý den prospěje víc než dlouhé jednou týdně.',
      ])
        Tip(TipKind.words, _wordsTitle, t),
    ];
  }

  static List<Tip> _appTips() => [
    for (final t in [
      'Tlačítko „Už umím“ používej upřímně: přeskočené slovo se vrátí až za '
          'zhruba ${Scheduler.skipStabilityDays.round()} dní.',
      'Tlačítko „Neučit“ u nového slova ho vyřadí: už ho neuvidíš a nepočítá '
          'se do pokroku. „Umím“ ho naopak ještě zařadí do opakování. '
          'Vyřazená slova vrátíš v seznamu slov.',
      'Žárovka vlevo nahoře při učení otevře tipy k zapamatování slov a '
          'vysvětlení tlačítek. Při učení tě nerušíme, tipy se otevřou jen '
          'klepnutím.',
      'Poslední odpovědi můžeš vrátit šipkou zpět.',
      'Která strana karty je první (rodný, nebo učený jazyk), se přepíná '
          'na domovské stránce.',
      'Den se do série počítá už od ${Motivation.streakMinCards} karet. Za '
          'každých 7 dní v řadě získáš ochranný den (nejvýš '
          '${Motivation.maxFreezes}), který sérii zachrání, když jeden den '
          'vynecháš.',
      'Nový studijní den začíná ve ${Scheduler.dayStartHour}:00 ráno, takže '
          'učení po půlnoci se ještě počítá do předchozího dne.',
      'V nastavení můžeš znovu určit svou úroveň testem nebo ručním výběrem.',
      if (Reminder.supported)
        'V nastavení zapneš připomínku, která ti pohlídá sérii.',
    ])
      Tip(TipKind.app, _appTitle, t),
  ];

  static List<Tip> _levelTips(
    LevelStep? current,
    LevelStep? next,
    int learned,
  ) {
    return [
      if (current != null)
        for (final t in current.tips)
          Tip(TipKind.level, 'Tip k úrovni ${current.code}', t),
      if (next != null)
        Tip(
          TipKind.level,
          'Cesta k úrovni ${next.code}',
          'Do úrovně ${next.code} ti zbývá ${next.threshold - learned} slov.',
        ),
    ];
  }

  /// Denní tip. [current] = nejvyšší dosažená úroveň (null = žádná),
  /// [next] = nejbližší nedosažená.
  static Tip forDay({
    required Course course,
    required LevelStep? current,
    required LevelStep? next,
    required int learned,
    required DateTime now,
  }) {
    final day = Scheduler.studyDayNumber(now);
    final pools =
        [
          _wordTips(course),
          _appTips(),
          _levelTips(current, next, learned),
        ].where((p) => p.isNotEmpty).toList();
    final pool = pools[day % pools.length];
    return pool[(day ~/ pools.length) % pool.length];
  }
}
