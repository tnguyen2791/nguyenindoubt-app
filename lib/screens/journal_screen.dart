import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
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
      padding: const EdgeInsets.all(NidSpace.xl),
      children: [
        const BrandHeader(
          title: 'Private journal',
          subtitle:
              'The note can be honest because it is not part of the chart.',
          trailing: StatusPill(
            label: 'clinician hidden',
            tone: PillTone.private,
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: NidSpace.l),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New entry', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NidSpace.m),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: NidSpace.m),
              TextField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'What shifted?'),
              ),
              const SizedBox(height: NidSpace.m),
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
              const SizedBox(height: NidSpace.m),
              FilledButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Save privately'),
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        if (widget.state.journalEntries.isEmpty)
          const EmptyState(
            icon: Icons.lock_outline,
            title: 'Your journal stays private',
            body: 'Start your first entry — only you can read it.',
          )
        else
          ...widget.state.journalEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: NidSpace.m),
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
                        StatusPill(
                          label: entry.moodTag ?? 'private',
                          tone: PillTone.neutral,
                        ),
                        const SizedBox(width: NidSpace.xs),
                        IconButton(
                          onPressed: () => _confirmDelete(entry.id),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete entry',
                          color: NidColors.slate,
                        ),
                      ],
                    ),
                    const SizedBox(height: NidSpace.s),
                    Text(entry.body),
                    const SizedBox(height: NidSpace.m),
                    Text(
                      '${shortDate(entry.createdAt)} - private by default',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: NidColors.canopy),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(String entryId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text(
          'This entry is permanently removed from this device. It is not '
          'clinical and is not monitored — only you can read it, and there is '
          'no undo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete entry'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.state.deleteJournalEntry(entryId);
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
