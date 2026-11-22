import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/day_stat.dart';
import '../theme.dart';

const _dayShort = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

String _newWords(int n) =>
    n == 1 ? 'nové slovo' : (n >= 2 && n <= 4 ? 'nová slova' : 'nových slov');

/// Karta "Posledních 7 dní": dva překrývající se sloupce v modré. Světlý
/// vzadu = naučená + zopakovaná (součet), tmavý vpředu = jen naučená. Tmavý
/// sloupec je plný, když den dosáhl cíle nových slov, jinak jen obrys.
/// Přerušovaná šedá čára = denní cíl, tmavá = cíl nových slov; fajfka nad
/// sloupcem = splněny oba cíle (denní i nových slov). Vybraný den má obrys a tučný popisek.
class WeekChart extends StatefulWidget {
  final List<DayStat> week; // 7 dní, poslední = dnes
  final List<DayStat> previousWeek; // předchozích 7 dní (srovnání)
  final int goal; // denní cíl (zopakované + naučené)
  final int newGoal; // cíl nových slov za den

  const WeekChart({
    super.key,
    required this.week,
    required this.previousWeek,
    required this.goal,
    required this.newGoal,
  });

  @override
  State<WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<WeekChart> {
  int? _selected;

  static const double _chartHeight = 140;
  // Místo nad nejvyšším sloupcem pro fajfku; sloupce se do něj nikdy nedostanou.
  static const double _topReserve = 18;
  static const double _plotHeight = _chartHeight - _topReserve;
  static const double _gutter = 28; // šířka osy y vlevo
  static const double _barWidth = 24;
  static const double _bubbleW = 118;
  static const double _bubbleH = 58;

  final light = Color.lerp(kToneBlue.solidA, Colors.white, 0.55);

  /// Krok osy y: 5 slov, u vyšších hodnot větší, ať čar není moc.
  static int _stepFor(int maxVal) {
    for (final s in const [5, 10, 20, 25, 50, 100, 200, 500, 1000]) {
      if (maxVal / s <= 6) return s;
    }
    return 1000;
  }

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final newThis = week.fold<int>(0, (a, d) => a + d.learned);
    final newPrev = widget.previousWeek.fold<int>(0, (a, d) => a + d.learned);
    final anyActivity = week.any((d) => d.total > 0);

    final diff = newThis - newPrev;
    String? compare;
    Color compareColor = kMuted;
    if (!anyActivity) {
      compare = 'Dnešní sloupec čeká na první slovo.';
    } else if (newPrev > 0) {
      if (diff > 0) {
        compare = 'o $diff víc než minulý týden';
        compareColor = kToneBlue.accent;
      } else if (diff < 0) {
        compare = 'o ${-diff} méně než minulý týden';
      } else {
        compare = 'stejně jako minulý týden';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Posledních 7 dní',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
              const Spacer(),
              // ? = vysvětlení grafu; větší plocha pro klepnutí než ikona
              InkResponse(
                onTap: _showLegend,
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: kMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$newThis ${_newWords(newThis)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          if (compare != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                compare,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: compareColor,
                ),
              ),
            ),
          const SizedBox(height: 18),
          _chart(week),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ legenda
  Widget _legendBar(Color fill) {
    return Container(
      width: 20,
      height: 24,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }

  Widget _legendDash(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(width: 5, height: 2, color: color),
          if (i < 2) const SizedBox(width: 3),
        ],
      ],
    );
  }

  Widget _legendRow(Widget swatch, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            height: 24,
            child: Align(alignment: Alignment.centerLeft, child: swatch),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: kInk),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: TextStyle(fontSize: 14, color: kMuted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegend() {
    final dark = Color.lerp(kToneBlue.solidA, Colors.white, 0.35)!;
    final lightC = Color.lerp(kToneBlue.solidA, Colors.white, 0.55 * 1.3)!;
    final lightLine = Color.lerp(kToneBlue.solidA, Colors.white, 0.55)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kFaint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Jak číst graf',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klepnutím na sloupec uvidíš čísla za daný den.',
                  style: TextStyle(fontSize: 13, color: kMuted),
                ),
                const SizedBox(height: 18),
                _legendRow(
                  _legendBar(lightC),
                  'Světlý sloupec:',
                  'všechna slova dne, nová i zopakovaná. Plný je, když splníš '
                      'denní cíl (${widget.goal}), do té doby je jen obrys.',
                ),
                _legendRow(
                  _legendBar(dark),
                  'Tmavý sloupec:',
                  'jen nová naučená slova. Plný je, když splníš cíl nových '
                      'slov (${widget.newGoal}), do té doby je jen obrys.',
                ),
                _legendRow(
                  _legendDash(lightLine),
                  'Světlá čára:',
                  'denní cíl (${widget.goal} slov).',
                ),
                _legendRow(
                  _legendDash(kToneBlue.solidA.withValues(alpha: 0.55)),
                  'Tmavá čára:',
                  'cíl nových slov (${widget.newGoal}).',
                ),
                _legendRow(
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: kToneBlue.accent,
                  ),
                  'Fajfka:',
                  'tento den jsou splněné oba cíle.',
                ),
              ],
            ),
          ),
    );
  }

  Widget _chart(List<DayStat> week) {
    var maxVal = math.max(widget.goal, widget.newGoal);
    for (final d in week) {
      if (d.total > maxVal) maxVal = d.total;
    }
    if (maxVal < 1) maxVal = 1;
    final step = _stepFor(maxVal);
    final top = ((maxVal + step - 1) ~/ step) * step; // horní okraj osy
    final scale = top.toDouble();

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final colW = (width - _gutter) / week.length;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, grow, _) {
            final sel = _selected;
            return TapRegion(
              onTapOutside: (_) {
                if (_selected != null) setState(() => _selected = null);
              },
              child: SizedBox(
                height: _chartHeight + 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // klepnutí mimo sloupce schová bublinu
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => setState(() => _selected = null),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: _chartHeight,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GridPainter(
                            step: step,
                            top: top,
                            plotHeight: _plotHeight,
                            gutter: _gutter,
                            lineColor: kTrack,
                            textColor: kMuted,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _gutter,
                      right: 0,
                      top: 0,
                      height: _chartHeight,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GoalLine(
                            height: widget.goal / scale * _plotHeight,
                            color:
                                Color.lerp(
                                  kToneBlue.solidA,
                                  Colors.white,
                                  0.55,
                                )!,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _gutter,
                      right: 0,
                      top: 0,
                      height: _chartHeight,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GoalLine(
                            height: widget.newGoal / scale * _plotHeight,
                            color: kToneBlue.solidA.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _gutter,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Row(
                        children: [
                          for (var i = 0; i < week.length; i++)
                            Expanded(
                              child: _column(
                                week[i],
                                i,
                                isToday: i == week.length - 1,
                                scale: scale,
                                grow: grow,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (sel != null)
                      Builder(
                        builder: (context) {
                          final d = week[sel];
                          final both =
                              d.total >= widget.goal &&
                              d.total > 0 &&
                              d.learned > 0 &&
                              d.learned >= widget.newGoal;
                          final cx = _gutter + (sel + 0.5) * colW;
                          final barTop =
                              _chartHeight -
                              d.total / scale * _plotHeight * grow;
                          final left =
                              math
                                  .max(
                                    0.0,
                                    math.min(
                                      cx - _bubbleW / 2,
                                      width - _bubbleW,
                                    ),
                                  )
                                  .toDouble();
                          return Positioned(
                            left: left,
                            top: barTop - _bubbleH - 8 - (both ? 16 : 0),
                            child: IgnorePointer(child: _bubble(d)),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bubble(DayStat d) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: kInk,
      height: 1.3,
    );
    return Container(
      width: _bubbleW + 8,
      height: _bubbleH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: softShadow(0.18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${d.learned} naučených', style: style),
          Text('${d.reviewed} zopakovaných', style: style),
          Text('${d.reviewed + d.learned} celkem', style: style),
        ],
      ),
    );
  }

  Widget _column(
    DayStat d,
    int i, {
    required bool isToday,
    required double scale,
    required double grow,
  }) {
    final selected = _selected == i;
    final reached = d.total >= widget.goal && d.total > 0;
    final newReached = d.learned > 0 && d.learned >= widget.newGoal;
    final both = reached && newReached; // fajfka jen při splnění obou cílů
    final dark = Color.lerp(kToneBlue.solidA, Colors.white, 0.35)!;
    final light = Color.lerp(kToneBlue.solidA, Colors.white, 0.55 * 1.3)!;
    const double radiusVal = 8.0;

    double h(int v) {
      if (v <= 0) return 0;
      final raw = v / scale * _plotHeight * grow;
      return math.max(4.0, math.min(raw, _plotHeight));
    }

    // Světlý sloupec = součet, tmavý = jen naučená (podmnožina součtu).
    // Minimální výška sloupce je kvůli zaoblení 16 px. Když je součet na
    // minimu (velké měřítko osy), naučená se vykreslí jako podíl součtu, aby
    // světlý sloupec nezakryl tmavý (a naopak) a poměr zůstal správný.
    const double minBar = radiusVal * 2;
    final hTotalRaw = h(d.total);
    final hTotal = d.total > 0 ? math.max(hTotalRaw, minBar) : 0.0;
    final hLearn =
        d.learned <= 0
            ? 0.0
            : (hTotalRaw >= minBar
                ? math.min(h(d.learned), hTotal)
                : hTotal * d.learned / d.total);

    Widget part({required double height, required Color fill, Color? border}) {
      final hh = height;
      final radius = const BorderRadius.vertical(
        top: Radius.circular(radiusVal),
      );
      if (border == null) {
        return Container(
          width: _barWidth,
          height: hh,
          decoration: BoxDecoration(color: fill, borderRadius: radius),
        );
      }
      // Obrys bez spodní čáry: jednotný okraj se protáhne pod základnu a ořízne.
      return SizedBox(
        width: _barWidth,
        height: hh,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: hh + 4,
            maxHeight: hh + 4,
            child: Container(
              width: _barWidth,
              height: hh + 4,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: radius,
                border: Border.all(color: border, width: 2),
              ),
            ),
          ),
        ),
      );
    }

    final Widget bar;
    if (d.total == 0) {
      bar = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kTrack),
      );
    } else {
      final barH = math.max(hTotal, radiusVal * 2);
      bar = SizedBox(
        width: _barWidth,
        height: barH,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. vzadu: součet naučených a zopakovaných (světlý)
            part(
              height: hTotal,
              fill:
                  reached
                      ? Color.lerp(light, dark, selected ? 0.5 : 0)!
                      : Colors.white,
              border:
                  reached
                      ? null
                      : Color.lerp(light, dark, selected ? 0.5 : 0.0)!,
            ),
            // 2. vpředu: jen naučená; plná při splněném cíli, jinak obrys
            if (hLearn > 0)
              part(
                height: hLearn,
                fill:
                    newReached
                        ? Color.lerp(
                          dark,
                          kToneBlue.solidA,
                          selected ? 0.6 : 0,
                        )!
                        : Colors.white,
                border:
                    newReached
                        ? null
                        : Color.lerp(
                          kToneBlue.solidA,
                          Colors.white,
                          selected ? 0.1 : 0.4,
                        )!,
              ),

            // označení vybraného dne: obrys kolem celého sloupce
          ],
        ),
      );
    }

    final label = _dayShort[d.date.weekday - 1];
    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (both)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: kToneBlue.accent,
                    ),
                  ),
                // klepnutí jen na sloupec (s malou rezervou), ne na celý sloupec grafu
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = selected ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: bar,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected
                    ? FontWeight.w900
                    : (isToday ? FontWeight.w700 : FontWeight.w500),
            color: selected || isToday ? kInk : kMuted,
          ),
        ),
      ],
    );
  }
}

