import 'package:drift/drift.dart' hide isNull;
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

Future<void> openSearch(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Search'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing in search filters the List live; clearing restores it',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(db, 'Buy milk and bread', DateTime(2026, 1, 1, 8));
    await seedMemo(db, 'MILK alternatives', DateTime(2026, 1, 1, 9));
    await seedMemo(db, 'unrelated', DateTime(2026, 1, 1, 10));
    await tester.pumpAndSettle();

    expect(find.text('unrelated'), findsOneWidget);

    await openSearch(tester);

    // Case-insensitive, anywhere in the body.
    await tester.enterText(find.byType(TextField), 'milk');
    await tester.pumpAndSettle();

    expect(find.text('Buy milk and bread'), findsOneWidget);
    expect(find.text('MILK alternatives'), findsOneWidget);
    expect(find.text('unrelated'), findsNothing);

    // Non-matching query shows the no-results state.
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No memos match'), findsOneWidget);

    // Clearing restores the full list.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('unrelated'), findsOneWidget);
    expect(find.text('Buy milk and bread'), findsOneWidget);

    // Close search, still all there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('unrelated'), findsOneWidget);

    await db.close();
  });

  testWidgets('search never shows trashed memos', (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(
      db,
      'secret trashed',
      DateTime(2026, 1, 1, 8),
      trashedAt: DateTime(2026, 1, 2),
    );
    await seedMemo(db, 'secret live', DateTime(2026, 1, 1, 9));
    await tester.pumpAndSettle();

    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pumpAndSettle();

    expect(find.text('secret live'), findsOneWidget);
    expect(find.text('secret trashed'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await db.close();
  });
}
