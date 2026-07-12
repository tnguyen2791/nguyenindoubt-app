import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/sleep_insights.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';

/// The design's `.k` section-label idiom — uppercase 11px/w700 canopy with
/// +0.09em tracking (0.09 × 11 ≈ 0.99). Used for clinician section headers so
/// they read as quiet kickers, not sentence-case titles. An optional [tail]
/// renders in ember for the "not alerts, just patterns" reassurance.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.tail});

  final String label;
  final String? tail;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.99,
      color: NidColors.canopy,
    );
    return Text.rich(
      TextSpan(
        text: label.toUpperCase(),
        style: base,
        children: tail == null
            ? null
            : [
                TextSpan(
                  text: tail!.toUpperCase(),
                  style: base.copyWith(color: NidColors.ember),
                ),
              ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(NidSpace.xl),
          children: [
            const BrandHeader(
              title: 'Clinician dashboard',
              subtitle:
                  'Accepted invites only. Sleep summaries, never journals.',
              trailing: StatusPill(
                label: 'no messaging',
                tone: PillTone.neutral,
                icon: Icons.forum_outlined,
              ),
            ),
            const SizedBox(height: NidSpace.l),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 310, child: list),
                  const SizedBox(width: NidSpace.l),
                  Expanded(child: detail),
                ],
              )
            else ...[
              list,
              const SizedBox(height: NidSpace.l),
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
        const _SectionLabel('Invite status'),
        const SizedBox(height: NidSpace.s),
        for (final link in state.clinicianLinkStatuses)
          Padding(
            padding: const EdgeInsets.only(bottom: NidSpace.s),
            // Affordance truth (SAFE-02): only rows that actually open a sleep
            // summary present as tappable. Accepted rows keep the InkWell +
            // chevron; inert rows (pending/revoked/expired) drop the ink ripple
            // and tap target entirely, mute to reduced opacity, and let the
            // status pill carry the "why".
            child: link.canOpenSleepSummary
                ? InkWell(
                    borderRadius: BorderRadius.circular(NidRadius.card),
                    onTap: () => state.selectPatient(link.patientUserId),
                    child: _InviteRow(
                      link: link,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: NidColors.canopy,
                      ),
                    ),
                  )
                : Opacity(
                    opacity: 0.6,
                    child: _InviteRow(
                      link: link,
                      trailing: StatusPill(
                        label: _linkStatusLabel(link.status),
                        tone: _linkStatusTone(link.status),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.link, required this.trailing});

  final ClinicianLinkStatusView link;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: NidColors.mint,
            foregroundColor: NidColors.canopy,
            child: Text((link.patientDisplayName ?? '?').characters.first),
          ),
          const SizedBox(width: NidSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.patientDisplayName ?? 'Unknown patient',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NidSpace.xs),
                Text('${link.inviteCode} - ${_linkStatusLabel(link.status)}'),
              ],
            ),
          ),
          trailing,
        ],
      ),
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

PillTone _linkStatusTone(LinkStatus status) {
  return switch (status) {
    LinkStatus.accepted => PillTone.good,
    LinkStatus.pending => PillTone.caution,
    LinkStatus.revoked => PillTone.flag,
    LinkStatus.expired => PillTone.caution,
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
    final week = clinicianWeekSummary(summaries);

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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.39,
                      ),
                    ),
                  ),
                  const StatusPill(
                    label: 'journal private',
                    tone: PillTone.private,
                  ),
                ],
              ),
              const SizedBox(height: NidSpace.l),
              const _SectionLabel(
                'Worth a look',
                tail: ' · not alerts, just patterns',
              ),
              const SizedBox(height: NidSpace.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatDeltaRow(
                    name: 'Avg sleep',
                    sub: 'last 7 nights',
                    value: week.avgLabel,
                    delta: week.deltaLabel,
                    flagged: week.deltaFlagged,
                  ),
                  const SizedBox(height: NidSpace.m),
                  StatDeltaRow(
                    name: 'Night-to-night',
                    sub: 'variability',
                    value: week.variabilityValue,
                    delta: week.variabilityWord,
                    flagged: week.variabilityFlagged,
                  ),
                  const SizedBox(height: NidSpace.m),
                  StatDeltaRow(
                    name: 'Nights with data',
                    sub: 'past week',
                    value: week.nightsLabel,
                    delta: 'sleep summaries only',
                  ),
                ],
              ),
              const SizedBox(height: NidSpace.l),
              SleepTrendBars(summaries: summaries),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Clinician visibility'),
              const SizedBox(height: NidSpace.s),
              const Text(
                'Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.',
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Closing humility note — clinician readings are context, never a
        // verdict, and the patient stays in control of what is shared.
        Text(
          'People control exactly what you see and can pause sharing anytime.\n'
          'Readings are educational context for conversations — never a diagnosis.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.6,
            color: NidColors.faint,
          ),
        ),
      ],
    );
  }
}
