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

Material 3 type scale with system fonts (Roboto / Noto Sans CJK on Android).
No custom family yet — this is an **open decision**. Body text is the hero of
the app; the list renders the memo's first line as plain body text with
ellipsis, never as a styled card.

## Layout

A single-column list, newest-updated first, full-bleed on the phone. One
primary action per screen (the FAB — *write*). Spacing follows Material 3
defaults; density leans slightly roomy so text rows breathe.

## Elevation & Depth

Depth is **tonal**, not shadowed: surface container tones separate the app bar,
rows, dialogs, and the floating snackbar from the page. No drop shadows beyond
Material defaults, no glass, no gradients.

## Components

- **FAB (primary):** the only primary-color action — creating a memo. Never
  more than one.
- **List rows:** `ListTile`; first line(s) of the body with ellipsis +
  a relative timestamp; swipe-left (Dismissible) to delete.
- **Delete / undo:** swiping moves the memo to Trash (sets `trashedAt`), then a
  **floating** SnackBar offers Undo. The destructive surface is the 朱红 error
  color. Undo restores the memo *unchanged* (updatedAt untouched).
- **Destructive confirmation:** emptying the Trash goes through an AlertDialog
  with a Cancel / Empty split. Dialog chrome uses error roles, not primary.
- **Editor:** a bare TextField, autofocus, no chrome; auto-saves.
- **Empty state:** icon + two lines, in primary/secondary — informational, not
  decorative.
- **Debug tooling:** a theme gallery (color roles, type, buttons, dialogs,
  snackbar, surfaces) exists behind `kDebugMode` for design iteration; it never
  ships in release.

## Do's and Don'ts

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
