---
version: alpha
name: Memova — 黛绿 (Dài Lǜ)
description: "Material 3 app identity: a muted ink-green seed with a vermilion error role. Single-user, text-first memo app."
colors:
  seed: "#3B7A57"
  primary-light: "#296A48"
  onPrimary-light: "#FFFFFF"
  primaryContainer-light: "#ADF2C6"
  onPrimaryContainer-light: "#075232"
  primary-dark: "#92D5AB"
  onPrimary-dark: "#003920"
  primaryContainer-dark: "#075232"
  onPrimaryContainer-dark: "#ADF2C6"
  secondary-light: "#4E6355"
  tertiary-light: "#3B6471"
  surface-light: "#F6FBF4"
  onSurface-light: "#171D19"
  surface-dark: "#0F1511"
  onSurface-dark: "#DFE4DD"
  error-light: "#BC3510"
  errorContainer-light: "#FBD9D0"
  onErrorContainer-light: "#8D280C"
  error-dark: "#F7B3A1"
  errorContainer-dark: "#8D280C"
  onError-dark: "#330E0B"
  onErrorContainer-dark: "#FBD9D0"
components:
  snackbar:
    behavior: floating
omitted:
  - section: rounded
    reason: "Material 3 default shape tokens in use; expressive shape pass deferred."
  - section: spacing
    reason: "Material 3 default spacing; no custom scale yet."
  - section: typography
    reason: "Material 3 type scale with system fonts; custom font undecided."
---

# Memova Design System

## Operating Principles (adopted from Google M3 + Apple HIG)

Every component decision is judged against these; when Google and Apple pull
against each other, memova resolves the conflict by letting **黛绿 be the only
loud element** and simplifying everything else.

1. **Deference (Apple):** the UI recedes; memo text is the star. Chrome stays
   minimal, borders stay zeroed where content lives.
2. **Clarity (Apple):** text is never smaller than it needs to be; icons are
   precise line icons at one stroke weight; numerals are tabular.
3. **Depth (Apple) / Motion meaningful (M3):** transitions explain spatial
   relations (editor rises like a sheet; a deleted memo slides out left).
4. **Accessibility by default (M3):** contrast comes from the algorithm, touch
   targets stay ≥48dp, every state is visible.
5. **States communicate (M3):** every tappable has a hover/pressed state layer.
6. **Hierarchy by tone (M3):** layering uses surface-container tones, not
   shadows or extra colors.
7. **Identity concentrated (M3 expressive × Apple subtle):** 黛绿 carries the
   identity; adornment everywhere else is subtracted.

## Overview

Memova is a personal, local-first memo app: a single column of plain-text
notes, no titles, no accounts. The UI must feel like a **calm instrument for
writing** — native Material 3 first, never decorative.

The identity is **黛绿 (dài lǜ)**, a muted deep green. The seed is deliberately
restrained: it should read as *ink with a green soul*, not as fresh or playful.
One semantic red — **朱红 (vermilion)** — is reserved exclusively for
destructive actions (delete, empty trash). Green creates and carries; red
destroys. Nothing else is allowed to shout.

Dark mode is a first-class target, not an afterthought (see Colors).

## Colors

The palette is **derived, not hand-picked**: at runtime the app builds
`ColorScheme.fromSeed(seed: #3B7A57, variant: tonalSpot)` and the Material 3
algorithm produces every role. This file records the seed, the variant, and the
hand-made overrides — never a frozen copy of all 45 roles (they would drift
from the algorithm).

