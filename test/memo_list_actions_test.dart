import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('tapping a memo opens the editor pre-filled; editing moves it '
      'to the top', (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(db, 'older memo', DateTime(2026, 1, 1, 8));
    await seedMemo(db, 'newer memo', DateTime(2026, 1, 1, 10));
    await tester.pumpAndSettle();

    // Tap the older one — it sits lower in the list.
    await tester.tap(find.text('older memo'));
    // Route transition with fixed pumps (the focused TextField's cursor
    // blink makes pumpAndSettle hang while the editor is open).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Pre-filled with the tapped memo's body.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'older memo');

    await tester.enterText(find.byType(TextField), 'older memo edited');
    await tester.pump(const Duration(milliseconds: 500)); // debounce fires
    await tester.pageBack(); // flush + close
    await tester.pumpAndSettle();

    // updatedAt bumped → the edited memo now sits on top.
    expect(find.text('older memo edited'), findsOneWidget);
    expect(find.text('newer memo'), findsOneWidget);
    final editedY = tester.getTopLeft(find.text('older memo edited')).dy;
    final newerY = tester.getTopLeft(find.text('newer memo')).dy;
    expect(editedY, lessThan(newerY));

    await db.close();
  });

  testWidgets('swiping removes the memo from the List; undo restores it',
      (tester) async {
    final db = await pumpApp(tester);
    await seedMemo(db, 'doomed memo', DateTime(2026, 1, 1, 8));
    await tester.pumpAndSettle();

    await tester.drag(find.text('doomed memo'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Gone from the List immediately, with an Undo affordance.
    expect(find.text('doomed memo'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Back, unchanged.
    expect(find.text('doomed memo'), findsOneWidget);

    // Let the snackbar's auto-hide timer fire before closing the DB.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await db.close();
  });
}
