import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/health_data_provider.dart';
import '../services/sleep_insights.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';
import 'patient_first_run.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        const BrandHeader(
          title: 'Morning check-in',
          subtitle: 'Start with the facts, then leave room for the story.',
        ),
        const SizedBox(height: NidSpace.l),
        // ONB-04: while there is no sleep data yet, the guided first-run
        // layer replaces both the '--' metric tiles and the empty trend
        // card with one calm primary action (see patient_first_run.dart).
        if (state.summaries.isEmpty)
          PatientFirstRun(state: state)
        else
          ..._withDataSections(context),
        const SizedBox(height: NidSpace.l),
        SectionCard(child: _ConsentLifecycleCard(state: state)),
      ],
    );
  }

  /// The with-data hierarchy (INS-01), top to bottom: greeting/status block
  /// with the one observational insight line -> score hero card -> two-up
  /// secondary mini-cards -> honest trend card with a consistency
  /// micro-insight. The consent card renders after everything in [build].
  List<Widget> _withDataSections(BuildContext context) {
    final score = computeSleepScore(state.summaries);
    final latest = state.summaries.last;
    final recent = state.summaries.length <= 7
        ? state.summaries
        : state.summaries.sublist(state.summaries.length - 7);
    final weekAverage =
        recent.fold<double>(
          0,
          (sum, summary) => sum + summary.sleepDurationHours,
        ) /
        recent.length;

    return [
      _GreetingBlock(
        firstName: _firstName(state.currentUser.displayName),
        tone: score.tone,
        insight: insightLine(state.summaries),
      ),
      const SizedBox(height: NidSpace.l),
      _ScoreHeroCard(score: score),
      const SizedBox(height: NidSpace.l),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MiniMetricCard(
                label: 'last night',
                value: hoursLabel(latest.sleepDurationHours),
                caption: latest.trendFlag,
              ),
            ),
            const SizedBox(width: NidSpace.m),
            Expanded(
              child: _MiniMetricCard(
                label: '7-night average',
                value: hoursLabel(weekAverage),
                caption: weekDeltaLabel(state.summaries),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: NidSpace.l),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_outlined, color: NidColors.canopy),
                const SizedBox(width: NidSpace.s),
                Expanded(
                  child: Text(
                    'Sleep trend · 7 nights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      state.isBusy ||
                          state.healthPermissionStatus ==
                              HealthPermissionStatus.unavailable
                      ? null
                      : state.importMockSleep,
                  icon: state.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Import'),
                ),
              ],
            ),
            const SizedBox(height: NidSpace.m),
            Wrap(
              spacing: NidSpace.s,
              runSpacing: NidSpace.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  label: _healthPermissionLabel(state.healthPermissionStatus),
                  tone: _healthPermissionTone(state.healthPermissionStatus),
                  icon: _healthPermissionIcon(state.healthPermissionStatus),
                ),
                Text(
                  _healthPermissionMessage(state.healthPermissionStatus),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: NidSpace.l),
            SleepTrendBars(summaries: state.summaries),
            const SizedBox(height: NidSpace.m),
            // INS-05: a consistency micro-insight instead of raw-count
            // framing — a balance observation about the week's rhythm.
            Text(
              consistencyCaption(state.summaries),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
  }
}

/// First whitespace-separated token of [displayName], for the greeting.
String _firstName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  return trimmed.split(RegExp(r'\s+')).first;
}

String _healthPermissionLabel(HealthPermissionStatus status) {
  return switch (status) {
    HealthPermissionStatus.unavailable => 'health unavailable',
    HealthPermissionStatus.notRequested => 'sleep permission needed',
    HealthPermissionStatus.partial => 'partial sleep access',
    HealthPermissionStatus.denied => 'sleep access denied',
    HealthPermissionStatus.revoked => 'sleep access revoked',
    HealthPermissionStatus.ready => 'sleep access ready',
  };
}

String _healthPermissionMessage(HealthPermissionStatus status) {
  return switch (status) {
    HealthPermissionStatus.unavailable =>
      'HealthKit or Health Connect is not available here.',
    HealthPermissionStatus.notRequested => 'Import requests sleep-only access.',
    HealthPermissionStatus.partial =>
      'Some sleep categories are available for import.',
    HealthPermissionStatus.denied =>
      'Permission was denied. Update system settings to import.',
    HealthPermissionStatus.revoked =>
      'Access changed in system settings. Reconnect to import.',
    HealthPermissionStatus.ready => 'Ready to sync recent sleep.',
  };
}

