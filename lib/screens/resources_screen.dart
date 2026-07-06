import 'package:flutter/material.dart';

import '../models/app_models.dart';
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
                color: card.crisisFlag ? NidColors.ember : NidColors.canopy,
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
              color: card.crisisFlag ? NidColors.ember : NidColors.canopy,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: NidSpace.l),
              Wrap(
                spacing: NidSpace.m,
                runSpacing: NidSpace.m,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showSafetyInstructions(
                      context,
                      title: 'Call or text 988',
                      body:
                          'Use the 988 Suicide and Crisis Lifeline for urgent emotional distress or self-harm concern in the U.S. Call or text 988 now.',
                    ),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call or text 988'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showSafetyInstructions(
                      context,
                      title: 'Emergency care',
                      body:
                          'For immediate danger, call 911 in the U.S. or go to the nearest emergency department. Use local emergency services if you are outside the U.S.',
                    ),
                    icon: const Icon(Icons.local_hospital_outlined),
                    label: const Text('Emergency care'),
                  ),
                ],
              ),
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

  Future<void> _showSafetyInstructions(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
