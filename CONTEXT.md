# Memova

Memova is a personal, local-first memo app for Android. It stores plain-text memos on the device and renders them as a simple Material 3 list.

## Language

**Memo** (备忘):
The core unit of the app: a single piece of plain text with no separate title. The list view displays the memo's first line(s) as its face.
_Avoid_: Note, 笔记 (Note implies richer structure this app deliberately doesn't have)

**Trash** (回收站):
Where deleted memos live until they are permanently removed. Deleting a memo moves it here; it is never lost instantly.
_Avoid_: Deleted, 已删除 (this is a place, not a state)

**Local-first** (本地优先):
All memo data lives on the device; there is no account, no backend, no cloud sync. The app must work fully offline.
_Avoid_: Cloud, 云同步 (an explicit non-goal)

**List** (列表):
The home screen: a reverse-chronological single-column list of memos, searchable, with the newest updated memo on top.
_Avoid_: Grid, 网格 (this app is text-first, not card-grid)
