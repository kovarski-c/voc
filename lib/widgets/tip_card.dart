import 'package:material_ui/material_ui.dart';

import '../services/tips.dart';
import '../theme.dart';

/// Box s denním tipem na domovské stránce (žárovka + nadpis + text).
class TipCard extends StatelessWidget {
  final Tip tip;
  const TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final tone = kToneAmber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 40,
            child: Icon(Icons.lightbulb_rounded, size: 22, color: tone.solidA),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.text,
                  style: TextStyle(fontSize: 14, height: 1.35, color: kInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
