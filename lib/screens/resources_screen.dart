import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
            padding: const EdgeInsets.all(20),
            itemCount: state.resources.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ResourceCard(card: state.resources[index]);
            },
          );
        }

        return GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
              const SizedBox(width: 8),
              StatusPill(
                label: card.category,
                color: card.crisisFlag
                    ? NidColors.ember.withValues(alpha: 0.12)
                    : NidColors.mint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(card.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (constrainBody) Expanded(child: body) else body,
          const SizedBox(height: 10),
          Text(
            card.disclaimer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: card.crisisFlag ? NidColors.ember : NidColors.canopy,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(20),
      children: [
        const BrandHeader(
          title: 'Safety and limits',
          subtitle: 'A companion can hold patterns. It cannot hold a crisis.',
          trailing: StatusPill(label: '988 / 911', icon: Icons.call_outlined),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use urgent support for danger, self-harm risk, harm to someone else, psychosis, intoxication, or when staying safe is uncertain.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
        const SizedBox(height: 16),
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
