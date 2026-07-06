import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/health_data_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.summaries.isEmpty ? null : state.summaries.last;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BrandHeader(
          title: 'Morning check-in',
          subtitle: 'Start with the facts, then leave room for the story.',
          trailing: StatusPill(
            label: state.currentUser.consentStatus == ConsentStatus.granted
                ? 'shared sleep'
                : 'private',
            icon: state.currentUser.consentStatus == ConsentStatus.granted
                ? Icons.verified_user_outlined
                : Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: 'last sleep',
              value: latest == null
                  ? '--'
                  : hoursLabel(latest.sleepDurationHours),
              caption: latest?.trendFlag ?? 'awaiting import',
            ),
            _MetricTile(
              label: 'quality proxy',
              value: latest == null ? '--' : '${latest.sleepQualityProxy}',
              caption: 'not a diagnosis',
            ),
            _MetricTile(
              label: 'clinician link',
              value: state.currentUser.consentStatus == ConsentStatus.granted
                  ? 'on'
                  : 'off',
              caption: state.currentUser.clinicCode ?? 'invite required',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined, color: NidColors.canopy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sleep trend',
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: _healthPermissionLabel(state.healthPermissionStatus),
                    icon: _healthPermissionIcon(state.healthPermissionStatus),
                  ),
                  Text(
                    _healthPermissionMessage(state.healthPermissionStatus),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SleepTrendBars(summaries: state.summaries),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(child: _ConsentLifecycleCard(state: state)),
      ],
    );
  }
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
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(
              label: hasActiveSharing
                  ? 'sharing active'
                  : state.currentUser.consentStatus == ConsentStatus.revoked
                  ? 'sharing revoked'
                  : 'invite required',
              icon: hasActiveSharing
                  ? Icons.verified_user_outlined
                  : Icons.lock_outline,
            ),
            if (state.currentUser.clinicCode != null)
              StatusPill(label: state.currentUser.clinicCode!),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Sleep sharing consent',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Only sleep summaries and samples become visible after consent. Journal notes, drafts, and private reflections stay private.',
        ),
        const SizedBox(height: 14),
        if (hasActiveSharing) ...[
          Text(
            'Sharing is active for ${state.currentUser.clinicCode}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
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
            const SizedBox(height: 12),
            _InviteValidationMessage(validation: validation),
          ],
        ],
        const SizedBox(height: 16),
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
    final color = validation.canAccept ? NidColors.canopy : Colors.red.shade700;
    final clinicianName = validation.clinicianDisplayName;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              validation.canAccept ? 'Invite preview' : 'Invite not available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(validation.message),
            if (validation.canAccept && clinicianName != null) ...[
              const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        if (events.isEmpty)
          const Text('No consent events yet.')
        else
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_eventActionLabel(event.action)} ${event.inviteCode}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: NidColors.canopy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
