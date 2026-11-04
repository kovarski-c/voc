import 'dart:math' as math;

/// Jeden "kurz" = jedna dvojice jazyků se seznamem slovíček.
/// Seznamy jsou řazené od nejčastějších slov po méně časté.
class Course {
  final String id; // stabilní id, podle něj se pojmenuje soubor s pokrokem
  final String frontLabel; // např. 'English'
  final String backLabel; // např. 'Luganda'
  final List<String> fronts;
  final List<String> backs;
  final List<String>? pronunciations;

  /// ISO kód země pro vlajku (např. 'UG', 'FR', 'IL'); null = obecná ikona.
  final String? flagCode;

  /// True = při prvním spuštění převezme pokrok ze starého souboru skills.json.
  final bool migratesLegacyProgress;

  Course({
    required this.id,
    required this.frontLabel,
    required this.backLabel,
    required this.fronts,
    required this.backs,
    this.pronunciations,
    this.flagCode,
    this.migratesLegacyProgress = false,
  }) : assert(fronts.length == backs.length,
            'Course $id: fronts a backs musí mít stejnou délku');

  int get length => math.min(fronts.length, backs.length);

  String front(int i) => fronts[i];
  String back(int i) => backs[i];
  String pronunciation(int i) => pronunciations?[i] ?? '';
}
