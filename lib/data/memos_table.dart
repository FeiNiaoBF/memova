import 'package:drift/drift.dart';

/// A single plain-text memo with no separate title (ADR-0003).
@DataClassName('Memo')
class Memos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn? get trashedAt => dateTime().nullable()();
}
