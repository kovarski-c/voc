import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../services/study_session.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/card_status.dart';
import '../widgets/course_flag.dart';
import '../widgets/two_tone_progress_bar.dart';

/// Domovská stránka: přepínač jazyka, celkový pokrok, počty, směr karet a tři režimy.
/// Neposouvá se, pokud se obsah vejde na displej.
class HomeView extends StatelessWidget {
  final StudyController c;
  final void Function(StudyMode mode) onStart;
  final VoidCallback onChangeCourse;

  const HomeView({
    super.key,
    required this.c,
    required this.onStart,
    required this.onChangeCourse,
  });

  @override
  Widget build(BuildContext context) {
    final s = c.session;
    final due = s.dueCount;
    final learning = s.learningCount;
    final unseen = s.unseenCount;
    final total = c.course.length;
    final learned = c.learnedCount;
    final solid = c.solidCount;
    final percent = total == 0 ? 0 : (learned * 100 / total).round();

    final bothEnabled = due + learning + unseen > 0;
    final reviewEnabled = learned > 0;
    final learnEnabled = learning + unseen > 0;

    final reviewSubtitle = due > 0
        ? '$due k opakování'
        : (learned > 0
            ? 'Nic není splatné, procvičit předčasně'
            : 'Zatím není co opakovat');
    final learnSubtitle = learnEnabled
        ? (due >= StudySession.reviewBatch
            ? '$learning v učení · $unseen nových · nejdřív opakuj ($due čeká)'
            : '$learning v učení · $unseen nových')
        : 'Žádná další slova';

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(c: c, onTap: onChangeCourse),
                  const SizedBox(height: 18),
                  _ProgressCard(
                    learned: learned,
                    solid: solid,
                    total: total,
                    percent: percent,
                    reviewedToday: c.reviewedToday,
                    learnedToday: c.learnedToday,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatPill(
                              value: due,
                              label: 'k opakování',
                              color: kReviewColor)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatPill(
                              value: learning,
                              label: 'v učení',
                              color: const Color(0xFFE69A00))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatPill(
                              value: unseen,
                              label: 'nových',
                              color: const Color(0xFF1976D2))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Která strana karty je první',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kMuted)),
                  ),
                  _DirectionPicker(c: c),
                  const SizedBox(height: 20),
                  _ModeCard(
                    title: 'Opakovat i učit se',
                    subtitle: '$due k opakování · nová slova po pěticích',
                    icon: Icons.play_arrow_rounded,
                    colors: const [Color(0xFF5B9BFF), Color(0xFF2F6FED)],
                    foreground: Colors.white,
                    emphasized: true,
                    onTap: bothEnabled ? () => onStart(StudyMode.both) : null,
                  ),
                  const SizedBox(height: 14),
                  _ModeCard(
                    title: 'Jen opakovat',
                    subtitle: reviewSubtitle,
                    icon: Icons.replay_rounded,
                    colors: const [Color(0xFF63D68F), Color(0xFF2EAE6B)],
                    foreground: Colors.white,
                    onTap: reviewEnabled
                        ? () => onStart(StudyMode.reviewOnly)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    title: 'Jen učit se',
                    subtitle: learnSubtitle,
                    icon: Icons.school_rounded,
                    colors: const [Color(0xFFFFD866), Color(0xFFFFB300)],
                    foreground: const Color(0xFF4A3500),
                    onTap: learnEnabled
                        ? () => onStart(StudyMode.learnOnly)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StudyController c;
  final VoidCallback onTap;
  const _Header({required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: softShadow(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CourseFlag(course: c.course, width: 30, height: 21),
                  const SizedBox(width: 10),
                  Text(c.course.backLabel,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, color: kMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int learned;
  final int solid;
  final int total;
  final int percent;
  final int reviewedToday;
  final int learnedToday;

  const _ProgressCard({
    required this.learned,
    required this.solid,
    required this.total,
    required this.percent,
    required this.reviewedToday,
    required this.learnedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$learned',
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: kInk)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('z $total slov',
                    style: const TextStyle(fontSize: 15, color: kMuted)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$percent %',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kBlue)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TwoToneProgressBar(
            light: total == 0 ? 0 : learned / total,
            dark: total == 0 ? 0 : solid / total,
            height: 12,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _Dot(Color(0xFFA5D6A7)),
              const SizedBox(width: 6),
              const Text('naučeno',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(width: 14),
              const _Dot(Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Text('pevně zvládnuto $solid',
                  style: const TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              Text('Dnes: $reviewedToday + $learnedToday',
                  style: const TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow(0.05),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}

/// Vlastní přepínač: všechny tři možnosti mají stejnou šířku a text uprostřed.
class _DirectionPicker extends StatelessWidget {
  final StudyController c;
  const _DirectionPicker({required this.c});

  @override
  Widget build(BuildContext context) {
    final options = <DirectionMode, String>{
      DirectionMode.auto: 'Automaticky',
      DirectionMode.nativeFront: c.course.frontLabel,
      DirectionMode.learnedFront: c.course.backLabel,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => c.setDirectionMode(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.settings.directionMode == e.key
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: c.settings.directionMode == e.key
                        ? softShadow(0.08)
                        : null,
                  ),
                  child: Text(
                    e.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: c.settings.directionMode == e.key
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: c.settings.directionMode == e.key ? kInk : kMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Karta s režimem procvičování. Výchozí režim je vyšší a výraznější.
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color foreground;
  final bool emphasized;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.foreground,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final radius = BorderRadius.circular(24);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: emphasized ? 108 : 82,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.last.withValues(alpha: emphasized ? 0.50 : 0.32),
                    blurRadius: emphasized ? 26 : 16,
                    offset: Offset(0, emphasized ? 12 : 7),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: emphasized ? 22 : 18),
              child: Row(
                children: [
                  Container(
                    width: emphasized ? 52 : 42,
                    height: emphasized ? 52 : 42,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        color: foreground, size: emphasized ? 34 : 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: emphasized ? 20 : 17,
                                fontWeight: FontWeight.w800,
                                color: foreground)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: foreground.withValues(alpha: 0.90))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: foreground.withValues(alpha: 0.8), size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
