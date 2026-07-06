import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';

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
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        color: NidColors.canopy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final markSize = isWide ? 82.0 : 62.0;
          // The square mark ships with a light background, so frame it in a
          // white badge to read as a deliberate logo rather than a gray tile
          // sitting on the canopy-green header.
          final mark = Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/brand/nguyenindoubt-square-mark.png',
                width: markSize,
                height: markSize,
                fit: BoxFit.cover,
              ),
            ),
          );
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
                const SizedBox(height: 6),
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
                Row(children: [mark, const SizedBox(width: 18), copy]),
                if (trailing != null) ...[
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: trailing!),
                ],
              ],
            );
          }

          return Row(
            children: [
              mark,
              const SizedBox(width: 18),
              copy,
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
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
    this.padding = const EdgeInsets.all(18),
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
    this.color = NidColors.mint,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NidColors.canopy.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: NidColors.canopy),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: NidColors.canopy,
                fontWeight: FontWeight.w800,
              ),
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
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: summaries.map((summary) {
              final heightFactor = summary.sleepDurationHours / maxHours;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        hoursLabel(summary.sleepDurationHours),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: NidColors.canopy,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 8),
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
        const SizedBox(height: 6),
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
        SizedBox(width: 16),
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
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF54635A)),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: NidColors.mint.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: NidColors.canopy),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
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
