import 'package:flutter_test/flutter_test.dart';
import 'package:memova/features/memo_list/relative_time.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  test('under a minute is "just now"', () {
    expect(relativeTime(now.subtract(const Duration(seconds: 30)), now: now),
        'just now');
  });

  test('minutes ago', () {
    expect(relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago');
  });

  test('hours ago', () {
    expect(relativeTime(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago');
  });

  test('days ago', () {
    expect(relativeTime(now.subtract(const Duration(days: 2)), now: now),
        '2d ago');
  });

  test('older than 30 days shows a date', () {
    expect(relativeTime(DateTime(2025, 11, 15), now: now), '2025-11-15');
  });

  test('future timestamps are "just now"', () {
    expect(relativeTime(now.add(const Duration(minutes: 5)), now: now),
        'just now');
  });
}
