import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'clinician_dashboard.dart';
import 'common_widgets.dart';
import 'explore_screen.dart';
import 'patient_dashboard.dart';
import 'tab_shells.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        if (widget.state.isSignedOut) {
          return _OnboardingScreen(
            onPatient: () async {
              await widget.state.startPatientOnboarding();
              setState(() {
                _selectedIndex = 0;
              });
            },
            onClinician: () async {
              await widget.state.continueAsClinicianDemo();
              setState(() {
                _selectedIndex = 0;
              });
            },
          );
        }

        if (widget.state.isOnboarding) {
          return _PatientOnboardingScreen(
            initialName: widget.state.currentUser.displayName,
            onBack: widget.state.signOut,
            onComplete: (displayName) async {
              await widget.state.completePatientOnboarding(
                displayName: displayName,
              );
              setState(() => _selectedIndex = 0);
            },
          );
        }

        if (widget.state.isClinician) {
          return Scaffold(
            appBar: _AppBar(state: widget.state, onSignOut: _signOut),
            body: Column(
              children: [
                _DemoNotice(
                  isBusy: widget.state.isBusy,
                  onReset: _confirmResetDemoData,
                ),
                Expanded(child: ClinicianDashboard(state: widget.state)),
              ],
            ),
          );
        }

        // The four selectable tabs (index 0-3). The design's center [+] is an
        // action, not a tab — it opens the Add-sheet and never selects.
        final screens = [
          PatientDashboard(state: widget.state), // Today
          TrendsScreen(state: widget.state), // Trends
          ExploreScreen(state: widget.state), // Explore
          ProfileScreen(state: widget.state, onSignOut: _signOut), // Profile
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 880;
            return Scaffold(
              appBar: _AppBar(state: widget.state, onSignOut: _signOut),
              body: Row(
                children: [
                  if (isWide)
                    _WideNavRail(
                      selectedIndex: _selectedIndex,
                      onSelect: (index) =>
                          setState(() => _selectedIndex = index),
                      onAdd: _openAddSheet,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _DemoNotice(
                          isBusy: widget.state.isBusy,
                          onReset: _confirmResetDemoData,
                        ),
                        Expanded(child: screens[_selectedIndex]),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: isWide
                  ? null
                  : _NidTabBar(
                      selectedIndex: _selectedIndex,
                      onSelect: (index) =>
                          setState(() => _selectedIndex = index),
                      onAdd: _openAddSheet,
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    await widget.state.signOut();
    setState(() => _selectedIndex = 0);
  }

  Future<void> _openAddSheet() => showAddSheet(context, widget.state);

  Future<void> _confirmResetDemoData() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data'),
        content: const Text(
          'Reset demo data: clear journal entries, imported sleep samples, and consent state stored on this device, then restore the seeded demo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset demo data'),
          ),
        ],
      ),
    );

    if (shouldReset != true) {
      return;
    }

    await widget.state.resetDemoData();
    if (mounted) {
      setState(() => _selectedIndex = 0);
    }
  }
}

/// The four selectable destinations, matching the design's tab grammar
/// (icon + short label). The center [+] Add action lives between Trends and
/// Explore but is not part of this list — it is an action, not a tab.
const List<({IconData icon, String label})> _patientTabs = [
  (icon: Icons.wb_sunny_outlined, label: 'Today'),
  (icon: Icons.bar_chart_outlined, label: 'Trends'),
  (icon: Icons.explore_outlined, label: 'Explore'),
  (icon: Icons.person_outline, label: 'Profile'),
];

