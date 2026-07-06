import 'package:flutter/material.dart';

import '../models/app_models.dart';
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
                    onPressed: state.isBusy ? null : state.importMockSleep,
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
              const SizedBox(height: 16),
              SleepTrendBars(summaries: state.summaries),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state.currentUser.consentStatus != ConsentStatus.granted)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'invite code NID-1138'),
                const SizedBox(height: 12),
                Text(
                  'Share sleep summaries with your clinician',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Only sleep summaries and samples become visible after consent. Journal notes stay private in this version.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: state.isBusy ? null : state.acceptClinicInvite,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Accept invite'),
                ),
              ],
            ),
          ),
      ],
    );
  }
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
