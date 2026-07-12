/// Phase 19 Weekly report screen (design `94`).
///
/// A calm, patient-only read on the past week: a takeaway headline, three
/// stats (avg readiness, avg sleep, days on target), a 7-night sleep bar strip,
/// a "what lined up" section of observational correlations from the patient's
/// own journal tags vs sleep, and a single gentle "one thing to try".
///
/// Everything renders from [computeWeeklyReport] over the patient's own
/// persisted data — nothing here is ever shown to a clinician (sleep-summaries-
/// only contract). Voice is "patterns, not grades": observational, non-
/// diagnostic, no shame, no emoji, no exclamation marks (brand-readme).
///
/// Reached by a gentle fade route from the Notifications feed's weekly-report
/// item and from Profile.
library;

import 'package:flutter/material.dart';

import '../services/weekly_report.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'detail_screens.dart';
import 'tab_shells.dart';

/// Pushes the Weekly report (94) as a gentle fade, rebuilding on state changes
/// so a re-import updates it live (the pushed-route pattern shared with the
/// detail screens — a pushed route sits outside AppShell's AnimatedBuilder).
void openWeeklyReport(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => WeeklyReportScreen(state: state),
      ),
    ),
  );
}

/// The Weekly report screen (94). Patient-only; reads the patient's own sleep,
/// readiness, and journal tags through [NguyenInDoubtState] and renders the
/// precomputed [WeeklyReport]. A week with too little data shows a calm empty.
class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final report = computeWeeklyReport(
      summaries: state.summaries,
      readiness: state.readinessHistory,
      journal: state.journalEntries,
      sleepGoalHours: state.preferences.sleepGoalMinutes / 60.0,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.nid.fog,
        title: const Text('Your week'),
      ),
      body: report.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(NidSpace.l),
              children: [
                EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: report.takeaway,
                  body: report.takeawaySub,
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(NidSpace.l),
              children: [_WeeklyReportBody(report: report)],
            ),
    );
  }
}

class _WeeklyReportBody extends StatelessWidget {
  const _WeeklyReportBody({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Range + takeaway headline + calm sub-line.
        Text(
          report.rangeLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.nid.faint,
          ),
        ),
        const SizedBox(height: NidSpace.xs),
        Text(
          report.takeaway,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.15,
            color: context.nid.canopy,
          ),
        ),
        const SizedBox(height: NidSpace.s),
        Text(
          report.takeawaySub,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.nid.slate,
            height: 1.5,
          ),
        ),
        const SizedBox(height: NidSpace.l),

        // Three-up stat grid.
        _StatGrid(stats: report.stats),
        const SizedBox(height: NidSpace.m),

        // 7-night sleep bar strip.
        _SectionCard(
          kicker: 'Sleep · ${report.nights.length} nights',
          headnote: 'color = hours',
          child: _NightBars(
            nights: report.nights,
            axisMax: report.nightsAxisMax,
          ),
        ),
        const SizedBox(height: NidSpace.m),

        // "What lined up" — observational tag-vs-sleep correlations.
        if (report.correlations.isNotEmpty) ...[
          _SectionCard(
            kicker: 'What lined up',
            headnote: 'from your tags',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < report.correlations.length; i++) ...[
                  if (i > 0) const SizedBox(height: NidSpace.m),
                  _CorrelationRow(correlation: report.correlations[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: NidSpace.m),
        ],

        // One thing to try — the single gentle suggestion, in the mint block.
        _OneThingToTry(text: report.oneThingToTry),
        const SizedBox(height: NidSpace.l),

        // Patterns-not-grades footer (verbatim design 94 close).
        Text(
          'Patterns, not grades — a week is data, not a verdict.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.nid.faint,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// The three-up summary stat grid (design `94` `.stats`).
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<WeeklyReportStat> stats;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight lets the three tiles share the tallest tile's height
    // without forcing an infinite height inside the vertically-unbounded list.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: NidSpace.s),
            Expanded(child: _StatTile(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final WeeklyReportStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NidSpace.l),
      decoration: BoxDecoration(
        color: context.nid.surface,
        borderRadius: BorderRadius.circular(NidRadius.card),
        border: Border.all(color: context.nid.canopy.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.44,
                color: context.nid.canopy,
              ),
              children: [
                TextSpan(text: stat.value),
                if (stat.unitTail != null)
                  TextSpan(
                    text: stat.unitTail,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.nid.slate,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            stat.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.nid.faint,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 7-night sleep bar strip — each night a value label over a bar whose
/// height is an honest fraction of the fixed hour axis and whose color encodes
/// hours on the sleep ramp (reusing the blessed `forSleepHours` mapping).
class _NightBars extends StatelessWidget {
  const _NightBars({required this.nights, required this.axisMax});

  final List<WeeklyReportNight> nights;
  final double axisMax;

  static const double _barsHeight = 100;

  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _barsHeight + 22, // reserve chrome for the value label
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final night in nights)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          night.sleepHours.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.nid.canopy,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: _barsHeight * night.fraction.clamp(0.0, 1.0),
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: NidStateColors.forSleepHours(
                                night.sleepHours,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                                bottom: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.s),
        Row(
          children: [
            for (var i = 0; i < nights.length; i++)
              Expanded(
                child: Text(
                  _dow[nights[i].date.weekday - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.nid.faint),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One "what lined up" row: a moss (or warm ember) dot and the observational
/// sentence.
class _CorrelationRow extends StatelessWidget {
  const _CorrelationRow({required this.correlation});

  final WeeklyReportCorrelation correlation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: correlation.warm ? context.nid.ember : context.nid.moss,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: NidSpace.m),
        Expanded(
          child: Text(
            correlation.text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: context.nid.slate,
            ),
          ),
        ),
      ],
    );
  }
}

/// The "one thing to try" mint block (design `94` `.try`).
class _OneThingToTry extends StatelessWidget {
  const _OneThingToTry({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NidSpace.l,
        vertical: NidSpace.l - 1,
      ),
      decoration: BoxDecoration(
        color: context.nid.mint,
        borderRadius: BorderRadius.circular(NidRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ONE THING TO TRY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.nid.moss,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: context.nid.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A white card with the design's `.k` kicker + optional right-aligned headnote
/// header, wrapping arbitrary content. Local to the weekly report so its header
/// grammar matches design 94 exactly.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.kicker,
    required this.child,
    this.headnote,
  });

  final String kicker;
  final String? headnote;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NidSpace.l),
      decoration: BoxDecoration(
        color: context.nid.surface,
        borderRadius: BorderRadius.circular(NidRadius.card),
        border: Border.all(color: context.nid.canopy.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: SectionKicker(kicker)),
              if (headnote != null)
                Text(
                  headnote!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.nid.faint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NidSpace.l),
          child,
        ],
      ),
    );
  }
}
