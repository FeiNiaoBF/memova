import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';
import 'package:memova/data/providers.dart';
import 'package:memova/main.dart';

/// Pumps the whole app with an in-memory database — the widget-test seam
/// (spec: Testing Decisions). Returns the database so tests can seed and
/// assert directly; it is the caller's job to close it.
Future<AppDatabase> pumpApp(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MemovaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Inserts a memo with explicit timestamps so ordering is deterministic.
/// Timestamps are otherwise managed by the data layer (#4).
Future<void> seedMemo(
  AppDatabase db,
  String body,
  DateTime updatedAt, {
  DateTime? trashedAt,
}) async {
  await db.into(db.memos).insert(MemosCompanion.insert(
        body: body,
        createdAt: updatedAt,
        updatedAt: updatedAt,
        trashedAt: Value(trashedAt),
      ));
}

/// Every memo row, newest-updated first — direct query for assertions.
Future<List<Memo>> allMemos(AppDatabase db) =>
    (db.select(db.memos)..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
        .get();
