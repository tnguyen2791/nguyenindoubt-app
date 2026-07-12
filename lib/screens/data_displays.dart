/// Reusable Oura-style data-display widgets — the Phase 11 kit.
///
/// Everything here is CustomPaint / plain widgets (no chart package) and
/// every color resolves through [NidColors] / [NidStateColors] — never a hex
/// literal in widget code. Motion stays gentle: the score arc eases in over
/// 600ms; nothing pops.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sleep_insights.dart';
import '../services/trends.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';

/// Maps a readiness subscore [fraction] (0.0-1.0) to a [StateTone] using the
/// same bands the readiness scoring uses (>=.85 optimal, >=.70 good, >=.50
/// fair, else attention). Keeps the contributor bar's color aligned to the
/// model's own value, so the evidence always matches the label.
StateTone nidReadinessTone(double fraction) {
  if (fraction >= 0.85) {
    return StateTone.optimal;
  }
  if (fraction >= 0.70) {
    return StateTone.good;
  }
  if (fraction >= 0.50) {
    return StateTone.fair;
  }
  return StateTone.attention;
}

/// Maps a [StateTone] to its blessed theme color.
Color nidToneColor(StateTone tone) {
  switch (tone) {
    case StateTone.optimal:
      return NidStateColors.optimal;
    case StateTone.good:
      return NidStateColors.good;
    case StateTone.fair:
      return NidStateColors.fair;
    case StateTone.attention:
      return NidStateColors.attention;
  }
}

/// The hero score readout: a mint ring track with a state-colored arc that
/// eases in, wrapping the score number and its state word.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.word,
    required this.color,
    this.size = 120,
    this.strokeWidth = 12,
  });

  final int score;
  final String word;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score.toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedScore, child) {
          return CustomPaint(
            painter: _ScoreRingPainter(
              progress: animatedScore / 100,
              color: color,
              trackColor: NidColors.mint,
              strokeWidth: strokeWidth,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  // Proportional to the ring so the number reads right at any
                  // size (34 @120). letterSpacing stays -0.02em @34.
                  fontSize: (size * 0.28).round().toDouble(),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.68,
                  color: NidColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                word,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NidColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Design -3 inset so the ring sits a hair inside its box (51 @120).
    final radius = ((size.shortestSide - strokeWidth) / 2) - 3;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) {
      return;
    }
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// One explainable score factor: name, state word, and a thin filled track.
class ContributorBar extends StatelessWidget {
  const ContributorBar({
    super.key,
    required this.name,
    required this.word,
    required this.tone,
    required this.fraction,
    this.infoTip,
  });

  final String name;
  final String word;
  final StateTone tone;
  final double fraction;
  final Widget? infoTip;

  @override
  Widget build(BuildContext context) {
    final toneColor = nidToneColor(tone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NidColors.contributorName,
              ),
            ),
            ?infoTip,
            const Spacer(),
            Text(
              word,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: NidColors.mint,
            borderRadius: BorderRadius.circular(NidRadius.pill),
          ),
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: toneColor,
                borderRadius: BorderRadius.circular(NidRadius.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small "i" affordance that opens a plain-language educational card.
///
/// Mandatory beside metric names a newcomer might not know. Body copy voice
/// (callers supply it): 1-2 sentences — what the metric is, plus what a
/// change usually means — ending reassuring, never a warning, and never an
/// exclamation mark.
class InfoTip extends StatelessWidget {
  const InfoTip({super.key, required this.term, required this.body});

  final String term;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(
                  term,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                content: Text(
                  body,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: NidColors.mint,
            shape: BoxShape.circle,
            border: Border.all(color: NidColors.canopy.withValues(alpha: 0.14)),
          ),
          child: const Center(
            child: Text(
              'i',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: NidColors.canopy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stat-delta idiom: metric name (with optional sub-line) on the left,
/// value over a directional delta word on the right.
class StatDeltaRow extends StatelessWidget {
  const StatDeltaRow({
    super.key,
    required this.name,
    this.sub,
    required this.value,
    required this.delta,
    this.flagged = false,
  });

  final String name;
  final String? sub;
  final String value;
  final String delta;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NidColors.ink,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: const TextStyle(fontSize: 12, color: NidColors.faint),
                ),
            ],
          ),
        ),
        const SizedBox(width: NidSpace.s),
        // Constrain the value/delta column so a long delta (e.g. an
        // observational insight line) wraps right-aligned instead of
        // overflowing the row at phone width.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: NidColors.ink,
                ),
              ),
              Text(
                delta,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: flagged ? NidColors.ember : NidColors.moss,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A calm score/metric trend line (design `06-trend-line` / `20-trends`): three
/// faint gridlines, a soft area fill under the line, the moss polyline with
/// round joins, an end dot on the latest point, and a date axis beneath. Honest
/// axes — the vertical scale spans the series' own min..max with a little
/// padding, so the line reads its real shape without fake normalization.
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.points, this.height = 130});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _TrendLinePainter(points: points),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: NidSpace.s),
        _TrendAxis(points: points),
      ],
    );
  }
}

