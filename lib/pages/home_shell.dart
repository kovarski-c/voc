import 'package:material_ui/material_ui.dart';

import '../services/study_session.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/achievement_dialog.dart';
import '../widgets/app_bottom_bar.dart';
import 'home_view.dart';
import 'placement_page.dart';
import 'session_views.dart';
import 'settings_page.dart';
import 'word_list_page.dart';

/// Hlavní kostra aplikace se spodní lištou: domů / karty / slova / nastavení.
class HomeShell extends StatefulWidget {
  final StudyController controller;
  final VoidCallback onChangeCourse;
  final VoidCallback? onBackToLanguage;

  const HomeShell({
    super.key,
    required this.controller,
    required this.onChangeCourse,
    this.onBackToLanguage,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _home = 0;
  static const int _cards = 1;
  static const int _words = 2;
  static const int _settings = 3;

  int _tab = _home;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAskPlacement();
      _maybeExplainExclude();
    });
  }

  /// Jednou (nový uživatel i po aktualizaci) vysvětlí rozdíl Umím / Neučit.
  void _maybeExplainExclude() {
    final c = widget.controller;
    if (!mounted || c.needsPlacement || c.settings.seenExcludeHelp) return;
    c.markExcludeHelpSeen();
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: kSurface,
            title: const Text('Přidali jsme tlačítko Neučit'),
            content: const Text(
              'U nového slova teď máš tři možnosti:\n\n'
              '• Naučit: slovo se zařadí do učení.\n'
              '• Umím: slovo znáš, ale v opakování se ti občas ukáže.\n'
              '• Neučit: slovo už neuvidíš a nepočítá se do pokroku. '
              'Vrátit ho můžeš v seznamu slov.\n\n'
              'Tipy k učení najdeš pod žárovkou v učení.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Rozumím'),
              ),
            ],
          ),
    );
  }

  /// Při prvním otevření kurzu bez pokroku nabídne výběr úrovně / test.
  void _maybeAskPlacement() {
    final c = widget.controller;
    if (!mounted || !c.needsPlacement) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder:
                (_) => PlacementPage(
                  controller: c,
                  firstRun: true,
                  onBackToLanguage: widget.onBackToLanguage,
                ),
          ),
        )
        .then((_) {
          if (mounted) _maybeExplainExclude();
        });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    // Když relace skončí (např. "Skončit" na mezi-obrazovce), vrátí se uživatel domů.
    if (_tab == _cards && widget.controller.phase == Phase.idle && mounted) {
      setState(() => _tab = _home);
    }
    _maybeCelebrate();
  }

  /// Úspěchy se oslaví jen mezi dávkami (mezi-obrazovka nebo domů), ne uprostřed karet.
  void _maybeCelebrate() {
    final c = widget.controller;
    if (_celebrating || !c.hasAchievements) return;
    if (c.phase != Phase.idle && c.phase != Phase.interlude) return;
    final list = c.takeAchievements();
    _celebrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _celebrating = false;
        return;
      }
      await showAchievements(context, c, list);
      _celebrating = false;
      _maybeCelebrate();
    });
  }

  void _select(int i) {
    final c = widget.controller;
    // Klepnutí na Karty spustí výchozí režim, pokud právě žádná relace neběží.
    if (i == _cards && c.phase == Phase.idle) c.start(StudyMode.both);
    setState(() => _tab = i);
  }

  /// Ikonka úprav na kartě: otevře slovo v seznamu.
  void _openWord(int key) {
    widget.controller.requestOpenWord(key);
    setState(() => _tab = _words);
  }

  void _start(StudyMode mode) {
    widget.controller.start(mode);
    setState(() => _tab = _cards);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _tab,
        children: [
          ListenableBuilder(
            listenable: c,
            builder:
                (_, _) => HomeView(
                  c: c,
                  onStart: _start,
                  onChangeCourse: widget.onChangeCourse,
                  onOpenSettings: () => setState(() => _tab = _settings),
                ),
          ),
          ListenableBuilder(
            listenable: c,
            builder: (_, _) {
              switch (c.phase) {
                case Phase.idle:
                  return const SizedBox.shrink();
                case Phase.interlude:
                  return SafeArea(child: InterludeView(c: c));
                case Phase.reviewing:
                case Phase.learning:
                  return PracticeView(c: c, onOpenWord: _openWord);
              }
            },
          ),
          WordListPage(controller: c),
          SettingsPage(controller: c, onChangeCourse: widget.onChangeCourse),
        ],
      ),
      bottomNavigationBar: AppBottomBar(index: _tab, onTap: _select),
    );
  }
}
