/// Phase 17 Settings screens: Goals (52) and Notifications (54).
///
/// Both are reached from the Profile tab's Preferences group by a gentle fade
/// route (project motion rule) and read/write the patient's on-device
/// [UserPreferences]. Voice stays calm and non-diagnostic: goals shape
/// guidance only, never scores; notifications are "never streaks, never
/// guilt". Nothing here schedules a real OS notification or runs analytics —
/// the toggles record a stored preference only.
library;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'detail_screens.dart';
import 'tab_shells.dart';

/// Pushes the Goals settings screen (52) as a gentle fade, rebuilding on state
/// changes so a stepper tap re-reads the persisted value live.
void openGoalsSettings(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => GoalsSettingsScreen(state: state),
      ),
    ),
  );
}

/// Pushes the Notifications settings screen (54) as a gentle fade, rebuilding
/// on state so a toggle reflects the persisted preference immediately.
void openNotificationSettings(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => NotificationSettingsScreen(state: state),
      ),
    ),
  );
}

/// Formats minutes-since-midnight as a compact "10:30p" style label matching
/// the mock's time pills.
String _clockLabel(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour24 = normalized ~/ 60;
  final minute = normalized % 60;
  final period = hour24 >= 12 ? 'p' : 'a';
  var hour12 = hour24 % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  final mm = minute.toString().padLeft(2, '0');
  return '$hour12:$mm$period';
}

/// The Goals & targets settings screen (52): a sleep goal stepper and an
/// activity step-target stepper, each with a calm data-informed hint drawn
/// from the patient's own recent averages. Goals shape guidance only — the
/// closing note makes that explicit — and never change scores.
class GoalsSettingsScreen extends StatelessWidget {
  const GoalsSettingsScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  static const int _sleepStepMinutes = 15;
  static const int _sleepMinMinutes = 5 * 60; // 5h floor
  static const int _sleepMaxMinutes = 11 * 60; // 11h ceiling
  static const int _stepStep = 500;
  static const int _stepMin = 2000;
  static const int _stepMax = 20000;

  UserPreferences get _prefs => state.preferences;

  void _bumpSleep(int deltaMinutes) {
    final next = (_prefs.sleepGoalMinutes + deltaMinutes).clamp(
      _sleepMinMinutes,
      _sleepMaxMinutes,
    );
    state.updatePreferences(_prefs.copyWith(sleepGoalMinutes: next));
  }

  void _bumpSteps(int delta) {
    final next = (_prefs.stepTarget + delta).clamp(_stepMin, _stepMax);
    state.updatePreferences(_prefs.copyWith(stepTarget: next));
  }

  /// The sleep hint: leads with the patient's own 30-night average when there
  /// is one, then the steady-not-shaming encouragement. Honest empty copy
  /// before any import (no fabricated number).
  String get _sleepHint {
    final avg = state.recentSleepAverageHours;
    if (avg == null) {
      return 'Once you import a few nights, this shows your own recent '
          'average. Small, steady increases stick better than big jumps.';
    }
    return 'Your recent nights average ${_durationLabel((avg * 60).round())}. '
        'Small, steady increases stick better than big jumps.';
  }

  /// The activity hint: leads with the patient's own recent average when there
  /// is one. Observational, never shaming.
  String get _activityHint {
    final avg = state.recentActivityAverageKcal;
    if (avg == null) {
      return 'After a wearable read, this reflects your own recent activity. '
          'A good stretch goal stays within reach.';
    }
    return 'Your recent days average about ${avg.round()} kcal of movement. '
        'A good stretch goal stays within reach.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NidColors.fog,
        title: const Text('Goals & targets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NidSpace.l),
        children: [
          const SectionKicker('Sleep'),
          const SizedBox(height: NidSpace.m),
          _GoalCard(
            value: _durationLabel(_prefs.sleepGoalMinutes),
            valueLabel: 'nightly sleep goal',
            hint: _sleepHint,
            onDecrement: _prefs.sleepGoalMinutes > _sleepMinMinutes
                ? () => _bumpSleep(-_sleepStepMinutes)
                : null,
            onIncrement: _prefs.sleepGoalMinutes < _sleepMaxMinutes
                ? () => _bumpSleep(_sleepStepMinutes)
                : null,
          ),
          const SizedBox(height: NidSpace.xl),

          const SectionKicker('Activity'),
          const SizedBox(height: NidSpace.m),
          _GoalCard(
            value: _stepLabel(_prefs.stepTarget),
            valueLabel: 'daily step target',
            hint: _activityHint,
            onDecrement: _prefs.stepTarget > _stepMin
                ? () => _bumpSteps(-_stepStep)
                : null,
            onIncrement: _prefs.stepTarget < _stepMax
                ? () => _bumpSteps(_stepStep)
                : null,
          ),
          const SizedBox(height: NidSpace.xl),

          Text(
            'Goals shape guidance only — they never change your scores.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: NidColors.faint),
          ),
        ],
      ),
    );
  }
}

/// A whole-hours + minutes label for a minute count ("8h 00m", "7h 30m").
String _durationLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final mm = m.toString().padLeft(2, '0');
  return '${h}h ${mm}m';
}

/// A grouped step-target label ("9,000").
String _stepLabel(int steps) {
  final text = steps.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}

