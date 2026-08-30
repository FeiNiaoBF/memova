import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/providers.dart';

/// Live memos, newest-updated first, as a reactive stream.
///
/// Every write to the `memos` table re-emits here, so the List updates by
/// itself — no setState, no refresh, no manual reload.
final liveMemosProvider = StreamProvider<List<Memo>>((ref) {
  return ref.watch(databaseProvider).memosDao.watchLiveMemos();
});
