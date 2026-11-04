import 'data/LU_english.dart' as english_words;
import 'data/LU_luganda.dart' as luganda;
import 'models/course.dart';

/// Registr všech kurzů. Nový jazyk = přidat sem další Course.
///
/// Pozor: `fronts` = rodná strana karty (slova, která už znáš),
/// `backs` = učený jazyk. `id` se nesmí měnit, podle něj se ukládá pokrok.
final List<Course> allCourses = [
  Course(
    id: 'luganda',
    frontLabel: 'English',
    backLabel: 'Luganda',
    fronts: english_words.english,
    backs: luganda.translations,
    flagCode: 'UG',
    migratesLegacyProgress: true, // pokrok ze starého skills.json patří sem
  ),
  // Příklad dalšího kurzu (až budou data hotová):
  // Course(
  //   id: 'french',
  //   frontLabel: 'Čeština',
  //   backLabel: 'Francouzština',
  //   fronts: czech_for_french.words,
  //   backs: french.words,
  //   flagCode: 'FR',
  // ),
];