/// The mobile bottom tab bar — Today · Trends · [+] · Explore · Profile.
/// Active canopy, faint inactive, and a canopy-filled center Add pill, per
/// 18-dashboard-mobile's `.tabbar` grammar.
class _NidTabBar extends StatelessWidget {
  const _NidTabBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.nid.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0x241E4A34)), // canopy @ ~14%.
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NidSpace.s,
            vertical: NidSpace.s,
          ),
          // A fixed-height row so the bottom bar reports a bounded intrinsic
          // height under the Scaffold's loose slot constraints (otherwise the
          // Expanded/Center children stretch to fill the whole screen).
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(
                  tab: _patientTabs[0],
                  selected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _TabItem(
                  tab: _patientTabs[1],
                  selected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                _AddButton(onTap: onAdd),
                _TabItem(
                  tab: _patientTabs[2],
                  selected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                ),
                _TabItem(
                  tab: _patientTabs[3],
                  selected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, String label}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.nid.canopy : context.nid.faint;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 22, color: color),
            const SizedBox(height: NidSpace.xs),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The center canopy-filled [+] Add action.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: 'Add to today',
          child: Material(
            color: context.nid.canopy,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add, color: context.nid.onAccent, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The wide-layout equivalent of the tab bar — a NavigationRail carrying the
/// same four destinations, with the [+] Add action as a leading canopy pill.
class _WideNavRail extends StatelessWidget {
  const _WideNavRail({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: NidSpace.m),
        child: Column(
          children: [
            Semantics(
              button: true,
              label: 'Add to today',
              child: Material(
                color: context.nid.canopy,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAdd,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.add,
                      color: context.nid.onAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: NidSpace.xs),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.nid.canopy,
              ),
            ),
          ],
        ),
      ),
      destinations: [
        for (final tab in _patientTabs)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.isBusy, required this.onReset});

  final bool isBusy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.nid.mint.withValues(alpha: 0.72),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NidSpace.l,
            vertical: NidSpace.m,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final copy = Text(
                'Demo mode: data stays on this device. It does not sync across browsers, phones, or the GitHub Pages demo, and it is not production storage.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.nid.canopy,
                  fontWeight: FontWeight.w600,
                ),
              );
              final reset = OutlinedButton.icon(
                onPressed: isBusy ? null : onReset,
                icon: const Icon(Icons.restart_alt_outlined),
                label: const Text('Reset demo data'),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    const SizedBox(height: NidSpace.s),
                    Align(alignment: Alignment.centerLeft, child: reset),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: NidSpace.m),
                  reset,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.state, required this.onSignOut});

  final NguyenInDoubtState state;
  final VoidCallback onSignOut;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final roleLabel = state.isClinician ? 'Clinician demo' : 'Patient demo';

    return AppBar(
      backgroundColor: context.nid.fog,
      titleSpacing: NidSpace.xl,
      title: Row(
        children: [
          const BrandMark(size: 34),
          const SizedBox(width: NidSpace.m),
          const Flexible(child: Text('NguyenInDoubt')),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: NidSpace.m),
          child: compact
              ? IconButton(
                  tooltip: 'Sign out',
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_outlined),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isClinician
                          ? Icons.badge_outlined
                          : Icons.person_outline,
                      size: 20,
                    ),
                    const SizedBox(width: NidSpace.s),
                    Text(
                      roleLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: NidSpace.m),
                    TextButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({required this.onPatient, required this.onClinician});

  final VoidCallback onPatient;
  final VoidCallback onClinician;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(NidSpace.xl),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _HeroCopy(
                              onPatient: onPatient,
                              onClinician: onClinician,
                            ),
                          ),
                          const SizedBox(width: NidSpace.xxl),
                          const Expanded(child: _StagPanel()),
                        ],
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          // Stag gets top billing on mobile (ONB-02).
                          const _StagPanel(),
                          const SizedBox(height: NidSpace.l),
                          _HeroCopy(
                            onPatient: onPatient,
                            onClinician: onClinician,
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onPatient, required this.onClinician});

  final VoidCallback onPatient;
  final VoidCallback onClinician;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 82),
        const SizedBox(height: NidSpace.l),
        Text(
          'NguyenInDoubt',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: context.nid.canopy,
            letterSpacing: -0.64,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          'Sleep data, private reflection, and mental-health guides with enough humility to leave room for doubt.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: NidSpace.xl),
        // Single patient-first primary action (ONB-02), full-width; the
        // radius/pad/weight come from the pass-1 filledButton theme.
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPatient,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Get started'),
          ),
        ),
        const SizedBox(height: NidSpace.m),
        // Required local-only disclosure, kept but lowered to calm
        // secondary copy (relocated, not deleted — ONB-02).
        Text(
          'Demo auth is local to this device. Firebase sign-in is not live yet.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.nid.slate),
        ),
        const SizedBox(height: NidSpace.l),
        // Clinician entry stays reachable, just visually quiet (ONB-02).
        TextButton(
          onPressed: onClinician,
          style: TextButton.styleFrom(
            foregroundColor: context.nid.slate,
            padding: EdgeInsets.zero,
          ),
          child: const Text("I'm a clinician"),
        ),
      ],
    );
  }
}

