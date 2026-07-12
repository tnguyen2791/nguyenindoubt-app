/// Phase 18 user-side sharing flow: request → choose scopes → send → status →
/// manage / pause (design 82 / 84 / 86 / 102 / 78).
///
/// This is the consent-first sharing journey a patient takes to share readings
/// with a provider. It is built entirely on the existing consent state machine
/// (`validateInviteCode` → `acceptValidatedInvite` → `revokeConsent`) so no new
/// trust boundary is introduced; where `acceptInvite` throws in Firebase mode
/// (needs a trusted backend op) the flow surfaces calm "not available yet" copy
/// rather than an uncaught throw.
///
/// THE PRIVACY CONTRACT IS PARAMOUNT. Journal is NEVER a shareable scope: the
/// scope list offers sleep summaries only, and the "Journal tags / Journal
/// notes" rows render as explicitly *Not offered* (design 102's contract-correct
/// treatment), never as a toggle a patient could flip on. The verbatim
/// "Hidden: journal entries, drafts, private reflections." disclosure stays on
/// every step that names what a provider can see. Readiness is patient-only and
/// is likewise never part of what a provider sees.
library;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'detail_screens.dart';
import 'tab_shells.dart';

/// The verbatim clinician-visibility disclosure. Kept identical to the
/// clinician surface and the dashboard consent card so the promise reads the
/// same everywhere it appears (test-asserted, do not reword).
const String kSharingVisibilityDisclosure =
    'Visible: sleep samples, daily summaries, trend flags. '
    'Hidden: journal entries, drafts, private reflections.';

/// Opens the user-side sharing flow (design 82 → 78/102) as a gentle fade,
/// rebuilding on state changes so a validate / accept / revoke updates the flow
/// live (the P12 pushed-route pattern: a route outside AppShell's
/// AnimatedBuilder must listen to [state] itself).
void openSharingFlow(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => SharingFlowScreen(state: state),
      ),
    ),
  );
}

/// The single entry point for the sharing journey. It routes to the right step
/// from the patient's current consent status, so the same "Sharing" row always
/// lands somewhere honest:
///   * granted  → Manage / pause (design 78)
///   * otherwise → Request + choose scopes + send (design 82 / 84 / 86), with
///     a validated-but-not-accepted invite showing the waiting status (102).
class SharingFlowScreen extends StatelessWidget {
  const SharingFlowScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final consent = state.currentUser.consentStatus;
    if (consent == ConsentStatus.granted) {
      return ManageSharingScreen(state: state);
    }
    return RequestSharingScreen(state: state);
  }
}

/// The read-only scopes a provider can be offered. Sleep-summaries-only per the
/// standing privacy contract — this list matches the current clinician surface.
/// Journal (tags AND notes) and readiness are deliberately absent; they are
/// rendered separately as explicitly *Not offered* rows so the patient can see
/// the contract, never toggle it.
class _OfferedScope {
  const _OfferedScope({required this.label, required this.detail});

  final String label;
  final String detail;
}

const List<_OfferedScope> _offeredScopes = [
  _OfferedScope(
    label: 'Scores & trends',
    detail: 'Sleep summaries and trend flags',
  ),
  _OfferedScope(
    label: 'Sleep detail',
    detail: 'Nightly sleep samples and daily summaries',
  ),
];

/// The scopes that are structurally NOT offered — the contract made visible.
/// These never become toggles; they read "Not offered" so a patient sees that
/// their journal (and private reflections) stay theirs, always.
const List<_OfferedScope> _withheldScopes = [
  _OfferedScope(
    label: 'Journal tags',
    detail: 'Not offered — your tags stay private',
  ),
  _OfferedScope(
    label: 'Journal notes',
    detail: 'Not offered — your notes stay private',
  ),
];

/// A small circle-back button in the design's `.back` grammar for the pushed
/// flow steps that are their own scaffold section.
class _FlowScaffold extends StatelessWidget {
  const _FlowScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: context.nid.fog, title: Text(title)),
      body: child,
    );
  }
}

/// Request + choose scopes + send (design 82 / 84 / 86 folded into one calm
/// screen). The patient names their provider by the invite code the clinician
/// gave them (the app's real, backend-safe mechanic), reviews exactly what will
/// be shared — sleep only, journal explicitly withheld — and sends the request.
///
/// "Send request" reuses `acceptValidatedInvite`. In the demo that activates
/// sharing immediately (there is no separate clinician-accept step in local
/// mode); in Firebase mode it surfaces the calm "not available yet" message the
/// state layer already produces, never a throw.
class RequestSharingScreen extends StatefulWidget {
  const RequestSharingScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  State<RequestSharingScreen> createState() => _RequestSharingScreenState();
}

