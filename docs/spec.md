# Spec: Memova MVP (v1)

> Published as issue on GitHub; this file is the versioned copy. Vocabulary follows [CONTEXT.md](../CONTEXT.md); decisions reference ADRs in [docs/adr/](../adr/).

## Problem Statement

As a single user, I lose track of small thoughts and to-remember items. Existing note apps demand accounts, cloud sync, titles, and structure before I can capture anything — the cost of writing one line is too high, and my notes end up locked in someone else's cloud.

## Solution

Memova: a local-first Android memo app. Open it and a single-column List of plain-text Memos appears, newest-updated first. One tap starts a new Memo — no title, just the body, saved automatically as I type. Deleted Memos go to a Trash for 30 days instead of vanishing. Everything lives on the device: no account, no network, no sync (ADR-0004).

## User Stories

1. As a user, I want to open the app and see my Memos listed immediately, so I can find recent thoughts without navigation.
2. As a user, I want Memos sorted by last-updated descending, so the memo I just touched is always on top.
3. As a user, I want to create a new Memo with a single tap, so capture is instant.
4. As a user, I want to write a body with no title field (ADR-0003), so I never stop to name anything.
5. As a user, I want edits saved automatically as I type, so there is no save button and no lost text.
6. As a user, I want a draft to survive the app being killed mid-typing, so an interruption never costs me a thought.
7. As a user, I want closing an untouched empty editor to leave no new Memo behind, so the List stays clean.
8. As a user, I want to open an existing Memo and continue editing it, so memos can grow over time.
9. As a user, I want to delete a Memo from the List, so clutter goes away in one action.
10. As a user, I want deleted Memos to move to the Trash instead of vanishing, so mistakes are reversible.
11. As a user, I want a brief undo affordance right after deleting, so an accidental swipe costs me nothing.
12. As a user, I want to view everything currently in the Trash, so I know what I've thrown away.
13. As a user, I want to restore a Memo from the Trash back to the List.
14. As a user, I want to permanently delete a single Memo from the Trash.
15. As a user, I want to empty the whole Trash at once, with a confirmation, so bulk cleanup is safe.
16. As a user, I want Memos trashed more than 30 days ago to be purged automatically, so the Trash doesn't grow forever.
17. As a user, I want to search my Memos by body text, so old Memos are findable without scrolling.
18. As a user, I want search to filter the List live as I type, case-insensitively, so results feel instant.
19. As a user, I want search to cover only non-trashed Memos, so the Trash doesn't pollute results.
20. As a user, I want the app to follow the system dark mode (ADR on theming: Material 3), so it's comfortable at night with no settings screen.
21. As a user, I want the app fully usable offline with all data on the device, so my notes exist only for me.
22. As a user, I want a clear empty state on first launch, so an empty List doesn't look broken.
23. As a user, I want each List row to show the Memo's first line(s) and a relative timestamp, so I can recognize memos at a glance.

## Implementation Decisions

- Flutter (stable channel), Android only, min SDK = Flutter default; app display name **Memova**, Android applicationId **`com.yeekox.memova`**.
- UI: Material 3, single-column List, system-following light/dark theming. No settings screen in v1.
- Persistence: Drift (SQLite) — ADR-0001. One `memos` table: `id`, `body`, `createdAt`, `updatedAt`, `trashedAt` (nullable; null = live memo). Timestamps managed by the data layer.
- State: Riverpod — ADR-0002. Drift's reactive `Stream`s feed providers; the UI never holds business state and never issues SQL.
- Architecture: feature-first modules with three rules — code grouped by feature under the feature directory; data access only via the data layer (Drift DAO); state only via providers. No repository interface, no use-case layer, no domain entity layer: Drift's in-memory database (`NativeDatabase.memory()`) is the single test seam, so fakes are unnecessary. If cloud sync ever happens, the repository seam is introduced that day (ADR-0004).
- Auto-save: the editor debounces (~500 ms) writes to the database; a Memo row is only created after the first character is typed.
- Trash: deleting sets `trashedAt`; purge runs on app start, removing Memos trashed more than 30 days ago.
- Search: case-insensitive substring match on `body` over live Memos.

## Testing Decisions

- Good tests assert external behavior (what the user sees and can do after an action), never widget internals or provider wiring details.
- Data layer tests run against a real Drift database backed by `NativeDatabase.memory()`: list ordering, trash filtering, search matching, purge cutoff.
- Widget tests pump the real app tree with the in-memory database injected through the provider overrides, then drive taps/typing and assert visible outcomes.
- No prior art exists (greenfield); this spec establishes the conventions.

## Out of Scope

- Cloud sync, accounts, any network activity (ADR-0004).
- Titles, tags/folders, pinning, colors, rich text, markdown, checklists, reminders.
- Export/backup (noted as a likely v2 candidate for a local-first app).
- iOS, desktop, web.
- Settings screens of any kind.

## Further Notes

- Tracer-bullet tickets implementing this spec are separate issues with native GitHub blocking edges, blockers first.
- CI runs `flutter analyze` and `flutter test` on every push/PR from ticket 1 onward.
