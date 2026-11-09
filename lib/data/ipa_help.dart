/// Nápověda k fonetické abecedě (IPA) pro jednotlivé kurzy.
/// Klíč = Course.id. Kurz bez položky nemá tlačítko nápovědy.
class IpaEntry {
  final String symbol;
  final String example; // slovo s výslovností
  final String hint; // jak se čte (česky)
  const IpaEntry(this.symbol, this.example, this.hint);
}

class IpaSection {
  final String title;
  final String? note;
  final List<IpaEntry> entries;
  const IpaSection(this.title, this.entries, {this.note});
}

List<IpaSection>? ipaHelpFor(String courseId) => _help[courseId];

const Map<String, List<IpaSection>> _help = {
  'french': _french,
  'english': _english,
};

const List<IpaSection> _french = [
  IpaSection('Jak číst zápis', [
    IpaEntry('/', 'le / la / les', 'Víc tvarů slova; výslovnosti jsou ve stejném pořadí.'),
    IpaEntry('( )', '(…)', 'Hláska v závorce se vyslovuje jen někdy.'),
    IpaEntry('\u0303', 'bon [bɔ̃]', 'Vlnka nad samohláskou = nosovka (vyslov ji nosem, bez samostatného n).'),
  ]),
  IpaSection('Samohlásky', [
    IpaEntry('i', 'si [si]', 'Jako české i.'),
    IpaEntry('y', 'tu [ty]', 'Řekni i a zakulať přitom rty (jako německé ü).'),
    IpaEntry('u', 'vous [vu]', 'Jako české u.'),
    IpaEntry('e', 'été [ete]', 'Zavřené é.'),
    IpaEntry('ɛ', 'père [pɛʁ]', 'Otevřené e, jako v české „pes“.'),
    IpaEntry('ø', 'peu [pø]', 'Řekni é a zakulať rty (jako německé ö).'),
    IpaEntry('œ', 'peur [pœʁ]', 'Řekni otevřené e a zakulať rty.'),
    IpaEntry('o', 'eau [o]', 'Zavřené ó.'),
    IpaEntry('ɔ', 'port [pɔʁ]', 'Otevřené o, jako české o.'),
    IpaEntry('a', 'chat [ʃa]', 'Jako české a.'),
    IpaEntry('ɑ', 'pâte [pɑt]', 'Hlubší, zadní a (dnes se často vyslovuje jako a).'),
    IpaEntry('ə', 'le [lə]', 'Krátké, nenápadné e (něco mezi e a ö); často se vynechává.'),
  ]),
  IpaSection('Nosovky', [
    IpaEntry('ɛ̃', 'vin [vɛ̃]', 'E vyslovené nosem.'),
    IpaEntry('ɑ̃', 'dans [dɑ̃]', 'A vyslovené nosem.'),
    IpaEntry('ɔ̃', 'bon [bɔ̃]', 'O vyslovené nosem.'),
    IpaEntry('œ̃', 'un [œ̃]', 'Dnes se často vyslovuje jako ɛ̃.'),
  ]),
  IpaSection('Polosamohlásky', [
    IpaEntry('j', 'hier [jɛʁ]', 'Jako české j.'),
    IpaEntry('w', 'oui [wi]', 'Krátké u se zakulacenými rty (ne české v).'),
    IpaEntry('ɥ', 'huit [ɥit]', 'Krátké y: rty zakulacené jako u y, ale hned přejdi na další hlásku.'),
  ]),
  IpaSection('Souhlásky', [
    IpaEntry('ʃ', 'chat [ʃa]', 'Jako české š.'),
    IpaEntry('ʒ', 'je [ʒə]', 'Jako české ž.'),
    IpaEntry('ʁ', 'rue [ʁy]', 'Francouzské r: tvoří se vzadu v hrdle, jako jemné chrčení (ne jazykem).'),
    IpaEntry('ɲ', 'agneau [aɲo]', 'Jako české ň.'),
    IpaEntry('ŋ', 'parking [paʁkiŋ]', 'Jako n v české „banka“; jen v přejatých slovech.'),
    IpaEntry('ɡ', 'gare [ɡaʁ]', 'Jako české g.'),
    IpaEntry('p b t d k f v s z m n l', 'pas, bon, tu …', 'Čtou se zhruba jako v češtině.'),
  ]),
];

