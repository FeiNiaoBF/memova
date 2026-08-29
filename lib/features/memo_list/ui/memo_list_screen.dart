import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../memo_list_providers.dart';
import '../relative_time.dart';

/// The home screen: live memos, newest-updated first (user stories 1-2).
class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(liveMemosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Memova')),
      body: memosAsync.when(
        data: (memos) =>
            memos.isEmpty ? const _EmptyState() : _MemoList(memos: memos),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}

class _MemoList extends StatelessWidget {
  const _MemoList({required this.memos});

  final List<Memo> memos;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: memos.length,
      itemBuilder: (context, index) => _MemoRow(memo: memos[index]),
    );
  }
}

class _MemoRow extends StatelessWidget {
  const _MemoRow({required this.memo});

  final Memo memo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        memo.body.split('\n').first,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(relativeTime(memo.updatedAt)),
    );
  }
}

/// First launch, nothing in the database yet (user story 22).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('No memos yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your memos will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
