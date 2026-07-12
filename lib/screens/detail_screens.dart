/// Phase 14 drill-down detail screens: Readiness (28) and Sleep (21).
///
/// Both are reached from the Today dashboard by a gentle fade route (project
/// motion rule). They reuse the Phase-11 data-display kit (ScoreRing,
/// ContributorBar, InfoTip, SleepTrendBars, StatDeltaRow) and stay strictly
/// observational and non-diagnostic — every score carries "not a diagnosis"
/// and unfamiliar signals carry an InfoTip that ends on reassurance.
///
/// Readiness is patient-only; nothing here is ever shown to a clinician.
library;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/sleep_insights.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';

/// Plain-language InfoTip bodies for the readiness contributors a newcomer may
/// not know. Keyed by the contributor [MetricType]. Voice: what the signal is,
/// what a change usually means, ending reassuring — never a warning, no
/// exclamation marks (brand-readme education layer).
const Map<MetricType, String> _readinessTipBodies = {
  MetricType.hrv:
      'The tiny timing differences between heartbeats, compared to your norm. '
      'Higher usually means rested; dips after stress recover with rest.',
  MetricType.temperature:
      'Overnight skin temperature vs your baseline. Small drifts are normal; '
      'sustained rises can follow a hard day and settle again on their own.',
  MetricType.respiratoryRate:
      'Your breaths per minute overnight. It sits in a steady personal range '
      'most nights, and small shifts settle on their own.',
  MetricType.sleep:
      'Your recent sleep vs what your body typically needs — a short window, '
      'so one short night will not sink it.',
  MetricType.activeEnergy:
      'How much you moved the day before. Both very light and very hard days '
      'can shape the next morning, and it evens out over a week.',
};

/// A fade-through route so a detail screen eases in rather than popping
/// (project motion rule). Kept here so both detail pushes share one transition.
Route<T> fadeDetailRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Pushes the Readiness detail (screen 28) as a gentle fade, rebuilding on
/// state changes so a re-import updates it live (the P12 journal-route
/// pattern: a pushed route sits outside AppShell's AnimatedBuilder).
void openReadinessDetail(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => ReadinessDetailScreen(state: state),
      ),
    ),
  );
}

/// Pushes the Sleep detail (screen 21) as a gentle fade, rebuilding on state.
void openSleepDetail(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => SleepDetailScreen(state: state),
      ),
    ),
  );
}

/// The Readiness detail screen (28): a 120px ring, the full multi-signal
/// contributor list with InfoTips + values, an observational caption, and the
/// verbatim "not a diagnosis" headnote.
class ReadinessDetailScreen extends StatelessWidget {
  const ReadinessDetailScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final readiness = state.readiness;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.nid.fog,
        title: const Text('Readiness'),
      ),
      body: readiness == null
          ? const _DetailEmpty(
              icon: Icons.favorite_outline,
              title: 'Readiness appears after a wearable read',
              body:
                  'Import from the Today screen to read your overnight signals '
                  '— readiness is observational, never a diagnosis.',
            )
          : ListView(
              padding: const EdgeInsets.all(NidSpace.l),
              children: [_ReadinessDetailBody(readiness: readiness)],
            ),
    );
  }
}

class _ReadinessDetailBody extends StatelessWidget {
  const _ReadinessDetailBody({required this.readiness});

  final ReadinessSummary readiness;

  @override
  Widget build(BuildContext context) {
    final tone = nidReadinessTone(readiness.readinessScore / 100);
    final toneColor = nidToneColor(tone);
    final watchCount =
        readiness.contributors
            .where((c) => nidReadinessTone(c.fraction) == StateTone.fair)
            .length +
        readiness.contributors
            .where((c) => nidReadinessTone(c.fraction) == StateTone.attention)
            .length;
    final watchPhrase = switch (watchCount) {
      0 => 'contributors steady',
      1 => 'one contributor to watch',
      _ => '$watchCount contributors to watch',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero ring — centered, 150px hero size, with the observational caption.
        Center(
          child: ScoreRing(
            score: readiness.readinessScore,
            word: readiness.state,
            color: toneColor,
            size: 150,
            strokeWidth: 14,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          '${_capitalize(readiness.state)} · $watchPhrase',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: toneColor,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Contributor card.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CONTRIBUTORS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.99,
                      color: context.nid.canopy,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'not a diagnosis',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.nid.faint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NidSpace.l),
              for (var i = 0; i < readiness.contributors.length; i++) ...[
                if (i > 0) const SizedBox(height: 10), // mock .crows gap:10px
                _ReadinessContributorRow(
                  contributor: readiness.contributors[i],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        Text(
          'Readiness compares each signal to your own recent baseline, never '
          'to anyone else. It is observational — a calm read on recovery, not '
          'a diagnosis.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.nid.slate),
        ),
      ],
    );
  }
}

/// One readiness contributor row: name (+ InfoTip when the signal is
/// unfamiliar), its own state word, a filled track, and the raw value beside
/// it when available.
class _ReadinessContributorRow extends StatelessWidget {
  const _ReadinessContributorRow({required this.contributor});

  final ReadinessContributor contributor;

  @override
  Widget build(BuildContext context) {
    final tone = nidReadinessTone(contributor.fraction);
    final tipBody = _readinessTipBodies[contributor.metric];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContributorBar(
          name: contributor.name,
          word: contributor.word,
          tone: tone,
          fraction: contributor.fraction,
          infoTip: tipBody == null
              ? null
              : InfoTip(term: contributor.name, body: tipBody),
        ),
        if (contributor.value != null) ...[
          const SizedBox(height: 4),
          Text(
            _valueLabel(contributor),
            style: TextStyle(fontSize: 11, color: context.nid.faint),
          ),
        ],
      ],
    );
  }
}

