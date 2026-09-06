import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../../../data/providers.dart';
import '../../../shared/relative_time.dart';
import '../trash_providers.dart';

/// The Trash: everything deleted within the last 30 days (user stories
/// 12-16). Restore, permanent delete, and empty-all behind a confirmation —
/// the app's single confirmation dialog (DESIGN.md #7 policy).
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashedMemosProvider);
    final dao = ref.read(databaseProvider).memosDao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空回收站',
            onPressed: trashedAsync.value?.isNotEmpty ?? false
                ? () => _confirmEmpty(context, dao)
                : null,
          ),
        ],
      ),
      body: trashedAsync.when(
        data: (trashed) => trashed.isEmpty
            ? const Center(child: Text('回收站是空的'))
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
        title: const Text('清空回收站？'),
        content: const Text(
          '回收站里的每条备忘都会被永久删除，无法撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
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
      itemCount: trashed.length + 1, // + footer note
      itemBuilder: (context, index) {
        if (index == trashed.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              '回收站里的备忘 30 天后自动清除',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          );
        }
        final memo = trashed[index];
        return ListTile(
          title: Text(
            memo.body.split('\n').first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('已删除 ${relativeTime(memo.trashedAt!)}'),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'restore':
                  dao.restoreMemo(memo.id);
                case 'delete':
                  // Deliberately unconfirmed (DESIGN.md #7 policy): the Trash
                  // itself is the safety buffer, and confirmations are
                  // reserved for emptying the whole Trash.
                  dao.deleteMemo(memo.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'restore',
                child: Text('恢复'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('永久删除'),
              ),
            ],
          ),
        );
      },
    );
  }
}
