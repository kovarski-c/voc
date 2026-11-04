import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pruh průběhu, jehož výplň má vždy zaoblené konce (i při velmi malé hodnotě).
/// Výplň je nejméně tak široká jako vysoká, takže na začátku vypadá jako kolečko.
class RoundedProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const RoundedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final v = value.clamp(0.0, 1.0);
        final fillW = v <= 0 ? 0.0 : math.min(maxW, math.max(height, maxW * v));
        return SizedBox(
          height: height,
          width: maxW,
          child: Stack(
            children: [
              Container(
                decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: radius),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: fillW,
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ],
          ),
        );
      },
    );
  }
}
