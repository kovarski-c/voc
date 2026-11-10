import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/study_session.dart';
import '../study_controller.dart';
import '../theme.dart';
import '../widgets/card_status.dart';
import '../widgets/flash_card.dart';
import '../widgets/intro_card.dart';
import '../widgets/ipa_help_sheet.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_progress_bar.dart';
import '../widgets/tone_button.dart';

/// Obrazovka mezi fázemi (po opakování, po pětici, po dávce): shrnutí a volba, jak dál.
class InterludeView extends StatelessWidget {
  final StudyController c;
  const InterludeView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final s = c.session;
    late final IconData icon;
    late final List<Color> colors;
    late final String title;
    late String subtitle;
    final tiles = <_Tile>[];
    String? primaryLabel;
    VoidCallback? primary;

    switch (c.interlude!) {
      case InterludeKind.reviewsDone:
        icon = Icons.check_rounded;
        colors = const [Color(0xFF63D68F), Color(0xFF2EAE6B)];
        title = 'Opakování hotovo';
        tiles.add(_Tile(s.reviewedInBlock, 'zopakováno', kReviewColor));
        final more =
            s.mode == StudyMode.both
                ? s.backlog >= StudySession.reviewBatch
                : s.backlog > 0;
        if (more) {
          subtitle = 'Zbývá ještě ${s.backlog} splatných slov.';
          tiles.add(_Tile(s.backlog, 'zbývá', const Color(0xFFE69A00)));
          primaryLabel = 'Pokračovat v opakování';
          primary = c.continueReviews;
        } else if (s.mode == StudyMode.both) {
          subtitle = 'Můžeš přejít na nová slova.';
          primaryLabel = 'Učit nová slova';
          primary = c.startLearning;
        } else {
          subtitle = 'Na dnes máš opakování hotové.';
        }
      case InterludeKind.groupDone:
        icon = Icons.auto_awesome_rounded;
        colors = const [Color(0xFFFFD866), Color(0xFFFFB300)];
        title = 'Skupina hotová';
        subtitle = 'Další skupina nových slov čeká.';
        tiles.add(_Tile(s.learnedInBlock, 'naučeno', const Color(0xFFE69A00)));
        if (s.skippedInBlock > 0) {
          tiles.add(_Tile(s.skippedInBlock, 'přeskočeno', kBlue));
        }
        primaryLabel = 'Další skupina';
        primary = c.startLearning;
      case InterludeKind.blockDone:
        icon = Icons.emoji_events_rounded;
        colors = const [Color(0xFF5B9BFF), Color(0xFF2F6FED)];
        title = 'Dnešní dávka hotová';
        subtitle = 'Chceš pokračovat dalším blokem?';
        tiles.add(_Tile(s.newInBlock, 'nových', kBlue));
        if (s.mode != StudyMode.learnOnly) {
          tiles.add(_Tile(s.reviewedInBlock, 'zopakováno', kReviewColor));
        }
        if (s.skippedInBlock > 0) {
          tiles.add(
            _Tile(s.skippedInBlock, 'přeskočeno', const Color(0xFFE69A00)),
          );
        }
        primaryLabel = 'Pokračovat';
        primary = c.nextBlock;
      case InterludeKind.allDone:
        icon = Icons.celebration_rounded;
        colors = const [Color(0xFF63D68F), Color(0xFF2EAE6B)];
        title = 'Vše hotovo';
        subtitle = 'Teď není co opakovat ani se učit.';
    }

