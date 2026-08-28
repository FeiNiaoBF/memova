# Memova

A personal, local-first memo app for Android: plain-text memos, no titles, no accounts, no cloud. Open it and type.

## What it is

- **Memo** — a single piece of plain text with no separate title; the list shows its first line(s).
- **List** — the home screen: newest-updated-first, searchable.
- **Trash** — deleted memos rest here for 30 days before automatic purge.
- **Local-first** — all data lives on the device. No sync, no backend (ADR-0004).

See [CONTEXT.md](CONTEXT.md) for the domain glossary and [docs/adr/](docs/adr/) for decisions.

## Tech

Flutter (Android) · Drift (SQLite, ADR-0001) · Riverpod (ADR-0002) · Material 3, system dark mode.

## Architecture rules

1. **Group code by feature** (feature-first directories), not by technical layer.
2. **Data access only via the data layer** — UI never touches SQL.
3. **State only via providers** — widgets hold no business state.

Deliberately absent: repository interfaces, use-case layers, domain entity layers. The Drift in-memory database is the single test seam; a repository seam will be introduced the day cloud sync becomes real (ADR-0004).

## Run

```sh
flutter pub get
flutter run            # on a connected device/emulator
```

## Test

```sh
flutter analyze
flutter test
```

CI runs both on every push and PR (`.github/workflows/ci.yml`). Building the APK requires an Android SDK locally: `flutter build apk`.

## Status

Work is tracked as GitHub issues; the spec is [#1](https://github.com/FeiNiaoBF/memova/issues/1) with tracer-bullet tickets blocked-first beneath it.
