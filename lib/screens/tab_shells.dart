import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'journal_screen.dart';
import 'resources_screen.dart';

/// A calm uppercase section kicker — the design's `.k` idiom (11px, 700,
/// letter-spacing, canopy). Reused across the new tab shells so section
/// labels read identically to the mocks.
class SectionKicker extends StatelessWidget {
  const SectionKicker(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.99, // 0.09em on an 11px kicker.
        color: NidColors.canopy,
      ),
    );
  }
}

/// The Trends tab — a calm shell for P12. Real 30-day trend, weekly averages
/// and consistency heatmap arrive in P14; until then this states the page's
/// intent with the design's title + section labels and a single honest
/// "coming soon" empty state. No fake data (roadmap scope call).
class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        Text(
          'Trends',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        const SectionKicker('Sleep score · 30 days'),
        const SizedBox(height: NidSpace.m),
        const EmptyState(
          icon: Icons.show_chart_outlined,
          title: 'Your sleep trend is coming soon',
          body:
              'Once a few nights are imported, this becomes a 30-day score '
              'trend — honest, sleep-only, never a diagnosis.',
        ),
        const SizedBox(height: NidSpace.l),
        const SectionKicker('Weekly sleep average'),
        const SizedBox(height: NidSpace.m),
        const EmptyState(
          icon: Icons.calendar_view_week_outlined,
          title: 'Weekly averages',
          body: 'Week-over-week sleep hours will settle in here.',
        ),
        const SizedBox(height: NidSpace.l),
        const SectionKicker('Consistency'),
        const SizedBox(height: NidSpace.m),
        const EmptyState(
          icon: Icons.grid_view_outlined,
          title: 'Consistency heatmap',
          body: 'A calendar of how close each night lands to your target.',
        ),
      ],
    );
  }
}

/// The Profile tab — the signed-in identity header plus grouped rows
/// (Account / Sharing / Preferences / Support) matching 31-profile's row
/// grammar. Rows are calm placeholders for P12 except the wired ones:
/// Journal opens the existing journal screen and Safety opens the existing
/// safety route (both must stay reachable now that the tab bar drops them),
/// and Sign out calls the real auth sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onSignOut,
  });

  final NguyenInDoubtState state;
  final VoidCallback onSignOut;

  String get _initial {
    final name = state.currentUser.displayName.trim();
    return name.isEmpty ? '?' : name.characters.first.toUpperCase();
  }

  void _openJournal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: NidColors.fog,
            title: const Text('Journal'),
          ),
          // Rebuild on state changes (add/delete) — outside AppShell's
          // AnimatedBuilder, the pushed route must listen itself.
          body: AnimatedBuilder(
            animation: state,
            builder: (_, _) => JournalScreen(state: state),
          ),
        ),
      ),
    );
  }

  void _openSafety(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: NidColors.fog,
            title: const Text('Safety and limits'),
          ),
          body: const SafetyScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        // Identity header — canopy avatar with the display-name initial.
        SectionCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: NidColors.canopy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: NidSpace.l),
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
                      'Demo member · data stays on this device',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NidColors.moss,
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

        const SectionKicker('Account'),
        const SizedBox(height: NidSpace.m),
        _ProfileGroup(
          rows: [
            _ProfileRow(
              icon: Icons.person_outline,
              label: 'Personal info',
              value: state.currentUser.displayName,
            ),
            _ProfileRow(
              icon: Icons.flag_outlined,
              label: 'Goals & targets',
              value: '8h sleep',
            ),
          ],
        ),
        const SizedBox(height: NidSpace.l),

        const SectionKicker('Sharing'),
        const SizedBox(height: NidSpace.m),
        _ProfileGroup(
          rows: [
            _ProfileRow(
              icon: Icons.medical_information_outlined,
              label: 'Share with your provider',
            ),
            _ProfileRow(
              icon: Icons.qr_code_2_outlined,
              label: 'Request to share',
            ),
          ],
        ),
        const SizedBox(height: NidSpace.l),

        const SectionKicker('Preferences'),
        const SizedBox(height: NidSpace.m),
        _ProfileGroup(
          rows: [
            _ProfileRow(
              icon: Icons.edit_note_outlined,
              label: 'Journal',
              onTap: () => _openJournal(context),
            ),
            _ProfileRow(
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              value: 'On',
            ),
            _ProfileRow(icon: Icons.lock_outline, label: 'Privacy & data'),
          ],
        ),
        const SizedBox(height: NidSpace.l),

        const SectionKicker('Support'),
        const SizedBox(height: NidSpace.m),
        _ProfileGroup(
          rows: [
            // Safety must stay reachable (standing project rule) now that the
            // tab bar no longer carries a Safety tab.
            _ProfileRow(
              icon: Icons.health_and_safety_outlined,
              label: 'Safety and limits',
              onTap: () => _openSafety(context),
            ),
            _ProfileRow(icon: Icons.help_outline, label: 'Help center'),
          ],
        ),
        const SizedBox(height: NidSpace.xl),

        // Sign out — the one wired identity action, in ember per the mock.
        Center(
          child: TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_outlined, color: NidColors.ember),
            label: const Text(
              'Sign out',
              style: TextStyle(
                color: NidColors.ember,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rounded white card wrapping a set of hairline-divided rows — the
/// design's `.group` container.
class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.rows});

  final List<_ProfileRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NidRadius.card),
        border: Border.all(color: NidColors.canopy.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: NidColors.canopy.withValues(alpha: 0.14),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// A single settings row: leading canopy icon, label, optional trailing value,
/// and a chevron. Non-functional rows still show the chevron so the grammar
/// reads consistently; [onTap] wires the reachable ones.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NidSpace.l,
          vertical: NidSpace.l - 1,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: NidColors.canopy),
            const SizedBox(width: NidSpace.m),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: NidColors.faint,
                ),
              ),
              const SizedBox(width: NidSpace.s),
            ],
            const Icon(Icons.chevron_right, size: 18, color: NidColors.faint),
          ],
        ),
      ),
    );
  }
}

