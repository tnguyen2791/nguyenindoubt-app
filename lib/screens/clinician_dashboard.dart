/// Phase 18 provider portal (design 74 / 76 / 80 / 96), expanding the Phase-11
/// clinician surface.
///
/// THE PRIVACY CONTRACT IS PARAMOUNT. The provider sees SLEEP SUMMARIES ONLY —
/// never journal content, journal tags, or readiness. The design mocks show a
/// "journal tags" scope chip, a journal-citing "Worth a look" card, and a
/// "scores · sleep · journal" shares label; those are stripped here per the
/// standing contract (see docs/design-handoff/INCORPORATION.md — the contract
/// wins over the handoff's opt-in-journal model). The verbatim
/// "Visible: sleep samples… Hidden: journal entries, drafts, private
/// reflections." disclosure and the Phase-11 directional stat-delta summary are
/// preserved unchanged.
library;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/sleep_insights.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';

/// The design's `.k` section-label idiom — uppercase 11px/w700 canopy with
/// +0.09em tracking (0.09 × 11 ≈ 0.99). Used for provider section headers so
/// they read as quiet kickers, not sentence-case titles. An optional [tail]
/// renders in ember for the "not alerts, just patterns" reassurance.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.tail});

  final String label;
  final String? tail;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.99,
      color: context.nid.canopy,
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
                  style: base.copyWith(color: context.nid.ember),
                ),
              ],
      ),
    );
  }
}

/// The verbatim clinician-visibility disclosure. Identical everywhere the
/// promise appears (test-asserted, do not reword).
const String _visibilityDisclosure =
    'Visible: sleep samples, daily summaries, trend flags. '
    'Hidden: journal entries, drafts, private reflections.';

/// The verbatim closing humility note — provider readings are context, never a
/// verdict, and the person stays in control (test-asserted).
const String _humilityNote =
    'People control exactly what you see and can pause sharing anytime.\n'
    'Readings are educational context for conversations — never a diagnosis.';

class ClinicianDashboard extends StatelessWidget {
  const ClinicianDashboard({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        final detail = _PatientDetail(bundle: state.selectedPatientBundle);
        final requests = _RequestsSection(state: state);
        final worthALook = _WorthALookSection(state: state);
        final roster = _RosterSection(state: state);

        final content = ListView(
          // Desktop page padding (mock 32/28/48); phone keeps the 24 gutter.
          padding: isWide
              ? const EdgeInsets.fromLTRB(32, 28, 32, 48)
              : const EdgeInsets.all(NidSpace.xl),
          children: [
            _ProviderHeader(state: state),
            const SizedBox(height: NidSpace.l),
            requests,
            const SizedBox(height: NidSpace.l),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        worthALook,
                        const SizedBox(height: NidSpace.l),
                        roster,
                      ],
                    ),
                  ),
                  const SizedBox(width: NidSpace.l),
                  Expanded(child: detail),
                ],
              )
            else ...[
              worthALook,
              const SizedBox(height: NidSpace.l),
              roster,
              const SizedBox(height: NidSpace.l),
              detail,
            ],
          ],
        );

        // Clamp the desktop portal to a comfortable reading measure (mock
        // 1120px) and centre it; phone widths use the full column.
        if (isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }
}

/// The provider portal header (design 76/74): a "Good morning" greeting, the
/// roster summary ("N people currently share readings with you · M worth a look
/// this morning"), a Provider badge, and a settings affordance. Grounded in the
/// sign-in promise ("you only ever see what each person has chosen to share").
class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharingCount = state.linkedPatients.length;
    final worthLook = _worthALookPatients(state).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Good morning, ${state.currentUser.displayName}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: context.nid.canopy,
                  letterSpacing: -0.39,
                ),
              ),
            ),
            const StatusPill(label: 'provider', tone: PillTone.neutral),
            const SizedBox(width: NidSpace.s),
            IconButton(
              tooltip: 'Provider settings',
              onPressed: () => _openProviderSettings(context, state),
              icon: Icon(Icons.settings_outlined, color: context.nid.canopy),
            ),
          ],
        ),
        const SizedBox(height: NidSpace.xs),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: context.nid.slate,
            ),
            children: [
              TextSpan(
                text:
                    '$sharingCount ${sharingCount == 1 ? 'person' : 'people'}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.nid.ink,
                ),
              ),
              const TextSpan(text: ' currently share readings with you · '),
              TextSpan(
                text: '$worthLook',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.nid.ink,
                ),
              ),
              const TextSpan(text: ' worth a look this morning'),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.s),
        // The sign-in promise, kept verbatim on the portal so the contract
        // reads up top (test-asserted, do not reword).
        Text(
          'Accepted invites only. Sleep summaries, never journals.',
          style: TextStyle(fontSize: 12, height: 1.5, color: context.nid.faint),
        ),
      ],
    );
  }
}

