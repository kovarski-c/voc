import 'package:material_ui/material_ui.dart';

/// Barevná schémata (volí se v nastavení). Světlý/tmavý režim je nezávislý
/// (viz [AppBrightness]); každé schéma má světlou i tmavou paletu.
///
/// Nové schéma přidáš ve 3 krocích:
///  1) přidej hodnotu na KONEC výčtu (pořadí se ukládá do nastavení),
///  2) vytvoř dvě konstanty AppPalette (světlou a tmavou),
///  3) přidej řádek do mapy [_schemes] níže.
enum AppThemeId {
  classic('Klasické'),
  autumn('Podzimní');

  final String label;
  const AppThemeId(this.label);
}

/// Světlý / tmavý režim (volí se v nastavení nezávisle na schématu).
enum AppBrightness {
  system('Podle systému'),
  light('Světlý'),
  dark('Tmavý');

  final String label;
  const AppBrightness(this.label);
}

/// Měkký stín pro bílé karty.
List<BoxShadow> softShadow([double opacity = 0.07]) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: opacity),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

/// Barevný tón: měkký přechod výplně + sytá barva + barvy textu na výplni.
/// Význam: zelená = opakování, žlutá = učení, modrá/fialová = hlavní akce a nové.
class Tone {
  final Color a; // měkký přechod: levý horní roh
  final Color b; // měkký přechod: pravý dolní roh
  final Color accent; // sytá barva (čísla, ikony)
  final Color solidA; // sytý přechod (kruh, dlaždice)
  final Color solidB;
  final Color ink; // nadpis na výplni
  final Color inkSoft; // podtitulek na výplni
  final Color onSolid; // ikona na sytém kruhu

  const Tone({
    required this.a,
    required this.b,
    required this.accent,
    required this.solidA,
    required this.solidB,
    required this.ink,
    required this.inkSoft,
    required this.onSolid,
  });

  /// Měkký přechod výplně; [alpha] < 1 ho zesvětlí (pro menší prvky).
  LinearGradient soft([double alpha = 1]) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [a.withValues(alpha: alpha), b.withValues(alpha: alpha)],
  );

  /// Sytý přechod (kruh s ikonou).
  LinearGradient get solid => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [solidA, solidB],
  );
}

/// Celá barevná paleta jednoho tématu.
class AppPalette {
  final bool dark; // tmavá paleta
  final Color bg; // pozadí obrazovek
  final Color
  surface; // karty, dialogy, spodní lišta (ve světlých paletách bílá)
  final Color blue; // hlavní barva (přepínače, posuvníky, akce)
  final Color ink; // hlavní text
  final Color muted; // doplňkový text
  final Color track; // neutrální pruhy, podklad přepínačů, okraje
  final Color faint; // vypnuté ikony, jemné čáry
  final Color offBg; // pozadí vypnutého tlačítka
  final Color offBorder; // okraj vypnuté karty
  final Color inactShieldBg;
  final Color inactShieldTxt;
  final Color actShieldTxt;
  final Tone toneBlue; // hlavní akce, nová slova
  final Tone toneGreen; // opakování
  final Tone toneAmber; // učení
  final Color purpleA;
  final Color purpleB;

  const AppPalette({
    this.dark = false,
    required this.bg,
    this.surface = const Color(0xFFFFFFFF),
    required this.blue,
    required this.ink,
    required this.muted,
    required this.track,
    required this.faint,
    required this.offBg,
    required this.offBorder,
    required this.inactShieldBg,
    required this.inactShieldTxt,
    required this.actShieldTxt,
    required this.toneBlue,
    required this.toneGreen,
    required this.toneAmber,
    required this.purpleA,
    required this.purpleB,
  });
}

const AppPalette kClassicLightPalette = AppPalette(
  bg: Color(0xFFF4F6FA),
  blue: Color(0xFF2F6FED),
  ink: Color(0xFF1D1B20),
  muted: Color(0xFF767676),
  track: Color(0xFFE6EAF2),
  faint: Color(0xFFB4BBC7),
  offBg: Color(0xFFEDEFF4),
  inactShieldBg: Color.fromRGBO(238, 238, 238, 1),
  inactShieldTxt: Color(0xFF767676),
  actShieldTxt: Color(0xFFFFFFFF),
  offBorder: Color(0xFFD9DDE6),
  purpleA: Color.fromARGB(255, 106, 77, 235),
  purpleB: Color(0xFF3B4A99),
  toneBlue: Tone(
    a: Color(0xFFC4D8FF),
    b: Color.fromARGB(255, 230, 231, 251),
    //b: Color.fromARGB(255, 233, 228, 245),
    accent: Color(0xFF2F6FED),
    solidA: Color(0xFF2F6FED),
    solidB: Color.fromARGB(255, 106, 77, 235),
    ink: Color(0xFF1F2A6B),
    inkSoft: Color(0xFF3B4A99),
    onSolid: Color(0xFFE6EDFF),
  ),
  toneGreen: Tone(
    a: Color(0xFFBDEBD2),
    b: Color.fromARGB(255, 218, 244, 218),
    accent: Color(0xFF168A5B),
    solidA: Color(0xFF23C16B),
    solidB: Color(0xFF14A3A8),
    ink: Color(0xFF11513A),
    inkSoft: Color(0xFF1D6E52),
    onSolid: Color(0xFFE3F8EE),
  ),
  toneAmber: Tone(
    a: Color(0xFFFFE1A0),
    b: Color.fromARGB(255, 251, 241, 210),
    //b: Color(0xFFFFCBB4),
    accent: Color.fromARGB(255, 217, 140, 16),
    solidA: Color(0xFFFFB300),
    solidB: Color(0xFFFF7A45),
    ink: Color(0xFF6B3E08),
    inkSoft: Color(0xFF8F5410),
    onSolid: Color(0xFFFFF3DC),
  ),
);

