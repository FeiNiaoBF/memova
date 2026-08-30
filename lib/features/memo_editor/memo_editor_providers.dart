import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// How long the editor waits after typing stops before writing to the
/// database (spec: ~500 ms auto-save debounce).
const _autosaveDelay = Duration(milliseconds: 500);

/// The memo editor session: current body + the row id once created.
///
/// Owns the debounce timer and all write logic (architecture rule 3 — the
/// widget holds no business state). The screen only reports keystrokes and
/// asks to close.
class MemoEditor extends Notifier<String> {
  Timer? _debounce;
  int? _memoId;

  @override
  String build() {
    // Riverpod 3 lifecycle: register cleanup here, not via a dispose override.
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// Every keystroke resets the debounce timer. An empty body never writes:
  /// a row is created only after the first character (spec, user story 7).
  void onBodyChanged(String body) {
    state = body;
    _debounce?.cancel();
    if (body.isEmpty) return;
    _debounce = Timer(_autosaveDelay, () => _persist(body));
  }

  Future<void> _persist(String body) async {
    final dao = ref.read(databaseProvider).memosDao;
    if (_memoId == null) {
      _memoId = await dao.createMemo(body);
    } else {
      await dao.updateMemoBody(_memoId!, body);
    }
  }

  /// Flushes the pending write, then drops an empty draft. Call before
  /// leaving the editor so the latest text is never lost to the debounce
  /// window.
  Future<void> close() async {
    _debounce?.cancel();
    final body = state;
    final dao = ref.read(databaseProvider).memosDao;
    if (body.isEmpty) {
      // Untouched, or everything was erased — this session leaves no row.
      if (_memoId != null) await dao.deleteMemo(_memoId!);
      return;
    }
    await _persist(body);
  }
}

/// One editor session. `autoDispose`: closing the screen disposes the
/// notifier, so the next open starts fresh — no stale id, no leftover timer.
final memoEditorProvider =
    NotifierProvider.autoDispose<MemoEditor, String>(MemoEditor.new);
