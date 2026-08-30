import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo_editor_providers.dart';

/// A fresh, title-less editor (ADR-0003). Typing auto-saves after a debounce;
/// closing flushes the pending write and cleans up empty drafts.
class MemoEditorScreen extends ConsumerStatefulWidget {
  const MemoEditorScreen({super.key});

  @override
  ConsumerState<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends ConsumerState<MemoEditorScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Flush pending writes, then leave. Shared by the app-bar back button and
  /// the system back gesture (PopScope).
  Future<void> _closeAndPop() async {
    await ref.read(memoEditorProvider.notifier).close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch (not just read): autoDispose providers are disposed when they
    // have no listeners — read alone does not subscribe, so the session
    // would be disposed after the first frame. Watching keeps it alive for
    // exactly this screen's lifetime.
    ref.watch(memoEditorProvider);
    final notifier = ref.read(memoEditorProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _closeAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _closeAndPop),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Start typing…',
              border: InputBorder.none,
            ),
            onChanged: notifier.onBodyChanged,
          ),
        ),
      ),
    );
  }
}
