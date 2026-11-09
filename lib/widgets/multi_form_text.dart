import 'package:flutter/material.dart';

/// Text na kartě s možností více tvarů ("le / la / l' / les").
/// - Tvary oddělené " / " se zalamují jako celek (zalomení jen mezi tvary).
/// - Písmo se zmenšuje podle délky, aby se dlouhé hodnoty vešly.
class MultiFormText extends StatelessWidget {
  final String text;
  final TextStyle style; // fontSize = základní velikost
  final TextAlign textAlign;

  const MultiFormText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  static double scaleFor(int length) {
    if (length <= 22) return 1.0;
    if (length <= 36) return 0.85;
    if (length <= 60) return 0.72;
    return 0.62;
  }

  @override
  Widget build(BuildContext context) {
    final base = style.fontSize ?? 24;
    final s = style.copyWith(fontSize: base * scaleFor(text.length));
    final parts = text.split(' / ');
    if (parts.length < 2) {
      return Text(text, style: s, textAlign: textAlign);
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: s.fontSize! * 0.3,
      runSpacing: 2,
      children: [
        for (var i = 0; i < parts.length; i++)
          Text(i < parts.length - 1 ? '${parts[i]} /' : parts[i],
              style: s, textAlign: textAlign),
      ],
    );
  }
}
