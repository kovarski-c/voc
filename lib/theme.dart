import 'package:flutter/material.dart';

/// Společné barvy a stíny aplikace.
const Color kBg = Color(0xFFF4F6FA);
const Color kBlue = Color(0xFF2F6FED);
const Color kInk = Color(0xFF1D1B20);
const Color kMuted = Color(0xFF767676);

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

const Tone kToneBlue = Tone(
  a: Color(0xFFC4D8FF),
  b: Color.fromARGB(255, 230, 231, 251),
  //b: Color.fromARGB(255, 233, 228, 245),
  accent: Color(0xFF2F6FED),
  solidA: Color(0xFF2F6FED),
  solidB: Color.fromARGB(255, 106, 77, 235),
  ink: Color(0xFF1F2A6B),
  inkSoft: Color(0xFF3B4A99),
  onSolid: Color(0xFFE6EDFF),
);

const Tone kToneGreen = Tone(
  a: Color(0xFFBDEBD2),
  b: Color.fromARGB(255, 218, 244, 218),
  accent: Color(0xFF168A5B),
  solidA: Color(0xFF23C16B),
  solidB: Color(0xFF14A3A8),
  ink: Color(0xFF11513A),
  inkSoft: Color(0xFF1D6E52),
  onSolid: Color(0xFFE3F8EE),
);

const Tone kToneAmber = Tone(
  a: Color(0xFFFFE1A0),
  b: Color.fromARGB(255, 251, 241, 210),
  //b: Color(0xFFFFCBB4),
  accent: Color.fromARGB(255, 217, 140, 16),
  solidA: Color(0xFFFFB300),
  solidB: Color(0xFFFF7A45),
  ink: Color(0xFF6B3E08),
  inkSoft: Color(0xFF8F5410),
  onSolid: Color(0xFFFFF3DC),
);
