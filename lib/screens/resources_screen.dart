import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/crisis_launcher.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        if (columns == 1) {
          return ListView.separated(
            padding: const EdgeInsets.all(NidSpace.xl),
            itemCount: state.resources.length,
            separatorBuilder: (_, _) => const SizedBox(height: NidSpace.m),
            itemBuilder: (context, index) {
              return _ResourceCard(card: state.resources[index]);
            },
          );
        }

        return GridView.count(
          padding: const EdgeInsets.all(NidSpace.xl),
          crossAxisCount: columns,
          crossAxisSpacing: NidSpace.m,
          mainAxisSpacing: NidSpace.m,
          childAspectRatio: 1.12,
          children: [
            for (final card in state.resources)
              _ResourceCard(card: card, constrainBody: true),
          ],
        );
      },
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.card, this.constrainBody = false});

  final ResourceCard card;
  final bool constrainBody;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      card.body,
      overflow: constrainBody ? TextOverflow.fade : TextOverflow.visible,
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: constrainBody ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                card.crisisFlag
                    ? Icons.emergency_outlined
                    : Icons.local_florist_outlined,
                color: card.crisisFlag ? context.nid.ember : context.nid.canopy,
              ),
              const SizedBox(width: NidSpace.s),
              StatusPill(
                label: card.category,
                tone: card.crisisFlag ? PillTone.flag : PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: NidSpace.m),
          Text(card.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: NidSpace.s),
          if (constrainBody) Expanded(child: body) else body,
          const SizedBox(height: NidSpace.m),
          Text(
            card.disclaimer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: card.crisisFlag ? context.nid.ember : context.nid.canopy,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key, this.launcher = const UrlCrisisLauncher()});

  final CrisisLauncher launcher;

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  /// Numbers whose launch could not be handled (web / no dialer) — surfaced as
  /// selectable text so the user can still act. Never auto-dials.
  final Set<String> _unlaunchable = <String>{};

  Future<void> _launch(Uri uri, String number) async {
    final launched = await widget.launcher.launch(uri);
    if (!launched && mounted) {
      setState(() => _unlaunchable.add(number));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackNumbers = _unlaunchable.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        const BrandHeader(
          title: 'Safety and limits',
          subtitle: 'A companion can hold patterns. It cannot hold a crisis.',
          trailing: StatusPill(
            label: '988 / 911',
            tone: PillTone.neutral,
            icon: Icons.call_outlined,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use urgent support for danger, self-harm risk, harm to someone else, psychosis, intoxication, or when staying safe is uncertain.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: NidSpace.l),
              Wrap(
                spacing: NidSpace.m,
                runSpacing: NidSpace.m,
                children: [
                  FilledButton.icon(
                    onPressed: () => _launch(Uri.parse('tel:988'), '988'),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call 988'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launch(Uri.parse('sms:988'), '988'),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Text 988'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _launch(Uri.parse('tel:911'), '911'),
                    icon: const Icon(Icons.local_hospital_outlined),
                    label: const Text('Call 911'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.nid.ember,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NidSpace.m),
              Text(
                'The 988 Suicide and Crisis Lifeline supports urgent emotional distress or self-harm concern in the U.S. — call or text any time.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: NidSpace.s),
              Text(
                'For immediate danger, call 911 or go to the nearest emergency department. Use local emergency services if you are outside the U.S.',
                style: theme.textTheme.bodyMedium,
              ),
              if (fallbackNumbers.isNotEmpty) ...[
                const SizedBox(height: NidSpace.m),
                Text(
                  'This device could not open the dialer. You can still reach '
                  'these lines directly:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NidSpace.s),
                for (final number in fallbackNumbers)
                  Padding(
                    padding: const EdgeInsets.only(top: NidSpace.xs),
                    child: SelectableText(
                      number,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        const SectionCard(
          child: Text(
            'NguyenInDoubt does not provide diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging in this MVP.',
          ),
        ),
      ],
    );
  }
}
