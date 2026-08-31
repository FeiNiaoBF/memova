import 'package:drift/drift.dart' hide isNull;
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

  test('createMemo persists the body and returns its id', () async {
    final id = await db.memosDao.createMemo('first thought');

    final memo = await (db.select(db.memos)
          ..where((m) => m.id.equals(id)))
        .getSingle();
    expect(memo.body, 'first thought');
    expect(memo.trashedAt, isNull);
  });

  test('updateMemoBody replaces the body and preserves createdAt', () async {
    final id = await db.memosDao.createMemo('v1');
    final before = await (db.select(db.memos)
          ..where((m) => m.id.equals(id)))
        .getSingle();

    await db.memosDao.updateMemoBody(id, 'v2');

    final after = await (db.select(db.memos)
          ..where((m) => m.id.equals(id)))
        .getSingle();
    expect(after.body, 'v2');
    expect(after.createdAt, before.createdAt);
  });

  test('trashMemo hides the memo from the live list', () async {
    final id = await db.memosDao.createMemo('to trash');

    await db.memosDao.trashMemo(id);

    final memos = await db.memosDao.watchLiveMemos().first;
    expect(memos, isEmpty);
  });

  test('restoreMemo brings the memo back unchanged', () async {
    final id = await db.memosDao.createMemo('back again');

    await db.memosDao.trashMemo(id);
    await db.memosDao.restoreMemo(id);

    final memos = await db.memosDao.watchLiveMemos().first;
    expect(memos.map((m) => m.body), ['back again']);
    expect(memos.single.trashedAt, isNull);
  });

  test('watchTrashedMemos emits trashed memos ordered by trashedAt descending',
      () async {
    await insertMemo(
      'old trash',
      updatedAt: DateTime(2026, 1, 1, 8),
      trashedAt: DateTime(2026, 1, 2, 8),
    );
    await insertMemo(
      'new trash',
      updatedAt: DateTime(2026, 1, 1, 10),
      trashedAt: DateTime(2026, 1, 3, 10),
    );
    await insertMemo('live', updatedAt: DateTime(2026, 1, 4));

    final trashed = await db.memosDao.watchTrashedMemos().first;

    expect(trashed.map((m) => m.body), ['new trash', 'old trash']);
  });

  test('emptyTrash permanently deletes every trashed memo', () async {
    await insertMemo(
      'trash one',
      updatedAt: DateTime(2026, 1, 1, 8),
      trashedAt: DateTime(2026, 1, 2),
    );
    await insertMemo(
      'trash two',
      updatedAt: DateTime(2026, 1, 1, 9),
      trashedAt: DateTime(2026, 1, 3),
    );
    await insertMemo('keep me', updatedAt: DateTime(2026, 1, 4));

    await db.memosDao.emptyTrash();

    final trashed = await db.memosDao.watchTrashedMemos().first;
    final live = await db.memosDao.watchLiveMemos().first;
    expect(trashed, isEmpty);
    expect(live.map((m) => m.body), ['keep me']);
  });

  test('purgeTrashedMemos deletes only memos trashed before the cutoff',
      () async {
    await insertMemo(
      'too old',
      updatedAt: DateTime(2026, 1, 1, 8),
      trashedAt: DateTime(2026, 1, 2),
    );
    await insertMemo(
      'recent trash',
      updatedAt: DateTime(2026, 1, 1, 9),
      trashedAt: DateTime(2026, 2, 1),
    );
    await insertMemo('live', updatedAt: DateTime(2026, 1, 1, 10));

    // Cutoff: Jan 31 → 'too old' (trashed Jan 2) goes, 'recent trash'
    // (trashed Feb 1) stays, live memos never touched.
    await db.memosDao.purgeTrashedMemos(before: DateTime(2026, 1, 31));

    final trashed = await db.memosDao.watchTrashedMemos().first;
    final live = await db.memosDao.watchLiveMemos().first;
    expect(trashed.map((m) => m.body), ['recent trash']);
    expect(live.map((m) => m.body), ['live']);
  });
}
