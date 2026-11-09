import 'package:flutter/material.dart';

import '../services/study_session.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/achievement_dialog.dart';
import '../widgets/app_bottom_bar.dart';
import 'home_view.dart';
import 'session_views.dart';
import 'settings_page.dart';
import 'word_list_page.dart';

/// Hlavní kostra aplikace se spodní lištou: domů / karty / slova / nastavení.
class HomeShell extends StatefulWidget {
  final StudyController controller;
  final VoidCallback onChangeCourse;

  const HomeShell({
    super.key,
    required this.controller,
    required this.onChangeCourse,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _home = 0;
  static const int _cards = 1;

  int _tab = _home;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
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
                  return PracticeView(c: c);
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
