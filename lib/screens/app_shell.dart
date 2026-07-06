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
  bool _started = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        if (!_started) {
          return _OnboardingScreen(
            onPatient: () async {
              await widget.state.continueAsPatient();
              setState(() {
                _started = true;
                _selectedIndex = 0;
              });
            },
            onClinician: () async {
              await widget.state.continueAsClinician();
              setState(() {
                _started = true;
                _selectedIndex = 0;
              });
            },
          );
        }

        if (widget.state.isClinician) {
          return Scaffold(
            appBar: _AppBar(
              state: widget.state,
              onPatientMode: _switchToPatient,
              onClinicianMode: _switchToClinician,
            ),
            body: ClinicianDashboard(state: widget.state),
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
              appBar: _AppBar(
                state: widget.state,
                onPatientMode: _switchToPatient,
                onClinicianMode: _switchToClinician,
              ),
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
                  Expanded(child: screens[_selectedIndex]),
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

  Future<void> _switchToPatient() async {
    await widget.state.continueAsPatient();
    setState(() => _selectedIndex = 0);
  }

  Future<void> _switchToClinician() async {
    await widget.state.continueAsClinician();
    setState(() => _selectedIndex = 0);
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    required this.state,
    required this.onPatientMode,
    required this.onClinicianMode,
  });

  final NguyenInDoubtState state;
  final VoidCallback onPatientMode;
  final VoidCallback onClinicianMode;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
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
          const Text('NguyenInDoubt'),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.person_outline),
                label: Text('Patient'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.badge_outlined),
                label: Text('Clinician'),
              ),
            ],
            selected: {state.isClinician},
            onSelectionChanged: (selection) {
              selection.first ? onClinicianMode() : onPatientMode();
            },
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
              label: const Text('Clinician demo'),
            ),
          ],
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
