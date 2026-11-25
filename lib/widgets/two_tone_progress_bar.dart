import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../theme.dart';

/// Dvoubarevný pruh: světlá část = naučeno, sytá část = pevně zvládnuto (sytá je podmnožina světlé).
class TwoToneProgressBar extends StatelessWidget {
  final double light; // 0..1
  final double dark; // 0..1, nejvýš light
  final Color? lightColor; // null = světlejší zelená tématu
  final Color? darkColor; // null = sytá zelená tématu
  // Volitelný konec přechodu zleva doprava: když je zadaný, výplň se
  // vybarví z [lightColor] do [lightColorEnd] (resp. [darkColor] do [darkColorEnd]).
  final Color? lightColorEnd;
  final Color? darkColorEnd;
  final double height;

  const TwoToneProgressBar({
    super.key,
    required this.light,
    required this.dark,
    this.lightColor,
    this.darkColor,
    this.lightColorEnd,
    this.darkColorEnd,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        Widget fill(double v, Color color, Color? end) {
          final width =
              v <= 0
                  ? 0.0
                  : math.min(w, math.max(height, w * v.clamp(0.0, 1.0)));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: end == null ? color : null,
              gradient:
                  end == null ? null : LinearGradient(colors: [color, end]),
              borderRadius: radius,
            ),
          );
        }

        return SizedBox(
          height: height,
          width: w,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kBarTrack,
                  borderRadius: radius,
                ),
              ),
              fill(light, lightColor ?? kToneGreen.a, lightColorEnd),
              fill(
                math.min(dark, light),
                darkColor ?? kToneGreen.accent,
                darkColorEnd,
              ),
            ],
          ),
        );
      },
    );
  }
}
