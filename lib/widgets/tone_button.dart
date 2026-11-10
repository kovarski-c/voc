import 'package:flutter/material.dart';

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

  const ToneButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onPressed,
    this.height = 48,
    this.fontSize = 15,
  });

  @override
  State<ToneButton> createState() => _ToneButtonState();
}

class _ToneButtonState extends State<ToneButton> {
  static const Color _offBg = Color(0xFFEDEFF4);
  static const Color _offAccent = Color(0xFFB9BEC9);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final enabled = w.onPressed != null;
    final radius = BorderRadius.circular(w.height / 2);

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
            onTap: w.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
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
                  // Ikona vedle textu ve stejném sytém přechodu jako dřív kruh.
                  enabled
                      ? ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback:
                            (bounds) => w.tone.solid.createShader(bounds),
                        child: Icon(
                          w.icon,
                          size: w.fontSize + 7,
                          color: Colors.white,
                        ),
                      )
                      : Icon(w.icon, size: w.fontSize + 7, color: _offAccent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
