import 'package:flutter/material.dart';

import '../services/study_session.dart';
import '../study_controller.dart';
import '../widgets/card_status.dart';
import '../widgets/flash_card.dart';
import '../widgets/rounded_progress_bar.dart';

/// Mezi fázemi: zpětná vazba a volba, jak pokračovat.
class InterludeView extends StatelessWidget {
  final StudyController c;
  const InterludeView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final s = c.session;
    late final String title;
    late String message;
    String? primaryLabel;
    VoidCallback? primary;

    switch (c.interlude!) {
      case InterludeKind.reviewsDone:
        title = 'Opakování hotovo';
        message = 'Zopakováno slov: ${s.reviewedInBlock}.';
        final more = s.mode == StudyMode.both
            ? s.backlog >= StudySession.reviewBatch
            : s.backlog > 0;
        if (more) {
          primaryLabel = 'Pokračovat v opakování';
          primary = c.continueReviews;
          message = '$message\nZbývá ještě ${s.backlog} splatných slov.';
        } else if (s.mode == StudyMode.both) {
          primaryLabel = 'Učit nová slova';
          primary = c.startLearning;
        }
      case InterludeKind.groupDone:
        title = 'Skupina hotová';
        message = 'Naučeno v této dávce: ${s.learnedInBlock} slov.'
            '${s.skippedInBlock > 0 ? '\nPřeskočeno (už umíš): ${s.skippedInBlock}.' : ''}';
        primaryLabel = 'Další skupina';
        primary = c.startLearning;
      case InterludeKind.blockDone:
        title = 'Dnešní dávka hotová';
        message = s.mode == StudyMode.learnOnly
            ? 'Nových slov: ${s.newInBlock}.\nChceš pokračovat dál?'
            : 'Nových slov: ${s.newInBlock}, zopakováno: ${s.reviewedInBlock}.\nChceš pokračovat dál?';
        primaryLabel = 'Pokračovat';
        primary = c.nextBlock;
      case InterludeKind.allDone:
        title = 'Vše hotovo';
        message = 'Teď není co opakovat ani se učit.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: kReviewColor),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            if (primary != null)
              FilledButton(onPressed: primary, child: Text(primaryLabel!)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: c.finish,
              child: Text(primary == null ? 'Zpět' : 'Skončit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Procvičování: karta, tlačítko "Dál" při představení a pruh postupu fáze.
class PracticeView extends StatelessWidget {
  final StudyController c;
  const PracticeView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final top = c.current;
    final nxt = c.next;
    final s = c.session;
    final reviewing = c.phase == Phase.reviewing;
    final label = reviewing
        ? 'Opakování ${s.phaseDone} / ${s.phaseTotal}'
        : (c.isIntro
            ? 'Nová slova: prohlédni si je'
            : 'Učení ${s.phaseDone} / ${s.phaseTotal}');

    return SafeArea(
      bottom: false,
      child: Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    if (nxt != null)
                      FlashCard(
                        key: ValueKey('bottom-${c.serial}-$nxt'),
                        course: c.course,
                        index: nxt,
                        info: c.infoOf(nxt),
                        showBack: false,
                        nativeFront: c.nativeFrontFor(nxt),
                        interactive: false,
                        onFlip: () {},
                        onAnswered: (_) {},
                      )
                    else
                      const SizedBox(width: 300, height: 308),
                    if (top != null)
                      FlashCard(
                        key: ValueKey('top-${c.serial}'),
                        course: c.course,
                        index: top,
                        info: c.infoOf(top),
                        showBack: c.showBack,
                        nativeFront: c.nativeFrontFor(top),
                        introMode: c.isIntro,
                        interactive: !c.isIntro,
                        onFlip: c.flip,
                        onAnswered: c.answer,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: c.isIntro
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                                onPressed: c.skipIntro,
                                child: const Text('Už umím')),
                            const SizedBox(width: 16),
                            FilledButton(
                                onPressed: c.ackIntro,
                                child: const Text('Dál')),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF767676))),
              const SizedBox(height: 8),
              RoundedProgressBar(
                value: c.phaseProgress,
                color: reviewing ? kReviewColor : kLearningColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
