import 'package:flutter_test/flutter_test.dart';
import 'package:memova/data/app_database.dart';
import 'package:memova/features/memo_list/memo_groups.dart';

void main() {
  final now = DateTime(2026, 8, 30, 12); // 周六

  Memo memo(String body, DateTime updatedAt) => Memo(
    id: 0,
    body: body,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    trashedAt: null,
  );

  test('groups consecutive memos into 今天/昨天/日期锚点', () {
    final groups = groupMemosByDay([
      memo('a', DateTime(2026, 8, 30, 10)),
      memo('b', DateTime(2026, 8, 30, 8)),
      memo('c', DateTime(2026, 8, 29, 20)),
      memo('d', DateTime(2026, 8, 22, 9)),
    ], now: now);

    expect(groups.length, 3);
    expect(groups[0].title, '今天');
    expect(groups[0].isToday, isTrue);
    expect(groups[0].subtitle, '8月30日 周日');
    expect(groups[0].memos.map((m) => m.body), ['a', 'b']);
    expect(groups[1].title, '昨天');
    expect(groups[1].memos.map((m) => m.body), ['c']);
    expect(groups[2].title, '8月22日');
    expect(groups[2].isToday, isFalse);
    expect(groups[2].subtitle, '周六'); // older dates: weekday only
  });

  test('empty input yields no groups', () {
    expect(groupMemosByDay([], now: now), isEmpty);
  });
}
