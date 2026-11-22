import 'package:flutter/foundation.dart';

import 'data/LU_english.dart' as lu_english;
import 'data/LU_luganda.dart' as lu_luganda;
import 'data/final_english_table.dart' as en_table;
import 'data/final_pronunciations_table.dart' as en_pron;
import 'data/final_translates_table.dart' as cs_for_en;
import 'models/course.dart';
import 'models/level.dart';
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
      levels: [
        levelA1(700),
        levelA2(1500),
        levelB1(2500),
        levelB2(4500),
        levelC1(8000),
      ],
      mnemonics: const Mnemonics(
        sound: 'angl. cheap (čti „číp“) = levný → „čip je levný“.',
        image:
            'angl. rude (hrubý): představ si rudého vzteklouna, který na tebe křičí.',
        sentence:
            'místo „window = okno“ si řekni „I open the window every morning.“',
        related:
            'information ≈ informace, doctor ≈ doktor, music ≈ hudba (muzika).',
      ),
    ),
  ];

  try {
    final words = await WordLoader.loadTsv(frenchAsset);
    if (words.isNotEmpty) {
      courses.add(
        Course.fromWords(
          id: 'french',
          frontLabel: 'Čeština',
          backLabel: 'Francouzština',
          words: words,
          flagCode: 'FR',
          // Úrovně nad délkou seznamu se nezobrazí, objeví se samy,
          // až bude seznam delší (cílově 5000 slov).
          levels: [
            levelA1(500),
            levelA2(1000),
            levelB1(2000),
            levelB2(3500),
            levelC1(5000),
          ],
          mnemonics: const Mnemonics(
            sound:
                'fr. chat (čti „ša“) = kočka → „ša, ša!“, jak kočku odháníš.',
            image:
                'fr. regarder (čti regardé) = dívat se: představ si člena národní gardy, jak se na tebe podezíravě dívá.',
            sentence:
                'místo „pain = chléb“ si řekni „Je mange du pain chaque matin.“ (Jím chleba každé ráno.)',
            related: 'restaurant ≈ restaurace, musée ≈ muzeum, hôtel ≈ hotel.',
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Načtení francouzštiny selhalo: $e');
  }

  courses.add(
    Course(
      id: 'luganda',
      frontLabel: 'English',
      backLabel: 'Luganda',
      fronts: lu_english.english,
      backs: lu_luganda.translations,
      flagCode: 'UG',
      levels: [
        levelA1(300),
        levelA2(700),
        levelB1(1300),
        levelB2(2000, top: true), // nejvyšší úroveň seznamu = purpurová
      ],
      // TODO: doplnit další příklady (zbytek tipu se ukáže bez příkladu).
      mnemonics: const Mnemonics(
        sound: 'lug. ssente (čti „sente“) = peníze → „cent“.',
      ),
      migratesLegacyProgress: true, // pokrok ze starého skills.json patří sem
    ),
  );
  return courses;
}