const List<IpaSection> _english = [
  IpaSection('Jak číst zápis', [
    IpaEntry('ː', 'see [siː]', 'Dvojtečka = dlouhá hláska.'),
    IpaEntry('ˈ', 'about [əˈbaʊt]', 'Značka před slabikou s hlavním přízvukem.'),
    IpaEntry('ˌ', 'dictionary [ˈdɪkʃənˌri]', 'Značka před slabikou s vedlejším přízvukem.'),
    IpaEntry('( )', '(r)', 'Hláska v závorce se vyslovuje jen někdy.'),
  ]),
  IpaSection('Samohlásky', [
    IpaEntry('ɪ', 'sit [sɪt]', 'Krátké, uvolněné i (mezi i a e).'),
    IpaEntry('iː', 'see [siː]', 'Dlouhé í.'),
    IpaEntry('e / ɛ', 'bed [bed]', 'Jako české e.'),
    IpaEntry('æ', 'cat [kæt]', 'Mezi e a a: otevři ústa jako na a, ale řekni e.'),
    IpaEntry('ɑː', 'car [kɑː]', 'Dlouhé á, vzadu v ústech.'),
    IpaEntry('ɒ', 'hot [hɒt]', 'Krátké, otevřené o.'),
    IpaEntry('ɔː', 'door [dɔː]', 'Dlouhé ó.'),
    IpaEntry('ʊ', 'put [pʊt]', 'Krátké, uvolněné u.'),
    IpaEntry('uː', 'food [fuːd]', 'Dlouhé ú.'),
    IpaEntry('ʌ', 'cup [kʌp]', 'Krátké a vzadu v ústech (mezi a a o).'),
    IpaEntry('ɜː', 'bird [bɜːd]', 'Dlouhé, neutrální ö (rty uvolněné).'),
    IpaEntry('ə', 'about [əˈbaʊt]', 'Neurčité krátké e v nepřízvučných slabikách.'),
  ]),
  IpaSection('Dvojhlásky', [
    IpaEntry('eɪ', 'day [deɪ]', 'e plynule přejde v i.'),
    IpaEntry('aɪ', 'my [maɪ]', 'a plynule přejde v i.'),
    IpaEntry('ɔɪ', 'boy [bɔɪ]', 'o plynule přejde v i.'),
    IpaEntry('əʊ', 'go [gəʊ]', 'Neurčité e přejde v u.'),
    IpaEntry('aʊ', 'now [naʊ]', 'a plynule přejde v u.'),
    IpaEntry('ɪə', 'here [hɪə]', 'i přejde v neurčité e.'),
    IpaEntry('eə', 'air [eə]', 'e přejde v neurčité e.'),
    IpaEntry('ʊə', 'tour [tʊə]', 'u přejde v neurčité e.'),
  ]),
  IpaSection('Souhlásky', [
    IpaEntry('θ', 'think [θɪŋk]', 'Jazyk mezi zuby, neznělé (jako s s jazykem mezi zuby).'),
    IpaEntry('ð', 'this [ðɪs]', 'Jazyk mezi zuby, znělé (jako z s jazykem mezi zuby).'),
    IpaEntry('ʃ', 'she [ʃiː]', 'Jako české š.'),
    IpaEntry('ʒ', 'vision [ˈvɪʒn]', 'Jako české ž.'),
    IpaEntry('ʧ', 'chair [ʧeə]', 'Jako české č.'),
    IpaEntry('ʤ', 'job [ʤɒb]', 'Jako české dž.'),
    IpaEntry('ŋ', 'sing [sɪŋ]', 'Jako n v české „banka“, bez k na konci.'),
    IpaEntry('j', 'yes [jes]', 'Jako české j.'),
    IpaEntry('w', 'we [wiː]', 'Krátké u se zakulacenými rty (ne české v).'),
    IpaEntry('h', 'hat [hæt]', 'Slabé, vydechované h.'),
    IpaEntry('r', 'red [red]', 'Jazyk se nedotýká patra, nevibruje (ne české r).'),
    IpaEntry('p b t d k g f v s z m n l', 'pen, big, top …', 'Čtou se zhruba jako v češtině (p, t, k jsou na začátku slova s výdechem).'),
  ]),
];
