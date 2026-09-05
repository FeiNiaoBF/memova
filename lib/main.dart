import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'data/providers.dart';
import 'features/memo_list/ui/memo_list_screen.dart';
import 'theme/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One database instance for the whole app. Purge memos trashed more than
  // 30 days ago before the first frame (user story 16); the same instance
  // is handed to the widget tree so UI and purge share one connection.
  final db = openAppDatabase();
  await db.memosDao.purgeTrashedMemos();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MemovaApp(),
    ),
  );
}

/// Root of the app. Theming follows the system (Material 3, light + dark);
/// 黛绿 seed with a 朱红 error role (see theme/themes.dart).
class MemovaApp extends StatelessWidget {
  const MemovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memova',
      theme: memovaTheme(Brightness.light),
      darkTheme: memovaTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MemoListScreen(),
    );
  }
}
