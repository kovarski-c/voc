import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../theme.dart';

/// Od kolika pixelů tažení se karta odhodí (a text s glow dosáhnou plné síly).
const double kSwipeThreshold = 80;

/// Text, icon, and color tone shown for one swipe direction.
class SwipeSide {
  final String text;
  final IconData icon;
  final dynamic tone;

  const SwipeSide({required this.text, required this.icon, required this.tone});
}

/// Jedna strana swipu: text, ikona a barevný tón.
class SwipeHint extends StatefulWidget {
  final ValueListenable<double> drag;
  final SwipeSide left;
  final SwipeSide right;

  const SwipeHint({
    super.key,
    required this.drag,
    required this.left,
    required this.right,
  });

  @override
  State<SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400), // délka doznívání
  );
  double _prev = 0; // poslední známý posun
  double _ghost = 0; // posun, od kterého glow doznívá

  @override
  void initState() {
    super.initState();
    widget.drag.addListener(_onDrag);
  }

  @override
  void dispose() {
    widget.drag.removeListener(_onDrag);
    _fade.dispose();
    super.dispose();
  }

  void _onDrag() {
    final x = widget.drag.value;
    if (x.abs() < 2) {
      // karta zmizela nebo se vrátila: nech glow doznít od posledního posunu
      if (_prev.abs() >= 2) {
        _ghost = _prev;
        _fade.forward(from: 0);
      }
    } else {
      _fade.stop(); // nový swipe přerušuje doznívání
    }
    _prev = x;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.drag, _fade]),
        builder: (context, _) {
          var x = widget.drag.value;
          var fade = 1.0;
          if (x.abs() < 2) {
            if (!_fade.isAnimating) return const SizedBox.expand();
            x = _ghost;
            fade = 1 - Curves.easeOut.transform(_fade.value);
          }
          final toRight = x > 0;
          final side = toRight ? widget.right : widget.left;
          final width = MediaQuery.of(context).size.width;
          final t = (x.abs() / (width - 50)).clamp(0.0, 1.0).toDouble() * fade;
          final past = x.abs() > kSwipeThreshold;
          final glow = side.tone.solidA;
          return Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: toRight ? null : -250,
                right: toRight ? -250 : null,
                width: 300,
                child: Center(
                  child: Transform.scale(
                    scaleX: 1.5,
                    scaleY: 3.0, // svislé protažení elipsy
                    child: SizedBox(
                      width: 300,
                      height:
                          300, // musí mít pevnou velikost, jinak se nevykreslí
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            // střed je na hraně obrazovky
                            center: Alignment.center,
                            radius:
                                0.5, // přesně do kraje čtverce, tam je už průhledná
                            colors: [
                              glow.withValues(alpha: 0.6 * t),
                              glow.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 180,
                left: 20,
                right: 20,
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * t,
                      child: _pill(side, past),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(SwipeSide side, bool past) {
    final tone = side.tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: tone.soft(),
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow(0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(side.icon, size: 20, color: tone.accent),
          const SizedBox(width: 6),
          Text(
            side.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: tone.ink,
            ),
          ),
        ],
      ),
    );
  }
}
