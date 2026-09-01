import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Identifies one editor session: which memo is being edited, if any.
class MemoEditorArgs {
  const MemoEditorArgs({this.memoId, this.initialBody = ''});

  /// Row id when editing an existing memo; `null` when creating a new one.
  final int? memoId;

  /// Pre-filled body for existing memos (empty for a new memo).
  final String initialBody;
}

/// The memo editor session: current body + the row id once created.
///
/// Owns all write logic (architecture rule 3 — the widget holds no business
/// state). The screen only reports keystrokes and asks to close. The family
/// argument tells this session which memo it is editing (`null` id = a
/// brand-new memo).
///
/// Every keystroke writes through to the database immediately (no debounce,
/// user story 6): a process kill mid-typing never costs text. Writes are
/// serialized on [_queue] so two fast keystrokes can't both create a row.
class MemoEditor extends Notifier<String> {
  MemoEditor(this.args);

  final MemoEditorArgs args;
  int? _memoId;
  Future<void> _queue = Future.value();

  @override
  String build() {
    _memoId = args.memoId;
    return args.initialBody;
  }

  /// Every keystroke persists immediately. An empty body never writes:
  /// a row is created only after the first character (spec, user story 7).
  void onBodyChanged(String body) {
    state = body;
    if (body.isEmpty) return;
    _queue = _queue.then((_) => _persist(body));
  }

  Future<void> _persist(String body) async {
    final dao = ref.read(databaseProvider).memosDao;
    if (_memoId == null) {
      _memoId = await dao.createMemo(body);
    } else {
      await dao.updateMemoBody(_memoId!, body);
    }
  }

  /// Waits for every pending keystroke to land, then drops an empty draft.
  /// Call before leaving the editor so nothing is lost to in-flight writes.
  Future<void> close() async {
    await _queue;
    if (state.isEmpty && _memoId != null) {
      // Everything was erased — this session leaves no row.
      final dao = ref.read(databaseProvider).memosDao;
      await dao.deleteMemo(_memoId!);
    }
  }
}

/// One editor session, keyed by its [MemoEditorArgs]. `autoDispose`: closing
/// the screen disposes the notifier, so the next open starts fresh — no stale
/// id, no leftover timer. Each memo id gets its own session state.
final memoEditorProvider =
    NotifierProvider.autoDispose.family<MemoEditor, String, MemoEditorArgs>(
  MemoEditor.new,
);
