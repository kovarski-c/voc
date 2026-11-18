import 'package:material_ui/material_ui.dart';

import '../study_controller.dart';
import '../theme.dart';
import '../widgets/course_flag.dart';
import 'placement_page.dart';
import '../widgets/backup_actions.dart';

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
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Nastavení',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
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
                              Text(
                                c.course.backLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${c.course.frontLabel} → ${c.course.backLabel}',
                                style: TextStyle(fontSize: 13, color: kMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: kMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Úroveň slovní zásoby',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder:
                              (_) =>
                                  PlacementPage(controller: c, firstRun: false),
                        ),
                      ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Určit úroveň',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Test nebo ruční výběr. Změní se jen slova, '
                              'která ještě nemají žádný pokrok.',
                              style: TextStyle(fontSize: 12.5, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: kMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Denní cíl',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.dailyGoal} karet denně',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: c.dailyGoal.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '${c.dailyGoal}',
                      onChanged: (v) => c.setDailyGoal(v.round()),
                    ),
                    Text(
                      'Do cíle se počítají zopakovaná i naučená slova. '
                      'Den se do série započítá už od 5 karet; ve 4:00 ráno začíná nový den.',
                      style: TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Cíl nových slov',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.newWordsGoal} nových slov denně',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: c.newWordsGoal.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${c.newWordsGoal}',
                      onChanged: (v) => c.setNewWordsGoal(v.round()),
                    ),
                    Text(
                      'Počítá se slovo, které dokončíš (3 správně v řadě). '
                      'Cíl neovlivňuje sérii, jen graf: dny s dosaženým cílem '
                      'mají sloupec naučených slov plný, ostatní jen obrys.',
                      style: TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Vzhled',
                child: Row(
                  children: [
                    for (final t in AppThemeId.values) ...[
                      if (t != AppThemeId.values.first)
                        const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeOption(
                          id: t,
                          selected: c.settings.theme == t,
                          onTap: () => c.setTheme(t),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Odezva',
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Vibrace při swipu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(value: c.settings.haptics, onChanged: c.setHaptics),
                  ],
                ),
              ),
              if (c.course.hasVulgar) ...[
                const SizedBox(height: 16),
                _Section(
                  title: 'Obsah',
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Skrýt vulgární slova',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: c.settings.hideVulgar,
                        onChanged: c.setHideVulgar,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _Section(
                title: 'Směr karet při opakování',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'V automatickém režimu se jako první ukáže ${c.course.frontLabel} '
                      'v $pct % případů, jinak ${c.course.backLabel}.',
                      style: TextStyle(fontSize: 14, color: kInk),
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
                          child: Text(
                            '$pct %',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Při učení je pořadí pevné: první zkoušení ukáže učený jazyk, '
                      'druhé rodný, další podle tohoto poměru. Přepínač na domovské '
                      'stránce má přednost.',
                      style: TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              if (backupAvailable) ...[
                const SizedBox(height: 16),
                _Section(
                  title: 'Záloha postupu',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Postup se ve webové verzi ukládá jen v tomto prohlížeči. '
                        'Stáhni si zálohu, abys o něj nepřišel/a při smazání dat '
                        'stránky nebo při přechodu na jiné zařízení.',
                        style: TextStyle(fontSize: 12.5, color: kMuted),
                      ),
                      const SizedBox(height: 12),
                      BackupButtons(c: c),
                    ],
                  ),
                ),
              ],
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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
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

/// Dlaždice pro výběr tématu: barvy a název v paletě daného tématu.
class _ThemeOption extends StatelessWidget {
  final AppThemeId id;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = paletteFor(id);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kBlue : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final tone in [p.toneBlue, p.toneGreen, p.toneAmber])
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: tone.solid,
                    ),
                  ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 20, color: kBlue),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              id.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
