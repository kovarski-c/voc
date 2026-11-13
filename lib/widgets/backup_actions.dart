import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../services/file_io.dart';
import '../study_controller.dart';
import '../theme.dart';
import 'tone_button.dart';

/// Záloha je jen ve webové verzi (na mobilu se ukládá do souborů aplikace).
bool get backupAvailable => fileIoSupported;

/// Stáhne (nebo na iOS nabídne uložit) zálohu postupu všech kurzů.
Future<void> exportBackup(BuildContext context, StudyController c) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await c.flush(); // ať záloha obsahuje i poslední odpověď
    final text = await BackupService.export();
    await saveTextFile(BackupService.fileName(), text);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Záloha je připravená.')),
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Zálohu se nepodařilo vytvořit: $e')),
    );
  }
}

/// Načte zálohu ze souboru, po potvrzení přepíše postup a znovu načte stránku.
Future<void> importBackup(BuildContext context, StudyController c) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  // Výběr souboru musí přijít hned po klepnutí, proto je před dialogem.
  final text = await pickTextFile();
  if (text == null || !context.mounted) return;

  final BackupData backup;
  try {
    backup = BackupService.parse(text);
  } on FormatException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }

  final at = backup.exportedAt;
  final when = at == null ? '' : ' z ${at.day}. ${at.month}. ${at.year}';
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Importovat zálohu?'),
          content: Text(
            'Záloha$when obsahuje postup v ${backup.courseCount} kurzech. '
            'Současný postup v těchto kurzech se přepíše.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zrušit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importovat'),
            ),
          ],
        ),
  );
  if (ok != true) return;

  try {
    c.store.freeze(); // staré údaje v paměti už nesmí nic přepsat
    await BackupService.restore(backup);
    reloadPage();
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Import se nepodařil: $e')),
    );
  }
}

/// Dvojice tlačítek Stáhnout / Importovat (pro Nastavení).
class BackupButtons extends StatelessWidget {
  final StudyController c;
  const BackupButtons({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ToneButton(
            label: 'Stáhnout',
            icon: Icons.download_rounded,
            tone: kToneBlue,
            onPressed: () => exportBackup(context, c),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ToneButton(
            label: 'Importovat',
            icon: Icons.upload_rounded,
            tone: kToneGreen,
            onPressed: () => importBackup(context, c),
          ),
        ),
      ],
    );
  }
}
