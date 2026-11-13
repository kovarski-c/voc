import 'package:flutter/material.dart';

import '../services/motivation.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/level_shield.dart';
import '../widgets/tone_button.dart';

/// Mapa slov: odznaky a dlaždice po stovkách slov (seřazeno podle frekvence).
/// Čím sytější zelená, tím líp dlaždici umíš.
class WordMapView extends StatelessWidget {
  final StudyController controller;
  final void Function(int startIndex) onJump;

  const WordMapView({
    super.key,
    required this.controller,
    required this.onJump,
  });

  static const Color _empty = Color(0xFFE3E7EE);

  static Color _tileColor(BandStat b) {
    if (b.unseen == b.total) return _empty;
    final t = b.score.clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFCDEBD2), const Color(0xFF2E7D32), t)!;
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final w = MediaQuery.sizeOf(context).width;
    const tile = 42.0, gap = 6.0;
    final cols = ((w - 40 + gap) / (tile + gap)).floor();
    final side = (w - (cols * tile + (cols - 1) * gap)) / 2;
    final bands = c.bandStats();
    final badges =
        Motivation.milestones
            .where((m) => m <= c.totalWords || c.badges.contains(m))
            .toList();

    final levels = c.levels;

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 4, side, 24),
      children: [
        if (levels.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Úrovně slovní zásoby',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kMuted,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final l in levels)
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      LevelShield(
                        level: l,
                        earned: c.levelCodes.contains(l.code),
                        width: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l.threshold}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.levelCodes.contains(l.code) ? kInk : kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Odznaky',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final m in badges)
              _Badge(value: m, earned: c.badges.contains(m)),
          ],
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            children: [
              const Text(
                'Mapa slov',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
              const Spacer(),
              _legend(_empty, 'nové'),
              const SizedBox(width: 10),
              _legend(const Color(0xFFCDEBD2), 'učím se'),
              const SizedBox(width: 10),
              _legend(const Color(0xFF2E7D32), 'umím'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Každá dlaždice = ${c.bandSize} slov od nejčastějších po méně časté.',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < bands.length; i++)
              _Tile(
                label: '${i + 1}',
                color: _tileColor(bands[i]),
                dark:
                    bands[i].unseen != bands[i].total && bands[i].score > 0.55,
                onTap: () => _showBand(context, bands[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: kMuted)),
    ],
  );

  void _showBand(BuildContext context, BandStat b) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Slova ${b.start + 1}–${b.end}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _num('${b.review}', 'naučeno', kToneGreen.accent),
                    _num('${b.solid}', 'pevně', kToneGreen.ink),
                    _num('${b.learning}', 'v učení', kToneAmber.accent),
                    _num('${b.unseen}', 'nových', kToneBlue.accent),
                  ],
                ),
                const SizedBox(height: 20),
                ToneButton(
                  label: 'Zobrazit v seznamu',
                  icon: Icons.format_list_bulleted_rounded,
                  tone: kToneBlue,
                  height: 52,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onJump(b.start);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _num(String value, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark; // sytá dlaždice => bílý text
  final VoidCallback onTap;
  const _Tile({
    required this.label,
    required this.color,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : const Color(0xFF5A6270),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int value;
  final bool earned;
  const _Badge({required this.value, required this.earned});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // sytý přechod žluté z palety aplikace, bez barevné záře
              color: earned ? kToneAmber.solidA : const Color(0xFFE3E7EE),
            ),
            child: Icon(
              Icons.military_tech_rounded,
              size: 28,
              color: earned ? kToneAmber.onSolid : const Color(0xFFB4BBC7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: earned ? kInk : kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
