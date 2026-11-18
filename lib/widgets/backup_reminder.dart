import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/storage.dart';
import '../../study_controller.dart';
import '../../theme.dart';
import 'backup_actions.dart';

/// Připomínání zálohy (jen web). Stav je v samostatném souboru, takže se
/// nedostane do zálohy ani se nepřepíše jejím importem.
class BackupReminderState {
  static const _name = 'backup_reminder.json';

  /// Po kolika dnech bez zálohy se ukáže dialog.
  static const dialogAfterDays = 3;

  /// Na jak dlouho odloží tlačítko „Později“.
  static const snoozeDays = 1;

  /// Mění se po každé záloze, aby se řádek obnovil.
  static final ValueNotifier<int> tick = ValueNotifier(0);

  int? firstMs; // první použití (počítá se, dokud není žádná záloha)
  int? lastMs; // poslední stažená záloha
  int? snoozeUntilMs;
  int? dialogDay; // den, kdy se dialog naposledy ukázal

  static Future<BackupReminderState> load() async {
    final s = BackupReminderState();
    try {
      final text = await Storage.read(_name);
      if (text != null) {
        final m = jsonDecode(text) as Map<String, dynamic>;
        s.firstMs = (m['first'] as num?)?.toInt();
        s.lastMs = (m['last'] as num?)?.toInt();
        s.snoozeUntilMs = (m['snooze'] as num?)?.toInt();
        s.dialogDay = (m['day'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('Načtení stavu zálohy selhalo: $e');
    }
    if (s.firstMs == null) {
      s.firstMs = DateTime.now().millisecondsSinceEpoch;
      await s.save();
    }
    return s;
  }

  Future<void> save() async {
    try {
      await Storage.write(
        _name,
        jsonEncode({
          'first': firstMs,
          'last': lastMs,
          'snooze': snoozeUntilMs,
          'day': dialogDay,
        }),
      );
    } catch (e) {
      debugPrint('Uložení stavu zálohy selhalo: $e');
    }
  }

  /// Zavolat po úspěšném stažení zálohy.
  static Future<void> markDone() async {
    final s = await load();
    s.lastMs = DateTime.now().millisecondsSinceEpoch;
    s.snoozeUntilMs = null;
    await s.save();
    tick.value++;
  }

  int get _refMs => lastMs ?? firstMs ?? DateTime.now().millisecondsSinceEpoch;

  int get daysSince =>
      DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(_refMs))
          .inDays;

  bool shouldShowDialog() {
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    if (daysSince < dialogAfterDays) return false;
    if (dialogDay == today) return false;
    final snooze = snoozeUntilMs;
    if (snooze != null && now.millisecondsSinceEpoch < snooze) return false;
    return true;
  }

  Future<void> markDialogShown() async {
    final now = DateTime.now();
    dialogDay = now.year * 10000 + now.month * 100 + now.day;
    await save();
  }

  Future<void> snooze() async {
    snoozeUntilMs =
        DateTime.now()
            .add(const Duration(days: snoozeDays))
            .millisecondsSinceEpoch;
    await save();
  }

  String get noteText {
    if (lastMs == null) return 'Zatím nezálohováno';
    final d = daysSince;
    if (d == 0) return 'Poslední záloha: dnes';
    if (d == 1) return 'Poslední záloha: včera';
    return 'Poslední záloha: před $d dny';
  }
}

/// Stálý řádek „Poslední záloha: …“ na mezi-obrazovce po dávce. Po
/// 3 dnech bez zálohy se navíc (nejvýš jednou denně) ukáže dialog.
class BackupReminder extends StatefulWidget {
  final StudyController c;
  const BackupReminder({super.key, required this.c});

  @override
  State<BackupReminder> createState() => _BackupReminderState();
}

class _BackupReminderState extends State<BackupReminder> {
  BackupReminderState? _state;

  @override
  void initState() {
    super.initState();
    BackupReminderState.tick.addListener(_reload);
    _load(maybeDialog: true);
  }

  @override
  void dispose() {
    BackupReminderState.tick.removeListener(_reload);
    super.dispose();
  }

  void _reload() => _load();

  Future<void> _load({bool maybeDialog = false}) async {
    final s = await BackupReminderState.load();
    if (!mounted) return;
    setState(() => _state = s);
    if (maybeDialog && s.shouldShowDialog()) {
      await s.markDialogShown();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDialog(s);
      });
    }
  }

  Future<void> _showDialog(BackupReminderState s) async {
    final d = s.daysSince;
    final text =
        s.lastMs == null
            ? 'Postup je uložený jen v tomto prohlížeči a ještě není '
                'zálohovaný. Když se data webu smažou, přijdeš o něj.'
            : 'Poslední záloha je stará $d ${d >= 5 ? 'dní' : 'dny'}. '
                'Když se data webu smažou, přijdeš o postup od té doby.';
    final download = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Stáhnout zálohu?'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Později'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Stáhnout'),
              ),
            ],
          ),
    );
    if (download == true) {
      if (!mounted) return;
      await exportBackup(context, widget.c);
    } else {
      await s.snooze();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(s.noteText, style: TextStyle(fontSize: 13, color: kMuted)),
    );
  }
}
