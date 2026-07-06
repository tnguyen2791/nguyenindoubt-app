import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'clinician_dashboard.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final copy = Text(
                'Demo mode: data stays on this device. It does not sync across browsers, phones, or the GitHub Pages demo, and it is not production storage.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NidColors.canopy,
                  fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: reset),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 12),
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
    final roleLabel = state.isClinician
        ? 'Clinician demo override'
        : 'Patient demo';

    return AppBar(
      backgroundColor: NidColors.fog,
      titleSpacing: 20,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/brand/nguyenindoubt-square-mark.png',
              width: 34,
              height: 34,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text('NguyenInDoubt')),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
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
                    const SizedBox(width: 8),
                    Text(
                      roleLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 12),
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
                padding: const EdgeInsets.all(24),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _HeroCopy(
                              onPatient: onPatient,
                              onClinician: onClinician,
                            ),
                          ),
                          const SizedBox(width: 28),
                          const Expanded(child: _StagPanel()),
                        ],
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          _HeroCopy(
                            onPatient: onPatient,
                            onClinician: onClinician,
                          ),
                          const SizedBox(height: 18),
                          const _StagPanel(),
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
        Image.asset(
          'assets/brand/nguyenindoubt-square-mark.png',
          width: 82,
          height: 82,
        ),
        const SizedBox(height: 18),
        Text('NguyenInDoubt', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 10),
        Text(
          'Sleep data, private reflection, and mental-health guides with enough humility to leave room for doubt.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Demo auth is local to this device. Firebase sign-in is not live yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: NidColors.moss,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onPatient,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Patient sign up'),
            ),
            OutlinedButton.icon(
              onPressed: onClinician,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Clinician demo override'),
            ),
          ],
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_outlined),
                ),
                const SizedBox(height: 18),
                Image.asset(
                  'assets/brand/nguyenindoubt-square-mark.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(height: 18),
                Text(
                  'Patient onboarding',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Demo mode stores your profile, journal entries, sleep imports, and consent state on this device only. Account-backed production storage is not enabled.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onSubmitted: widget.onComplete,
                ),
                const SizedBox(height: 22),
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
      borderRadius: BorderRadius.circular(8),
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
            padding: const EdgeInsets.all(18),
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