class _TrendAxis extends StatelessWidget {
  const _TrendAxis({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    // Three ticks: first, middle, last — matching the mock's calm 3-label axis.
    final first = points.first.date;
    final mid = points[points.length ~/ 2].date;
    final last = points.last.date;
    final labels = points.length < 3
        ? [shortDate(first), shortDate(last)]
        : [shortDate(first), shortDate(mid), shortDate(last)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final label in labels)
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: NidColors.faint),
          ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({required this.points});

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Three faint gridlines at 1/4, 1/2, 3/4 height (design `.07` opacity).
    final grid = Paint()
      ..color = NidColors.canopy.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (final fraction in const [0.25, 0.5, 0.75]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (points.length < 2) {
      return;
    }

    // Honest vertical scale: the series' own min..max with 8% padding, so the
    // line reads its real shape (never renormalized to a fake 0-baseline).
    final values = points.map((p) => p.value).toList();
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.08;
    final lo = minV - pad;
    final span = (maxV + pad) - lo;

    Offset pointAt(int i) {
      final x = points.length == 1
          ? 0.0
          : size.width * (i / (points.length - 1));
      final t = ((points[i].value - lo) / span).clamp(0.0, 1.0);
      final y = size.height - t * size.height;
      return Offset(x, y);
    }

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }

    // Area fill under the line (design `rgba(93,127,67,.12)` == moss @ 12%).
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = NidColors.moss.withValues(alpha: 0.12),
    );

    // The trend line itself.
    canvas.drawPath(
      line,
      Paint()
        ..color = NidColors.moss
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End dot on the latest point.
    canvas.drawCircle(
      pointAt(points.length - 1),
      4,
      Paint()..color = NidColors.moss,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

/// The weekly-average bars (design `20-trends` `.bars`): up to four columns,
/// each a value label over a bar whose height is an honest fraction of the
/// axis max, colored on the sleep-hours ramp for sleep and on the state ramp
/// for score/activity. A `W1..W4` day label sits beneath.
class WeeklyAverageBars extends StatelessWidget {
  const WeeklyAverageBars({
    super.key,
    required this.weekly,
    required this.axisMax,
    required this.signal,
    this.height = 120,
  });

  final List<WeeklyAverage> weekly;
  final double axisMax;
  final TrendSignal signal;
  final double height;

  Color _barColor(double value) {
    if (signal == TrendSignal.sleep) {
      return NidStateColors.forSleepHours(value);
    }
    // Score/activity: color by fraction of the axis on the state ramp.
    final fraction = axisMax == 0 ? 0.0 : (value / axisMax).clamp(0.0, 1.0);
    return nidToneColor(nidReadinessTone(fraction));
  }

  String _valueLabel(double value) {
    if (signal == TrendSignal.sleep) {
      return value.toStringAsFixed(1);
    }
    if (signal == TrendSignal.activity) {
      return value.round().toString();
    }
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    // Chrome above/below the bar: the value label (~16), two gaps (5 + 6), and
    // the W-label (~14). Reserve it so a full-height bar never overflows the
    // column at the tallest week.
    const chrome = 44.0;
    return SizedBox(
      height: height + chrome,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final w in weekly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NidSpace.s),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _valueLabel(w.value),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NidColors.canopy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: height * w.fraction.clamp(0.0, 1.0),
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _barColor(w.value),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                            bottom: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      w.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: NidColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The consistency heatmap (design `13-consistency-heatmap` / `20-trends`): a
/// Monday-first 7-column calendar whose cells are colored by how close each day
/// lands to target (l1..l4), with short/attention days flagged in ember and
/// gaps left transparent. A weekday header and a less→more legend frame it.
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({
    super.key,
    required this.cells,
    this.flagLabel = 'short night',
  });

  final List<HeatLevel> cells;

  /// The legend word for the flagged tone (e.g. "short night" for sleep,
  /// "low readiness" for readiness).
  final String flagLabel;

  static Color _cellColor(HeatLevel level) {
    switch (level) {
      case HeatLevel.empty:
        return NidStateColors.heatEmpty;
      case HeatLevel.flag:
        return NidStateColors.heatFlag;
      case HeatLevel.l1:
        return NidStateColors.heatL1;
      case HeatLevel.l2:
        return NidStateColors.heatL2;
      case HeatLevel.l3:
        return NidStateColors.heatL3;
      case HeatLevel.l4:
        return NidStateColors.heatL4;
    }
  }

  @override
  Widget build(BuildContext context) {
    const dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekday header.
        Row(
          children: [
            for (final d in dow)
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: NidColors.faint),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final level = cells[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: _cellColor(level),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        ),
        const SizedBox(height: NidSpace.m),
        // Legend: less → more, plus the flag swatch. Wraps so the two groups
        // never overflow at the narrowest phone width.
        Wrap(
          spacing: NidSpace.m,
          runSpacing: NidSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'less',
                  style: TextStyle(fontSize: 11, color: NidColors.faint),
                ),
                const SizedBox(width: NidSpace.s),
                for (final level in const [
                  HeatLevel.l1,
                  HeatLevel.l2,
                  HeatLevel.l3,
                  HeatLevel.l4,
                ]) ...[
                  _LegendSwatch(color: _cellColor(level)),
                  const SizedBox(width: 4),
                ],
                const SizedBox(width: NidSpace.xs),
                const Text(
                  'more',
                  style: TextStyle(fontSize: 11, color: NidColors.faint),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendSwatch(color: NidStateColors.heatFlag),
                const SizedBox(width: NidSpace.xs),
                Text(
                  flagLabel,
                  style: const TextStyle(fontSize: 11, color: NidColors.faint),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
