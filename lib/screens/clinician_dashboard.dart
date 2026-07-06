import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class ClinicianDashboard extends StatelessWidget {
  const ClinicianDashboard({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        final detail = _PatientDetail(bundle: state.selectedPatientBundle);
        final list = _PatientList(state: state);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const BrandHeader(
              title: 'Clinician dashboard',
              subtitle:
                  'Accepted invites only. Sleep summaries, never journals.',
              trailing: StatusPill(
                label: 'no messaging',
                icon: Icons.forum_outlined,
              ),
            ),
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 310, child: list),
                  const SizedBox(width: 16),
                  Expanded(child: detail),
                ],
              )
            else ...[
              list,
              const SizedBox(height: 16),
              detail,
            ],
          ],
        );
      },
    );
  }
}

class _PatientList extends StatelessWidget {
  const _PatientList({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    if (state.clinicianLinkStatuses.isEmpty) {
      return const SectionCard(
        child: EmptyState(
          icon: Icons.group_off_outlined,
          title: 'No invite links',
          body: 'Invite lifecycle status appears here.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final link in state.clinicianLinkStatuses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: link.canOpenSleepSummary
                  ? () => state.selectPatient(link.patientUserId)
                  : null,
              child: SectionCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: NidColors.mint,
                      foregroundColor: NidColors.canopy,
                      child: Text(
                        (link.patientDisplayName ?? '?').characters.first,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.patientDisplayName ?? 'Unknown patient',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${link.inviteCode} - ${_linkStatusLabel(link.status)}',
                          ),
                        ],
                      ),
                    ),
                    if (link.canOpenSleepSummary)
                      const Icon(Icons.chevron_right, color: NidColors.canopy)
                    else
                      StatusPill(label: _linkStatusLabel(link.status)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _linkStatusLabel(LinkStatus status) {
  return switch (status) {
    LinkStatus.accepted => 'accepted',
    LinkStatus.pending => 'pending',
    LinkStatus.revoked => 'revoked',
    LinkStatus.expired => 'expired',
  };
}

class _PatientDetail extends StatelessWidget {
  const _PatientDetail({required this.bundle});

  final PatientSleepBundle? bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle == null) {
      return const SectionCard(
        child: EmptyState(
          icon: Icons.bedtime_outlined,
          title: 'Select a patient',
          body: 'Linked sleep summaries will load here.',
        ),
      );
    }

    final summaries = bundle!.summaries;
    final average = summaries.isEmpty
        ? 0.0
        : summaries
                  .map((summary) => summary.sleepDurationHours)
                  .reduce((a, b) => a + b) /
              summaries.length;
    final shortNights = summaries
        .where((summary) => summary.sleepDurationHours < 6)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bundle!.patient.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const StatusPill(label: 'journal private'),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ClinicianMetric(
                    label: '7-day avg',
                    value: average == 0 ? '--' : hoursLabel(average),
                  ),
                  _ClinicianMetric(
                    label: 'short nights',
                    value: '$shortNights',
                  ),
                  _ClinicianMetric(
                    label: 'samples',
                    value: '${bundle!.samples.length}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SleepTrendBars(summaries: summaries),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinician visibility',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClinicianMetric extends StatelessWidget {
  const _ClinicianMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NidColors.mint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
