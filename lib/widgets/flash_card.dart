import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/card_progress.dart';
import '../models/course.dart';
import 'card_status.dart';

// ---- Vzhled karty: tady si můžeš hrát ----
const double kCardRadius = 16; // zaoblení rohů
const double kCardElevation = 2; // síla stínu
const Color kCardShadowColor = Colors.black; // barva stínu
const double kCardSize = 300; // šířka i výška karty
const int kFlipMs = 350; // délka otočení karty

/// Karta. Klepnutím se otočí (animace), swipem se odhodí
/// (doprava = umím, doleva = neumím). V režimu představení ukazuje obě strany.
/// Slovo je vždy uprostřed karty; výslovnost a překlad visí pod ním.
class FlashCard extends StatefulWidget {
  final Course course;
  final int index;
  final CardInfo info;
  final bool showBack;
  final bool nativeFront; // true = první se ukáže rodné slovo (course.front)
  final bool interactive;
  final bool introMode;
  final VoidCallback onFlip;
  final void Function(bool known) onAnswered;

  const FlashCard({
    super.key,
    required this.course,
    required this.index,
    required this.info,
    required this.showBack,
    required this.nativeFront,
    required this.onFlip,
    required this.onAnswered,
    this.interactive = true,
    this.introMode = false,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        final a = _anim;
        if (a != null) setState(() => _offsetX = a.value);
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
    setState(() => _offsetX += d.delta.dx);
  }

  Future<void> _onDragEnd(DragEndDetails _) async {
    if (_controller.isAnimating) return;
    final known = _offsetX > 40;
    final unknown = _offsetX < -40;
    final answered = known || unknown;
    final endX = known ? 500.0 : (unknown ? -500.0 : 0.0);

    _anim = Tween<double>(begin: _offsetX, end: endX).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.reset();
    await _controller.forward();
    if (!mounted) return;
    if (answered) {
      widget.onAnswered(known);
    } else {
      setState(() => _offsetX = 0.0);
    }
  }

  Widget _centered(Alignment a, Widget child) => Align(
        alignment: a,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      );

  Widget _faceContent(bool showBack) {
    final c = widget.course;
    final i = widget.index;
    const dark = Color(0xFF1D1B20);
    const grey = Color(0xFF767676);

    if (widget.introMode) {
      final pron = c.pronunciation(i);
      return Stack(children: [
        _centered(
          Alignment.center,
          Text(c.front(i),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w500, color: dark),
              textAlign: TextAlign.center),
        ),
        if (pron.isNotEmpty)
          _centered(const Alignment(0, 0.27),
              Text(pron, style: const TextStyle(fontSize: 16, color: grey))),
        _centered(
          const Alignment(0, 0.6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 120, child: Divider(height: 1)),
              const SizedBox(height: 10),
              Text(c.back(i),
                  style: const TextStyle(fontSize: 22, color: dark),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ]);
    }

    final showNative = showBack != widget.nativeFront;
    final pron = showNative ? c.pronunciation(i) : '';
    return Stack(children: [
      _centered(
        Alignment.center,
        Text(
          showNative ? c.front(i) : c.back(i),
          style: TextStyle(
            fontSize: 24,
            fontWeight: showNative ? FontWeight.w500 : FontWeight.normal,
            color: dark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      if (pron.isNotEmpty)
        _centered(const Alignment(0, 0.27),
            Text(pron, style: const TextStyle(fontSize: 16, color: grey))),
    ]);
  }

  Widget _card(bool showBack) {
    final alpha = _offsetX.abs().toInt().clamp(0, 255);
    return Card(
      elevation: kCardElevation,
      shadowColor: kCardShadowColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      color: Colors.white,
      child: SizedBox(
        width: kCardSize,
        height: kCardSize,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF767676)),
                    ),
                    const SizedBox(height: 10),
                    CardStatus(info: widget.info),
                  ],
                ),
              ),
            ),
            _faceContent(showBack),
            if (!widget.introMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(
                    _offsetX > 0 ? Icons.check_outlined : Icons.close_outlined,
                    size: 24,
                    color: _offsetX > 0
                        ? Color.fromARGB(alpha, 76, 175, 80)
                        : Color.fromARGB(alpha, 244, 67, 54),
                  ),
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
                    transform: Matrix4.identity()
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
