import 'package:material_ui/material_ui.dart';

import '../models/level.dart';
import '../services/motivation.dart';
import '../study_controller.dart';
import '../theme.dart';
import 'level_shield.dart';
import 'pill_button.dart';

/// Oslava nových úspěchů (denní cíl, série, milník). Ukáže se mezi dávkami, ne uprostřed karet.
Future<void> showAchievements(
  BuildContext context,
  StudyController c,
  List<Achievement> list,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder:
        (_) => _AchievementDialog(
          list: list,
          total: c.totalWords,
          levels: c.course.levels,
        ),
  );
}

class _Style {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final LevelStep? level; // u úrovně se místo kruhu kreslí štít
  final String? hint; // u úrovně: co s ní můžeš dělat
  const _Style(
    this.icon,
    this.colors,
    this.title,
    this.subtitle, [
    this.level,
    this.hint,
  ]);
}

_Style _styleOf(Achievement a, int total, List<LevelStep> levels) {
  switch (a.type) {
    case AchievementType.goal:
      return _Style(
        Icons.task_alt_rounded,
        [kToneGreen.solidA, kToneGreen.solidB],
        'Denní cíl splněn',
        'Dnes máš hotovo ${a.value} karet.',
      );
    case AchievementType.streak:
      return _Style(
        Icons.local_fire_department_rounded,
        [kToneAmber.solidA, kToneAmber.solidB],
        '${a.value} dní v řadě',
        'Učíš se už ${a.value} dní po sobě.',
      );
    case AchievementType.milestone:
      return _Style(
        Icons.military_tech_rounded,
        [kToneAmber.a, kToneAmber.solidA],
        '${a.value} slov',
        'Naučených slov: ${a.value}.',
      );
    case AchievementType.level:
      final lv = levels.firstWhere((l) => l.code == a.code);
      return _Style(
        Icons.shield_rounded,
        [lv.light, lv.dark],
        'Úroveň ${lv.code}',
        'Tvoje slovní zásoba (${a.value} slov) odpovídá úrovni ${lv.code}!',
        lv,
        lv.tips.isEmpty ? null : lv.tips.first,
      );
  }
}

class _AchievementDialog extends StatelessWidget {
  final List<Achievement> list;
  final int total;
  final List<LevelStep> levels;
  const _AchievementDialog({
    required this.list,
    required this.total,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: SingleChildScrollView(
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 22),
              _Row(style: _styleOf(list[i], total, levels)),
            ],
            const SizedBox(height: 26),
            PillButton(
              label: 'Pokračovat',
              color: _styleOf(list.first, total, levels).colors.last,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final _Style style;
  const _Row({required this.style});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder:
              (context, v, child) => Transform.scale(scale: v, child: child),
          child:
              style.level != null
                  ? LevelShield(level: style.level!, earned: true, width: 84)
                  : Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: style.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.colors.last.withValues(alpha: 0.45),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(style.icon, size: 50, color: Colors.white),
                  ),
        ),
        const SizedBox(height: 16),
        Text(
          style.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          style.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: kMuted),
        ),
        if (style.hint != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: style.colors.last.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 20,
                  color: style.colors.last,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    style.hint!,
                    style: TextStyle(fontSize: 14, height: 1.35, color: kInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
