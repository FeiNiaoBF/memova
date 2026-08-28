import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memova/main.dart';

void main() {
  testWidgets('placeholder home shows the app name and empty-state hint',
      (tester) async {
    await tester.pumpWidget(const MemovaApp());

    expect(find.text('Memova'), findsOneWidget);
    expect(find.text('Nothing here yet — the List is coming.'),
        findsOneWidget);
  });

  testWidgets('follows system light mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(const MemovaApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Memova'));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('follows system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(const MemovaApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Memova'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
