import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../../../data/providers.dart';
import '../../../dev/theme_gallery_screen.dart';
import '../../../shared/relative_time.dart';
import '../../../theme/themes.dart';
import '../../memo_editor/memo_editor_providers.dart';
import '../../memo_editor/ui/memo_editor_screen.dart';
import '../../trash/trash_providers.dart';
import '../../trash/ui/trash_screen.dart';
import '../memo_groups.dart';
import '../memo_list_providers.dart';

/// The home screen: live memos grouped by date landmarks (DESIGN.md #3),
/// transparent app bar (#2), searchable (#7).
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
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Theme preview',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeGalleryScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Trash',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TrashScreen()),
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
        data: (memos) {
          if (memos.isEmpty) {
            return searching
                ? const _NoResults()
                : const _ListEmptyState(); // context-switches on trash count
          }
          // Search is finding, not reminiscing — flat list, no landmarks.
          return searching
              ? _MemoList(memos: memos, showTime: true, bottomPadding: 96)
              : _GroupedMemoList(memos: memos);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }
}

/// Full-screen search: a field on top, the live-filtered List below (#7).
/// Flat by design — search is finding, not reminiscing (DESIGN.md logic rule).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final memosAsync = ref.watch(liveMemosProvider);

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(searchQueryProvider.notifier).clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索备忘',
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
                onPressed: () =>
                    ref.read(searchQueryProvider.notifier).update(''),
              ),
          ],
        ),
        body: memosAsync.when(
          data: (memos) => memos.isEmpty
              ? const _NoResults()
              : _MemoList(memos: memos, showTime: true),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Something went wrong: $error')),
        ),
      ),
    );
  }
}

/// The grouped List (#3): date landmark anchors + standard rows.
class _GroupedMemoList extends ConsumerWidget {
  const _GroupedMemoList({required this.memos});

  final List<Memo> memos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(databaseProvider).memosDao;
    final groups = groupMemosByDay(memos);

    final children = <Widget>[];
    for (final group in groups) {
      children.add(
        _GroupHeader(
          title: group.title,
          subtitle: group.subtitle,
          isToday: group.isToday,
        ),
      );
      for (final memo in group.memos) {
        children.add(
          Dismissible(
            key: ValueKey(memo.id),
            direction: DismissDirection.endToStart,
            background: const _DismissBackground(),
            confirmDismiss: (_) => _trashWithUndo(context, dao, memo),
            child: _MemoRow(
              memo: memo,
              showTime: group.isToday,
              onTap: () => _openEditor(context, memo),
            ),
          ),
        );
      }
    }

    // Bottom clearance 96px: the last row must never hide under the FAB.
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }

  Future<bool> _trashWithUndo(
    BuildContext context,
    MemosDao dao,
    Memo memo,
  ) async {
    try {
      await dao.trashMemo(memo.id);
    } catch (_) {
      if (context.mounted) _showDatabaseError(context);
      return false;
    }
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已移到回收站'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => unawaited(
            _runDatabaseAction(context, () => dao.restoreMemo(memo.id)),
          ),
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

/// Flat list (search results) — no landmark anchors.
class _MemoList extends ConsumerWidget {
  const _MemoList({
    required this.memos,
    required this.showTime,
    this.bottomPadding = 0,
  });

  final List<Memo> memos;
  final bool showTime;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(databaseProvider).memosDao;

    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottomPadding),
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
            showTime: showTime,
            onTap: () => _openEditor(context, memo),
          ),
        );
      },
    );
  }

  Future<bool> _trashWithUndo(
    BuildContext context,
    MemosDao dao,
    Memo memo,
  ) async {
    try {
      await dao.trashMemo(memo.id);
    } catch (_) {
      if (context.mounted) _showDatabaseError(context);
      return false;
    }
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已移到回收站'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => unawaited(
            _runDatabaseAction(context, () => dao.restoreMemo(memo.id)),
          ),
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

/// Date landmark anchor (今天 / 昨天 / 8月22日 + weekday cue). Typography,
/// not graphics — the rule line is the only scaffolding.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.subtitle,
    required this.isToday,
  });

  final String title;
  final String subtitle;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: isToday ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 16 / 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

/// The memo row (component #1, DESIGN.md): M3 two-line list idiom — first
/// line semibold as the implicit title, muted preview, right-aligned time.
class _MemoRow extends StatelessWidget {
  const _MemoRow({
    required this.memo,
    required this.showTime,
    required this.onTap,
  });

  final Memo memo;
  final bool showTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lines = memo.body.split('\n');
    final title = lines.first;
    final preview = lines.skip(1).join(' ');
    // Hybrid time rule (#3): today shows relative time; older rows drop it —
    // the group anchor already answers "when". Search rows always show it.
    final time = showTime ? relativeTime(memo.updatedAt) : null;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Row(
        children: [
          if (preview.isNotEmpty)
            Expanded(
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (time != null) ...[
            if (preview.isNotEmpty) const SizedBox(width: 12),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _runDatabaseAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) _showDatabaseError(context);
  }
}

void _showDatabaseError(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
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

/// The List empty state — context-switches on trash content (DESIGN.md #5):
/// nothing anywhere → the onboarding declaration; everything in the Trash →
/// the "都还在" reassurance with the recovery path.
class _ListEmptyState extends ConsumerWidget {
  const _ListEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedCount =
        (ref.watch(trashedMemosProvider).value ?? const []).length;
    final colorScheme = Theme.of(context).colorScheme;

    if (trashedCount > 0) {
      return _EmptyShell(
        hero: Text.rich(TextSpan(text: '都还在。'), style: _heroStyle(context)),
        copy: '备忘在回收站里躺着，30 天内随时可以拿回来。',
        action: FilledButton.tonal(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const TrashScreen())),
          child: const Text('去回收站看看'),
        ),
      );
    }

    return _EmptyShell(
      hero: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: '想到，就'),
            TextSpan(
              text: '写下来',
              style: TextStyle(color: colorScheme.primary),
            ),
            const TextSpan(text: '。'),
          ],
        ),
        style: _heroStyle(context),
      ),
      copy: '无标题、无分类、无网络。\n写下的每一句都只在这台手机上，自动保存。',
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MemoEditorScreen(args: MemoEditorArgs()),
          ),
        ),
        child: const Text('写第一条'),
      ),
    );
  }

  TextStyle _heroStyle(BuildContext context) {
    return TextStyle(
      fontFamily: serifFontFamily,
      fontSize: 31,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}

/// Shared empty-state shell: centered, hero + copy + optional action.
class _EmptyShell extends StatelessWidget {
  const _EmptyShell({
    required this.hero,
    required this.copy,
    required this.action,
  });

  final Widget hero;
  final String copy;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle.merge(child: hero),
            const SizedBox(height: 14),
            Text(
              copy,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            action,
          ],
        ),
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
          Text('没有匹配的备忘', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('试试其他关键词', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