class _RequestSharingScreenState extends State<RequestSharingScreen> {
  final TextEditingController _inviteController = TextEditingController();

  NguyenInDoubtState get _state => widget.state;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validation = _state.inviteValidation;
    final canSend = validation?.canAccept ?? false;
    final revoked = _state.currentUser.consentStatus == ConsentStatus.revoked;

    return _FlowScaffold(
      title: 'Share with a provider',
      child: ListView(
        padding: const EdgeInsets.all(NidSpace.l),
        children: [
          Text(
            'Choose who to share with',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              color: context.nid.canopy,
              letterSpacing: -0.52,
            ),
          ),
          const SizedBox(height: NidSpace.s),
          Text(
            'Enter the invite code your provider gave you. You pick exactly '
            "what's shared — sleep only — and nothing leaves until you send.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.nid.slate,
            ),
          ),
          const SizedBox(height: NidSpace.l),

          if (revoked) ...[
            const _ContractFine(
              'Sharing was revoked. A revoked invite cannot be reused; enter a '
              'new pending code to share again.',
            ),
            const SizedBox(height: NidSpace.m),
          ],

          TextField(
            controller: _inviteController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'NID-1138',
              prefixIcon: Icon(Icons.qr_code_2_outlined),
              border: OutlineInputBorder(),
            ),
            onSubmitted: _state.isBusy
                ? null
                : (value) => _state.validateInviteCode(value),
          ),
          const SizedBox(height: NidSpace.m),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _state.isBusy
                  ? null
                  : () => _state.validateInviteCode(_inviteController.text),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Find provider'),
            ),
          ),

          if (validation != null) ...[
            const SizedBox(height: NidSpace.l),
            _ProviderCard(validation: validation),
          ],

          const SizedBox(height: NidSpace.l),
          const SectionKicker("They'll see"),
          const SizedBox(height: NidSpace.m),
          const _ScopeGroup(),
          const SizedBox(height: NidSpace.m),
          const _ContractFine(
            'Read-only, one provider, and you see everything they see. They '
            'can accept or decline — and you can cancel anytime.',
          ),
          const SizedBox(height: NidSpace.s),
          Text(
            kSharingVisibilityDisclosure,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.nid.faint,
            ),
          ),

          const SizedBox(height: NidSpace.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!canSend || _state.isBusy) ? null : _sendRequest,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Send request'),
            ),
          ),
          const SizedBox(height: NidSpace.s),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    await _state.acceptValidatedInvite();
    if (!mounted) {
      return;
    }
    // On success the patient is now sharing → show the confirmation. If the
    // backend guarded the accept (Firebase mode), consent is unchanged and the
    // validation now carries the calm "not available yet" message, which the
    // provider card already renders — so we stay on this screen.
    if (_state.currentUser.consentStatus == ConsentStatus.granted) {
      await Navigator.of(context).pushReplacement(
        fadeDetailRoute<void>(
          AnimatedBuilder(
            animation: _state,
            builder: (_, _) => RequestSentScreen(state: _state),
          ),
        ),
      );
    }
  }
}

/// The provider identity card (design 82/84 `.result` / `.prov`): the clinician
/// the validated invite resolves to, with a calm verified marker. Falls back to
/// the validation's own message when the code is not shareable.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.validation});

  final InviteValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = validation.clinicianDisplayName;
    final canAccept = validation.canAccept;

    if (!canAccept || name == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.nid.ember.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(NidRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NidSpace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite not available', style: theme.textTheme.titleMedium),
              const SizedBox(height: NidSpace.s),
              Text(validation.message),
            ],
          ),
        ),
      );
    }

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.nid.canopy,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: TextStyle(
                color: context.nid.onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: NidSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: NidSpace.xs),
                Text(
                  'Accepting share requests',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.nid.slate,
                  ),
                ),
              ],
            ),
          ),
          const StatusPill(
            label: 'verified',
            tone: PillTone.good,
            icon: Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }
}

