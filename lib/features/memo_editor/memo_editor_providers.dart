import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

typedef MemoSave = Future<int> Function(int? memoId, String body);

/// The default write-through operation. It is a function seam rather than a
/// repository layer so the editor's failure recovery can be tested without
/// changing the app's small feature-first architecture.
final memoSaveProvider = Provider<MemoSave>((ref) {
  return (memoId, body) async {
    final dao = ref.read(databaseProvider).memosDao;
    if (memoId == null) return dao.createMemo(body);
    await dao.updateMemoBody(memoId, body);
    return memoId;
  };
});

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
enum EditorSaveState { saved, saving, error }

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
  Object? _lastWriteError;

  @override
  MemoEditorState build() {
    _memoId = args.memoId;
    return MemoEditorState(
      body: args.initialBody,
      saveState: EditorSaveState.saved,
    );
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
    _queue = _queue.then((_) async {
      try {
        _memoId = await _persist(body);
        _lastWriteError = null;
        // Only flip back to saved if no newer keystroke is waiting behind
        // this write — otherwise the queue drains them in order and the last
        // one flips the flag.
        if (state.body == body) {
          state = state.copyWith(saveState: EditorSaveState.saved);
        }
      } catch (error) {
        _lastWriteError = error;
        if (state.body == body) {
          state = state.copyWith(saveState: EditorSaveState.error);
        }
        // Keep the queue usable: a later keystroke can retry after a
        // transient storage failure instead of inheriting a rejected Future.
      }
    });
  }

  Future<int> _persist(String body) {
    return ref.read(memoSaveProvider)(_memoId, body);
  }

  /// Waits for every pending keystroke to land, retries the current body once
  /// after a failed write, then drops an empty draft. Returns false when the
  /// final retry fails so the screen can keep the user's text visible.
  Future<bool> close() async {
    await _queue;
    if (_lastWriteError != null && state.body.isNotEmpty) {
      _lastWriteError = null;
      onBodyChanged(state.body);
      await _queue;
    }
    if (_lastWriteError != null && state.body.isNotEmpty) return false;

    if (state.body.isEmpty && _memoId != null) {
      // Everything was erased — this session leaves no row.
      final dao = ref.read(databaseProvider).memosDao;
      await dao.deleteMemo(_memoId!);
    }
    return true;
  }
}

/// One editor session, keyed by its [MemoEditorArgs]. `autoDispose`: closing
/// the screen disposes the notifier, so the next open starts fresh — no stale
/// id, no leftover timer. Each memo id gets its own session state.
final memoEditorProvider = NotifierProvider.autoDispose
    .family<MemoEditor, MemoEditorState, MemoEditorArgs>(MemoEditor.new);
