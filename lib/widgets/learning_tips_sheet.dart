import 'package:material_ui/material_ui.dart';

import '../models/course.dart';
import '../services/scheduler.dart';
import '../theme.dart';

/// Tipy při učení pod žárovkou: vysvětlení tlačítek a mnemotechnické tipy.
/// Formát jako nápověda k fonetické abecedě, jen v jantarové barvě.
/// [firstTime] přidá nahoru krátké vysvětlení, kde se tipy dají otevřít.
Future<void> showLearningTips(
  BuildContext context,
  Course course, {
  bool firstTime = false,
}) {
  final m = course.mnemonics;
  final days = Scheduler.skipStabilityDays.round();
  final sections = <_Section>[
    _Section('Jak si zapamatovat nová slova', [
      _Entry(
        'Podobné',
        _ex(
          'Hledej podobnost s češtinou nebo se slovy, která znáš.',
          m.related,
        ),
      ),
      _Entry('Zvuk', _ex('Najdi české slovo, které zní podobně.', m.sound)),
      _Entry(
        'Obraz',
        _ex(
          'Propoj význam se zvukem. Čím bizarnější a smyslovější, tím lepší.',
          m.image,
        ),
      ),
      _Entry('Věta', _ex('Použij slovo ve větě.', m.sentence)),
      const _Entry('Nahlas', 'Řekni slovo nahlas, zvuk se spojí s významem.'),
    ]),
    _Section('Tlačítka u nového slova', [
      const _Entry(
        'Naučit',
        'Slovo se zařadí do učení a bude se ti ukazovat, dokud ho nezvládneš. '
            'Čím lépe ho umíš, tím delší je doba, než ho znovu uvidíš.',
      ),
      _Entry(
        'Umím',
        'Slovo už znáš. Nebude se učit, ale občas se ti připomene v opakování '
            '(poprvé zhruba za $days dní).',
      ),
      const _Entry(
        'Neučit',
        'Slovo tě nezajímá nebo ho nepotřebuješ. Už ho neuvidíš a nepočítá se '
            'do pokroku. Vrátit ho můžeš v seznamu slov (Změnit stav slova).',
      ),
    ]),
  ];

  final tone = kToneAmber;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder:
              (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kFaint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: tone.solidA),
                      const SizedBox(width: 8),
                      Text(
                        'Tipy k učení',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tady najdeš pár tipů, jak se snáz naučit nová slova '
                    'a jak používat tlačítka učení.',
                    style: TextStyle(fontSize: 13, color: kMuted),
                  ),
                  if (firstTime) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: tone.soft(),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_rounded, color: tone.solidA),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Novinka: pod žárovkou vlevo nahoře najdeš '
                              'tipy na zapamatování nových slovíček '
                              'a nápovědu k tlačítkům.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tone.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final s in sections) ...[
                    const SizedBox(height: 18),
                    Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: softShadow(0.05),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < s.entries.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 14,
                                endIndent: 14,
                              ),
                            _Row(s.entries[i], tone),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
        ),
  );
}

String _ex(String base, String? example) =>
    example == null ? base : '$base Příklad: $example';

class _Section {
  final String title;
  final List<_Entry> entries;
  const _Section(this.title, this.entries);
}

class _Entry {
  final String label;
  final String text;
  const _Entry(this.label, this.text);
}

class _Row extends StatelessWidget {
  final _Entry e;
  final Tone tone;
  const _Row(this.e, this.tone);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              e.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tone.accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              e.text,
              style: TextStyle(fontSize: 14, color: kInk, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