/// Osa y: tenké vodorovné čáry po [step] slovech a popisky vlevo.
class _GridPainter extends CustomPainter {
  final int step;
  final int top;
  final double plotHeight;
  final double gutter;
  final Color lineColor;
  final Color textColor;

  const _GridPainter({
    required this.step,
    required this.top,
    required this.plotHeight,
    required this.gutter,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
          ..color = lineColor
          ..strokeWidth = 0.8;
    for (var v = 0; v <= top; v += step) {
      final y = size.height - v / top * plotHeight;
      canvas.drawLine(Offset(gutter, y), Offset(size.width, y), line);
      if (v > 0) {
        final tp =
            TextPainter(
                text: TextSpan(
                  text: '$v',
                  style: TextStyle(fontSize: 10, color: textColor),
                ),
              )
              ..textDirection = TextDirection.ltr
              ..layout();
        tp.paint(canvas, Offset(gutter - 6 - tp.width, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.step != step ||
      old.top != top ||
      old.lineColor != lineColor ||
      old.textColor != textColor;
}

/// Přerušovaná vodorovná čára ve výšce [height] pixelů od spodku.
class _GoalLine extends CustomPainter {
  final double height;
  final Color color;
  const _GoalLine({required this.height, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - height;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalLine old) =>
      old.height != height || old.color != color;
}
