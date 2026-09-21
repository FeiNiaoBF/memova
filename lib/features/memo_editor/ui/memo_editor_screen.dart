import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo_editor_providers.dart';

/// The writing surface (DESIGN.md #4): a bare full-bleed text field —
/// Deference, borders zeroed — plus a quiet save-state line that makes the
/// write-through guarantee *perceivable* (confidence before offloading).
class MemoEditorScreen extends ConsumerStatefulWidget {
  const MemoEditorScreen({super.key, required this.args});

  final MemoEditorArgs args;

  @override
  ConsumerState<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends ConsumerState<MemoEditorScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.args.initialBody,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Flush pending writes, then leave. Shared by the app-bar back button and
  /// the system back gesture (PopScope).
  Future<void> _closeAndPop() async {
    final closed = await ref
        .read(memoEditorProvider(widget.args).notifier)
        .close();
    if (!mounted) return;
    if (!closed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch (not just read): autoDispose providers are disposed when they
    // have no listeners — read alone does not subscribe, so the session
    // would be disposed after the first frame.
    final state = ref.watch(memoEditorProvider(widget.args));
    final notifier = ref.read(memoEditorProvider(widget.args).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _closeAndPop();
      },
      child: Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _closeAndPop)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
              child: Text(
                switch (state.saveState) {
                  EditorSaveState.saved => '已保存',
                  EditorSaveState.saving => '保存中…',
                  EditorSaveState.error => '保存失败',
                },
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: state.saveState == EditorSaveState.error
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 18, height: 1.75),
                  decoration: const InputDecoration(
                    hintText: '写点什么…',
                    border: InputBorder.none,
                  ),
                  onChanged: notifier.onBodyChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