    final accuracy =
        s.answeredInBlock >= 5
            ? (s.correctInBlock * 100 / s.answeredInBlock).round()
            : null;
    final hardest = s.hardestInBlock;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder:
                    (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 62, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: kMuted),
            ),
            if (tiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
            ],
            if (accuracy != null || hardest != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: softShadow(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (accuracy != null)
                      Text(
                        'Přesnost: $accuracy % (${s.correctInBlock} z ${s.answeredInBlock})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (accuracy != null && hardest != null)
                      const SizedBox(height: 6),
                    if (hardest != null)
                      Text(
                        'Nejvíc se pletlo: ${c.course.front(hardest)} – ${c.course.back(hardest)}',
                        style: const TextStyle(fontSize: 14, color: kMuted),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (primary != null)
              PillButton(
                label: primaryLabel!,
                icon: Icons.arrow_forward_rounded,
                color: colors.last,
                onPressed: primary,
              ),
            const SizedBox(height: 8),
            if (c.canUndo)
              TextButton.icon(
                onPressed: c.undo,
                icon: const Icon(Icons.undo_rounded, size: 18, color: kMuted),
                label: const Text(
                  'Vrátit poslední kartu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ),
            TextButton(
              onPressed: c.finish,
              child: Text(
                primary == null ? 'Zpět' : 'Skončit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Tile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow(0.06),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
        ],
      ),
    );
  }
}

/// Rozměry tlačítek při představení nových slov (celý blok = výška + spodní odsazení).
const double kIntroButtonHeight = 48;
const double kIntroButtonsBottom = 24;

/// Procvičování: pruh postupu nahoře, karta uprostřed, tlačítka dole.
/// Spodní blok má stejnou výšku v učení i v opakování, takže karta sedí pořád na stejném místě.
class PracticeView extends StatelessWidget {
  final StudyController c;
  const PracticeView({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final top = c.current;
    final nxt = c.next;
    final s = c.session;
    final reviewing = c.phase == Phase.reviewing;
    final label =
        reviewing
            ? 'Opakování ${s.phaseDone} / ${s.phaseTotal}'
            : (c.isIntro
                ? 'Nová slova · doleva „už umím“, doprava „dál“'
                : 'Učení ${s.phaseDone} / ${s.phaseTotal}');

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Vlevo nápověda k fonetické abecedě, vpravo Zpět.
                    SizedBox(
                      width: 40,
                      height: 32,
                      child:
                          hasIpaHelp(c.course)
                              ? IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 22,
                                color: kMuted,
                                tooltip: 'Fonetická abeceda',
                                onPressed: () => showIpaHelp(context, c.course),
                                icon: const Icon(Icons.help_outline_rounded),
                              )
                              : null,
                    ),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                        color: kInk,
                        disabledColor: const Color(0xFFC9CED8),
                        tooltip: 'Vrátit poslední kartu',
                        onPressed: c.canUndo ? c.undo : null,
                        icon: const Icon(Icons.undo_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RoundedProgressBar(
                  value: c.phaseProgress,
                  color: reviewing ? kToneGreen.solidA : kLearningColor,
                ),
              ],
            ),
          ),
          // Karta je vždy uprostřed této oblasti; tlačítka (jen při představení
          // nových slov) jsou přes ni položená dole a pozici karty neovlivňují.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // Karta se smí protáhnout jen tak, aby se vešla (a nepřekrývala
                // tlačítka při představení nových slov).
                final maxCard = math.max(
                  kCardSize,
                  box.maxHeight -
                      (c.isIntro
                          ? kIntroButtonHeight + kIntroButtonsBottom + 24
                          : 24),
                );
                return Stack(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (nxt != null)
                            FlashCard(
                              key: ValueKey('bottom-${c.serial}-$nxt'),
                              course: c.course,
                              index: nxt,
                              number: c.numberOf(nxt),
                              info: c.infoOf(nxt),
                              showBack: false,
                              nativeFront: c.nativeFrontFor(nxt),
                              interactive: false,
                              maxHeight: maxCard,
                              onFlip: () {},
                              onAnswered: (_) {},
                            )
                          else
                            const SizedBox(width: 300, height: 308),
                          if (top != null && c.isIntro)
                            IntroCard(
                              key: ValueKey('top-${c.serial}'),
                              course: c.course,
                              index: top,
                              number: c.numberOf(top),
                              info: c.infoOf(top),
                              maxHeight: maxCard,
                              haptics: c.settings.haptics,
                              // doprava = dál, doleva = už umím (jako tlačítka)
                              onSwiped:
                                  (next) => next ? c.ackIntro() : c.skipIntro(),
                            )
                          else if (top != null)
                            FlashCard(
                              key: ValueKey('top-${c.serial}'),
                              course: c.course,
                              index: top,
                              number: c.numberOf(top),
                              info: c.infoOf(top),
                              showBack: c.showBack,
                              nativeFront: c.nativeFrontFor(top),
                              maxHeight: maxCard,
                              haptics: c.settings.haptics,
                              onFlip: c.flip,
                              onAnswered: c.answer,
                            ),
                        ],
                      ),
                    ),
                    if (c.isIntro)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: kIntroButtonsBottom,
                        height: kIntroButtonHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: ToneButton(
                                label: 'Už umím',
                                icon: Icons.check_rounded,
                                tone: kToneGreen,
                                height: kIntroButtonHeight,
                                fontSize: 15,
                                onPressed: c.skipIntro,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ToneButton(
                                label: 'Dál',
                                icon: Icons.arrow_forward_rounded,
                                tone: kToneBlue,
                                height: kIntroButtonHeight,
                                fontSize: 15,
                                onPressed: c.ackIntro,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