/// The offered/withheld scope group (design 84/78 `.group`). Offered scopes show
/// an "on" tick (sleep-only, fixed on — this phase shares the full sleep scope
/// set, matching the current clinician surface). Withheld scopes read "Not
/// offered" — the contract made visible, never a flippable toggle.
class _ScopeGroup extends StatelessWidget {
  const _ScopeGroup();

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final scope in _offeredScopes) {
      rows.add(_ScopeRow(scope: scope, offered: true));
    }
    for (final scope in _withheldScopes) {
      rows.add(_ScopeRow(scope: scope, offered: false));
    }

    return Container(
      decoration: BoxDecoration(
        color: context.nid.surface,
        borderRadius: BorderRadius.circular(NidRadius.card),
        border: Border.all(color: context.nid.canopy.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.nid.canopy.withValues(alpha: 0.14),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.scope, required this.offered});

  final _OfferedScope scope;
  final bool offered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NidSpace.l,
        vertical: NidSpace.l - 1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: offered ? context.nid.ink : context.nid.faint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scope.detail,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.nid.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NidSpace.m),
          if (offered)
            Icon(Icons.check_circle, size: 22, color: context.nid.moss)
          else
            Text(
              'Not offered',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.nid.faint,
              ),
            ),
        ],
      ),
    );
  }
}

/// The "request sent" confirmation (design 86). A calm checkmark, the provider
/// name, the offered scope chips (sleep-only), and two exits: back to the app,
/// or review the sharing status.
class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerName = state.currentUser.clinicCode ?? 'your provider';

    return Scaffold(
      backgroundColor: context.nid.fog,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NidSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.nid.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: context.nid.canopy,
                ),
              ),
              const SizedBox(height: NidSpace.l),
              Text(
                'Sharing is on',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: context.nid.canopy,
                  letterSpacing: -0.52,
                ),
              ),
              const SizedBox(height: NidSpace.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'Sharing starts with your next morning reading — read-only, '
                  "and you'll always see exactly what they see ($providerName). "
                  'Pause anytime.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.nid.slate,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: NidSpace.l),
              Wrap(
                spacing: NidSpace.s,
                runSpacing: NidSpace.s,
                alignment: WrapAlignment.center,
                children: [
                  for (final scope in _offeredScopes)
                    StatusPill(
                      label: scope.label.toLowerCase(),
                      tone: PillTone.neutral,
                    ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: NidSpace.s),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  fadeDetailRoute<void>(
                    AnimatedBuilder(
                      animation: state,
                      builder: (_, _) => ManageSharingScreen(state: state),
                    ),
                  ),
                ),
                child: const Text('Review sharing settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manage / pause sharing (design 78, with the 102 "what you offered" readout).
/// Shows the active provider, exactly what they can see (sleep-only, journal
/// explicitly withheld), the verbatim disclosure, and a calm "Pause sharing"
/// that revokes consent. Pausing is quiet — the copy makes clear no notice goes
/// to the provider (consent rule, enforced in the state layer: revoke never
/// notifies).
class ManageSharingScreen extends StatelessWidget {
  const ManageSharingScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharing = state.currentUser.consentStatus == ConsentStatus.granted;
    final providerCode = state.currentUser.clinicCode;

    return _FlowScaffold(
      title: 'Share with your provider',
      child: ListView(
        padding: const EdgeInsets.all(NidSpace.l),
        children: [
          if (!sharing)
            EmptyState(
              icon: Icons.link_off_outlined,
              title: 'Not sharing right now',
              body: providerCode == null
                  ? 'Enter an invite code to start sharing sleep summaries '
                        'with a provider.'
                  : 'Sharing is paused. You can start again anytime with a new '
                        'invite code.',
            )
          else ...[
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.nid.canopy,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      color: context.nid.onAccent,
                    ),
                  ),
                  const SizedBox(width: NidSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sharing active',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: NidSpace.xs),
                        Text(
                          providerCode == null
                              ? 'Read-only, one provider'
                              : 'Invite $providerCode · read-only',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.nid.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusPill(
                    label: 'verified',
                    tone: PillTone.good,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: NidSpace.l),
            const SectionKicker('What your provider can see'),
            const SizedBox(height: NidSpace.m),
            const _ScopeGroup(),
            const SizedBox(height: NidSpace.m),
            const _ContractFine(
              'Sharing is read-only and one provider only. Changes apply '
              "immediately, and you'll see everything they see.",
            ),
            const SizedBox(height: NidSpace.s),
            Text(
              kSharingVisibilityDisclosure,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: context.nid.faint,
              ),
            ),
            const SizedBox(height: NidSpace.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.isBusy ? null : state.revokeConsent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.nid.ember,
                ),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Pause sharing'),
              ),
            ),
            const SizedBox(height: NidSpace.s),
            Text(
              'Pausing hides everything at once — no notice goes to your '
              'provider, and you can resume anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: context.nid.faint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The design's `.fine` shield-icon reassurance line, reused across the flow.
class _ContractFine extends StatelessWidget {
  const _ContractFine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: context.nid.moss),
        const SizedBox(width: NidSpace.s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.nid.faint,
            ),
          ),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
