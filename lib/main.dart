import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/memo_list/ui/memo_list_screen.dart';

void main() => runApp(const ProviderScope(child: MemovaApp()));

/// Root of the app. Theming follows the system (Material 3, light + dark).
class MemovaApp extends StatelessWidget {
  const MemovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MemoListScreen(),
    );
  }
}
