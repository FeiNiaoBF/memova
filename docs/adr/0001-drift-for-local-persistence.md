# Drift for local persistence

All memo data is stored locally in SQLite via the Drift ORM. We chose Drift over sqflite (raw SQL, no type safety), and over Hive and Isar (both effectively abandoned by their author, so a new app would inherit a maintenance liability). Drift is the community-default, actively-maintained SQLite ORM: type-safe queries, built-in reactive streams, and a stable migration path — the "safe, boring, correct" choice for a local-first app.
