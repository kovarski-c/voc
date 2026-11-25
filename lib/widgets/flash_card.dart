import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/card_progress.dart';
import '../models/course.dart';
import 'card_status.dart';
import 'multi_form_text.dart';
import 'swipe_hint.dart' show kSwipeThreshold;
import '../theme.dart';

// ---- Vzhled karty: tady si můžeš hrát ----
const double kCardRadius = 30; // zaoblení rohů
const double kCardElevation = 5; // síla stínu
const Color kCardShadowColor = Color.fromARGB(100, 5, 5, 5); // barva stínu
const double kCardSize = 300; // šířka i výška karty
const int kFlipMs = 350; // délka otočení karty
const double kCardMaxHeight =
    440; // karta se s dlouhým textem protáhne nejvýš sem, pak se scrolluje

/// Odkud (od horního okraje karty) začíná slovo. Střed karty je 150,
/// jednořádkové slovo tak vychází přesně doprostřed.
const double kWordTop = 134;

/// Karta. Klepnutím se otočí (animace), swipem se odhodí
/// (doprava = umím, doleva = ještě neumím). Barevný glow a nápis při tažení
/// kreslí SwipeHint mimo kartu; kartě stačí hlásit posun přes [dragOffset].
/// Slovo začíná vždy na stejném místě; když je textu moc, posouvá se
/// uvnitř karty (svisle), takže se nic nepřekrývá.
class FlashCard extends StatefulWidget {
  final Course course;
  final int index; // klíč karty (id slova)
  final int number; // číslo v UI (pozice ve viditelném seznamu)
  final CardInfo info;
  final bool showBack;
  final bool nativeFront; // true = první se ukáže rodné slovo (course.front)
  final bool interactive;
  final bool introMode;
  final bool haptics;
  final double maxHeight; // nejvyšší povolená výška karty (dál se scrolluje)
  final VoidCallback onFlip;
  final void Function(bool known) onAnswered;
  final ValueNotifier<double>? dragOffset; // posun karty pro SwipeHint

  const FlashCard({
    super.key,
    required this.course,
    required this.index,
    required this.number,
    required this.info,
    required this.showBack,
    required this.nativeFront,
    required this.onFlip,
    required this.onAnswered,
    this.interactive = true,
    this.introMode = false,
    this.haptics = true,
    this.maxHeight = kCardMaxHeight,
    this.dragOffset,
  });

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with TickerProviderStateMixin {
  double _offsetX = 0.0;
  late final AnimationController _controller; // odhození swipem
  late final AnimationController _flip; // otočení
  Animation<double>? _anim;
  bool _prevShowBack = false;
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
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFlipMs),
    );
  }

  @override
  void didUpdateWidget(FlashCard old) {
    super.didUpdateWidget(old);
    if (!widget.introMode && old.showBack != widget.showBack) {
      _prevShowBack = old.showBack;
      _flip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flip.dispose();
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
    final known = _offsetX > kSwipeThreshold;
    final unknown = _offsetX < -kSwipeThreshold;
    final answered = known || unknown;
    final endX = known ? 500.0 : (unknown ? -500.0 : 0.0);

    if (answered && widget.haptics) {
      if (known) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    _anim = Tween<double>(
      begin: _offsetX,
      end: endX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.reset();
    await _controller.forward();
    if (!mounted) return;
    if (answered) {
      widget.onAnswered(known);
    } else {
      _past = false;
      _setOffset(0.0);
    }
  }

  Widget _scrollable(List<Widget> children) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );

  Widget _faceContent(bool showBack) {
    final c = widget.course;
    final i = widget.index;
    final dark = kInk;
    final grey = kMuted;

    if (widget.introMode) {
      // Nejdřív učený jazyk s výslovností, pod čárou teprve rodný význam.
      final pron = c.pronunciation(i);
      return _scrollable([
        MultiFormText(
          c.back(i),
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
        MultiFormText(c.front(i), style: TextStyle(fontSize: 22, color: dark)),
      ]);
    }

    final showNative = showBack != widget.nativeFront;
    // Výslovnost patří k učené straně (back).
    final pron = showNative ? '' : c.pronunciation(i);
    return _scrollable([
      MultiFormText(
        showNative ? c.front(i) : c.back(i),
        style: TextStyle(
          fontSize: 24,
          fontWeight: showNative ? FontWeight.w500 : FontWeight.normal,
          color: dark,
        ),
      ),
      if (pron.isNotEmpty) ...[
        const SizedBox(height: 4),
        MultiFormText(pron, style: TextStyle(fontSize: 16, color: grey)),
      ],
    ]);
  }

  Widget _card(bool showBack) {
    final intro = widget.introMode;
    return Card(
      elevation: kCardElevation,
      shadowColor: kCardShadowColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      color: kSurface,
      child: ConstrainedBox(
        // Výška: aspoň čtverec, s dlouhým textem se protáhne (karta zůstane
        // vycentrovaná) až do maxHeight, pak se text uvnitř scrolluje.
        constraints: BoxConstraints(
          minWidth: kCardSize,
          maxWidth: kCardSize,
          minHeight: kCardSize,
          maxHeight: math.max(kCardSize, widget.maxHeight),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: kWordTop),
                Flexible(child: _faceContent(showBack)),
                SizedBox(height: intro ? 16 : 46),
              ],
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
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
            child: GestureDetector(
              onTap: widget.introMode ? null : widget.onFlip,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  // Otočení kolem svislé osy; strana se vymění v půlce, kdy je karta kolmo.
                  final t = _flip.isAnimating ? _flip.value : 1.0;
                  final side = t < 0.5 ? _prevShowBack : widget.showBack;
                  final angle = t < 0.5 ? t * math.pi : (t - 1) * math.pi;
                  return Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                    child: _card(side),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
