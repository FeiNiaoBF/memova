import 'package:flutter_test/flutter_test.dart';
import 'package:memova/shared/relative_time.dart';

void main() {
  final now = DateTime(2026, 8, 30, 12); // 周六

  group('relativeTime（混合制：今天相对，之后日期地标）', () {
    test('刚刚', () {
      expect(relativeTime(now.subtract(const Duration(seconds: 30)), now: now),
          '刚刚');
    });

    test('分钟', () {
      expect(relativeTime(now.subtract(const Duration(minutes: 32)), now: now),
          '32分钟前');
    });

    test('小时（同一自然日）', () {
      expect(relativeTime(now.subtract(const Duration(hours: 3)), now: now),
          '3小时前');
    });

    test('超过 24h → 日期地标 + 星期', () {
      expect(relativeTime(DateTime(2026, 8, 22), now: now), '8月22日 周六');
    });

    test('跨年加年份', () {
      expect(relativeTime(DateTime(2025, 12, 31), now: now), '2025年12月31日 周三');
    });

    test('未来时间按刚刚处理', () {
      expect(relativeTime(now.add(const Duration(minutes: 5)), now: now),
          '刚刚');
    });
  });

  group('dateAnchorLabel（组锚：今天/昨天/真实日期）', () {
    test('今天', () {
      expect(dateAnchorLabel(now, now: now), '今天');
    });

    test('昨天', () {
      expect(dateAnchorLabel(now.subtract(const Duration(days: 1)), now: now),
          '昨天');
    });

    test('更早 → 真实日期 + 星期（绝不写"更早"）', () {
      expect(dateAnchorLabel(DateTime(2026, 8, 22), now: now), '8月22日 周六');
    });

    test('锚点星期正确（8月30日是周六）', () {
      expect(fullDateStamp(now, now: now), '8月30日 周日');
    });
  });
}