class _PatientOnboardingScreen extends StatefulWidget {
  const _PatientOnboardingScreen({
    required this.initialName,
    required this.onBack,
    required this.onComplete,
  });

  final String initialName;
  final VoidCallback onBack;
  final ValueChanged<String> onComplete;

  @override
  State<_PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<_PatientOnboardingScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _nameController.text.trim();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(NidSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back affordance in a calm 32x32 circle — white fill, a
                  // 1px canopy@14% hairline, canopy chevron.
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Material(
                      color: context.nid.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: context.nid.canopy.withValues(alpha: 0.14),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.onBack,
                        customBorder: const CircleBorder(),
                        child: Tooltip(
                          message: 'Back',
                          child: Icon(
                            Icons.arrow_back_outlined,
                            size: 18,
                            color: context.nid.canopy,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: NidSpace.l),
                  const BrandMark(size: 64),
                  const SizedBox(height: NidSpace.l),
                  Text(
                    'Patient onboarding',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      color: context.nid.canopy,
                      letterSpacing: -0.52,
                    ),
                  ),
                  const SizedBox(height: NidSpace.m),
                  Text(
                    'Demo mode stores your profile, journal entries, sleep imports, and consent state on this device only. Account-backed production storage is not enabled.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: NidSpace.l),
                  // What this app does — three calm expectations (ONB-03).
                  const _ExpectationBullet(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep, privately imported',
                  ),
                  const SizedBox(height: NidSpace.s),
                  const _ExpectationBullet(
                    icon: Icons.lock_outline,
                    label: 'A journal only you can read',
                  ),
                  const SizedBox(height: NidSpace.s),
                  const _ExpectationBullet(
                    icon: Icons.menu_book_outlined,
                    label: 'Guides, with room for doubt',
                  ),
                  const SizedBox(height: NidSpace.xl),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onComplete(value);
                      }
                    },
                  ),
                  const SizedBox(height: NidSpace.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      // An empty/whitespace-only name cannot submit (ONB-03).
                      onPressed: trimmed.isEmpty
                          ? null
                          : () => widget.onComplete(_nameController.text),
                      icon: const Icon(Icons.check_outlined),
                      label: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: NidSpace.s),
                  TextButton(
                    // Explicit skip proceeds with the demo fallback name —
                    // completePatientOnboarding trims empty input and falls
                    // back to the seeded demo profile name.
                    onPressed: () => widget.onComplete(''),
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpectationBullet extends StatelessWidget {
  const _ExpectationBullet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.nid.mint,
            borderRadius: BorderRadius.circular(NidRadius.tile),
          ),
          child: Icon(icon, size: 18, color: context.nid.canopy),
        ),
        const SizedBox(width: NidSpace.m),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StagPanel extends StatelessWidget {
  const _StagPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(NidRadius.card),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.asset(
              'assets/brand/stag-illustration.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(NidSpace.l),
            color: context.nid.ink.withValues(alpha: 0.72),
            child: Text(
              'Just ask. Then protect what should stay private.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: context.nid.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}
