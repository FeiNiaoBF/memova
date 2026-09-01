import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';

import 'helpers.dart';
Future<void> openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  // Drive the route transition with fixed pumps. pumpAndSettle is banned
  // here: the focused TextField's cursor blink never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

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

  testWidgets('typing persists the memo to the database', (tester) async {
    final db = await pumpApp(tester);

    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'hello memo');
    await tester.pump();

    final memos = await allMemos(db);
    expect(memos.map((m) => m.body), ['hello memo']);

    // Pop the editor before closing the DB: closing while a session that has
    // written is still open hangs under FakeAsync (drift internal timing).
    // Popping first is also the real user flow.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await db.close();
  });

  testWidgets('every keystroke persists immediately, with no close or flush',
      (tester) async {
    // User story 6: an interruption must never cost a thought. The write must
    // land at keystroke time, not on close — on a real device that write is
    // already in the SQLite file, so a process kill mid-typing loses nothing.
    // (close()'s only remaining job is cleaning up empty drafts.)
    final db = await pumpApp(tester);

    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'don\'t lose me');
    await tester.pump(); // let the write land

    final memos = await allMemos(db);
    expect(memos.map((m) => m.body), ['don\'t lose me']);

    await tester.pageBack(); // close() runs, but it isn't what persisted
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
