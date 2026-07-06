import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

String shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String hoursLabel(double hours) => '${hours.toStringAsFixed(1)}h';

/// State the [StatusPill] encodes through color, never mint-for-everything.
enum PillTone { neutral, good, caution, flag, private }

extension PillToneColors on PillTone {
  /// The single place a pill color encodes state: (background, foreground).
  /// Every value resolves to a blessed [NidColors] tone (DS-03).
  ({Color background, Color foreground}) get colors {
    switch (this) {
      case PillTone.neutral:
        return (background: NidColors.mint, foreground: NidColors.canopy);
      case PillTone.good:
        return (
          background: Color.alphaBlend(
            NidColors.sage.withValues(alpha: 0.45),
            Colors.white,
          ),
          foreground: NidColors.canopy,
        );
      case PillTone.caution:
        return (
          background: Color.alphaBlend(
            NidColors.bark.withValues(alpha: 0.16),
            Colors.white,
          ),
          foreground: NidColors.bark,
        );
      case PillTone.flag:
        return (
          background: NidColors.ember.withValues(alpha: 0.14),
          foreground: NidColors.ember,
        );
      case PillTone.private:
        return (background: NidColors.fog, foreground: NidColors.ink);
    }
  }
}

/// The single framed-badge brand lockup (DS-05). Frames the square mark in a
/// white badge with enforced clearspace, and clamps to a minimum render size
/// so the mark never degrades into a raw muddy tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final effective = size < 28 ? 28.0 : size;
    // Clearspace ~11% of the mark keeps the badge from feeling cramped.
    final clearspace = effective * 0.11;
    return Container(
      padding: EdgeInsets.all(clearspace),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NidRadius.badge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NidRadius.card),
        child: Image.asset(
          'assets/brand/nguyenindoubt-square-mark.png',
          width: effective,
          height: effective,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Container(
      padding: EdgeInsets.all(isWide ? NidSpace.xl : NidSpace.l),
      decoration: BoxDecoration(
        color: NidColors.canopy,
        borderRadius: BorderRadius.circular(NidRadius.card),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final markSize = isWide ? 82.0 : 62.0;
          final mark = BrandMark(size: markSize);
          final copy = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: NidSpace.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    mark,
                    const SizedBox(width: NidSpace.l),
                    copy,
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: NidSpace.m),
                  Align(alignment: Alignment.centerLeft, child: trailing!),
                ],
              ],
            );
          }

          return Row(
            children: [
              mark,
              const SizedBox(width: NidSpace.l),
              copy,
              if (trailing != null) ...[
                const SizedBox(width: NidSpace.l),
                trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NidSpace.l),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.color,
    this.icon,
  });

  final String label;

  /// The state this pill encodes. Drives background + foreground.
  final PillTone tone;

  /// Optional background override. When non-null it wins over [tone]'s
  /// background — retained so un-migrated call-sites keep compiling while
  /// screens move to `tone:` in Wave 2.
  final Color? color;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = tone.colors;
    final background = color ?? palette.background;
    final foreground = palette.foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NidRadius.pill),
        border: Border.all(color: NidColors.canopy.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NidSpace.m,
          vertical: NidSpace.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: NidSpace.xs),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepTrendBars extends StatelessWidget {
  const SleepTrendBars({super.key, required this.summaries});

  final List<DailySummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const EmptyState(
        icon: Icons.bedtime_outlined,
        title: 'No sleep samples yet',
        body: 'Import mock health data to populate this view.',
      );
    }

    final maxHours = summaries
        .map((summary) => summary.sleepDurationHours)
        .fold<double>(
          1,
          (previous, current) => current > previous ? current : previous,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SleepBarLegend(),
        const SizedBox(height: NidSpace.m),
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: summaries.map((summary) {
              final heightFactor = summary.sleepDurationHours / maxHours;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NidSpace.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        hoursLabel(summary.sleepDurationHours),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NidColors.canopy,
                        ),
                      ),
                      const SizedBox(height: NidSpace.xs),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: heightFactor.clamp(0.25, 1.0),
                          alignment: Alignment.bottomCenter,
                          // Oura-style: softly rounded tops, gentle bottom.
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: summary.sleepDurationHours < 6
                                  ? NidColors.ember
                                  : NidColors.moss,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9),
                                bottom: Radius.circular(6),
                              ),
                            ),
                            child: const SizedBox(width: double.infinity),
                          ),
                        ),
                      ),
                      const SizedBox(height: NidSpace.s),
                      Text(
                        shortDate(summary.date),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: NidSpace.xs),
        // Calm baseline hairline under the chart.
        Container(height: 1, color: NidColors.canopy.withValues(alpha: 0.14)),
      ],
    );
  }
}

class _SleepBarLegend extends StatelessWidget {
  const _SleepBarLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        _LegendDot(color: NidColors.moss, label: 'on target'),
        SizedBox(width: NidSpace.l),
        _LegendDot(color: NidColors.ember, label: 'short night'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: NidSpace.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NidColors.slate),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NidSpace.xl),
      decoration: BoxDecoration(
        color: NidColors.mint.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(NidRadius.card),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: NidColors.canopy),
          const SizedBox(height: NidSpace.s),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NidSpace.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
