import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _moodTag = 'steady';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const BrandHeader(
          title: 'Private journal',
          subtitle:
              'The note can be honest because it is not part of the chart.',
          trailing: StatusPill(
            label: 'clinician hidden',
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New entry', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'What shifted?'),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'steady', label: Text('Steady')),
                    ButtonSegment(value: 'uneasy', label: Text('Uneasy')),
                    ButtonSegment(value: 'low', label: Text('Low')),
                  ],
                  selected: {_moodTag},
                  onSelectionChanged: (selected) {
                    setState(() => _moodTag = selected.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Save privately'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...widget.state.journalEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      StatusPill(label: entry.moodTag ?? 'private'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(entry.body),
                  const SizedBox(height: 10),
                  Text(
                    '${shortDate(entry.createdAt)} - private by default',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: NidColors.canopy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      return;
    }

    await widget.state.addJournalEntry(
      title: title,
      body: body,
      moodTag: _moodTag,
    );
    _titleController.clear();
    _bodyController.clear();
  }
}
