import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The app-wide database instance.
///
/// Tests override this with an in-memory database — that override is the
/// whole testing strategy of this app (spec: Testing Decisions).
final databaseProvider = Provider<AppDatabase>((ref) => openAppDatabase());
