import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/word.dart';

/// Načte TSV s 9 sloupci:
/// id, fr, ipa, cs, pos, flag, vulgar, src_rank, merged_ranks.
/// Neprovádí trim() řádku (poslední sloupec může být prázdný), odstraní jen '\r'.
class WordLoader {
  static const int columns = 9;

  static Future<List<Word>> loadTsv(String asset) async {
    var raw = await rootBundle.loadString(asset);
    if (raw.startsWith('\uFEFF')) raw = raw.substring(1);
    return parse(raw, source: asset);
  }

  /// Čistý parser (kvůli testům bez rootBundle).
  static List<Word> parse(String raw, {String source = 'tsv'}) {
    final words = <Word>[];
    final seen = <int>{};
    final lines = raw.split('\n');
    for (var n = 1; n < lines.length; n++) {
      // n == 0 je hlavička
      var line = lines[n];
      if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
      if (line.isEmpty) continue; // typicky prázdný konec souboru
      final c = line.split('\t');
      if (c.length != columns) {
        debugPrint('$source, řádek ${n + 1}: ${c.length} sloupců místo '
            '$columns, přeskakuji');
        continue;
      }
      final id = int.tryParse(c[0]);
      if (id == null) {
        debugPrint('$source, řádek ${n + 1}: neplatné id "${c[0]}", přeskakuji');
        continue;
      }
      if (!seen.add(id)) {
        debugPrint('$source, řádek ${n + 1}: duplicitní id $id, přeskakuji');
        continue;
      }
      words.add(Word(
        id: id,
        front: c[1],
        ipa: c[2],
        translation: c[3],
        pos: c[4],
        flag: c[5],
        vulgar: c[6] == '1',
      ));
    }
    return words;
  }
}
