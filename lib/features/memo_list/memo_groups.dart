import '../../data/app_database.dart';
import '../../shared/relative_time.dart';

/// A date landmark group in the List (#3, DESIGN.md): 今天 / 昨天 / a real
/// date. Anchors are typography, not graphics — no rails.
class MemoGroup {
  const MemoGroup({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.isToday,
    required this.memos,
  });

  /// The calendar day this group covers (used to detect day boundaries).
  final DateTime date;

  /// 今天 / 昨天 / `8月22日`.
  final String title;

  /// 今天/昨天 → full date stamp (`8月30日 周六`); older → weekday only.
  final String subtitle;

  /// Whether this group is today (the only group allowed the 黛绿 accent).
  final bool isToday;

  final List<Memo> memos;
}

/// Groups a newest-first memo list by the calendar day of `updatedAt`.
///
/// Logic rule (DESIGN.md): grouping follows `updatedAt`, so a memo written
/// days ago but edited today joins 今天 — consistent with newest-first.
List<MemoGroup> groupMemosByDay(List<Memo> memos, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final groups = <MemoGroup>[];

  for (final memo in memos) {
    final t = memo.updatedAt;
    final isNewDay = groups.isEmpty || !isSameDay(groups.last.date, t);
    if (isNewDay) {
      final isToday = isSameDay(t, reference);
      final isYesterday = isSameDay(
        t,
        reference.subtract(const Duration(days: 1)),
      );
      groups.add(
        MemoGroup(
          date: t,
          title: isToday
              ? '今天'
              : isYesterday
              ? '昨天'
              : dateLandmarkLabel(t, now: reference),
          subtitle: (isToday || isYesterday)
              ? fullDateStamp(t, now: reference)
              : weekdayLabel(t),
          isToday: isToday,
          memos: [],
        ),
      );
    }
    groups.last.memos.add(memo);
  }
  return groups;
}
