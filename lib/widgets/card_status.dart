import 'package:flutter/material.dart';

import '../models/card_progress.dart';
import '../theme.dart';
import 'rounded_progress_bar.dart';

const Color kReviewColor = Color(0xFF4CAF50);
const Color kLearningColor = Color(0xFFFFB300);

/// Štítek stavu karty + indikátor pod ním:
/// nová (modrá), učení (žlutá, bublinky), opakování (zelená, pruh jistoty);
/// barvy tónů jsou společné s kartami režimů (Tone v theme.dart).
class CardStatus extends StatelessWidget {
  final CardInfo info;

  /// true = pod štítkem je vždy vyhrazené místo pro indikátor (bublinky / pruh),
  /// takže štítek stojí na stejném místě u všech stavů (karty).
  /// false = u nového slova (nemá indikátor) je jen štítek, takže se dá
  /// vycentrovat (řádek seznamu, detail).
  final bool reserveIndicator;
  const CardStatus({
    super.key,
    required this.info,
    this.reserveIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Tone tone;
    switch (info.kind) {
      case CardKind.newCard:
        label = 'nová';
        tone = kToneBlue;
      case CardKind.learning:
        label = 'učení';
        tone = kToneAmber;
      case CardKind.review:
        label = 'opakování';
        tone = kToneGreen;
    }

    final hasIndicator = reserveIndicator || info.kind != CardKind.newCard;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: tone.a,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tone.ink,
            ),
          ),
        ),
        if (hasIndicator) ...[
          const SizedBox(height: 6),
          SizedBox(height: 10, child: Center(child: _indicator())),
        ],
      ],
    );
  }

  Widget _indicator() {
    switch (info.kind) {
      case CardKind.newCard:
        return const SizedBox.shrink();
      case CardKind.learning:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(info.target, (i) {
            final filled = i < info.streak;
            return Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? kToneAmber.solidA : Colors.transparent,
                border: Border.all(
                  color: filled ? kToneAmber.solidA : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
            );
          }),
        );
      case CardKind.review:
        return SizedBox(
          width: 56,
          child: RoundedProgressBar(
            value: info.confidence,
            color: kToneGreen.solidA,
            height: 6,
          ),
        );
    }
  }
}