String _valueLabel(ReadinessContributor contributor) {
  final value = contributor.value;
  if (value == null) {
    return '';
  }
  // Whole-number signals read without a decimal; temperature keeps one.
  final unit = contributor.unit ?? '';
  final needsDecimal = unit == '°C' || unit == 'h' || unit == 'brpm';
  final valueText = needsDecimal
      ? value.toStringAsFixed(1)
      : value.round().toString();
  return unit.isEmpty ? valueText : '$valueText $unit';
}

/// The Sleep detail screen (21): last-night stats (duration + delta), the
/// honest 7-night trend (reused SleepTrendBars), and sleep sub-stats. Sleep
/// data only — real, and never a diagnosis.
class SleepDetailScreen extends StatelessWidget {
  const SleepDetailScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final summaries = state.summaries;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.nid.fog,
        title: const Text('Sleep'),
      ),
      body: summaries.isEmpty
          ? const _DetailEmpty(
              icon: Icons.bedtime_outlined,
              title: 'No sleep imported yet',
              body:
                  'Import from the Today screen to read last night and your '
                  '7-night trend.',
            )
          : ListView(
              padding: const EdgeInsets.all(NidSpace.l),
              children: [_SleepDetailBody(summaries: summaries)],
            ),
    );
  }
}

class _SleepDetailBody extends StatelessWidget {
  const _SleepDetailBody({required this.summaries});

  final List<DailySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final score = computeSleepScore(summaries);
    final toneColor = nidToneColor(score.tone);
    final latest = summaries.last;
    final recent = summaries.length <= 7
        ? summaries
        : summaries.sublist(summaries.length - 7);
    final weekAverage =
        recent.fold<double>(0, (sum, s) => sum + s.sleepDurationHours) /
        recent.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero: sleep score ring + protective/short caption with last night.
        Center(
          child: ScoreRing(
            score: score.value,
            word: 'quality',
            color: toneColor,
            size: 150,
            strokeWidth: 14,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          '${_capitalize(latest.trendFlag)} · ${hoursLabel(latest.sleepDurationHours)} asleep',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: toneColor,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Last-night stats: duration + delta, and the week average + delta.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'LAST NIGHT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.99,
                      color: context.nid.canopy,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'not a diagnosis',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.nid.faint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NidSpace.l),
              StatDeltaRow(
                name: 'Total sleep',
                sub: 'last night',
                value: hoursLabel(latest.sleepDurationHours),
                delta: insightLine(summaries),
              ),
              const SizedBox(height: NidSpace.m),
              StatDeltaRow(
                name: '7-night average',
                sub: 'recent nights',
                value: hoursLabel(weekAverage),
                delta: weekDeltaLabel(summaries),
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // The honest 7-night trend — reused SleepTrendBars.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SLEEP TREND · 7 NIGHTS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.99,
                  color: context.nid.canopy,
                ),
              ),
              const SizedBox(height: NidSpace.l),
              SleepTrendBars(summaries: summaries),
              const SizedBox(height: NidSpace.m),
              Text(
                consistencyCaption(summaries),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Sleep sub-stats: the score's own contributors, explainable.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTRIBUTORS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.99,
                  color: context.nid.canopy,
                ),
              ),
              const SizedBox(height: NidSpace.l),
              for (var i = 0; i < score.contributors.length; i++) ...[
                if (i > 0) const SizedBox(height: NidSpace.m),
                ContributorBar(
                  name: score.contributors[i].name,
                  word: score.contributors[i].word,
                  tone: score.contributors[i].tone,
                  fraction: score.contributors[i].fraction,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailEmpty extends StatelessWidget {
  const _DetailEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NidSpace.l),
      children: [EmptyState(icon: icon, title: title, body: body)],
    );
  }
}

String _capitalize(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);
