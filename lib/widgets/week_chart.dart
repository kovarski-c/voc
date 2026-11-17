import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/day_stat.dart';
import '../theme.dart';

const _dayShort = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

String _newWords(int n) =>
    n == 1 ? 'nové slovo' : (n >= 2 && n <= 4 ? 'nová slova' : 'nových slov');

/// Karta "Posledních 7 dní": skládané sloupce v modré (tmavší dole = nově
/// naučená slova, světlejší nahoře = zopakovaná), osa y s tenkými čárami,
/// přerušovaná čára = denní cíl. Nad grafem je jen počet nových slov za týden
/// a srovnání s minulým týdnem. Klepnutím na sloupec se nad ním ukáže bublina.
class WeekChart extends StatefulWidget {
  final List<DayStat> week; // 7 dní, poslední = dnes
  final List<DayStat> previousWeek; // předchozích 7 dní (srovnání)
  final int goal; // denní cíl (zopakované + naučené)

  const WeekChart({
    super.key,
    required this.week,
    required this.previousWeek,
    required this.goal,
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
  static const double _bubbleH = 46;

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
          Text(
            'Posledních 7 dní',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
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

  Widget _chart(List<DayStat> week) {
    var maxVal = widget.goal;
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
            return SizedBox(
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
                          color: kMuted.withValues(alpha: 0.55),
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
                        final reached = d.total >= widget.goal && d.total > 0;
                        final cx = _gutter + (sel + 0.5) * colW;
                        final barTop =
                            _chartHeight - d.total / scale * _plotHeight * grow;
                        final left =
                            math
                                .max(
                                  0.0,
                                  math.min(cx - _bubbleW / 2, width - _bubbleW),
                                )
                                .toDouble();
                        return Positioned(
                          left: left,
                          top: barTop - _bubbleH - 8 - (reached ? 16 : 0),
                          child: IgnorePointer(child: _bubble(d)),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bubble(DayStat d) {
    const style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.3,
    );
    return Container(
      width: _bubbleW,
      height: _bubbleH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(12),
        boxShadow: softShadow(0.18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${d.learned} naučených', style: style),
          Text('${d.reviewed} zopakovaných', style: style),
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
    final emphasized = isToday || selected;
    final alpha = emphasized ? 1.0 : 0.6;
    final reached = d.total >= widget.goal && d.total > 0;
    final dark = kToneBlue.solidA;
    final light = Color.lerp(kToneBlue.solidA, Colors.white, 0.55)!;

    double h(int v) {
      if (v <= 0) return 0;
      final raw = v / scale * _plotHeight * grow;
      return math.max(4.0, math.min(raw, _plotHeight));
    }

    final hLearn = h(d.learned);
    final hRev = h(d.reviewed);

    final Widget bar;
    if (d.total == 0) {
      bar = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kTrack),
      );
    } else {
      final bool hasRev = hRev > 0;
      final bool hasLearn = hLearn > 0;
      const double radiusVal = 8.0;

      // Pomocná funkce pro vytvoření jednoho samostatného zaobleného sloupce
      Widget buildBarPart({required double height, required Color color}) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(radiusVal),
          ),
          child: Container(
            width: _barWidth,
            height: math.max(height, radiusVal * 2),
            color: color,
          ),
        );
      }

      // Stack zajistí, že sloupce jsou přes sebe po ose Z
      bar = SizedBox(
        width: _barWidth,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Větší/spodní sloupec (např. naučená slova)
            if (hasLearn)
              buildBarPart(
                height: hLearn,
                color: dark.withValues(alpha: alpha),
              ),

            // 2. Menší sloupec (např. zopakovaná slova) - je v kódu níže, takže se vykreslí PŘED ním
            if (hasRev)
              buildBarPart(height: hRev, color: light.withValues(alpha: alpha)),
          ],
        ),
      );
    }

    final label = _dayShort[d.date.weekday - 1];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = selected ? null : i),
      child: Column(
        children: [
          SizedBox(
            height: _chartHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reached)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: kToneBlue.accent,
                      ),
                    ),
                  bar,
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              color: emphasized ? kInk : kMuted,
            ),
          ),
        ],
      ),
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
        final tp = TextPainter(
          text: TextSpan(
            text: '$v',
            style: TextStyle(fontSize: 10, color: textColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
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
