import 'package:flutter/material.dart';

/// Velké zaoblené tlačítko: vyplněné (s jemným přechodem) nebo jen s obrysem.
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final Color color;
  final double height;
  final double fontSize;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.color = const Color(0xFF2F6FED),
    this.height = 56,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    final fg = filled ? Colors.white : color;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.w800, color: fg)),
        ),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: fontSize + 5, color: fg),
        ],
      ],
    );

    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: filled
              ? LinearGradient(
                  colors: [
                    Color.lerp(color, Colors.white, 0.22)!,
                    color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : Colors.white,
          border: filled ? null : Border.all(color: color, width: 2),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
