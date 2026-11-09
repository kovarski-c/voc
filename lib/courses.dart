import 'package:flutter/foundation.dart';

import 'data/LU_english.dart' as lu_english;
import 'data/LU_luganda.dart' as lu_luganda;
import 'data/final_english_table.dart' as en_table;
import 'data/final_pronunciations_table.dart' as en_pron;
import 'data/final_translates_table.dart' as cs_for_en;
import 'models/course.dart';
import 'services/word_loader.dart';

/// Cesta k francouzskému seznamu (musí být v pubspec.yaml v sekci assets).
const String frenchAsset = 'assets/words/french/french.tsv';

/// Načte všechny kurzy. Nový jazyk = přidat sem další Course.
///
/// Pozor: `fronts` = rodná strana karty (slova, která už znáš),
/// `backs` = učený jazyk. `id` se nesmí měnit, podle něj se ukládá pokrok.
Future<List<Course>> loadCourses() async {
  final courses = <Course>[
    Course(
      id: 'english',
      frontLabel: 'Čeština',
      backLabel: 'English',
      fronts: cs_for_en.translations,
      backs: en_table.english,
      pronunciations: en_pron.pronunciations,
      flagCode: 'GB',
    ),
  ];

  try {
    final words = await WordLoader.loadTsv(frenchAsset);
    if (words.isNotEmpty) {
      courses.add(Course.fromWords(
        id: 'french',
        frontLabel: 'Čeština',
        backLabel: 'Francouzština',
        words: words,
        flagCode: 'FR',
      ));
    }
  } catch (e) {
    debugPrint('Načtení francouzštiny selhalo: $e');
  }

  courses.add(Course(
    id: 'luganda',
    frontLabel: 'English',
    backLabel: 'Luganda',
    fronts: lu_english.english,
    backs: lu_luganda.translations,
    flagCode: 'UG',
    migratesLegacyProgress: true, // pokrok ze starého skills.json patří sem
  ));
  return courses;
}
