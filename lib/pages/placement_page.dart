import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/levels.dart';
import '../services/placement.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/level_shield.dart';
import '../widgets/multi_form_text.dart';
import '../widgets/rounded_progress_bar.dart';
import '../widgets/tone_button.dart';

enum _Stage { welcome, test, result, picker }

/// Úvodní výběr úrovně: začít od nuly, vybrat úroveň, nebo udělat krátký test.
/// Při prvním otevření kurzu se ukáže sama, později je v Nastavení.
class PlacementPage extends StatefulWidget {
  final StudyController controller;
  final bool firstRun;

  const PlacementPage({
    super.key,
    required this.controller,
    required this.firstRun,
  });

  @override
  State<PlacementPage> createState() => _PlacementPageState();
}

class _PlacementPageState extends State<PlacementPage> {
  _Stage _stage = _Stage.welcome;
  PlacementTest? _test;

  StudyController get c => widget.controller;

  void _startTest() {
    final t = PlacementTest(total: c.totalWords);
    setState(() {
      _test = t;
      _stage = t.done ? _Stage.result : _Stage.test;
    });
  }

  void _answer(bool known) {
    final t = _test!;
    t.answer(known);
    setState(() {
      if (t.done) _stage = _Stage.result;
    });
  }

  Future<void> _apply(int known) async {
    // Dřívější výběr se přepíše; procvičená slova zůstanou, proto jen informace.
    final n = c.placementCardCount;
    if (n > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Upravit úroveň?'),
              content: Text(
                'Přepíšu $n slov z předchozího výběru. Slova, která jsi sama '
                'procvičila, zůstanou beze změny.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Zrušit'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Pokračovat'),
                ),
              ],
            ),
      );
      if (ok != true || !mounted) return;
    }
    c.applyPlacement(known: known, answers: _test?.answers ?? const []);
    if (mounted) Navigator.of(context).pop();
  }

  void _fromScratch() {
    if (widget.firstRun) c.skipPlacement();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (widget.firstRun) c.skipPlacement(); // zavření = od nuly
        } else {
          setState(() => _stage = _Stage.welcome);
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(key: ValueKey(_stage), child: _body()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Šipka zpět: z dalších kroků vrací na úvod, z úvodu zavře stránku.
  /// Při prvním spuštění (není kam se vrátit) se na úvodu nezobrazuje.
  Widget _topBar() {
    final show = _stage != _Stage.welcome || !widget.firstRun;
    return SizedBox(
      height: 52,
      child: Align(
        alignment: Alignment.centerLeft,
        child:
            show
                ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    tooltip: 'Zpět',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kInk),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      fixedSize: const Size(44, 44),
                      shadowColor: Colors.black,
                      elevation: 1,
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.welcome:
        return _welcome();
      case _Stage.test:
        return _testView();
      case _Stage.result:
        return _result();
      case _Stage.picker:
        return _picker();
    }
  }

  // ---------------------------------------------------------------- úvod
  Widget _welcome() {
    return ListView(
      children: [
        const SizedBox(height: 4),
        const Text(
          'Odkud začneš?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Když už část slov umíš, nemusíš se je učit od začátku. Slova, která '
          'označíme jako známá, se ti budou připomínat postupně.',
          style: TextStyle(fontSize: 15, color: kMuted, height: 1.35),
        ),
        const SizedBox(height: 22),
        if (c.totalWords >= 60)
          _OptionCard(
            icon: Icons.bolt_rounded,
            title: 'Udělat krátký test',
            subtitle:
                'Asi 20 slov, zhruba dvě minuty. Ukáže doporučenou úroveň.',
            tone: kToneBlue,
            big: true,
            onTap: _startTest,
          ),
        if (c.levels.isNotEmpty)
          _OptionCard(
            icon: Icons.stairs_rounded,
            title: 'Vybrat úroveň sám',
            subtitle: 'Řeknu, kolik slov už umím.',
            tone: kToneGreen,
            onTap: () => setState(() => _stage = _Stage.picker),
          ),
        _OptionCard(
          icon: Icons.flag_rounded,
          title: 'Začít od nuly',
          subtitle: 'Žádná slova zatím neznám.',
          tone: kToneAmber,
          onTap: _fromScratch,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- test
  Widget _testView() {
    final t = _test!;
    final rank = t.currentRank!;
    final key = c.order[rank];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Krátký test',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kMuted,
              ),
            ),
            const Spacer(),
            Text(
              'Slovo ${t.answers.length + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RoundedProgressBar(value: t.progress, color: kBlue, height: 10),
        const Spacer(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: AspectRatio(
              aspectRatio: 1,
              child: _TestCard(
                key: ValueKey(rank),
                front: c.course.back(key),
                pronunciation: c.course.pronunciation(key),
                meaning: c.course.front(key),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Klepnutím kartu otočíš a ověříš si význam. Slova, která nepoznáš, tě aplikace naučí.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: kMuted),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: ToneButton(
                label: 'Neznám',
                icon: Icons.close_rounded,
                tone: kToneBlue,
                height: 56,
                fontSize: 16,
                onPressed: () => _answer(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ToneButton(
                label: 'Znám',
                icon: Icons.check_rounded,
                tone: kToneGreen,
                height: 56,
                fontSize: 16,
                onPressed: () => _answer(true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- výsledek
  Widget _result() {
    final est = _test!.estimate;
    final shown = (est / 50).round() * 50;
    final cur = Levels.current(c.levels, est);
    final next = Levels.next(c.levels, est);
    final atStart = est < 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        if (cur != null && !atStart)
          Center(child: LevelShield(level: cur, earned: true, width: 84)),
        const SizedBox(height: 18),
        Text(
          atStart
              ? 'Začneš od začátku'
              : (cur != null
                  ? 'Úroveň ${cur.code}'
                  : 'Zatím před první úrovní'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          atStart
              ? 'Test vyšel tak, že žádná slova nebudu označovat jako známá.'
              : 'Odhad: znáš asi $shown nejčastějších slov.'
                  '${next != null ? ' Další úroveň ${next.code} je od ${next.threshold} slov.' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: kMuted, height: 1.35),
        ),
        const Spacer(),
        ToneButton(
          label: atStart ? 'Začít' : 'Potvrdit a začít',
          icon: Icons.arrow_forward_rounded,
          tone: kToneBlue,
          height: 56,
          fontSize: 16,
          onPressed: () => _apply(est),
        ),
        const SizedBox(height: 8),
        if (c.levels.isNotEmpty)
          ToneButton(
            label: 'Vybrat úroveň sám',
            icon: Icons.stairs_rounded,
            tone: kToneGreen,
            height: 56,
            fontSize: 16,
            onPressed: () => setState(() => _stage = _Stage.picker),
          ),
        SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: TextButton(
            onPressed: _startTest,
            child: const Text(
              'Zopakovat test',
              style: TextStyle(color: kMuted),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- výběr
  Widget _picker() {
    return ListView(
      children: [
        const SizedBox(height: 4),
        const Text(
          'Kolik už umíš?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vyber nejvyšší úroveň, kterou už máš. Slova do ní se označí jako '
          'známá a budou se ti připomínat postupně.',
          style: TextStyle(fontSize: 15, color: kMuted, height: 1.35),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          icon: Icons.flag_rounded,
          title: 'Začít od nuly',
          subtitle: 'Žádná slova neoznačím jako známá.',
          tone: kToneAmber,
          onTap: _fromScratch,
        ),
        for (final l in c.levels)
          _OptionCard(
            leading: LevelShield(level: l, earned: true, width: 32),
            title: 'Umím úroveň ${l.code}',
            subtitle: 'Prvních ${l.threshold} slov se označí jako známá.',
            onTap: () => _apply(l.threshold),
          ),
      ],
    );
  }
}

class _OptionCard extends StatefulWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String subtitle;
  final Tone? tone; // null = bílá karta
  final bool big;
  final VoidCallback onTap;

  const _OptionCard({
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    this.tone,
    required this.onTap,
    this.big = false,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final tone = w.tone;
    final white = tone == null;
    final radius = BorderRadius.circular(w.big ? 24 : 20);
    final circle = w.big ? 52.0 : 44.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: tone?.soft(),
            color: white ? Colors.white : null,
            borderRadius: radius,
            boxShadow: white ? softShadow() : null,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: w.big ? 20 : 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: circle,
                      child: Center(
                        child:
                            w.leading ??
                            Container(
                              width: circle,
                              height: circle,
                              decoration: BoxDecoration(
                                gradient: tone?.solid,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                w.icon,
                                size: w.big ? 30 : 25,
                                color: tone?.onSolid ?? kInk,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.title,
                            style: TextStyle(
                              fontSize: w.big ? 19 : 17,
                              fontWeight: FontWeight.w800,
                              color: white ? kInk : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            w.subtitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: white ? kMuted : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: tone?.accent ?? kMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Čtvercová karta testu. Klepnutím se otočí a ukáže význam slova,
/// takže si člověk může ověřit, jestli odhadl správně (a znal všechny významy).
class _TestCard extends StatefulWidget {
  final String front; // učené slovo
  final String pronunciation;
  final String meaning; // rodný význam

  const _TestCard({
    super.key,
    required this.front,
    required this.pronunciation,
    required this.meaning,
  });

  @override
  State<_TestCard> createState() => _TestCardState();
}

class _TestCardState extends State<_TestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  bool _back = false;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_flip.isAnimating) return;
    setState(() => _back = !_back);
    _flip.forward(from: 0);
  }

  Widget _face(bool back) {
    const grey = Color(0xFF767676);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF2F6FF)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kBlue.withValues(alpha: 0.10), width: 1.5),
        boxShadow: softShadow(0.10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              back ? 'Význam slova' : 'Znáš význam tohoto slova?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kBlue,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MultiFormText(
                      back ? widget.meaning : widget.front,
                      style: TextStyle(
                        fontSize: back ? 30 : 38,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        height: 1.15,
                      ),
                    ),
                    if (!back && widget.pronunciation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      MultiFormText(
                        widget.pronunciation,
                        style: const TextStyle(fontSize: 16, color: grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Icon(
            Icons.touch_app_rounded,
            size: 20,
            color: kBlue.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          // Strana se vymění v půlce otočení, kdy je karta kolmo.
          final t = _flip.isAnimating ? _flip.value : 1.0;
          final showBack = t < 0.5 ? !_back : _back;
          final angle = t < 0.5 ? t * math.pi : (t - 1) * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
            child: _face(showBack),
          );
        },
      ),
    );
  }
}
