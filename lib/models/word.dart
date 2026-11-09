/// Jedno slovo z TSV souboru (french.tsv).
/// Pozor: `front` je text francouzské strany (sloupec fr), tedy UČENÝ jazyk.
/// V Course je to `back`; `translation` (cs) je rodná strana = `Course.front`.
class Word {
  final int id; // stabilní klíč, podle něj se ukládá pokrok
  final String front; // fr (může obsahovat více tvarů "a / b")
  final String ipa;
  final String translation; // cs
  final String pos;
  final String flag;
  final bool vulgar;

  const Word({
    required this.id,
    required this.front,
    required this.ipa,
    required this.translation,
    required this.pos,
    required this.flag,
    required this.vulgar,
  });
}
