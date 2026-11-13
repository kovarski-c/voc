import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../services/study_session.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../models/level.dart';
import '../widgets/course_flag.dart';
import '../widgets/level_shield.dart';
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
    final total = c.totalWords;
    final learned = c.learnedCount;
    final solid = c.solidCount;
    final percent = total == 0 ? 0 : (learned * 100 / total).round();

    final bothEnabled = due + learning + unseen > 0;
    final reviewEnabled = learned > 0;
    final learnEnabled = learning + unseen > 0;

    final reviewSubtitle =
        due > 0
            ? '$due k opakování'
            : (learned > 0
                ? 'Nic není splatné, procvičit předčasně'
                : 'Zatím není co opakovat');
    final learnSubtitle =
        learnEnabled
            ? (due >= StudySession.reviewBatch
                ? '$learning v učení · $unseen nových · nejdřív opakuj ($due čeká)'
                : '$learning v učení · $unseen nových')
            : 'Žádná další slova';

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
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
                        levels: c.levels,
                        level: c.currentLevel,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatPill(
                              value: due,
                              label: 'k opakování',
                              tone: kToneGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatPill(
                              value: learning,
                              label: 'v učení',
                              tone: kToneAmber,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatPill(
                              value: unseen,
                              label: 'nových',
                              tone: kToneBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Která strana karty je první',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ),
                      _DirectionPicker(c: c),
                      const SizedBox(height: 20),
                      _ModeCard(
                        title: 'Opakování a učení',
                        subtitle: '$due k opakování · nová slova po pěticích',
                        icon: Icons.play_arrow_rounded,
                        tone: kToneBlue,
                        emphasized: true,
                        onTap:
                            bothEnabled ? () => onStart(StudyMode.both) : null,
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _ModeCard(
                                title: 'Jen opakování',
                                subtitle: reviewSubtitle,
                                icon: Icons.replay_rounded,
                                tone: kToneGreen,
                                onTap:
                                    reviewEnabled
                                        ? () => onStart(StudyMode.reviewOnly)
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeCard(
                                title: 'Jen učení',
                                subtitle: learnSubtitle,
                                icon: Icons.school_rounded,
                                tone: kToneAmber,
                                onTap:
                                    learnEnabled
                                        ? () => onStart(StudyMode.learnOnly)
                                        : null,
                              ),
                            ),
                          ],
                        ),
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
    final streak = c.streak;
    final done = c.doneToday;
    final goal = c.dailyGoal;
    final reached = done >= goal;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: softShadow(),
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(26),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CourseFlag(course: c.course, width: 30, height: 21),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            c.course.backLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded, color: kMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Dnešní cíl: $done / $goal karet',
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: softShadow(),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (done / goal).clamp(0.0, 1.0),
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFE3E7EE),
                    color: reached ? kToneGreen.solidA : kToneBlue.accent,
                  ),
                ),
                reached
                    ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: kToneGreen.solidA,
                    )
                    : Text(
                      '$done',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Série dní (nejdelší: ${c.bestStreak})',
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              boxShadow: softShadow(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 24,
                  color:
                      streak > 0 ? kToneAmber.solidB : const Color(0xFFB4BBC7),
                ),
                const SizedBox(width: 2),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: streak > 0 ? kInk : kMuted,
                  ),
                ),
              ],
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
  final List<LevelStep> levels;
  final LevelStep? level;

  const _ProgressCard({
    required this.learned,
    required this.solid,
    required this.total,
    required this.percent,
    required this.reviewedToday,
    required this.learnedToday,
    required this.levels,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final darkColor = level?.dark ?? const Color(0xFF9AA3B2);
    final lightColor = Color.lerp(darkColor, Colors.white, 0.5)!;
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
              Text(
                '$learned',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: kInk,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'z $total slov',
                  style: const TextStyle(fontSize: 15, color: kMuted),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: kToneBlue.soft(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent %',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kToneBlue.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LevelScale(
            levels: levels,
            learned: learned,
            total: total,
            bar: TwoToneProgressBar(
              light: total == 0 ? 0 : learned / total,
              dark: total == 0 ? 0 : solid / total,
              lightColor: lightColor,
              darkColor: darkColor,
              height: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Dot(darkColor),
              const SizedBox(width: 6),
              Text(
                'pevně zvládnuto $solid',
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
              const SizedBox(width: 14),
              _Dot(lightColor),
              const SizedBox(width: 6),
              const Text(
                'naučeno',
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
              const Spacer(),
              Text(
                'Dnes: $reviewedToday + $learnedToday',
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
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
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Tone tone;
  const _StatPill({
    required this.value,
    required this.label,
    required this.tone,
  });

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
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tone.accent,
            ),
          ),
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
                    // Neaktivní výplň má barvu podkladu (neprůhledná), jinak by
                    // při animaci stín prosvítal a problikl by tmavě.
                    color:
                        c.settings.directionMode == e.key
                            ? Colors.white
                            : const Color(0xFFE6EAF2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        c.settings.directionMode == e.key
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
                      fontWeight:
                          c.settings.directionMode == e.key
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

/// Karta s režimem procvičování: měkký přechod ve výplni a světlý vnitřní okraj.
/// Hlavní režim je přes celou šířku, vlevo kruh se sytým přechodem; ostatní jsou
/// menší dlaždice (ikona nahoře, pod ní text), dvě vedle sebe.
/// Po stisku se karta lehce zmenší.
class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Tone tone;
  final bool emphasized;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  static const Color _offBg = Color(0xFFEDEFF4);
  static const Color _offAccent = Color(0xFFB9BEC9);
  static const Color _offBorder = Color(0xFFD9DDE6);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final tone = w.tone;
    final enabled = w.onTap != null;
    final big = w.emphasized;
    final radius = BorderRadius.circular(big ? 24 : 20);
    final accent = enabled ? tone.accent : _offAccent;
    final titleColor = enabled ? tone.ink : kMuted;
    final subColor = enabled ? tone.inkSoft : kMuted;

    final titleText = Text(
      w.title,
      style: TextStyle(
        fontSize: big ? 20 : 16,
        fontWeight: FontWeight.w700,
        color: titleColor,
      ),
    );
    final subText = Text(
      w.subtitle,
      maxLines: big ? 2 : 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.5, color: subColor),
    );

    final Widget content =
        big
            ? Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: enabled ? tone.solid : null,
                    color: enabled ? null : _offAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: enabled ? tone.onSolid : _offBg,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleText, const SizedBox(height: 2), subText],
                  ),
                ),
              ],
            )
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(w.icon, color: accent, size: 26),
                const SizedBox(height: 14),
                titleText,
                const SizedBox(height: 2),
                subText,
              ],
            );

    return AnimatedScale(
      scale: enabled && _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          gradient: enabled ? tone.soft() : null,
          color: enabled ? null : _offBg,
          borderRadius: radius,
          border: Border.all(
            color: enabled ? Colors.white.withValues(alpha: 0.9) : _offBorder,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: w.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding:
                  big
                      ? const EdgeInsets.symmetric(horizontal: 18, vertical: 20)
                      : const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