IconData _healthPermissionIcon(HealthPermissionStatus status) {
  return switch (status) {
    HealthPermissionStatus.unavailable => Icons.block_outlined,
    HealthPermissionStatus.notRequested => Icons.lock_clock_outlined,
    HealthPermissionStatus.partial => Icons.rule_outlined,
    HealthPermissionStatus.denied => Icons.lock_outline,
    HealthPermissionStatus.revoked => Icons.link_off_outlined,
    HealthPermissionStatus.ready => Icons.check_circle_outline,
  };
}

PillTone _healthPermissionTone(HealthPermissionStatus status) {
  return switch (status) {
    HealthPermissionStatus.unavailable => PillTone.caution,
    HealthPermissionStatus.notRequested => PillTone.neutral,
    HealthPermissionStatus.partial => PillTone.caution,
    HealthPermissionStatus.denied => PillTone.flag,
    HealthPermissionStatus.revoked => PillTone.flag,
    HealthPermissionStatus.ready => PillTone.good,
  };
}

class _ConsentLifecycleCard extends StatefulWidget {
  const _ConsentLifecycleCard({required this.state});

  final NguyenInDoubtState state;

  @override
  State<_ConsentLifecycleCard> createState() => _ConsentLifecycleCardState();
}

class _ConsentLifecycleCardState extends State<_ConsentLifecycleCard> {
  final TextEditingController _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final validation = state.inviteValidation;
    final hasActiveSharing =
        state.currentUser.consentStatus == ConsentStatus.granted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: NidSpace.s,
          runSpacing: NidSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(
              label: hasActiveSharing
                  ? 'sharing active'
                  : state.currentUser.consentStatus == ConsentStatus.revoked
                  ? 'sharing revoked'
                  : 'invite required',
              tone: hasActiveSharing
                  ? PillTone.good
                  : state.currentUser.consentStatus == ConsentStatus.revoked
                  ? PillTone.flag
                  : PillTone.neutral,
              icon: hasActiveSharing
                  ? Icons.verified_user_outlined
                  : Icons.lock_outline,
            ),
            if (state.currentUser.clinicCode != null)
              StatusPill(
                label: state.currentUser.clinicCode!,
                tone: PillTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          'Sleep sharing consent',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: NidSpace.s),
        const Text(
          'Only sleep summaries and samples become visible after consent. Journal notes, drafts, and private reflections stay private.',
        ),
        const SizedBox(height: NidSpace.l),
        if (hasActiveSharing) ...[
          Text(
            'Sharing is active for ${state.currentUser.clinicCode}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: NidSpace.m),
          OutlinedButton.icon(
            onPressed: state.isBusy ? null : state.revokeConsent,
            icon: const Icon(Icons.link_off_outlined),
            label: const Text('Revoke sharing'),
          ),
        ] else ...[
          if (state.currentUser.consentStatus == ConsentStatus.revoked) ...[
            const Text(
              'Sharing was revoked. A revoked invite cannot be reused; validate a new pending code to share again.',
            ),
            const SizedBox(height: NidSpace.m),
          ],
          TextField(
            controller: _inviteController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'NID-1138',
              border: OutlineInputBorder(),
            ),
            onSubmitted: state.isBusy
                ? null
                : (value) => state.validateInviteCode(value),
          ),
          const SizedBox(height: NidSpace.m),
          Wrap(
            spacing: NidSpace.s,
            runSpacing: NidSpace.s,
            children: [
              FilledButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () => state.validateInviteCode(_inviteController.text),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Validate invite'),
              ),
              if (validation?.canAccept ?? false)
                FilledButton.icon(
                  onPressed: state.isBusy ? null : state.acceptValidatedInvite,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Accept sharing'),
                ),
            ],
          ),
          if (validation != null) ...[
            const SizedBox(height: NidSpace.m),
            _InviteValidationMessage(validation: validation),
          ],
        ],
        const SizedBox(height: NidSpace.l),
        _ConsentHistoryList(events: state.consentHistory),
      ],
    );
  }
}

class _InviteValidationMessage extends StatelessWidget {
  const _InviteValidationMessage({required this.validation});

