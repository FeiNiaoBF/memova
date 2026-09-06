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

/// What the save-state line shows (#4: the trust bridge between the
/// write-through mechanism and the user's confidence in it).
enum EditorSaveState { saved, saving }

class MemoEditorState {
  const MemoEditorState({required this.body, required this.saveState});

  final String body;
  final EditorSaveState saveState;

  MemoEditorState copyWith({String? body, EditorSaveState? saveState}) =>
      MemoEditorState(
        body: body ?? this.body,
        saveState: saveState ?? this.saveState,
      );
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
class MemoEditor extends Notifier<MemoEditorState> {
  MemoEditor(this.args);

  final MemoEditorArgs args;
  int? _memoId;
  Future<void> _queue = Future.value();

  @override
  MemoEditorState build() {
    _memoId = args.memoId;
    return MemoEditorState(body: args.initialBody, saveState: EditorSaveState.saved);
  }

  /// Every keystroke persists immediately. An empty body never writes:
  /// a row is created only after the first character (spec, user story 7).
  void onBodyChanged(String body) {
    state = state.copyWith(body: body, saveState: EditorSaveState.saving);
    if (body.isEmpty) {
      // Nothing pending — an empty draft is trivially "saved".
      state = state.copyWith(saveState: EditorSaveState.saved);
      return;
    }
    _queue = _queue.then((_) => _persist(body));
  }

  Future<void> _persist(String body) async {
    final dao = ref.read(databaseProvider).memosDao;
    if (_memoId == null) {
      _memoId = await dao.createMemo(body);
    } else {
      await dao.updateMemoBody(_memoId!, body);
    }
    // Only flip back to saved if no newer keystroke is waiting behind this
    // write — otherwise the queue drains them in order and the last one
    // flips the flag.
    if (state.body == body) {
      state = state.copyWith(saveState: EditorSaveState.saved);
    }
  }

  /// Waits for every pending keystroke to land, then drops an empty draft.
  /// Call before leaving the editor so nothing is lost to in-flight writes.
  Future<void> close() async {
    await _queue;
    if (state.body.isEmpty && _memoId != null) {
      // Everything was erased — this session leaves no row.
      final dao = ref.read(databaseProvider).memosDao;
      await dao.deleteMemo(_memoId!);
    }
  }
}

/// One editor session, keyed by its [MemoEditorArgs]. `autoDispose`: closing
/// the screen disposes the notifier, so the next open starts fresh — no stale
/// id, no leftover timer. Each memo id gets its own session state.
final memoEditorProvider = NotifierProvider.autoDispose
    .family<MemoEditor, MemoEditorState, MemoEditorArgs>(MemoEditor.new);