/// Podzim: krémové pozadí, cihlová (hlavní), olivová (opakování), hořčicová (učení).
const AppPalette kAutumnLightPalette = AppPalette(
  bg: Color(0xFFFFF7EF),
  blue: Color(0xFFC4572D),
  ink: Color(0xFF3B2A20),
  muted: Color(0xFF7F6E62),
  track: Color(0xFFEFE3D3),
  faint: Color(0xFFC9B9A8),
  offBg: Color(0xFFF3EADF),
  offBorder: Color(0xFFE4D6C5),
  inactShieldBg: Color(0xFFF3EADF),
  inactShieldTxt: Color(0xFF7F6E62),
  actShieldTxt: Color(0xFFFFFFFF),
  purpleA: Color(0xFF8C467A),
  purpleB: Color(0xFF633257),
  toneBlue: Tone(
    a: Color(0xFFF6D2BE),
    b: Color(0xFFFBE6DA),
    accent: Color(0xFFB5472A),
    solidA: Color(0xFFC4572D),
    solidB: Color(0xFF9E3B2B),
    ink: Color(0xFF5A2412),
    inkSoft: Color(0xFF8A3B22),
    onSolid: Color(0xFFFFE9DD),
  ),

  toneGreen: Tone(
    a: Color(0xFFD4DEA8), // Ideální střed: jemně zlatavá, už ne tak tmavá
    b: Color(0xFFE5ECC7), // Pevná, ale o kousek světlejší smetanová zeleň
    accent: Color(0xFF536625), // Čitelná zemitá olivová pro ikony
    solidA: Color(
      0xFF758F35,
    ), // Zlatavě olivová se správnou svítivostí pro glow
    solidB: Color(
      0xFF52661F,
    ), // Hlubší přechod pro hloubku, ale akorát vyvážený
    ink: Color(0xFF24300D), // Pevná lesní zeleň pro skvělý kontrast nadpisů
    inkSoft: Color(0xFF4A5B1D), // Měkký, ale dobře čitelný podtón
    onSolid: Color(0xFFF4F8EA), // Světlý text na plném zeleném podkladu
  ),

  toneAmber: Tone(
    a: Color(
      0xFFF7D19E,
    ), // O kousek jasnější a šťavnatější medový tón (více života)
    b: Color(
      0xFFF0E0CB,
    ), // Pevnější, hřejivější krémová (tak akorát, aby nebyla světlá ani moc tmavá)
    accent: Color(0xFF8C4C0C), // Výraznější hnědo-jantarová pro čitelné ikony
    solidA: Color(
      0xFFE89E0A,
    ), // Živější, svítivější žluto-jantarová pro silnější glow
    solidB: Color(
      0xFFC77800,
    ), // Hlubší zlatavý přechod, který tomu dodá hloubku
    ink: Color(0xFF422705), // Sytá čokoládová pro skvělý kontrast nadpisů
    inkSoft: Color(0xFF704313), // Hřejivá hnědá podtónu
    onSolid: Color(0xFFFFF9EE), // Světlý text na plném pozadí
  ),
);

/// Klasické schéma, tmavý režim: téměř černé pozadí, tmavě šedé karty.
const AppPalette kClassicDarkPalette = AppPalette(
  dark: true,
  bg: Color(0xFF0F1115),
  surface: Color(0xFF1A1D24),
  blue: Color(0xFF6C9BFF),
  ink: Color(0xFFECEEF3),
  muted: Color(0xFF9AA0AC),
  track: Color(0xFF2A2F3A),
  faint: Color(0xFF5A6170),
  offBg: Color(0xFF22262F),
  offBorder: Color(0xFF30353F),
  inactShieldBg: Color(0xFF30353F),
  inactShieldTxt: Color(0xFF9AA0AC),
  actShieldTxt: Color(0xFFFFFFFF),
  purpleA: Color(0xFF8A72F0),
  purpleB: Color(0xFF4A5BB8),
  toneBlue: Tone(
    a: Color(0xFF22345E),
    b: Color(0xFF2A2750),
    accent: Color(0xFF8DB1FF),
    solidA: Color(0xFF3F7BFF),
    solidB: Color(0xFF7A5CF0),
    ink: Color(0xFFDCE6FF),
    inkSoft: Color(0xFFA9BAF0),
    onSolid: Color(0xFFF0F4FF),
  ),
  toneGreen: Tone(
    a: Color(0xFF1C4033),
    b: Color(0xFF1F3A2A),
    accent: Color(0xFF4FD39A),
    solidA: Color(0xFF23C16B),
    solidB: Color(0xFF14A3A8),
    ink: Color(0xFFD6F5E6),
    inkSoft: Color(0xFF9ADBBD),
    onSolid: Color(0xFFE9FBF2),
  ),
  toneAmber: Tone(
    a: Color(0xFF4A3716),
    b: Color(0xFF3D2F1A),
    accent: Color(0xFFFFB84D),
    solidA: Color(0xFFFFB300),
    solidB: Color(0xFFFF7A45),
    ink: Color(0xFFFFE8BF),
    inkSoft: Color(0xFFE6BE7E),
    onSolid: Color(0xFFFFF3DC),
  ),
);

