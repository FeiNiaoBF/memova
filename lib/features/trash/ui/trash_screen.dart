import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../../../data/providers.dart';
import '../../../shared/relative_time.dart';
import '../trash_providers.dart';

/// The Trash: everything deleted within the last 30 days (user stories
/// 12-16). Restore, permanent delete, and empty-all behind a confirmation.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashedMemosProvider);
    final dao = ref.read(databaseProvider).memosDao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty trash',
            onPressed: trashedAsync.value?.isNotEmpty ?? false
                ? () => _confirmEmpty(context, dao)
                : null,
          ),
        ],
      ),
      body: trashedAsync.when(
        data: (trashed) => trashed.isEmpty
            ? const Center(child: Text('Trash is empty'))
            : _TrashList(trashed: trashed),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }

  Future<void> _confirmEmpty(BuildContext context, MemosDao dao) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty trash?'),
        content: const Text(
          'Every memo in the Trash will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await dao.emptyTrash();
    }
  }
}

class _TrashList extends ConsumerWidget {
  const _TrashList({required this.trashed});

  final List<Memo> trashed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(databaseProvider).memosDao;

    return ListView.builder(
      itemCount: trashed.length,
      itemBuilder: (context, index) {
        final memo = trashed[index];
        return ListTile(
          title: Text(
            memo.body.split('\n').first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('Trashed ${relativeTime(memo.trashedAt!)}'),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'restore':
                  dao.restoreMemo(memo.id);
                case 'delete':
                  dao.deleteMemo(memo.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'restore',
                child: Text('Restore'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete forever'),
              ),
            ],
          ),
        );
      },
    );
  }
}