  final InviteValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final color = validation.canAccept ? NidColors.canopy : NidColors.ember;
    final clinicianName = validation.clinicianDisplayName;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(NidRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NidSpace.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              validation.canAccept ? 'Invite preview' : 'Invite not available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: NidSpace.s),
            Text(validation.message),
            if (validation.canAccept && clinicianName != null) ...[
              const SizedBox(height: NidSpace.s),
              Text('Clinician: $clinicianName'),
              const Text(
                'Visible after acceptance: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConsentHistoryList extends StatelessWidget {
  const _ConsentHistoryList({required this.events});

  final List<ConsentHistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consent history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: NidSpace.s),
        if (events.isEmpty)
          const Text('No consent events yet.')
        else
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: NidSpace.s),
              child: Row(
                children: [
                  Icon(
                    event.action == ConsentEventAction.accepted
                        ? Icons.verified_user_outlined
                        : Icons.link_off_outlined,
                    size: 18,
                    color: event.action == ConsentEventAction.accepted
                        ? NidColors.canopy
                        : NidColors.ember,
                  ),
                  const SizedBox(width: NidSpace.s),
                  Expanded(
                    child: Text(
                      '${_eventActionLabel(event.action)} ${event.inviteCode}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: NidSpace.s),
                  Text(
                    _shortDate(event.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

String _eventActionLabel(ConsentEventAction action) {
  return switch (action) {
    ConsentEventAction.accepted => 'Accepted',
    ConsentEventAction.revoked => 'Revoked',
  };
}

String _shortDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

/// The greeting/status block at the top of the with-data dashboard — not a
/// card. Carries THE one observational insight line (INS-04); headlines
/// describe the night, never the person.
class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({
    required this.firstName,
    required this.tone,
    required this.insight,
  });

  final String firstName;
  final StateTone tone;
  final String insight;

  static String _daypart() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 17) {
      return 'afternoon';
    }
    return 'evening';
  }

  static String _headline(StateTone tone) {
    return switch (tone) {
      StateTone.optimal => 'A protective night',
      StateTone.good => 'A steady night',
      StateTone.fair => 'A lighter night',
      StateTone.attention => 'A short night',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'Good ${_daypart()}, $firstName',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: NidSpace.s),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: NidColors.moss,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: NidSpace.s),
            Flexible(
              child: Text(
                _headline(tone),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  color: NidColors.canopy,
                  height: 1.12,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NidSpace.s),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            insight,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// The hero readout (INS-02): score ring + the three explainable
/// contributors, headlined by the verbatim non-diagnostic humility note.
class _ScoreHeroCard extends StatelessWidget {
  const _ScoreHeroCard({required this.score});

  final SleepScore score;

  static const String _scoreTipBody =
      'A 0-100 summary of your recent sleep, combining duration, rhythm, '
      "and the week's direction. It compares only to your own recent "
      'nights, so one rough night barely moves it.';

  static const String _consistencyTipBody =
      'How similar your recent nights have been. Rhythm drifts during '
      'travel or busy weeks and settles again on its own.';

  @override
  Widget build(BuildContext context) {
    final toneColor = nidToneColor(score.tone);
    final contributors = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < score.contributors.length; i++) ...[
          if (i > 0) const SizedBox(height: NidSpace.m),
          ContributorBar(
            name: score.contributors[i].name,
            word: score.contributors[i].word,
            tone: score.contributors[i].tone,
            fraction: score.contributors[i].fraction,
            infoTip: score.contributors[i].name == 'Consistency'
                ? const InfoTip(term: 'Consistency', body: _consistencyTipBody)
                : null,
          ),
        ],
      ],
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SLEEP SCORE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: NidColors.canopy,
                ),
              ),
              const InfoTip(term: 'Sleep score', body: _scoreTipBody),
              const SizedBox(width: NidSpace.s),
              const Expanded(
                child: Text(
                  'not a diagnosis',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NidColors.faint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.l),
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = ScoreRing(
                score: score.value,
                word: score.word,
                color: toneColor,
              );
              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ring),
                    const SizedBox(height: NidSpace.l),
                    contributors,
                  ],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: NidSpace.l),
                  Expanded(child: contributors),
                ],
              );
            },
          ),
          const SizedBox(height: NidSpace.l),
          Text(
            score.caption,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: toneColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A calm secondary metric mini-card for the two-up row under the hero.
class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: NidColors.canopy),
          ),
          const SizedBox(height: NidSpace.s),
          Text(value, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: NidSpace.xs),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
