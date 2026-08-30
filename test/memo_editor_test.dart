import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';
import 'package:memova/data/providers.dart';
import 'package:memova/main.dart';

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

Future<void> openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  // Drive the route transition with fixed pumps. pumpAndSettle is banned
  // here: the focused TextField's cursor blink never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Direct query — the database is the test seam, no stream needed in tests.
Future<List<Memo>> allMemos(AppDatabase db) =>
    (db.select(db.memos)..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
        .get();

void main() {
  testWidgets('FAB opens an empty editor focused on the body', (tester) async {
    final db = await pumpApp(tester);

    await openEditor(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(tester.testTextInput.hasAnyClients, isTrue); // the field has focus

    await db.close();
  });

  testWidgets('typing persists the memo after the debounce', (tester) async {
    final db = await pumpApp(tester);

    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'hello memo');
    await tester.pump(const Duration(milliseconds: 500)); // debounce fires
    await tester.pump(); // let the async write complete

    final memos = await allMemos(db);
    expect(memos.map((m) => m.body), ['hello memo']);

    // Pop the editor before closing the DB: closing while a session that has
    // written is still open hangs under FakeAsync (drift internal timing).
    // Popping first is also the real user flow.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await db.close();
  });

  testWidgets('returning to the List shows the new memo on top',
      (tester) async {
    final db = await pumpApp(tester);
    await db.into(db.memos).insert(MemosCompanion.insert(
          body: 'older memo',
          createdAt: DateTime(2026, 1, 1, 8),
          updatedAt: DateTime(2026, 1, 1, 8),
        ));
    await tester.pumpAndSettle();

    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'fresh memo');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pageBack(); // flush + close
    await tester.pumpAndSettle();

    expect(find.text('fresh memo'), findsOneWidget);
    expect(find.text('older memo'), findsOneWidget);
    final freshY = tester.getTopLeft(find.text('fresh memo')).dy;
    final olderY = tester.getTopLeft(find.text('older memo')).dy;
    expect(freshY, lessThan(olderY));

    await db.close();
  });

  testWidgets('closing an untouched empty editor creates no row',
      (tester) async {
    final db = await pumpApp(tester);

    await openEditor(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(await allMemos(db), isEmpty);

    await db.close();
  });

  testWidgets('erasing everything and closing leaves no row behind',
      (tester) async {
    final db = await pumpApp(tester);

    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'temp');
    await tester.pump(const Duration(milliseconds: 500)); // row created
    await tester.enterText(find.byType(TextField), ''); // erased, no write
    await tester.pageBack(); // close: cleanup deletes the empty row
    await tester.pumpAndSettle();

    expect(await allMemos(db), isEmpty);

    await db.close();
  });
}
