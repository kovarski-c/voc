import 'dart:math' as math;

import 'word.dart';

/// Jeden "kurz" = jedna dvojice jazyků se seznamem slovíček.
/// Seznamy jsou řazené od nejčastějších slov po méně časté.
///
/// Klíč karty (`key`) je to, podle čeho se ukládá pokrok:
/// u kurzů bez `ids` je to pozice v seznamu (jako dřív), u kurzů s `ids`
/// (TSV) stabilní id slova. Metody front/back/pronunciation berou KLÍČ.
/// Výslovnost patří k učené straně (`back`).
class Course {
  final String id; // stabilní id, podle něj se pojmenuje soubor s pokrokem
  final String frontLabel; // např. 'English'
  final String backLabel; // např. 'Luganda'
  final List<String> fronts;
  final List<String> backs;
  final List<String>? pronunciations;

  /// Klíče karet v pořadí seznamu; null = klíč je pozice.
  final List<int>? ids;

  /// Příznak vulgárnosti podle pozice; null = žádná vulgární slova.
  final List<bool>? vulgar;

  /// ISO kód země pro vlajku (např. 'UG', 'FR', 'IL'); null = obecná ikona.
  final String? flagCode;

  /// True = při prvním spuštění převezme pokrok ze starého souboru skills.json.
  final bool migratesLegacyProgress;

  late final Map<int, int>? _pos = ids == null
      ? null
      : {for (var i = 0; i < ids!.length; i++) ids![i]: i};

  Course({
    required this.id,
    required this.frontLabel,
    required this.backLabel,
    required this.fronts,
    required this.backs,
    this.pronunciations,
    this.ids,
    this.vulgar,
    this.flagCode,
    this.migratesLegacyProgress = false,
  }) : assert(fronts.length == backs.length,
            'Course $id: fronts a backs musí mít stejnou délku'),
        assert(ids == null || ids.length == fronts.length,
            'Course $id: ids musí mít stejnou délku jako seznam slov'),
        assert(vulgar == null || vulgar.length == fronts.length,
            'Course $id: vulgar musí mít stejnou délku jako seznam slov');

  /// Kurz z TSV: front = cs (rodná strana), back = fr, výslovnost = ipa.
  factory Course.fromWords({
    required String id,
    required String frontLabel,
    required String backLabel,
    required List<Word> words,
    String? flagCode,
  }) =>
      Course(
        id: id,
        frontLabel: frontLabel,
        backLabel: backLabel,
        fronts: [for (final w in words) w.translation],
        backs: [for (final w in words) w.front],
        pronunciations: [for (final w in words) w.ipa],
        ids: [for (final w in words) w.id],
        vulgar: [for (final w in words) w.vulgar],
        flagCode: flagCode,
      );

  int get length => math.min(fronts.length, backs.length);

  /// Klíče všech karet v pořadí učení.
  List<int> get keys => ids ?? List<int>.generate(length, (i) => i);

  bool get hasVulgar => vulgar != null && vulgar!.contains(true);

  bool has(int key) => _pos == null ? key >= 0 && key < length : _pos!.containsKey(key);

  int _p(int key) => _pos == null ? key : _pos![key]!;

  /// Více významů se na kartě i v seznamu vždy odděluje čárkou (ne středníkem).
  static String _commas(String s) =>
      s.contains(';') ? s.replaceAll(RegExp(r'\s*;\s*'), ', ') : s;

  String front(int key) => _commas(fronts[_p(key)]);
  String back(int key) => _commas(backs[_p(key)]);
  String pronunciation(int key) => pronunciations?[_p(key)] ?? '';
  bool isVulgar(int key) => vulgar?[_p(key)] ?? false;
}
