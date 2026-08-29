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
  /// stays in sync without any manual refresh.
  Stream<List<Memo>> watchLiveMemos() {
    return (select(memos)
          ..where((m) => m.trashedAt.isNull())
          ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
        .watch();
  }
}
