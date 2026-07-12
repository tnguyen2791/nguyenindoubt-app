/// Phase 17 Notifications feed (design 48).
///
/// A calm, display-only list of Today / Yesterday / This week notification
/// items. These are seeded/static for now — there is no real delivery, no
/// scheduling, and no analytics. Items that reference an in-app screen open it
/// by a gentle fade route (readiness/sleep detail, weekly report, trends,
/// sharing placeholder); the rest are read-only. Voice is observational and
/// non-diagnostic per the
/// brand: "worth watching, not worrying", "never streaks, never guilt".
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'detail_screens.dart';
import 'tab_shells.dart';
import 'weekly_report_screen.dart';

/// Where a notification item leads when tapped. Kept as a small enum so the
/// seed data stays plain and the screen owns the (context-dependent)
/// navigation. `none` items are read-only.
enum NotificationTarget {
  none,
  readiness,
  sleep,
  trends,
  sharing,
  weeklyReport,
}

/// One calm notification item (seeded/static). Display-only — no real delivery.
class NotificationItem {
  const NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
    this.target = NotificationTarget.none,
    this.unread = false,
    this.warm = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Compact timestamp label shown on the row's trailing edge ("7:02a", "Sun").
  final String when;

  /// The in-app screen this item opens, if any.
  final NotificationTarget target;

  /// Whether the item shows the ember unread dot (Today items in the mock).
  final bool unread;

  /// Whether the icon tile uses the warm ember treatment (a flagged signal).
  final bool warm;
}

/// One dated section of the feed (Today / Yesterday / This week).
class NotificationSection {
  const NotificationSection({required this.label, required this.items});

  final String label;
  final List<NotificationItem> items;
}

/// The seeded feed, matching design 48's three sections and calm copy. Static
/// content — display-only, no real delivery. Sharing items point at a calm
/// placeholder until the P18 sharing flow lands.
const List<NotificationSection> seedNotificationSections = [
  NotificationSection(
    label: 'Today',
    items: [
      NotificationItem(
        icon: Icons.group_outlined,
        title: 'Dr. Nguyen accepted your request',
        body:
            "Sharing starts with tomorrow morning's reading — scores & trends "
            'and sleep detail, exactly as you chose. Review or pause anytime.',
        when: '7:41a',
        target: NotificationTarget.sharing,
        unread: true,
      ),
      NotificationItem(
        icon: Icons.wb_sunny_outlined,
        title: 'Your morning reading is ready',
        body:
            'Readiness 82 — balanced. A protective night and a low resting '
            'heart rate.',
        when: '7:02a',
        target: NotificationTarget.readiness,
        unread: true,
      ),
      NotificationItem(
        icon: Icons.nightlight_outlined,
        title: 'Bedtime is drifting later',
        body:
            "You've gone to bed about 40 minutes later than usual for three "
            'nights. An earlier wind-down tonight could help.',
        when: '7:02a',
        target: NotificationTarget.sleep,
        unread: true,
      ),
    ],
  ),
  NotificationSection(
    label: 'Yesterday',
    items: [
      NotificationItem(
        icon: Icons.group_off_outlined,
        title: "Your sharing request wasn't accepted",
        body:
            'Dr. Nguyen declined for now — nothing was ever shared. You can '
            'ask again anytime, or check with their office first.',
        when: '4:12p',
        target: NotificationTarget.sharing,
      ),
      NotificationItem(
        icon: Icons.local_fire_department_outlined,
        title: 'Goal reached early',
        body:
            'You hit your movement goal by mid-afternoon — nicely paced across '
            'the day.',
        when: '3:41p',
      ),
      NotificationItem(
        icon: Icons.error_outline,
        title: 'Elevated overnight heart rate',
        body:
            'Resting heart rate ran above your range last night. A late meal '
            'or alcohol can do this — worth watching, not worrying.',
        when: '7:15a',
        target: NotificationTarget.readiness,
        warm: true,
      ),
    ],
  ),
  NotificationSection(
    label: 'This week',
    items: [
      NotificationItem(
        icon: Icons.calendar_today_outlined,
        title: 'Your weekly report is ready',
        body:
            'A steadier week — bedtimes tightened up and readiness climbed. '
            'One takeaway inside.',
        when: 'Sun',
        target: NotificationTarget.weeklyReport,
      ),
      NotificationItem(
        icon: Icons.check_circle_outline,
        title: 'Baseline complete',
        body:
            'Fourteen days of calibration are done. Your scores now compare '
            'you to your own typical range.',
        when: 'Mon',
      ),
      NotificationItem(
        icon: Icons.trending_up_outlined,
        title: 'Sleep quality trending up',
        body:
            'Average sleep score rose 6 points this week, mostly from more '
            'consistent bedtimes.',
        when: 'Sun',
        target: NotificationTarget.trends,
      ),
    ],
  ),
];

