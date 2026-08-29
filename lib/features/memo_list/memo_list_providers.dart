import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';

/// The app-wide database instance.
///
/// Tests override this with an in-memory database — that override is the
/// whole testing strategy of this app (spec: Testing Decisions).
/// Lives here for now; moves to `lib/data/` when a second feature arrives.
final databaseProvider = Provider<AppDatabase>((ref) => openAppDatabase());

/// Live memos, newest-updated first, as a reactive stream.
///
/// Every write to the `memos` table re-emits here, so the List updates by
/// itself — no setState, no refresh, no manual reload.
final liveMemosProvider = StreamProvider<List<Memo>>((ref) {
  return ref.watch(databaseProvider).memosDao.watchLiveMemos();
});
