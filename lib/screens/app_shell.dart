import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'clinician_dashboard.dart';
import 'common_widgets.dart';
import 'journal_screen.dart';
import 'patient_dashboard.dart';
import 'resources_screen.dart';

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

        final screens = [
          PatientDashboard(state: widget.state),
          JournalScreen(state: widget.state),
          ResourcesScreen(state: widget.state),
          const SafetyScreen(),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 880;
            return Scaffold(
              appBar: _AppBar(state: widget.state, onSignOut: _signOut),
              body: Row(
                children: [
                  if (isWide)
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.insights_outlined),
                          label: Text('Sleep'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.edit_note_outlined),
                          label: Text('Journal'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.menu_book_outlined),
                          label: Text('Guides'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.health_and_safety_outlined),
                          label: Text('Safety'),
                        ),
                      ],
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
                  : NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.insights_outlined),
                          label: 'Sleep',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.edit_note_outlined),
                          label: 'Journal',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_outlined),
                          label: 'Guides',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.health_and_safety_outlined),
                          label: 'Safety',
                        ),
                      ],
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

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.isBusy, required this.onReset});

  final bool isBusy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NidColors.mint.withValues(alpha: 0.72),
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
                  color: NidColors.canopy,
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
      backgroundColor: NidColors.fog,
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
        Text('NguyenInDoubt', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: NidSpace.m),
        Text(
          'Sleep data, private reflection, and mental-health guides with enough humility to leave room for doubt.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: NidSpace.xl),
        // Single patient-first primary action (ONB-02).
        FilledButton.icon(
          onPressed: onPatient,
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('Get started'),
        ),
        const SizedBox(height: NidSpace.m),
        // Required local-only disclosure, kept but lowered to calm
        // secondary copy (relocated, not deleted — ONB-02).
        Text(
          'Demo auth is local to this device. Firebase sign-in is not live yet.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NidColors.slate),
        ),
        const SizedBox(height: NidSpace.l),
        // Clinician entry stays reachable, just visually quiet (ONB-02).
        TextButton(
          onPressed: onClinician,
          style: TextButton.styleFrom(
            foregroundColor: NidColors.slate,
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(NidSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_outlined),
                ),
                const SizedBox(height: NidSpace.l),
                const BrandMark(size: 64),
                const SizedBox(height: NidSpace.l),
                Text(
                  'Patient onboarding',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: NidSpace.m),
                Text(
                  'Demo mode stores your profile, journal entries, sleep imports, and consent state on this device only. Account-backed production storage is not enabled.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: NidSpace.xl),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onSubmitted: widget.onComplete,
                ),
                const SizedBox(height: NidSpace.xl),
                FilledButton.icon(
                  onPressed: () => widget.onComplete(_nameController.text),
                  icon: const Icon(Icons.check_outlined),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
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
            color: NidColors.ink.withValues(alpha: 0.72),
            child: Text(
              'Just ask. Then protect what should stay private.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
