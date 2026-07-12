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

/// Single-letter weekday label for compact chart axes.
String dayLetter(DateTime date) =>
    const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

/// State the [StatusPill] encodes through color, never mint-for-everything.
enum PillTone { neutral, good, caution, flag, private }

extension PillToneColors on PillTone {
  /// The single place a pill color encodes state: (background, foreground).
  /// Every value resolves to the active [NidPalette] tone (DS-03), so pills
  /// adapt to light/dark. `bark` (caution) has no palette slot and stays fixed.
  ({Color background, Color foreground}) colorsFor(NidPalette p) {
    switch (this) {
      case PillTone.neutral:
        return (background: p.mint, foreground: p.canopy);
      case PillTone.good:
        return (
          background: Color.alphaBlend(
            p.sage.withValues(alpha: 0.45),
            p.surface,
          ),
          foreground: p.canopy,
        );
      case PillTone.caution:
        return (
          background: Color.alphaBlend(
            NidColors.bark.withValues(alpha: 0.16),
            p.surface,
          ),
          foreground: NidColors.bark,
        );
      case PillTone.flag:
        return (
          background: p.ember.withValues(alpha: 0.14),
          foreground: p.ember,
        );
      case PillTone.private:
        return (background: p.fog, foreground: p.ink);
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
        color: context.nid.surface,
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
        color: context.nid.canopy,
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.nid.onAccent,
                  ),
                ),
                const SizedBox(height: NidSpace.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.nid.onAccent.withValues(alpha: 0.84),
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
    this.padding = const EdgeInsets.all(NidSpace.cardPad),
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
    final palette = tone.colorsFor(context.nid);
    final background = color ?? palette.background;
    final foreground = palette.foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NidRadius.pill),
        border: Border.all(color: context.nid.canopy.withValues(alpha: 0.08)),
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

  /// The fixed hour axis every bar renders against — heights are honest
  /// fractions of this window, so a 2h night reads tiny.
  static const double axisMaxHours = 9.5;

  /// Fixed height of the bar region the hairline aligns against.
  static const double _chartHeight = 168;

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

    const targetBottom = _chartHeight * (8 / axisMaxHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 8h-target hairline in gridline style, behind the bars.
              Positioned(
                left: 0,
                right: 0,
                bottom: targetBottom,
                child: Container(
                  height: 1,
                  color: context.nid.canopy.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                right: 0,
                bottom: targetBottom + 2,
                child: Text(
                  '8h',
                  style: TextStyle(fontSize: 10, color: context.nid.faint),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: summaries.map((summary) {
                  final heightFactor =
                      (summary.sleepDurationHours / axisMaxHours).clamp(
                        0.0,
                        1.0,
                      );
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NidSpace.xs,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              alignment: Alignment.bottomCenter,
                              // Oura-style: softly rounded tops, gentle
                              // bottom, color encodes hours on the ramp.
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: NidStateColors.forSleepHours(
                                    summary.sleepDurationHours,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(7),
                                    bottom: Radius.circular(4),
                                  ),
                                ),
                                child: const SizedBox(width: double.infinity),
                              ),
                            ),
                          ),
                          // Value label rides just above the bar top.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: _chartHeight * heightFactor + 6,
                            child: Text(
                              hoursLabel(summary.sleepDurationHours),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: context.nid.canopy,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.s),
        Row(
          children: summaries.map((summary) {
            return Expanded(
              child: Text(
                dayLetter(summary.date),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: context.nid.faint),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: NidSpace.xs),
        // Calm baseline hairline under the chart.
        Container(height: 1, color: context.nid.canopy.withValues(alpha: 0.14)),
        const SizedBox(height: NidSpace.m),
        // Explicit scale: short-to-optimal hours ramp.
        Row(
          children: [
            Text(
              '5h short',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NidStateColors.rampColors[0],
              ),
            ),
            const SizedBox(width: NidSpace.s),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NidRadius.pill),
                  gradient: const LinearGradient(
                    colors: NidStateColors.rampColors,
                    stops: NidStateColors.rampStops,
                  ),
                ),
              ),
            ),
            const SizedBox(width: NidSpace.s),
            Text(
              '8h+ optimal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NidStateColors.optimal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The design's `.sw` pill toggle: a 44x26 track — mint off, canopy on — with
/// a shadowed white knob that slides across. Gentle ~200ms motion (the one
/// place a shadow is allowed, per brand-readme). Used across the Settings
/// screens for stored preferences.
class NidToggle extends StatelessWidget {
  const NidToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 26,
          decoration: BoxDecoration(
            color: value ? context.nid.canopy : context.nid.mint,
            borderRadius: BorderRadius.circular(NidRadius.pill),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.nid.ink.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
        color: context.nid.mint.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(NidRadius.card),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: context.nid.canopy),
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
