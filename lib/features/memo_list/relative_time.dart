/// A compact "how long ago" label for a memo's `updatedAt`.
///
/// Pure function, no Flutter dependency — trivially unit-testable.
/// `[now]` is injectable so tests are deterministic.
String relativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';

  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}