/// The goal card (mock `.card` + `.goal`): a big canopy readout with its
/// label, a − / + stepper pair, and a hairline-topped data-informed hint.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.value,
    required this.valueLabel,
    required this.hint,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String value;
  final String valueLabel;
  final String hint;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.68,
                        color: NidColors.canopy,
                      ),
                    ),
                    const SizedBox(height: NidSpace.xs),
                    Text(
                      valueLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NidColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              _StepButton(
                icon: Icons.remove,
                semanticLabel: 'Decrease $valueLabel',
                onTap: onDecrement,
              ),
              const SizedBox(width: NidSpace.s),
              _StepButton(
                icon: Icons.add,
                semanticLabel: 'Increase $valueLabel',
                filled: true,
                onTap: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: NidSpace.l),
          Container(height: 1, color: NidColors.canopy.withValues(alpha: 0.14)),
          const SizedBox(height: NidSpace.l),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: NidColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 40x40 stepper button (mock `.sbtn`): outlined on fog for decrement, a
/// canopy-filled pill for increment. Disabled at the clamp bounds.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = filled ? NidColors.canopy : NidColors.fog;
    final foreground = filled ? Colors.white : NidColors.canopy;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(NidRadius.m12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NidRadius.m12),
                border: Border.all(
                  color: filled
                      ? NidColors.canopy
                      : NidColors.canopy.withValues(alpha: 0.14),
                ),
              ),
              child: Icon(icon, size: 20, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Notifications settings screen (54): Daily + Signals toggle groups and a
/// Quiet hours card. Every toggle writes a stored preference only — the app
/// does not schedule OS notifications or run analytics. The closing note keeps
/// the promise: "never streaks, never guilt".
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  UserPreferences get _prefs => state.preferences;

  void _save(UserPreferences next) => state.updatePreferences(next);

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NidColors.fog,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NidSpace.l),
        children: [
          const SectionKicker('Daily'),
          const SizedBox(height: NidSpace.m),
          _ToggleGroup(
            rows: [
              _ToggleRow(
                label: 'Morning reading',
                description: 'One note when your scores are ready',
                value: prefs.morningReading,
                onChanged: (v) => _save(prefs.copyWith(morningReading: v)),
              ),
              _ToggleRow(
                label: 'Evening wind-down',
                description: 'A reminder ahead of your bedtime window',
                value: prefs.eveningWindDown,
                onChanged: (v) => _save(prefs.copyWith(eveningWindDown: v)),
              ),
              _ToggleRow(
                label: 'Weekly report',
                description: "Sunday summary of the week's trends",
                value: prefs.weeklyReport,
                onChanged: (v) => _save(prefs.copyWith(weeklyReport: v)),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.xl),

          const SectionKicker('Signals'),
          const SizedBox(height: NidSpace.m),
          _ToggleGroup(
            rows: [
              _ToggleRow(
                label: 'Out-of-range alerts',
                description: 'Heart rate or temperature outside your range',
                value: prefs.outOfRangeAlerts,
                onChanged: (v) => _save(prefs.copyWith(outOfRangeAlerts: v)),
              ),
              _ToggleRow(
                label: 'Goal milestones',
                description: 'When you reach a target early',
                value: prefs.goalMilestones,
                onChanged: (v) => _save(prefs.copyWith(goalMilestones: v)),
              ),
              _ToggleRow(
                label: 'Ring battery & sync',
                description: 'Low charge or a missed sync',
                value: prefs.ringBatterySync,
                onChanged: (v) => _save(prefs.copyWith(ringBatterySync: v)),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.xl),

          const SectionKicker('Quiet hours'),
          const SizedBox(height: NidSpace.m),
          _QuietHoursCard(
            enabled: prefs.quietHoursEnabled,
            fromLabel: _clockLabel(prefs.quietHoursFromMinutes),
            untilLabel: _clockLabel(prefs.quietHoursUntilMinutes),
            onChanged: (v) => _save(prefs.copyWith(quietHoursEnabled: v)),
          ),
          const SizedBox(height: NidSpace.xl),

          Text(
            "We only write when there's something worth knowing — never "
            'streaks, never guilt.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: NidColors.faint),
          ),
        ],
      ),
    );
  }
}

/// The Do-not-disturb quiet-hours card (mock `.quiet`): a mint icon tile, a
/// title/subtitle, the enable toggle, and the From / Until time pills. Times
/// are display-only stored preferences (a real time picker lands with delivery
/// scheduling in a later phase).
class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({
    required this.enabled,
    required this.fromLabel,
    required this.untilLabel,
    required this.onChanged,
  });

  final bool enabled;
  final String fromLabel;
  final String untilLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NidColors.mint,
                  borderRadius: BorderRadius.circular(NidRadius.tile),
                ),
                child: const Icon(
                  Icons.nightlight_outlined,
                  size: 18,
                  color: NidColors.canopy,
                ),
              ),
              const SizedBox(width: NidSpace.m),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do not disturb',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: NidColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nothing arrives during these hours',
                      style: TextStyle(fontSize: 12, color: NidColors.slate),
                    ),
                  ],
                ),
              ),
              NidToggle(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: NidSpace.l),
          Row(
            children: [
              Expanded(
                child: _TimePill(label: 'From', time: fromLabel),
              ),
              const SizedBox(width: NidSpace.s),
              Expanded(
                child: _TimePill(label: 'Until', time: untilLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: NidSpace.m),
      decoration: BoxDecoration(
        color: NidColors.fog,
        borderRadius: BorderRadius.circular(NidRadius.m12),
        border: Border.all(color: NidColors.canopy.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: NidColors.faint,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: NidColors.canopy,
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded white card wrapping hairline-divided toggle rows — the mock's
/// `.group` container for settings toggles.
class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({required this.rows});

  final List<_ToggleRow> rows;

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

/// A settings row with a label, a calm description, and a trailing [NidToggle]
/// (mock `.row` + `.sw`).
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

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
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NidColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: NidColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NidSpace.m),
          NidToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
