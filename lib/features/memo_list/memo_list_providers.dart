import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/providers.dart';

/// The active search query on the List (empty = no filtering).
///
/// Updated as the user types in the search field (#7); watched by
/// [liveMemosProvider] so the List re-filters on every change.
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

/// Live memos, newest-updated first, as a reactive stream.
///
/// Every write to the `memos` table re-emits here, so the List updates by
/// itself — no setState, no refresh, no manual reload. When a search query
/// is active, only matching live memos are emitted (#7).
final liveMemosProvider = StreamProvider<List<Memo>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(databaseProvider).memosDao.watchLiveMemos(query: query);
});