/// Podzim, tmavý režim: teplé hnědé pozadí, cihlová, olivová a hořčicová.
const AppPalette kAutumnDarkPalette = AppPalette(
  dark: true,
  bg: Color(0xFF17120E),
  surface: Color(0xFF241C16),
  blue: Color(0xFFE57A4E),
  ink: Color(0xFFF3E7DB),
  muted: Color(0xFFA8978A),
  track: Color(0xFF352B22),
  faint: Color(0xFF6B5A4C),
  offBg: Color(0xFF2B221A),
  offBorder: Color(0xFF3A2F25),
  inactShieldBg: Color(0xFF352B22),
  inactShieldTxt: Color(0xFFA8978A),
  actShieldTxt: Color(0xFFFFFFFF),
  purpleA: Color(0xFFB05A9A),
  purpleB: Color(0xFF7A3F6C),
  toneBlue: Tone(
    a: Color(0xFF4A2619),
    b: Color(0xFF3B2218),
    accent: Color(0xFFFF9A72),
    solidA: Color(0xFFC4572D),
    solidB: Color(0xFF9E3B2B),
    ink: Color(0xFFFFE0D2),
    inkSoft: Color(0xFFE0A58C),
    onSolid: Color(0xFFFFE9DD),
  ),
  toneGreen: Tone(
    a: Color(0xFF2E3A16),
    b: Color(0xFF28331A),
    accent: Color(0xFFA9C65A),
    solidA: Color(0xFF758F35),
    solidB: Color(0xFF52661F),
    ink: Color(0xFFE6EFC8),
    inkSoft: Color(0xFFBFD08A),
    onSolid: Color(0xFFF4F8EA),
  ),
  toneAmber: Tone(
    a: Color(0xFF4B3414),
    b: Color(0xFF3D2C16),
    accent: Color(0xFFF2B44D),
    solidA: Color(0xFFE89E0A),
    solidB: Color(0xFFC77800),
    ink: Color(0xFFFBE3BC),
    inkSoft: Color(0xFFE0B97E),
    onSolid: Color(0xFFFFF9EE),
  ),
);

/// Světlá a tmavá paleta jednoho schématu.
class _Scheme {
  final AppPalette light;
  final AppPalette dark;
  const _Scheme(this.light, this.dark);
}

/// Registr schémat: každá hodnota [AppThemeId] musí mít řádek.
const Map<AppThemeId, _Scheme> _schemes = {
  AppThemeId.classic: _Scheme(kClassicLightPalette, kClassicDarkPalette),
  AppThemeId.autumn: _Scheme(kAutumnLightPalette, kAutumnDarkPalette),
};

AppPalette paletteFor(AppThemeId id, {required bool dark}) {
  final s = _schemes[id] ?? _schemes[AppThemeId.classic]!;
  return dark ? s.dark : s.light;
}

/// Má se použít tmavý režim? [system] je jas systému (telefonu).
bool resolveDark(AppBrightness mode, Brightness system) => switch (mode) {
  AppBrightness.system => system == Brightness.dark,
  AppBrightness.light => false,
  AppBrightness.dark => true,
};

/// Právě používaná paleta. Mění se při přepnutí schématu nebo režimu
/// a při změně jasu systému (main.dart).
AppPalette palette = kClassicLightPalette;

/// Původní názvy zůstávají, jen už nejsou `const`, ale čtou aktuální paletu.
Color get kBg => palette.bg;
Color get kSurface => palette.surface;

/// Podklad pruhů průběhu (ve světlých paletách šedá 300).
Color get kBarTrack => palette.dark ? palette.track : Colors.grey[300]!;
Color get kBlue => palette.blue;
Color get kInk => palette.ink;
Color get kMuted => palette.muted;
Color get kTrack => palette.track;
Color get kFaint => palette.faint;
Color get kOffBg => palette.offBg;
Color get kOffBorder => palette.offBorder;
Tone get kToneBlue => palette.toneBlue;
Tone get kToneGreen => palette.toneGreen;
Tone get kToneAmber => palette.toneAmber;
Color get kInactShieldBg => palette.inactShieldBg;
Color get kInactShieldTxt => palette.inactShieldTxt;
Color get kAactShieldTxt => palette.actShieldTxt;
