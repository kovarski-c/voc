import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Tlačítko ve stylu karet režimů na home page: měkký přechod ve výplni,
/// světlý vnitřní okraj, text v barvě tónu a vedle něj ikona ve sytém přechodu
/// tónu. Po stisku se lehce zmenší.
class ToneButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Tone tone;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;

  /// Ikona nad textem (pro úzká tlačítka vedle sebe, kde by text přetékal).
  final bool vertical;

  const ToneButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onPressed,
    this.height = 48,
    this.fontSize = 15,
    this.vertical = false,
  });

  @override
  State<ToneButton> createState() => _ToneButtonState();
}

class _ToneButtonState extends State<ToneButton> {
  static Color get _offBg => kOffBg;
  static Color get _offAccent => kFaint;

  bool _pressed = false;

  Widget _icon(bool enabled, double size) {
    final w = widget;
    // Ikona ve stejném sytém přechodu jako dřív kruh.
    return enabled
        ? ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => w.tone.solid.createShader(bounds),
          child: Icon(w.icon, size: size, color: Colors.white),
        )
        : Icon(w.icon, size: size, color: _offAccent);
  }

  Widget _inline(bool enabled) {
    final w = widget;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            w.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: w.fontSize,
              fontWeight: FontWeight.w800,
              color: enabled ? w.tone.ink : kMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _icon(enabled, w.fontSize + 7),
      ],
    );
  }

  /// Ikona nahoře, text pod ní; text se v nouzi zmenší, ale nikdy se neořízne.
  Widget _stacked(bool enabled) {
    final w = widget;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _icon(enabled, w.fontSize + 8),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            w.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: w.fontSize,
              fontWeight: FontWeight.w800,
              color: enabled ? w.tone.ink : kMuted,
            ),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final enabled = w.onPressed != null;
    final radius = BorderRadius.circular(w.height / 3);

    return AnimatedScale(
      scale: enabled && _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        height: w.height,
        decoration: BoxDecoration(
          gradient: enabled ? w.tone.soft() : null,
          color: enabled ? null : _offBg,
          borderRadius: radius,
          border: Border.all(
            color: kSurface.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: w.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: w.vertical ? _stacked(enabled) : _inline(enabled),
            ),
          ),
        ),
      ),
    );
  }
}