/// The Explore tab — re-homes the existing resources content under the
/// design's "Explore" title + intro line (the full 70-explore rebuild —
/// featured practice, marker explainers, article rows — lands in P15). The
/// resource cards, including the crisis/988 line, are kept intact.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NidSpace.xl,
            NidSpace.xl,
            NidSpace.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: NidColors.canopy,
                  letterSpacing: -0.52,
                ),
              ),
              const SizedBox(height: NidSpace.xs),
              Text(
                'Short reads and practices — learn what your body is telling '
                'you.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NidColors.slate,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: ResourcesScreen(state: state)),
      ],
    );
  }
}

/// Shows the P12 Add-sheet stub — a bottom sheet matching 30-add-sheet's
/// grammar. The one wired action is "Import sleep" (reuses the existing mock
/// import); the rest are calm placeholders that land in later phases.
Future<void> showAddSheet(BuildContext context, NguyenInDoubtState state) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: NidColors.fog,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => _AddSheet(state: state),
  );
}

class _AddSheet extends StatelessWidget {
  const _AddSheet({required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NidSpace.xl,
          NidSpace.m,
          NidSpace.xl,
          NidSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: NidColors.canopy.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(NidRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: NidSpace.l),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to today',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: NidColors.canopy),
                ),
              ],
            ),
            const SizedBox(height: NidSpace.s),
            const SectionKicker('Sleep'),
            const SizedBox(height: NidSpace.m),
            _AddAction(
              icon: Icons.download_outlined,
              label: 'Import sleep',
              body: 'Requests sleep-only access, then reads last night.',
              enabled: !state.isBusy,
              onTap: () async {
                Navigator.of(context).pop();
                await state.importMockSleep();
              },
            ),
            const SizedBox(height: NidSpace.l),
            const SectionKicker('Lifestyle & mood'),
            const SizedBox(height: NidSpace.m),
            const _AddAction(
              icon: Icons.local_cafe_outlined,
              label: 'Log lifestyle tags',
              body: 'Naps, caffeine, meditation — coming soon.',
              enabled: false,
            ),
            const SizedBox(height: NidSpace.m),
            const _AddAction(
              icon: Icons.sentiment_satisfied_outlined,
              label: 'Note how you feel',
              body: 'A quick mood tag for the day — coming soon.',
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAction extends StatelessWidget {
  const _AddAction({
    required this.icon,
    required this.label,
    required this.body,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String body;
  final bool enabled;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NidRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onTap?.call() : null,
          child: Padding(
            padding: const EdgeInsets.all(NidSpace.l),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NidColors.mint,
                    borderRadius: BorderRadius.circular(NidRadius.tile),
                  ),
                  child: Icon(icon, size: 20, color: NidColors.canopy),
                ),
                const SizedBox(width: NidSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: NidSpace.xs),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NidColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
