import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level.dart';

/// Štít úrovně. Dosažený = vyplněný přechodem barvy úrovně,
/// nedosažený = šedý s obrysem v barvě úrovně.
class LevelShield extends StatelessWidget {
  final LevelStep level;
  final bool earned;
  final double width;

  const LevelShield({
    super.key,
    required this.level,
    required this.earned,
    this.width = 24,
  });

  double get height => width * 1.18;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ShieldPainter(level, earned),
        child: Padding(
          padding: EdgeInsets.only(bottom: height * 0.10),
          child: Center(
            child: Text(
              level.code,
              style: TextStyle(
                fontSize: width * 0.40,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color:
                    earned
                        ? level.onColor
                        : const Color.fromARGB(255, 162, 164, 169),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final LevelStep level;
  final bool earned;
  const _ShieldPainter(this.level, this.earned);

  static Path _path(double w, double h) {
    final r = w * 0.16;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h * 0.52)
      ..quadraticBezierTo(w, h * 0.80, w / 2, h)
      ..quadraticBezierTo(0, h * 0.80, 0, h * 0.52)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _path(size.width, size.height);
    if (earned) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [level.light, level.dark],
          ).createShader(rect),
      );
    } else {
      canvas.drawPath(path, Paint()..color = Colors.grey.shade200);
      final stroke = math.max(1.4, size.width * 0.07);
      canvas.save();
      // obrys vykreslený dovnitř štítu
      canvas.clipPath(path);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 2
          ..color = Colors.transparent,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.level != level || old.earned != earned;
}

/// Osa úrovní nad pruhem pokroku: štíty na místech, kde úroveň leží
/// (úměrně počtu slov), a světlé dělicí čárky přes pruh.
class LevelScale extends StatelessWidget {
  final List<LevelStep> levels;
  final int learned;
  final int total;
  final Widget bar;
  final double shieldWidth;

  const LevelScale({
    super.key,
    required this.levels,
    required this.learned,
    required this.total,
    required this.bar,
    this.shieldWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty || total <= 0) return bar;
    final shieldHeight = shieldWidth * 1.18;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final half = shieldWidth / 2;
        const gap = 2.0;
        final ticks = [for (final l in levels) w * l.threshold / total];

        // štíty se nesmějí překrývat ani vyčnívat z karty
        final xs = [for (final t in ticks) t.clamp(half, w - half).toDouble()];
        for (var i = 1; i < xs.length; i++) {
          xs[i] = math.max(xs[i], xs[i - 1] + shieldWidth + gap);
        }
        for (var i = xs.length - 2; i >= 0; i--) {
          xs[i] = math.min(xs[i], xs[i + 1] - shieldWidth - gap);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: shieldHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < levels.length; i++)
                    Positioned(
                      left: xs[i] - half,
                      top: 0,
                      child: LevelShield(
                        level: levels[i],
                        earned: learned >= levels[i].threshold,
                        width: shieldWidth,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Stack(
              children: [
                bar,
                for (final t in ticks)
                  if (t < w - 1)
                    Positioned(
                      left: t - 1,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: const ColoredBox(color: Color(0xCCFFFFFF)),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}
