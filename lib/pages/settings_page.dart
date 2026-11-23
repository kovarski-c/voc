import 'package:material_ui/material_ui.dart';

import '../services/motivation.dart';
import '../services/reminder.dart';
import '../services/settings_store.dart';
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
                              'Test, ruční výběr, nebo začít od nuly. Slova nad novou '
                              'úrovní se vrátí mezi nová.',
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
                title: 'Nová slova',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Choice(
                            label: 'Představit',
                            selected:
                                c.settings.newWordMode == NewWordMode.introduce,
                            onTap:
                                () => c.setNewWordMode(NewWordMode.introduce),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Choice(
                            label: 'Zkusit vybavit',
                            selected:
                                c.settings.newWordMode == NewWordMode.recall,
                            onTap: () => c.setNewWordMode(NewWordMode.recall),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.settings.newWordMode == NewWordMode.introduce
                          ? 'Nové slovo se nejdřív ukáže i s překladem a pak se zkouší.'
                          : 'Nové slovo se hned zkouší jako otáčecí kartička. '
                              'Když ho napoprvé znáš, přeskočí se rovnou do '
                              'opakování a do cíle nových slov se nepočítá.',
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
                title: 'Denní tip',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Zobrazovat denní tip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: c.settings.showTips,
                          onChanged: c.setShowTips,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Na domovské stránce ukáže tip k učení slov, k aplikaci '
                      'nebo k tvé úrovni. Když se začnou opakovat, můžeš je skrýt.',
                      style: TextStyle(fontSize: 12.5, color: kMuted),
                    ),
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
              if (Reminder.supported) ...[
                const SizedBox(height: 16),
                _ReminderSection(c: c),
              ],
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
                      'v $pct\u00A0% případů, jinak ${c.course.backLabel}.',
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

/// Denní připomínka, aby člověk neztratil sérii (jen Android).
class _ReminderSection extends StatelessWidget {
  final StudyController c;
  const _ReminderSection({required this.c});

  static String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _toggle(BuildContext context, bool v) async {
    final ok = await c.setReminderEnabled(v);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Oznámení nejsou povolená. Zapni je v nastavení telefonu.',
          ),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final cur = c.settings.reminderMinutes;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      builder:
          (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (t != null) c.setReminderTime(t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final on = c.settings.reminderEnabled;
    return _Section(
      title: 'Připomínka série',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Připomenout procvičování',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Switch(value: on, onChanged: (v) => _toggle(context, v)),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickTime(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Čas připomínky',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: kToneBlue.soft(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _fmt(c.settings.reminderMinutes),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kToneBlue.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Oznámení přijde v nastavený čas jen tehdy, když dnešek ještě není '
            'do série započítaný (stačí ${Motivation.streakMinCards} karet). '
            'Po splnění se dnešní připomínka zruší.',
            style: TextStyle(fontSize: 12.5, color: kMuted),
          ),
        ],
      ),
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

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kBg : kOffBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? kToneBlue.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? kToneBlue.accent : kMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
