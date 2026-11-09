import 'package:flutter/material.dart';

import '../data/ipa_help.dart';
import '../models/course.dart';
import '../theme.dart';

bool hasIpaHelp(Course course) => ipaHelpFor(course.id) != null;

/// Otevře nápovědu k fonetické abecedě daného kurzu.
Future<void> showIpaHelp(BuildContext context, Course course) {
  final sections = ipaHelpFor(course.id);
  if (sections == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Fonetická abeceda · ${course.backLabel}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 4),
          const Text(
              'Výslovnost se zapisuje do hranatých závorek. Příklady jsou orientační.',
              style: TextStyle(fontSize: 13, color: kMuted)),
          for (final s in sections) ...[
            const SizedBox(height: 18),
            Text(s.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: softShadow(0.05),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < s.entries.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                    _Row(s.entries[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final IpaEntry e;
  const _Row(this.e);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(e.symbol,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: kBlue)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.example,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: kInk)),
                const SizedBox(height: 2),
                Text(e.hint,
                    style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
