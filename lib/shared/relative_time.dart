/// Research-driven time labels for memova (#3, DESIGN.md): relative metric
/// time within today (useful inside an episode), date landmarks beyond
/// (memory reconstructs when-things-happened from landmarks and chronology,
/// not from precise clocks).
///
/// Pure functions, no Flutter dependency — trivially unit-testable.
/// `[now]` is injectable so tests are deterministic.
library;

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// True when two date-times fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 周一…周日 for a date-time.
String weekdayLabel(DateTime t) => _weekdays[t.weekday - 1];

/// 「8月22日」 — date landmark without the weekday (year rule as above).
String dateLandmarkLabel(DateTime t, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final base = '${t.month}月${t.day}日';
  return t.year == reference.year ? base : '${t.year}年$base';
}

/// 「8月30日 周六」 — a real-date landmark with the weekday cue; the year is
/// prepended only when it differs from [now]'s year.
String fullDateStamp(DateTime t, {DateTime? now}) {
  return '${dateLandmarkLabel(t, now: now)} ${weekdayLabel(t)}';
}

/// Row-level label: relative metric time for today, a date landmark beyond.
String relativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.isNegative) return '刚刚';
  if (diff.inSeconds < 60) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (isSameDay(time, reference)) return '${diff.inHours}小时前';
  return fullDateStamp(time, now: reference);
}

/// Group-anchor label: 今天 / 昨天 / 「8月22日 周六」 (never vague buckets).
String dateAnchorLabel(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (isSameDay(time, reference)) return '今天';
  if (isSameDay(time, reference.subtract(const Duration(days: 1)))) {
    return '昨天';
  }
  return fullDateStamp(time, now: reference);
}
