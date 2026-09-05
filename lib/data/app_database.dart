import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'memos_table.dart';

part 'app_database.g.dart';

/// The single Drift database of the app (ADR-0001).
///
/// This class IS the test seam: tests construct it with
/// `NativeDatabase.memory()` (no file, no disk), the app opens it with a
/// real SQLite file. Everything else — DAO, providers, UI — is identical
/// in both worlds.
@DriftDatabase(tables: [Memos], daos: [MemosDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

/// Opens the on-device database file.
///
/// [LazyDatabase] delays touching the file until the first query runs, so
/// constructing the database in `main()` costs nothing until the UI asks.
AppDatabase openAppDatabase() {
  return AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase(File('${dir.path}/memova.sqlite'));
  }));
}

/// Data access for memos — the only place queries are written
/// (architecture rule 2: UI never touches SQL).
@DriftAccessor(tables: [Memos])
class MemosDao extends DatabaseAccessor<AppDatabase> with _$MemosDaoMixin {
  MemosDao(super.attachedDatabase);

  /// Live (non-trashed) memos, newest-updated first, as a reactive stream.
  ///
  /// `.watch()` re-emits whenever the `memos` table changes, so the UI
  /// stays in sync without any manual refresh. An optional [query] filters
  /// to memos whose body contains it, case-insensitively and anywhere in
  /// the text — the search behaviour of ticket #7.
  Stream<List<Memo>> watchLiveMemos({String? query}) {
    final statement = select(memos)
      ..where((m) => m.trashedAt.isNull())
      ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]);
    if (query != null && query.isNotEmpty) {
      statement.where((m) => m.body.lower().contains(query.toLowerCase()));
    }
    return statement.watch();
  }

  /// Creates a memo from its body and returns the new row id.
  ///
  /// Timestamps are owned by the data layer (spec: "timestamps managed by
  /// the data layer"): they default to now. [createdAt]/[updatedAt] only
  /// exist for demo seeding and tests that must pin time.
  Future<int> createMemo(
    String body, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return into(memos).insert(
      MemosCompanion.insert(
        body: body,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      ),
    );
  }

  /// Replaces the body and bumps [Memos.updatedAt] — the bump is what keeps
  /// a just-edited memo on top of the List.
  Future<void> updateMemoBody(int id, String body) {
    return (update(memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(body: Value(body), updatedAt: Value(DateTime.now())),
    );
  }

  /// Permanently removes a memo row. Only used to clean up empty drafts;
  /// user-facing deletion goes through the Trash (ticket #6).
  Future<void> deleteMemo(int id) {
    return (delete(memos)..where((m) => m.id.equals(id))).go();
  }

  /// Moves a memo to the Trash: sets [Memos.trashedAt], which hides it from
  /// the live List (ticket #6 builds the Trash screen around this state).
  Future<void> trashMemo(int id) {
    return (update(memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(trashedAt: Value(DateTime.now())),
    );
  }

  /// Returns a memo from the Trash to the List. [Memos.updatedAt] is left
  /// untouched, so the memo lands back exactly where it was.
  Future<void> restoreMemo(int id) {
    return (update(memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(trashedAt: const Value(null)),
    );
  }

  /// Trashed memos, most-recently-trashed first, as a reactive stream.
  ///
  /// Powers the Trash screen (#6); the List's [watchLiveMemos] stays the
  /// single source of truth for live memos.
  Stream<List<Memo>> watchTrashedMemos() {
    return (select(memos)
          ..where((m) => m.trashedAt.isNotNull())
          ..orderBy([(m) => OrderingTerm.desc(m.trashedAt)]))
        .watch();
  }

  /// Permanently deletes every trashed memo. Live memos are untouched.
  ///
  /// The UI guards this behind a confirmation (#6, user story 15).
  Future<void> emptyTrash() {
    return (delete(memos)..where((m) => m.trashedAt.isNotNull())).go();
  }

  /// Permanently deletes memos trashed before [before] (default: 30 days ago).
  ///
  /// Called on app start (#6, user story 16); [before] is injectable so
  /// tests pin the cutoff instead of depending on the wall clock.
  Future<void> purgeTrashedMemos({DateTime? before}) async {
    final cutoff = before ?? DateTime.now().subtract(const Duration(days: 30));
    await (delete(memos)..where((m) => m.trashedAt.isSmallerThanValue(cutoff))).go();
  }
}
