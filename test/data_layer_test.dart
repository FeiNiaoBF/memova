import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Real Drift on an in-memory SQLite — the data-layer seam.
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// Test helper: inserts a memo with explicit timestamps so ordering is
  /// deterministic. Timestamps are otherwise managed by the data layer (#4).
  Future<void> insertMemo(
    String body, {
    required DateTime updatedAt,
    DateTime? trashedAt,
  }) {
    return db.into(db.memos).insert(MemosCompanion.insert(
          body: body,
          createdAt: updatedAt,
          updatedAt: updatedAt,
          trashedAt: Value(trashedAt),
        ));
  }

  test('watchLiveMemos emits live memos ordered by updatedAt descending',
      () async {
    await insertMemo('older', updatedAt: DateTime(2026, 1, 1, 8));
    await insertMemo('newer', updatedAt: DateTime(2026, 1, 1, 10));

    final memos = await db.memosDao.watchLiveMemos().first;

    expect(memos.map((m) => m.body), ['newer', 'older']);
  });

  test('watchLiveMemos excludes trashed memos', () async {
    await insertMemo('kept', updatedAt: DateTime(2026, 1, 1, 8));
    await insertMemo(
      'trashed',
      updatedAt: DateTime(2026, 1, 1, 10),
      trashedAt: DateTime(2026, 1, 2),
    );

    final memos = await db.memosDao.watchLiveMemos().first;

    expect(memos.map((m) => m.body), ['kept']);
  });
}
