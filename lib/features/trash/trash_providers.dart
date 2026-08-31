import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/providers.dart';

/// Trashed memos, most-recently-trashed first, as a reactive stream.
///
/// Feeds the Trash screen (#6). Any change to the `memos` table (restore,
/// delete, purge) re-emits here automatically. `autoDispose`: the stream
/// lives only while the Trash screen is open — popping the route releases
/// it, so it never lingers behind the List (and never double-subscribes
/// the database with the List's own stream).
final trashedMemosProvider = StreamProvider.autoDispose<List<Memo>>((ref) {
  return ref.watch(databaseProvider).memosDao.watchTrashedMemos();
});