/// "Requests · people who opted in" (design 76). Each pending invite is a
/// person who asked to share; the provider can Accept or Decline. In the demo
/// these are best-effort local actions (there is no live backend accept), so
/// they surface calm feedback rather than mutating a trusted link.
class _RequestsSection extends StatelessWidget {
  const _RequestsSection({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.clinicianLinkStatuses
        .where((link) => link.status == LinkStatus.pending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Requests', tail: ' · people who opted in'),
        const SizedBox(height: NidSpace.m),
        if (pending.isEmpty)
          const SectionCard(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No open requests',
              body:
                  'People opt in from their own app. New share requests appear '
                  'here for you to accept or decline.',
            ),
          )
        else
          for (final link in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: NidSpace.s),
              child: _RequestCard(link: link),
            ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.link});

  final ClinicianLinkStatusView link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = Row(
      children: [
        CircleAvatar(
          backgroundColor: context.nid.mint,
          foregroundColor: context.nid.canopy,
          child: Text((link.patientDisplayName ?? '?').characters.first),
        ),
        const SizedBox(width: NidSpace.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                link.patientDisplayName ?? 'Unknown person',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: NidSpace.xs),
              // Sleep-only scopes — journal is never in a request offer.
              Text(
                'Asked to share scores & trends · sleep detail with you',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.nid.slate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: NidSpace.s,
      runSpacing: NidSpace.s,
      children: [
        FilledButton(
          onPressed: () => _requestFeedback(
            context,
            'People opt in from their own app. Accepting invites needs a '
            'verified backend step — not available in this demo.',
          ),
          child: const Text('Accept'),
        ),
        OutlinedButton(
          onPressed: () => _requestFeedback(
            context,
            'Declining is quiet — no notice goes to '
            '${link.patientDisplayName ?? 'them'}. Nothing is shared.',
          ),
          child: const Text('Decline'),
        ),
      ],
    );

    return SectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // At narrow (phone) widths the Accept/Decline pair drops below the
          // identity so nothing overflows; wide layouts keep it inline.
          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: NidSpace.m),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: NidSpace.m),
              actions,
            ],
          );
        },
      ),
    );
  }
}

/// "Worth a look · not alerts, just patterns" (design 76/80). Sleep-only
/// pattern observations for the accepted patients whose recent nights show a
/// dip or high variability. NEVER cites journal tags (the design's HRV/journal
/// citations are stripped) — the observation is grounded purely in the sleep
/// summaries the provider is allowed to see.
class _WorthALookSection extends StatelessWidget {
  const _WorthALookSection({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final flagged = _worthALookPatients(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          'Worth a look',
          tail: ' · not alerts, just patterns',
        ),
        const SizedBox(height: NidSpace.m),
        if (flagged.isEmpty)
          const SectionCard(
            child: EmptyState(
              icon: Icons.spa_outlined,
              title: 'Nothing stands out this morning',
              body:
                  "Everyone's recent sleep looks steady. Patterns show up here "
                  'when a few nights drift — never as an alarm.',
            ),
          )
        else
          for (final entry in flagged)
            Padding(
              padding: const EdgeInsets.only(bottom: NidSpace.s),
              child: _WorthALookCard(
                name: entry.name,
                why: entry.why,
                onOpen: () => state.selectPatient(entry.patientId),
              ),
            ),
      ],
    );
  }
}

class _WorthALookCard extends StatelessWidget {
  const _WorthALookCard({
    required this.name,
    required this.why,
    required this.onOpen,
  });

