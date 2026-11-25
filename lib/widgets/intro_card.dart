import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/card_progress.dart';
import '../models/course.dart';
import 'card_status.dart';
import 'flash_card.dart'
    show
        kCardRadius,
        kCardElevation,
        kCardShadowColor,
        kCardSize,
        kCardMaxHeight;
import 'multi_form_text.dart';
import 'swipe_hint.dart' show kSwipeThreshold;
import '../theme.dart';

/// Výška hlavičky (číslo + štítek stavu + indikátor), kterou obsah nesmí zasahovat.
const double kIntroHeaderHeight = 92;

/// Výška volného pruhu dole (obsah do něj nikdy nezasáhne).
const double kIntroFooterHeight = 44;

/// Karta pro představení nového slova (učící karta).
/// Obsah (slovo, výslovnost, čára, překlad) je jako celek vycentrovaný
/// v prostoru mezi hlavičkou a spodním pruhem, takže se nic nepřekrývá.
/// Swipe: doprava = už umím, doleva = naučit. Nereaguje na klepnutí.
/// Glow a nápis při tažení kreslí SwipeHint mimo kartu přes [dragOffset].
/// Procvičovací karta (FlashCard) zůstává beze změny.
class IntroCard extends StatefulWidget {
  final Course course;
  final int index; // klíč karty (id slova)
  final int number; // číslo v UI
  final CardInfo info;
  final bool interactive;
  final bool haptics;
  final double maxHeight;
  final void Function(bool known) onSwiped; // true = už umím, false = naučit
  final ValueNotifier<double>? dragOffset; // posun karty pro SwipeHint

  const IntroCard({
    super.key,
    required this.course,
    required this.index,
    required this.number,
    required this.info,
    required this.onSwiped,
    this.interactive = true,
    this.haptics = true,
    this.maxHeight = kCardMaxHeight,
    this.dragOffset,
  });

  @override
  State<IntroCard> createState() => _IntroCardState();
}

class _IntroCardState extends State<IntroCard>
    with SingleTickerProviderStateMixin {
  double _offsetX = 0.0;
  late final AnimationController _controller;
  Animation<double>? _anim;
  bool _past = false; // tažení už přesáhlo práh odhození

  void _setOffset(double v) {
    setState(() => _offsetX = v);
    widget.dragOffset?.value = v;
  }

  @override
  void initState() {
    super.initState();
    // nová karta začíná bez glow (předchozí odhozená mohla nechat posun ±500)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.dragOffset?.value = 0,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      final a = _anim;
      if (a != null) _setOffset(a.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_controller.isAnimating) return;
    _setOffset(_offsetX + d.delta.dx);
    final past = _offsetX.abs() > kSwipeThreshold;
    if (past != _past) {
      _past = past;
      if (past && widget.haptics) HapticFeedback.selectionClick();
    }
  }

  Future<void> _onDragEnd(DragEndDetails _) async {
    if (_controller.isAnimating) return;
    final known = _offsetX > kSwipeThreshold; // doprava = už umím
    final learn = _offsetX < -kSwipeThreshold; // doleva = naučit
    final answered = known || learn;
    final endX = known ? 500.0 : (learn ? -500.0 : 0.0);

    if (answered && widget.haptics) {
      known ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    }

    _anim = Tween<double>(
      begin: _offsetX,
      end: endX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.reset();
    await _controller.forward();
    if (!mounted) return;
    if (answered) {
      widget.onSwiped(known);
    } else {
      _past = false;
      _setOffset(0.0);
    }
  }

  Widget _content() {
    const contentMinHeight =
        kCardSize - kIntroHeaderHeight - kIntroFooterHeight;

    // Krátký obsah je uprostřed, dlouhý karty prodlouží a nakonec se scrolluje.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: contentMinHeight),
        child: Center(
          child: WordBlock(course: widget.course, index: widget.index),
        ),
      ),
    );
  }

  Widget _card() {
    return Card(
      elevation: kCardElevation,
      shadowColor: kCardShadowColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      color: kSurface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: kCardSize,
          maxWidth: kCardSize,
          minHeight: kCardSize,
          maxHeight: math.max(kCardSize, widget.maxHeight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hlavička: číslo + stav.
            SizedBox(
              height: kIntroHeaderHeight,
              // OverflowBox: i kdyby hlavička vyšla o pixel vyšší (řádkování
              // písma v zařízení), nehlásí se overflow a obsah se nehýbe.
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.number}',
                        style: TextStyle(fontSize: 14, color: kMuted),
                      ),
                      const SizedBox(height: 10),
                      CardStatus(info: widget.info),
                    ],
                  ),
                ),
              ),
            ),
            // Obsah: vycentrovaný mezi hlavičkou a spodním pruhem.
            Flexible(child: _content()),
            const SizedBox(height: kIntroFooterHeight),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.interactive,
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(_offsetX, _offsetX.abs() / 10),
          child: Transform.rotate(
            angle: (_offsetX / 300) * (math.pi / 10),
            child: _card(),
          ),
        ),
      ),
    );
  }
}

/// Slovo, výslovnost, čára a překlad pod sebou (sdílené učící kartou a
/// detailem slova v seznamu, aby vypadaly stejně).
class WordBlock extends StatelessWidget {
  final Course course;
  final int index; // klíč karty (id slova)
  const WordBlock({super.key, required this.course, required this.index});

  @override
  Widget build(BuildContext context) {
    final dark = kInk;
    final grey = kMuted;
    final pron = course.pronunciation(index);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MultiFormText(
          course.back(index),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: dark,
          ),
        ),
        if (pron.isNotEmpty) ...[
          const SizedBox(height: 4),
          MultiFormText(pron, style: TextStyle(fontSize: 16, color: grey)),
        ],
        const SizedBox(height: 14),
        const SizedBox(width: 120, child: Divider(height: 1)),
        const SizedBox(height: 14),
        MultiFormText(
          course.front(index),
          style: TextStyle(fontSize: 22, color: dark),
        ),
      ],
    );
  }
}
