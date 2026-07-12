import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/trends.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';
import 'detail_screens.dart';
import 'journal_screen.dart';
import 'notifications_feed.dart';
import 'resources_screen.dart';
import 'settings_screens.dart';

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

/// The Trends tab (screens 20/24): a Sleep · Readiness · Activity segmented
/// control and a Week · Month · Quarter range toggle over the real signals,
/// with a score/metric trend line, weekly averages, and a consistency heatmap.
///
/// All three signals derive from persisted, patient-owned data (sleep from the
/// daily summaries, readiness + activity from the readiness series). Ranges
/// beyond available history show the available window calmly; a signal with no
/// data yet shows a calm empty state. Observational, never a diagnosis.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendSignal _signal = TrendSignal.sleep;
  TrendRange _range = TrendRange.month;

  NguyenInDoubtState get _state => widget.state;

  /// The signal's uppercase-noun kicker word ("Sleep score" / "Readiness" /
  /// "Activity") for the trend card, matching the mock's `.k` labels.
  String get _signalNoun => switch (_signal) {
    TrendSignal.sleep => 'Sleep score',
    TrendSignal.readiness => 'Readiness',
    TrendSignal.activity => 'Activity',
  };

  String get _flagLabel => switch (_signal) {
    TrendSignal.sleep => 'short night',
    TrendSignal.readiness => 'low readiness',
    TrendSignal.activity => 'off balance',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = computeTrendData(
      signal: _signal,
      range: _range,
      summaries: _state.summaries,
      readiness: _state.readinessHistory,
    );

    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        Text(
          'Trends',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        _SignalSegmented(
          value: _signal,
          onChanged: (s) => setState(() => _signal = s),
        ),
        const SizedBox(height: NidSpace.m),
        _RangeToggle(
          value: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: NidSpace.l),

        if (data.isEmpty)
          _TrendsEmpty(signal: _signal)
        else ...[
          _TrendCard(data: data, signalNoun: _signalNoun, state: _state),
          const SizedBox(height: NidSpace.l),
          _WeeklyCard(data: data),
          const SizedBox(height: NidSpace.l),
          _ConsistencyCard(data: data, flagLabel: _flagLabel),
        ],
      ],
    );
  }
}

/// The Sleep · Readiness · Activity segmented control — canopy-active pill on a
/// mint track (design `.seg`).
class _SignalSegmented extends StatelessWidget {
  const _SignalSegmented({required this.value, required this.onChanged});

  final TrendSignal value;
  final ValueChanged<TrendSignal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: NidColors.mint,
        borderRadius: BorderRadius.circular(NidRadius.pill),
      ),
      child: Row(
        children: [
          for (final signal in TrendSignal.values)
            Expanded(
              child: _SegButton(
                label: signal.label,
                selected: signal == value,
                onTap: () => onChanged(signal),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(NidRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NidRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: NidSpace.s),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? NidColors.canopy : NidColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Week · Month · Quarter range toggle — outlined pills, canopy-filled when
/// active (design `.range`).
class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});

  final TrendRange value;
  final ValueChanged<TrendRange> onChanged;

  @override
  Widget build(BuildContext context) {
    // Wrap so the three pills never overflow at the narrowest phone width;
    // they still read as a left-aligned row on any real device.
    return Wrap(
      spacing: NidSpace.s,
      runSpacing: NidSpace.s,
      children: [
        for (final range in TrendRange.values)
          _RangePill(
            label: range.label,
            selected: range == value,
            onTap: () => onChanged(range),
          ),
      ],
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? NidColors.canopy : Colors.white,
        borderRadius: BorderRadius.circular(NidRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NidRadius.pill),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NidRadius.pill),
              border: Border.all(
                color: selected
                    ? NidColors.canopy
                    : NidColors.canopy.withValues(alpha: 0.14),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: NidSpace.l,
              vertical: NidSpace.s - 2,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : NidColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The score/metric trend card: a `.k` header + headnote, a three-stat readout
/// (avg / best / avg sleep), and the [TrendLine]. Tapping the Sleep card opens
/// the Sleep detail (21); the Readiness card opens the Readiness detail (28).
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.data,
    required this.signalNoun,
    required this.state,
  });

  final TrendData data;
  final String signalNoun;
  final NguyenInDoubtState state;

  String _fmt(double value) {
    if (data.signal == TrendSignal.activity) {
      return value.round().toString();
    }
    return value.round().toString();
  }

  VoidCallback? _onTap(BuildContext context) {
    switch (data.signal) {
      case TrendSignal.sleep:
        return () => openSleepDetail(context, state);
      case TrendSignal.readiness:
        return () => openReadinessDetail(context, state);
      case TrendSignal.activity:
        return null; // no dedicated detail route yet (P14b/later)
    }
  }

  @override
  Widget build(BuildContext context) {
    final onTap = _onTap(context);
    final card = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SectionKicker(
                  '$signalNoun · ${data.points.length} days',
                ),
              ),
              Text(
                data.headnote,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NidColors.faint,
                ),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.m),
          Row(
            children: [
              Expanded(
                child: _TrendStat(value: _fmt(data.average), label: 'average'),
              ),
              Expanded(
                child: _TrendStat(value: _fmt(data.best), label: 'best'),
              ),
              Expanded(
                child: data.avgSleepHours != null
                    ? _TrendStat(
                        value: data.avgSleepHours!.toStringAsFixed(1),
                        unit: 'h',
                        label: 'avg sleep',
                      )
                    : data.signal == TrendSignal.activity
                    ? _TrendStat(value: data.unit, label: 'active energy')
                    : const _TrendStat(value: 'you', label: 'vs baseline'),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.l),
          TrendLine(points: data.points),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NidRadius.card),
      child: card,
    );
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat({required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.22,
                color: NidColors.ink,
              ),
            ),
            if (unit != null)
              Text(
                unit!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NidColors.slate,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: NidColors.faint),
        ),
      ],
    );
  }
}

