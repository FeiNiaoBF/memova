import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Opens the Trash from the List app bar and settles the route transition.
Future<void> openTrash(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Trash'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('trash entry lists trashed memos with their trashed timestamp',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(
      db,
      'in trash',
      DateTime(2026, 1, 1),
      trashedAt: DateTime(2026, 1, 2),
    );
    await seedMemo(db, 'live memo', DateTime(2026, 1, 3));
    await tester.pumpAndSettle();

    await openTrash(tester);

    // Trashed memo listed with its trashed-at date; live memos absent.
    expect(find.text('in trash'), findsOneWidget);
    expect(find.textContaining('2026-01-02'), findsOneWidget);
    expect(find.text('live memo'), findsNothing);
    expect(find.text('Trash'), findsOneWidget); // app bar title

    // Pop back so the autoDispose trash stream is released before close
    // (mirrors the single-stream invariant of the list tests).
    await tester.pageBack();
    await tester.pumpAndSettle();

    await db.close();
  });

  testWidgets('restore from the Trash returns the memo to the List',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(
      db,
      'wanted back',
      DateTime(2026, 1, 1),
      trashedAt: DateTime(2026, 1, 2),
    );
    await tester.pumpAndSettle();

    await openTrash(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    // Gone from the Trash, back on the List behind it.
    expect(find.text('wanted back'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('wanted back'), findsOneWidget);

    await db.close();
  });

  testWidgets('permanently deleting a memo removes it from the Trash',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(
      db,
      'to delete forever',
      DateTime(2026, 1, 1),
      trashedAt: DateTime(2026, 1, 2),
    );
    await tester.pumpAndSettle();

    await openTrash(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    expect(find.text('to delete forever'), findsNothing);

    // Irrecoverable: gone from the database entirely.
    final rows = await (db.select(db.memos)
          ..where((m) => m.body.equals('to delete forever')))
        .get();
    expect(rows, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await db.close();
  });

  testWidgets('empty trash asks for confirmation before purging',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(
      db,
      'trash one',
      DateTime(2026, 1, 1),
      trashedAt: DateTime(2026, 1, 2),
    );
    await seedMemo(
      db,
      'trash two',
      DateTime(2026, 1, 1, 9),
      trashedAt: DateTime(2026, 1, 3),
    );
    await tester.pumpAndSettle();

    await openTrash(tester);

    // Cancel keeps everything.
    await tester.tap(find.byTooltip('Empty trash'));
    await tester.pumpAndSettle();
    expect(find.text('Empty trash?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('trash one'), findsOneWidget);
    expect(find.text('trash two'), findsOneWidget);

    // Confirm purges everything.
    await tester.tap(find.byTooltip('Empty trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty'));
    await tester.pumpAndSettle();
    expect(find.text('trash one'), findsNothing);
    expect(find.text('trash two'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await db.close();
  });
}
