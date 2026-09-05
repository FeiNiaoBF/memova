import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// Debug-only component gallery: renders the app's Material 3 theme across
/// the surfaces needed to judge a color direction. Reachable only in debug
/// builds (kDebugMode entry on the List); never shipped to release.
class ThemeGalleryScreen extends ConsumerWidget {
  const ThemeGalleryScreen({super.key});

  static const _demoMemos = [
    (body: '今晚 7 点取快递：菜鸟驿站 3-2-1809', age: Duration(minutes: 2)),
    (body: '给妈妈回电话', age: Duration(minutes: 30)),
    (body: '买牛奶和鸡蛋\n顺便看看有没有燕麦', age: Duration(hours: 2)),
    (body: '周三下午的项目例会\n带上周的 sprint 数据', age: Duration(hours: 5)),
    (body: 'MacBook 充电器在办公室抽屉里', age: Duration(hours: 26)),
    (body: 'book dentist appointment for next month', age: Duration(days: 2)),
    (body: '房租 4500 转账 + 水电费', age: Duration(days: 4)),
    (body: '研究 MD3 expressive 的 Flutter 落地方式', age: Duration(days: 12)),
    (body: '这个月的读书目标：读完《设计中的设计》', age: Duration(days: 31)),
    (body: 'Q3 旅行计划：杭州两日', age: Duration(days: 60)),
    (body: '周末大扫除', age: Duration(days: 90)),
    (body: '一句话', age: Duration(minutes: 1)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(databaseProvider).memosDao;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Demo data', children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    for (final demo in _demoMemos) {
                      final now = DateTime.now();
                      final created = now.subtract(demo.age);
                      await dao.createMemo(
                        demo.body,
                        createdAt: created,
                        updatedAt: created,
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Seeded 12 demo memos')),
                      );
                    }
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Seed 12 memos'),
                ),
              ],
            ),
          ]),
          _Section('Color roles', children: [
            _SwatchRow(
              label: 'Primary',
              color: colorScheme.primary,
              onColor: colorScheme.onPrimary,
              container: colorScheme.primaryContainer,
              onContainer: colorScheme.onPrimaryContainer,
            ),
            _SwatchRow(
              label: 'Secondary',
              color: colorScheme.secondary,
              onColor: colorScheme.onSecondary,
              container: colorScheme.secondaryContainer,
              onContainer: colorScheme.onSecondaryContainer,
            ),
            _SwatchRow(
              label: 'Tertiary',
              color: colorScheme.tertiary,
              onColor: colorScheme.onTertiary,
              container: colorScheme.tertiaryContainer,
              onContainer: colorScheme.onTertiaryContainer,
            ),
            _SwatchRow(
              label: 'Error',
              color: colorScheme.error,
              onColor: colorScheme.onError,
              container: colorScheme.errorContainer,
              onContainer: colorScheme.onErrorContainer,
            ),
            _SurfaceRow(
              label: 'Surface',
              surface: colorScheme.surface,
              low: colorScheme.surfaceContainerLow,
              base: colorScheme.surfaceContainer,
              high: colorScheme.surfaceContainerHigh,
              text: colorScheme.onSurface,
            ),
          ]),
          _Section('Type scale', children: [
            Text('displaySmall — 备忘', style: textTheme.displaySmall),
            Text('headlineMedium — 备忘', style: textTheme.headlineMedium),
            Text('titleLarge — 备忘', style: textTheme.titleLarge),
            Text('bodyLarge — 一行普通的备忘文字。',
                style: textTheme.bodyLarge),
            Text('bodyMedium — 一行普通的备忘文字。',
                style: textTheme.bodyMedium),
            Text('labelLarge — 备忘', style: textTheme.labelLarge),
          ]),
          _Section('Buttons', children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                FilledButton.tonal(
                    onPressed: () {}, child: const Text('Tonal')),
                OutlinedButton(
                    onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
                IconButton.filled(
                    onPressed: () {}, icon: const Icon(Icons.favorite)),
                FloatingActionButton.small(
                    onPressed: () {}, child: const Icon(Icons.add)),
              ],
            ),
          ]),
          _Section('Inputs & selection', children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Memo body',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Autosave'),
              value: true,
              onChanged: (_) {},
            ),
            CheckboxListTile(
              title: const Text('Remind me'),
              value: false,
              onChanged: (_) {},
            ),
          ]),
          _Section('Feedback', children: [
            Row(
              children: [
                FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Empty trash?'),
                      content: const Text(
                          'Every memo in the Trash will be permanently deleted.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Empty')),
                      ],
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Memo moved to Trash'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {},
                      ),
                    ),
                  ),
                  child: const Text('Snackbar'),
                ),
              ],
            ),
          ]),
          _Section('Surfaces', children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.sticky_note_2_outlined,
                    color: colorScheme.primary),
                title: const Text('第一行是 memo 的脸'),
                subtitle: const Text('5m ago'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
              ),
            ),
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Filled card — 一段填充卡片的演示文字，用来观察 surfaceContainer 在内容上的观感。',
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
          ]),
          _Section('Chips', children: [
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.bookmark),
                  label: const Text('Bookmark'),
                  onPressed: () {},
                ),
                FilterChip(
                  label: const Text('Selected'),
                  selected: true,
                  onSelected: (_) {},
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.label,
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
  });

  final String label;
  final Color color;
  final Color onColor;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          _Chip(color: color, onColor: onColor),
          const SizedBox(width: 8),
          _Chip(color: container, onColor: onContainer),
        ],
      ),
    );
  }
}

class _SurfaceRow extends StatelessWidget {
  const _SurfaceRow({
    required this.label,
    required this.surface,
    required this.low,
    required this.base,
    required this.high,
    required this.text,
  });

  final String label;
  final Color surface;
  final Color low;
  final Color base;
  final Color high;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          _Chip(color: surface, onColor: text),
          const SizedBox(width: 8),
          _Chip(color: low, onColor: text),
          const SizedBox(width: 8),
          _Chip(color: base, onColor: text),
          const SizedBox(width: 8),
          _Chip(color: high, onColor: text),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.onColor});

  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'A',
          style: TextStyle(color: onColor, fontSize: 12),
        ),
      ),
    );
  }
}