/// The weekly-averages card: a `.k` header + `hours`/`avg` note and the
/// [WeeklyAverageBars].
class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.data});

  final TrendData data;

  String get _note => switch (data.signal) {
    TrendSignal.sleep => 'hours',
    TrendSignal.readiness => 'avg score',
    TrendSignal.activity => 'kcal',
  };

  String get _kicker => switch (data.signal) {
    TrendSignal.sleep => 'Weekly sleep avg',
    TrendSignal.readiness => 'Weekly readiness avg',
    TrendSignal.activity => 'Weekly activity avg',
  };

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: SectionKicker(_kicker)),
              Text(
                _note,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NidColors.faint,
                ),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.m),
          WeeklyAverageBars(
            weekly: data.weekly,
            axisMax: data.weeklyAxisMax,
            signal: data.signal,
          ),
        ],
      ),
    );
  }
}

/// The consistency card: a `.k` header + the "24 / 30 on target" note and the
/// [ConsistencyHeatmap].
class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.data, required this.flagLabel});

  final TrendData data;
  final String flagLabel;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(child: SectionKicker('Consistency')),
              Text(
                data.consistencyLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NidColors.faint,
                ),
              ),
            ],
          ),
          const SizedBox(height: NidSpace.m),
          ConsistencyHeatmap(cells: data.cells, flagLabel: flagLabel),
        ],
      ),
    );
  }
}

/// A calm empty state for a signal with no data yet in the selected range —
/// honest, never fabricated. Sleep points users to the import; readiness /
/// activity explain the wearable read.
class _TrendsEmpty extends StatelessWidget {
  const _TrendsEmpty({required this.signal});

  final TrendSignal signal;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (signal) {
      TrendSignal.sleep => (
        'Your sleep trend appears after a few nights',
        'Import from the Today screen, and this becomes an honest score '
            'trend — sleep-only, never a diagnosis.',
      ),
      TrendSignal.readiness => (
        'Readiness trends after a wearable read',
        'Import from the Today screen to read your overnight signals — '
            'readiness compares each day to your own baseline, never a '
            'diagnosis.',
      ),
      TrendSignal.activity => (
        'Activity trends after a wearable read',
        'Once your prior-day activity is read, this shows how movement '
            'settled across the range — observational, never a diagnosis.',
      ),
    };
    return EmptyState(
      icon: Icons.show_chart_outlined,
      title: title,
      body: body,
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
    final prefs = state.preferences;
    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: NidColors.canopy,
                  letterSpacing: -0.52,
                ),
              ),
            ),
            // The notifications feed (48) — a calm bell that opens the
            // display-only Today / Yesterday / This week list.
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => openNotificationsFeed(context, state),
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: NidColors.canopy,
              ),
            ),
          ],
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
              value: _sleepGoalLabel(prefs.sleepGoalMinutes),
              onTap: () => openGoalsSettings(context, state),
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
              value: _notificationsSummary(prefs),
              onTap: () => openNotificationSettings(context, state),
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

/// The Profile "Goals & targets" trailing value: a compact "8h sleep" style
/// label from the persisted sleep goal.
String _sleepGoalLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) {
    return '${h}h sleep';
  }
  return '${h}h ${m}m sleep';
}

/// The Profile "Notifications" trailing summary: "On" when any daily/signal
/// preference is enabled, otherwise "Off". A calm at-a-glance state, matching
/// the mock's `On` value.
String _notificationsSummary(UserPreferences prefs) {
  final anyOn =
      prefs.morningReading ||
      prefs.eveningWindDown ||
      prefs.weeklyReport ||
      prefs.outOfRangeAlerts ||
      prefs.goalMilestones ||
      prefs.ringBatterySync;
  return anyOn ? 'On' : 'Off';
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
