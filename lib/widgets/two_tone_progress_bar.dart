import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../theme.dart';

/// Dvoubarevný pruh: světlá část = naučeno, sytá část = pevně zvládnuto (sytá je podmnožina světlé).
class TwoToneProgressBar extends StatelessWidget {
  final double light; // 0..1
  final double dark; // 0..1, nejvýš light
  final Color? lightColor; // null = světlejší zelená tématu
  final Color? darkColor; // null = sytá zelená tématu
  final double height;

  const TwoToneProgressBar({
    super.key,
    required this.light,
    required this.dark,
    this.lightColor,
    this.darkColor,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        Widget fill(double v, Color color) {
          final width =
              v <= 0 ? 0.0 : math.min(w, math.max(height, w * v.clamp(0.0, 1.0)));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width,
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: radius),
          );
        }

        return SizedBox(
          height: height,
          width: w,
          child: Stack(
            children: [
              Container(
                decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: radius),
              ),
              fill(light, lightColor ?? kToneGreen.a),
              fill(math.min(dark, light), darkColor ?? kToneGreen.accent),
            ],
          ),
        );
      },
    );
  }
}
