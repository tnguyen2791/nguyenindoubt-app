import 'package:flutter/material.dart';

import '../services/health_data_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';

/// The Phase 10 guided first-run layer for the empty patient dashboard
/// (ONB-04).
///
/// [PatientDashboard] renders this in place of the metric tiles and the
/// sleep-trend card while `state.summaries` is empty: one calm hero with a
/// single primary action instead of a graveyard of `--` placeholders. The
/// body copy doubles as sleep-only permission priming — it states the
/// promise (sleep only, never the journal) before any OS prompt appears.
///
/// Deliberately modular and self-contained so Phase 11 (dashboard hierarchy
/// + insights) can extend or replace this layer without touching the data
/// dashboard.
class PatientFirstRun extends StatelessWidget {
  const PatientFirstRun({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    final importDisabled =
        state.isBusy ||
        state.healthPermissionStatus == HealthPermissionStatus.unavailable;

    return SectionCard(
      padding: const EdgeInsets.all(NidSpace.xl),
      child: Column(
        children: [
          Icon(Icons.bedtime_outlined, size: 34, color: context.nid.canopy),
          const SizedBox(height: NidSpace.s),
          Text(
            "Start with last night's sleep",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              letterSpacing: -0.48,
            ),
          ),
          const SizedBox(height: NidSpace.s),
          Text(
            'Import requests sleep-only access before anything is read — '
            'we only ever look at your sleep, never your journal.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.nid.slate),
          ),
          const SizedBox(height: NidSpace.l),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: importDisabled ? null : state.importMockSleep,
              icon: state.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Import sleep'),
            ),
          ),
        ],
      ),
    );
  }
}