/// Pushes the Notifications feed (48) as a gentle fade, rebuilding on state so
/// a target that reads live data (readiness/sleep detail) stays current.
void openNotificationsFeed(BuildContext context, NguyenInDoubtState state) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      AnimatedBuilder(
        animation: state,
        builder: (_, _) => NotificationsFeedScreen(state: state),
      ),
    ),
  );
}

/// The Notifications feed screen (48): Today / Yesterday / This week sections
/// of calm, non-diagnostic items. Display-only — tapping an item opens its
/// referenced in-app screen where one exists.
class NotificationsFeedScreen extends StatelessWidget {
  const NotificationsFeedScreen({
    super.key,
    required this.state,
    this.sections = seedNotificationSections,
  });

  final NguyenInDoubtState state;
  final List<NotificationSection> sections;

  void _open(BuildContext context, NotificationTarget target) {
    switch (target) {
      case NotificationTarget.none:
        return;
      case NotificationTarget.readiness:
        openReadinessDetail(context, state);
      case NotificationTarget.sleep:
        openSleepDetail(context, state);
      case NotificationTarget.weeklyReport:
        // The weekly report reads the patient's own week — a real pushed
        // screen now (P19), no longer a placeholder.
        openWeeklyReport(context, state);
      case NotificationTarget.trends:
        // Trends is a top-level tab, not a pushed route; a calm sheet keeps the
        // item honest without faking a second Trends surface here.
        _showTargetPlaceholder(
          context,
          title: 'Open Trends',
          body:
              'This links to your Trends tab, where the week\'s sleep, '
              'readiness, and activity live.',
        );
      case NotificationTarget.sharing:
        // The sharing flow lands in P18 — a calm placeholder for now.
        _showTargetPlaceholder(
          context,
          title: 'Sharing',
          body:
              'Provider sharing is on the way. Nothing is shared until you '
              'set it up and choose exactly what to share.',
        );
    }
  }

  void _showTargetPlaceholder(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NidColors.fog,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NidSpace.l),
        children: [
          for (final section in sections) ...[
            SectionKicker(section.label),
            const SizedBox(height: NidSpace.kickerBottom),
            _NotificationCard(
              items: section.items,
              onOpen: (target) => _open(context, target),
            ),
            const SizedBox(height: NidSpace.kickerTop),
          ],
          const SizedBox(height: NidSpace.s),
          Text(
            "That's everything. We only write when there's something worth "
            'knowing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.6,
              color: NidColors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

/// A white card wrapping hairline-divided notification rows (mock `.card`).
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.items, required this.onOpen});

  final List<NotificationItem> items;
  final ValueChanged<NotificationTarget> onOpen;

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
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: NidColors.canopy.withValues(alpha: 0.14),
              ),
            _NotificationRow(item: items[i], onOpen: onOpen),
          ],
        ],
      ),
    );
  }
}

/// One notification row: an icon tile (warm ember for flagged signals), the
/// title + timestamp, the calm body, and an ember unread dot for unread items.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onOpen});

  final NotificationItem item;
  final ValueChanged<NotificationTarget> onOpen;

  @override
  Widget build(BuildContext context) {
    final tappable = item.target != NotificationTarget.none;
    final tileColor = item.warm
        ? NidColors.ember.withValues(alpha: 0.14)
        : NidColors.mint;
    final iconColor = item.warm ? NidColors.ember : NidColors.canopy;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NidSpace.l,
        vertical: NidSpace.l - 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread dot sits just left of the icon tile.
          SizedBox(
            width: 10,
            child: item.unread
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: NidColors.ember,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(NidRadius.tile),
            ),
            child: Icon(item.icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: NidSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: NidColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: NidSpace.s),
                    Text(
                      item.when,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NidColors.faint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: NidColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!tappable) {
      return row;
    }
    return InkWell(onTap: () => onOpen(item.target), child: row);
  }
}
