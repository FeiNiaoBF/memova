import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';
import 'package:memova/features/memo_list/memo_list_providers.dart';
import 'package:memova/main.dart';

/// Pumps the real app tree with an in-memory database injected through the
/// provider override — the single test seam (spec: Testing Decisions).
///
/// Every test MUST end with `await db.close()`: drift schedules a
/// zero-duration timer when a watched stream is cancelled (which happens when
/// the tree disposes the provider), and flutter_test flags pending timers.
/// Closing the database first makes drift skip that timer (drift's own
/// testing guidance).
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

void main() {
  testWidgets('with no memos, shows the empty state', (tester) async {
    final db = await pumpApp(tester);

    expect(find.text('No memos yet'), findsOneWidget);

    await db.close();
  });

  testWidgets('memos appear in the list, newest-updated first', (tester) async {
    final db = await pumpApp(tester);

    // Insert after the screen is already showing — the reactive stream
    // must update the List on its own, no manual refresh.
    await db.into(db.memos).insert(MemosCompanion.insert(
          body: 'older memo',
          createdAt: DateTime(2026, 1, 1, 8),
          updatedAt: DateTime(2026, 1, 1, 8),
        ));
    await db.into(db.memos).insert(MemosCompanion.insert(
          body: 'newer memo',
          createdAt: DateTime(2026, 1, 1, 10),
          updatedAt: DateTime(2026, 1, 1, 10),
        ));
    await tester.pumpAndSettle();

    expect(find.text('newer memo'), findsOneWidget);
    expect(find.text('older memo'), findsOneWidget);

    // Newest-updated must sit above the older one on screen.
    final newerY = tester.getTopLeft(find.text('newer memo')).dy;
    final olderY = tester.getTopLeft(find.text('older memo')).dy;
    expect(newerY, lessThan(olderY));

    await db.close();
  });

  testWidgets('each row shows a relative timestamp', (tester) async {
    final db = await pumpApp(tester);

    final updated = DateTime.now().subtract(const Duration(minutes: 5));
    await db.into(db.memos).insert(MemosCompanion.insert(
          body: 'a memo',
          createdAt: updated,
          updatedAt: updated,
        ));
    await tester.pumpAndSettle();

    expect(find.text('5m ago'), findsOneWidget);

    await db.close();
  });

  testWidgets('follows system light mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final db = await pumpApp(tester);

    final context = tester.element(find.text('Memova'));
    expect(Theme.of(context).brightness, Brightness.light);

    await db.close();
  });

  testWidgets('follows system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final db = await pumpApp(tester);

    final context = tester.element(find.text('Memova'));
    expect(Theme.of(context).brightness, Brightness.dark);

    await db.close();
  });
}
