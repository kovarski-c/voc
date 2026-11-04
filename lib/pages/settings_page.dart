import 'package:flutter/material.dart';

import '../study_controller.dart';
import '../theme.dart';
import '../widgets/course_flag.dart';

/// Nastavení (záložka vpravo dole).
class SettingsPage extends StatelessWidget {
  final StudyController controller;
  final VoidCallback onChangeCourse;

  const SettingsPage({
    super.key,
    required this.controller,
    required this.onChangeCourse,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final p = c.settings.nativeFrontProb;
          final pct = (p * 100).round();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text('Nastavení',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
              ),
              _Section(
                title: 'Jazyk',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onChangeCourse,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CourseFlag(course: c.course, width: 36, height: 25),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.course.backLabel,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  '${c.course.frontLabel} → ${c.course.backLabel}',
                                  style: const TextStyle(
                                      fontSize: 13, color: kMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Směr karet při opakování',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'V automatickém režimu se jako první ukáže ${c.course.frontLabel} '
                      'v $pct % případů, jinak ${c.course.backLabel}.',
                      style: const TextStyle(fontSize: 14, color: kInk),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: p,
                            min: 0,
                            max: 1,
                            divisions: 20,
                            label: '$pct %',
                            onChanged: c.setNativeFrontProb,
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text('$pct %',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const Text(
                      'Při učení je pořadí pevné: první zkoušení ukáže učený jazyk, '
                      'druhé rodný, další podle tohoto poměru. Přepínač na domovské '
                      'stránce má přednost.',
                      style: TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: softShadow(),
          ),
          child: child,
        ),
      ],
    );
  }
}