- **Seed #3B7A57 (黛绿):** a muted, low-tone green. Under `tonalSpot` it
  survives faithfully as a deep ink-green (light primary #296A48) instead of
  being washed out, because its identity *is* restraint.
- **Surfaces:** faintly green-tinted (light #F6FBF4 / dark #0F1511). Depth is
  tonal (surfaceContainerLow → High), not shadowed.
- **Tertiary:** the algorithm lands on a teal (light #3B6471 / dark #A3CDDC) —
  a quiet complement; do not fight it.
- **Error — 朱红 vermilion override:** Material's error roles are *not*
  seed-derived (they stay crimson whatever the seed). Memova replaces them with
  the 朱红 family, re-toned to Material's error role structure so contrast is
  preserved: light error tone 40 (#BC3510) on container tone 90 (#FBD9D0);
  dark error tone 80 (#F7B3A1) on container tone 30 (#8D280C). On/on-container
  text follow Material's tone rules.
- **Why not `vibrant`:** for this seed, vibrant pushes the dark-mode primary to
  a near-neon green (#00E390) — the opposite of 黛绿's character. `tonalSpot`
  is correct *because* the seed is already muted. (For a bright seed this
  reasoning inverts — see Do's and Don'ts.)

## Typography

**Fonts — two-voice system (confirmed 2026-09):**

- **Sans (default):** system `Noto Sans CJK` / Roboto for everything functional
  — rows, previews, timestamps, buttons, editor text (17→**18px**/1.75 tuned).
- **Serif (accent, system):** the device's system serif (AOSP ships
  `NotoSerifCJK-Regular.ttc`; accessed via `fontFamily: 'serif'` with a sans
  fallback chain — **zero bundle size**) for exactly two identity moments: the
  empty-state declaration 「想到，就写下来。」 and the app bar title. Serif = the
  writing semantics; it never touches functional text (small-size CJK serif
  readability is a red line). If a device fails to resolve the system serif,
  the fallback renders sans — graceful, zero-cost degradation.
- **Sizes (tuned):** group date 13→**14** (anchor presence); editor 17→**18**
  (writing comfort). Everything else per the M3 scale in the token block.

## Layout

A single-column list, newest-updated first, full-bleed on the phone. One
primary action per screen (the FAB — *write*). Spacing rhythm (tokens):
screen edge 20px; row vertical 12px; group header top 16px (first 10px);
app bar 56px; FAB margins 16px; **list bottom clearance 96px** (last row must
never hide under the FAB).

**Component logic rules:** the top bar is fixed (no scroll-under overlap);
groups follow `updatedAt` (an old memo edited today joins 今天 — consistent
with newest-first); search results render as a flat list (no landmark groups —
search is finding, not reminiscing); the Trash renders flat, sorted by
trashedAt.

## Elevation & Depth

Depth is **tonal**, not shadowed: surface container tones separate the app bar,
rows, dialogs, and the floating snackbar from the page. No drop shadows beyond
Material defaults, no glass, no gradients.

## Components

- **Top app bar (confirmed 2026-09):** **transparent** — no tint, content runs
  to the top edge (Deference). Title `Memova` 22px/500 left-aligned (Clarity);
  actions are precise line icons (search, trash) at one 1.7px stroke weight,
  44dp touch targets. Rejected: surface-container tint (B) — a memo list stays
  short enough that a scroll anchor isn't worth the added chrome.
- **FAB (primary, confirmed 2026-09):** the only primary-color action — creating
  a memo. Never more than one. Shape: **16px rounded square** (M3 official FAB
  shape, same family as the 12px cards; full-circle is an M2 habit and reads
  as "old Material"). Position: bottom-right — the natural thumb zone (49% of
  users hold phones one-thumbed; Hoober's 1333-user field study). Touch
  targets ≥48dp (Fitts); icon-button min raised from 44 to 48dp.
- **Buttons — five states, five jobs (confirmed 2026-09):** the M3 emphasis
  hierarchy maps to fixed roles: `filled` = the single primary/final action
  per screen (写第一条); `tonal` = secondary, non-create actions (去回收站看看);
  `outlined` = the safe side of a destructive dialog (取消); `text` = lowest-
  weight actions (Undo in the snackbar); `error` = destruction only (清空).
  The `elevated` variant is deliberately unused. Every tappable gets M3 state
  layers — hovered 8%, focused/pressed 10% foreground overlay (verified in the
  Flutter SDK) — for free from Material components; never hand-roll them.
- **List rows — MemoRow (confirmed 2026-09):** an M3 **two-line list**
  idiom (Apple Notes family): the body's first line renders **semibold
  (titleMedium) as the implicit title** — the visual answer to "no titles"
  (ADR-0003) — with a muted second-line preview and the relative timestamp
  right-aligned (labelSmall, tabular numerals). Dense rows (M3 List), hover
  state layer = onSurface tint; market precedent: Apple Notes. Card variants
  were rejected: memova has no tags/colors (Keep) and is not a fragment feed
  (flomo). The earlier editorial/flat-row exploration was superseded by this
  research-grounded choice. Swipe-left (Dismissible) deletes.
- **Time presentation (confirmed 2026-09, research-driven):** the list is
  grouped by **date landmarks** — 今天 (with the real date + weekday), 昨天,
  then real dates (`8月22日 周六`) — never vague buckets like "更早".
  Rationale: memory reconstructs when-things-happened from landmarks,
  chronology and context, not precise clocks (Nature Rev. Psychol. 2025
  temporal-cognition review; Risko & Gilbert 2016; Gilbert et al. 2023).
  Timestamps are **hybrid**: within 24h rows show relative time (刚才 /
  3小时前); beyond 24h the date lives at the group anchor and row-level time
  is dropped (redundant). Graphic timeline rails were rejected (no research
  support; Gantt-chart risk). Code impact: `relativeTime()` becomes hybrid,
  list gains date-group headers.
- **Empty state (confirmed 2026-09, two contexts):**
  - *First launch / fully emptied* (list empty + trash empty): a typographic
    declaration — 「想到，就写下来。」(display, 黛绿 emphasis on 写下来) + the
    three refusals recast as promises (无标题/无分类/无网络 → they are
    commitments, not missing features) + a filled-primary CTA 「写第一条」
    (duplicates the FAB action — acceptable; NN/g: first-use empty states are
    onboarding opportunities with a clear next action). No illustrations.
  - *List empty but Trash has content*: 「都还在。」 + a tonal (secondary
    container) button 「去回收站看看」 — deliberately NOT primary: it is not a
    create action. This state protects against the "did I lose everything?"
    misreading and surfaces the recovery path.
  - Context rule: the empty state switches on trash content, not on a
    first-run flag — zero new state needed (watchTrashedMemos already knows).
- **Delete / undo (confirmed 2026-09, with confirmation policy):** swiping
  moves the memo to Trash (sets `trashedAt`) — **no confirmation**, a floating
  SnackBar offers Undo (4s, text button). Restoring restores *unchanged*
  (updatedAt untouched). Single-memo **Delete forever does NOT confirm**: the
  trash itself is the safety buffer, the two-step menu is already friction,
  and the 30-day purge would delete it anyway. **Exactly one confirmation
  exists in the whole app** — emptying the Trash — because habituation
  research shows confirmations lose their power when overused (81% of users
  click through similar dialogs). Dialog copy must be **specific** (state the
  count: "2 条备忘"), never vague. Dialog chrome uses error roles, not primary.
- **Editor (confirmed 2026-09):** a bare full-bleed writing surface (17px/1.75,
  no borders, no container — Deference/CLT), autofocus, **plus a quiet save
  state line** (`已保存` with a small primary dot, 11px) under the app bar.
  Rationale: cognitive offloading is governed by **confidence in the external
  store** (Boldt & Gilbert 2019) — the write-through queue guarantees the
  save, but an invisible guarantee doesn't earn the trust people need before
  they stop re-checking; the save line is germane feedback (flow's
  immediate-feedback condition), not extraneous chrome. A card-style editor
  surface was rejected: a decorative container adds extraneous load and breaks
  continuity with the list's flat rows.
- **Empty state:** icon + two lines, in primary/secondary — informational, not
  decorative.
- **Debug tooling:** a theme gallery (color roles, type, buttons, dialogs,
  snackbar, surfaces) exists behind `kDebugMode` for design iteration; it never
  ships in release.

## Do's and Don'ts

### Deferred tuning checklist（全局微调轮的清单 —— 结构全部锁完后集中做）

- 字级逐项过：列表行/时间戳/空态/编辑器的字号与行高是否统一节奏
- 颜色应用逐项过：onSurfaceVariant / outline 的使用场景是否一致，时间戳颜色深浅
- 间距节奏：组与组、行与行、屏幕边缘
- 明暗两套逐项对照

### General

- Do keep the M3 algorithm as the single source of truth: change the **seed or
  variant**, never hand-replace the derived palette role by role.
- Do reserve 朱红 error red for destructive actions; it must not become a
  highlight color.
- Don't switch this seed to `vibrant`/`fidelity` variants — the dark-mode
  primary goes neon or the tertiary turns pink; if the palette needs more
  energy, change the *seed family* instead of cranking chroma.
- Don't offer two themes that differ only in the brightness of the **same hue**
  family — `tonalSpot` normalizes chroma and they will read as identical.
- Don't use purple gradients, stock illustrations, emoji-as-icons, or
  meaningless glassmorphism; a memo app must stay quiet.
- Do keep text-first: rows are typography, not cards.
- Don't bury content in elevation or decoration; 黛绿 is the mood, white space
  is the frame.

## Accessibility

- Color roles come from the Material algorithm with its built-in WCAG contrast
  discipline; the 朱红 override keeps Material's tone structure (error tone
  40/80, containers 90/30) precisely so contrast survives the hue change.
- On/on-container pairs must not be re-picked by eye — if the vermilion family
  needs adjustment, re-tone through the same role structure.
- Destructive actions must stay legible as such in both light and dark mode
  (distinct error container + on-color pairs above).
