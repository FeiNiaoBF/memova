import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../../../data/providers.dart';
import '../../../shared/relative_time.dart';
import '../../memo_editor/memo_editor_providers.dart';
import '../../memo_editor/ui/memo_editor_screen.dart';
import '../../trash/ui/trash_screen.dart';
import '../memo_list_providers.dart';

/// The home screen: live memos, newest-updated first (user stories 1-2),
/// with a searchable app bar (#7).
class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(liveMemosProvider);
    final query = ref.watch(searchQueryProvider);
    final searching = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memova'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _openSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Trash',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TrashScreen(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MemoEditorScreen(args: MemoEditorArgs()),
            ),
          );
        },
        tooltip: 'New memo',
        child: const Icon(Icons.add),
      ),
      body: memosAsync.when(
        data: (memos) => memos.isEmpty
            ? (searching ? const _NoResults() : const _EmptyState())
            : _MemoList(memos: memos),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }

  /// Pushes a full-screen search route (search field + filtered list).
  void _openSearch(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchScreen(),
      ),
    );
  }
}

/// Full-screen search: a field on top, the live-filtered List below (#7).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final memosAsync = ref.watch(liveMemosProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search memos',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).update(value),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () => ref.read(searchQueryProvider.notifier).update(''),
            ),
        ],
      ),
      body: memosAsync.when(
        data: (memos) =>
            memos.isEmpty ? const _NoResults() : _MemoList(memos: memos),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}

class _MemoList extends ConsumerWidget {
  const _MemoList({required this.memos});

  final List<Memo> memos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(databaseProvider).memosDao;

    return ListView.builder(
      itemCount: memos.length,
      itemBuilder: (context, index) {
        final memo = memos[index];
        return Dismissible(
          key: ValueKey(memo.id),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          confirmDismiss: (_) => _trashWithUndo(context, dao, memo),
          child: _MemoRow(
            memo: memo,
            onTap: () => _openEditor(context, memo),
          ),
        );
      },
    );
  }

  /// Trash the memo and offer an Undo. Returns false so the row snaps back;
  /// the reactive stream then removes it once `trashedAt` lands.
  Future<bool> _trashWithUndo(
    BuildContext context,
    MemosDao dao,
    Memo memo,
  ) async {
    await dao.trashMemo(memo.id);
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Memo moved to Trash'),
        action: SnackBarAction(
          label: 'Undo',
          // Restore leaves updatedAt untouched, so the memo returns
          // exactly where it was.
          onPressed: () => dao.restoreMemo(memo.id),
        ),
      ),
    );
    return false;
  }

  void _openEditor(BuildContext context, Memo memo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoEditorScreen(
          args: MemoEditorArgs(memoId: memo.id, initialBody: memo.body),
        ),
      ),
    );
  }
}

class _MemoRow extends StatelessWidget {
  const _MemoRow({required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        memo.body.split('\n').first,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(relativeTime(memo.updatedAt)),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
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

/// A search query matched nothing (user story 18/19).
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No memos match',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