  final String name;
  final String why;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(NidRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(NidSpace.cardPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: context.nid.mint,
                foregroundColor: context.nid.canopy,
                child: Text(name.characters.first),
              ),
              const SizedBox(width: NidSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: NidSpace.xs),
                    Text(
                      why,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.nid.slate,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NidSpace.s),
              const StatusPill(label: 'pattern', tone: PillTone.flag),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Everyone" roster (design 76). One row per accepted, consent-scoped
/// patient plus the inert lifecycle rows (pending/revoked/expired) from the
/// Phase-11 surface — SAFE-02 affordance truth is preserved: only accepted rows
/// open a reading. The shares label is SLEEP-ONLY ("scores · sleep") — the
/// design's "scores · sleep · journal" is stripped per the contract.
class _RosterSection extends StatelessWidget {
  const _RosterSection({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    if (state.clinicianLinkStatuses.isEmpty) {
      return const SectionCard(
        child: EmptyState(
          icon: Icons.group_off_outlined,
          title: 'No one is sharing yet',
          body: 'Accepted share links and their status appear here.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Everyone'),
        const SizedBox(height: NidSpace.m),
        for (final link in state.clinicianLinkStatuses)
          Padding(
            padding: const EdgeInsets.only(bottom: NidSpace.s),
            // Affordance truth (SAFE-02): only accepted rows open a sleep
            // summary and present as tappable (InkWell + chevron). Inert rows
            // (pending/revoked/expired) drop the ripple + tap target, mute to
            // reduced opacity, and let the status pill carry the "why".
            child: link.canOpenSleepSummary
                ? InkWell(
                    borderRadius: BorderRadius.circular(NidRadius.card),
                    onTap: () => state.selectPatient(link.patientUserId),
                    child: _InviteRow(
                      link: link,
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.nid.canopy,
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
            backgroundColor: context.nid.mint,
            foregroundColor: context.nid.canopy,
            child: Text((link.patientDisplayName ?? '?').characters.first),
          ),
          const SizedBox(width: NidSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.patientDisplayName ?? 'Unknown patient',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: NidSpace.xs),
                // Lifecycle label — preserved verbatim for affordance/lifecycle
                // coverage ("NID-8274 - accepted", etc.).
                Text('${link.inviteCode} - ${_linkStatusLabel(link.status)}'),
                if (link.status == LinkStatus.accepted) ...[
                  const SizedBox(height: 2),
                  // Sleep-only shares descriptor — journal is never in the
                  // provider's scope, so it never appears in a shares label.
                  Text(
                    'shares: scores · sleep',
                    style: TextStyle(fontSize: 12, color: context.nid.faint),
                  ),
                ],
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

/// The person-first shared-readings detail (design 80). SLEEP-ONLY — the
/// Phase-11 directional stat-delta summary, the honest 7-night trend, the
/// verbatim visibility disclosure, and the humility note. The design's
/// readiness ring and "Journal · this week / tags" card are NOT rendered:
/// readiness is patient-only, and journal is never in the provider bundle.
class _PatientDetail extends StatelessWidget {
  const _PatientDetail({required this.bundle});

  final PatientSleepBundle? bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle == null) {
      return const SectionCard(
        child: EmptyState(
          icon: Icons.bedtime_outlined,
          title: 'Select a person',
          body: 'Their shared sleep summaries load here — sleep only.',
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
                      "${bundle!.patient.displayName}'s readings",
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
              const SizedBox(height: NidSpace.xs),
              Text(
                'This is the same view they see at home, scoped to sleep only.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.nid.slate),
              ),
              const SizedBox(height: NidSpace.l),
              const _SectionLabel('This week', tail: ' · sleep summaries only'),
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
              const _SectionLabel('Where this helps'),
              const SizedBox(height: NidSpace.s),
              Text(
                'It is context for a conversation — "your week looked heavy, '
                'how are you sleeping?" — not something to act on by itself. '
                'If something looks off for more than a few days, the most '
                'useful next step is usually just asking about it.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.nid.slate,
                  height: 1.55,
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
              const _SectionLabel('Clinician visibility'),
              const SizedBox(height: NidSpace.s),
              const Text(_visibilityDisclosure),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Closing humility note — provider readings are context, never a
        // verdict, and the person stays in control of what is shared.
        Text(
          _humilityNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.6,
            color: context.nid.faint,
          ),
        ),
      ],
    );
  }
}

/// One "Worth a look" observation, derived purely from a patient's sleep.
class _FlaggedPatient {
  const _FlaggedPatient({
    required this.patientId,
    required this.name,
    required this.why,
  });

  final String patientId;
  final String name;
  final String why;
}

/// The accepted patients whose recent sleep is worth a calm second look —
/// sleep-only reasoning, never journal. A patient is surfaced when their last
/// night is a short night (< 6h) or their week is highly variable. The demo's
/// selected bundle is the one accepted patient, so this reads from it; the
/// reasoning generalizes to any loaded bundle.
List<_FlaggedPatient> _worthALookPatients(NguyenInDoubtState state) {
  final bundle = state.selectedPatientBundle;
  if (bundle == null || bundle.summaries.isEmpty) {
    return const [];
  }
  final summaries = List<DailySummary>.of(bundle.summaries)
    ..sort((a, b) => a.date.compareTo(b.date));
  final week = clinicianWeekSummary(summaries);
  final latest = summaries.last;

  final flagged = <_FlaggedPatient>[];
  if (latest.sleepDurationHours < 6.0) {
    flagged.add(
      _FlaggedPatient(
        patientId: bundle.patient.id,
        name: bundle.patient.displayName,
        why:
            'A couple of shorter nights this week — the kind of stretch that '
            'usually settles with a few earlier nights.',
      ),
    );
  } else if (week.variabilityFlagged) {
    flagged.add(
      _FlaggedPatient(
        patientId: bundle.patient.id,
        name: bundle.patient.displayName,
        why:
            'Night-to-night sleep has been swinging more than usual. Worth a '
            'gentle check-in, not an alarm.',
      ),
    );
  }
  return flagged;
}

/// Opens the provider settings sheet (design 96): the provider identity, the
/// sharing-requests summary, notification preferences (display-only in the
/// demo), and the "good to know" contract note. Kept as a bottom sheet so it
/// works at both phone and desktop widths without a new route surface.
Future<void> _openProviderSettings(
  BuildContext context,
  NguyenInDoubtState state,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.nid.fog,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ProviderSettingsSheet(state: state),
  );
}

class _ProviderSettingsSheet extends StatelessWidget {
  const _ProviderSettingsSheet({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = state.clinicianLinkStatuses;
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            NidSpace.xl,
            NidSpace.m,
            NidSpace.xl,
            NidSpace.xl,
          ),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.nid.canopy.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(NidRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: NidSpace.l),
            Text(
              'Provider settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: context.nid.canopy,
                letterSpacing: -0.39,
              ),
            ),
            const SizedBox(height: NidSpace.l),
            // Identity.
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.nid.canopy,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      state.currentUser.displayName.characters.first,
                      style: TextStyle(
                        color: context.nid.onAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: NidSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.currentUser.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: NidSpace.xs),
                        Text(
                          'Verified provider',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.nid.moss,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NidSpace.l),
            const _SectionLabel('Sharing requests'),
            const SizedBox(height: NidSpace.m),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'People opt in from their own app. Accept or decline on the '
                    'dashboard — and remove access anytime.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: context.nid.slate,
                    ),
                  ),
                  const SizedBox(height: NidSpace.m),
                  for (final link in requests) ...[
                    _SettingsRequestRow(link: link),
                    if (link != requests.last)
                      Divider(
                        height: NidSpace.l,
                        color: context.nid.canopy.withValues(alpha: 0.14),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: NidSpace.l),
            const _SectionLabel('Notifications'),
            const SizedBox(height: NidSpace.m),
            SectionCard(
              child: Column(
                children: const [
                  _SettingsInfoRow(
                    label: 'Morning digest',
                    detail: 'One email when new readings arrive',
                    value: '8:00a',
                  ),
                  _SettingsInfoRow(
                    label: 'Pattern notes',
                    detail: "When someone's readings show a multi-day pattern",
                    value: 'On',
                  ),
                  _SettingsInfoRow(
                    label: 'Sharing changes',
                    detail: 'When someone starts sharing with you',
                    value: 'On',
                  ),
                ],
              ),
            ),
            const SizedBox(height: NidSpace.l),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Good to know'),
                  const SizedBox(height: NidSpace.s),
                  Text(
                    "You're never notified when someone pauses or narrows their "
                    "sharing — that's by design. What you see is always exactly "
                    "what they've chosen, nothing more. Sleep summaries only — "
                    'journal entries, drafts, and private reflections stay '
                    'theirs.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.nid.slate,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRequestRow extends StatelessWidget {
  const _SettingsRequestRow({required this.link});

  final ClinicianLinkStatusView link;

  @override
  Widget build(BuildContext context) {
    final connected = link.status == LinkStatus.accepted;
    // Sleep-only descriptor — never "scores, sleep & journal" (contract).
    final detail = connected
        ? 'Sharing · scores & sleep'
        : link.status == LinkStatus.pending
        ? 'Asked to share · scores & sleep'
        : '${_linkStatusLabel(link.status)} · scores & sleep';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                link.patientDisplayName ?? 'Unknown person',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(fontSize: 12, color: context.nid.slate),
              ),
            ],
          ),
        ),
        const SizedBox(width: NidSpace.s),
        StatusPill(
          label: connected
              ? 'connected'
              : link.status == LinkStatus.pending
              ? 'waiting on you'
              : _linkStatusLabel(link.status),
          tone: connected ? PillTone.good : PillTone.neutral,
        ),
      ],
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.label,
    required this.detail,
    required this.value,
  });

  final String label;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NidSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: context.nid.slate),
                ),
              ],
            ),
          ),
          const SizedBox(width: NidSpace.s),
          Text(value, style: TextStyle(fontSize: 13, color: context.nid.faint)),
        ],
      ),
    );
  }
}

void _requestFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
