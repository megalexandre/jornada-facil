---
name: flutter-responsive-ui
description: >-
  Helps build and adjust responsive Flutter screens — ones that work well both
  on a phone (portrait, touch) and in a wide desktop/web window. Use when the
  request involves creating a new screen/widget, fixing a layout that stretches
  or feels cramped in a wide window, choosing breakpoints, adapting navigation
  for desktop, or "make it responsive" / "works on the computer too". Applies to
  both the mobile app and the web build (`app/lib`) — same Dart code on both.
---

# Responsive screens — jornada Flutter app

The devcontainer's `web` service serves the same code at `localhost:8080` (see
the `run` skill), so every screen runs on a phone **and** in a wide window. The
base is `lib/shared/utils/responsive.dart`:

- `context.isCompact` / `context.isExpanded` — width bands (cutoffs at 600 and
  840, Material 3 window size classes).
- `context.horizontalMargin` — 16 on compact, 24 on expanded
  (`AppSpacing.marginMobile`/`marginDesktop`).
- `responsiveValue(context, compact: x, expanded: y)` — pick a value per band.

**MediaQuery vs. LayoutBuilder** (the most common confusion): `context.isCompact`
decides based on the **whole screen** — use it in the page/`Scaffold`. A reusable
widget that decides based on the **space it's given** (a card in a `Row`, a panel
in a split) uses `LayoutBuilder` + `constraints.maxWidth`, never `MediaQuery` —
otherwise it thinks it has the full screen even when squeezed into a column.

## Patterns (by payoff)

1. **Max width.** A `Column`/`ListView` straight in `Scaffold.body` (most screens
   today) stretches to the window edge on desktop. Wrap it in `Center` +
   `ConstrainedBox(maxWidth: 840)` + padding `context.horizontalMargin`. Solves
   almost everything on its own, no per-breakpoint layout.
2. **Adaptive navigation.** In `MainScaffold`, a side `NavigationRail` when
   `context.isExpanded`, otherwise the current bottom `NavigationBar`. Same
   `_allTabs`/permissions/`tracksJourney` filtering — only *where* it's drawn
   changes.
3. **Grids via `responsiveValue`**, not two separate screens. E.g.
   `GridView.count(crossAxisCount: responsiveValue(context, compact: 1, expanded: 3))`.
   Simple tile lists usually just need pattern 1.
4. **No stray pixels in the margin.** Replace `EdgeInsets.symmetric(horizontal: 16)`
   with `context.horizontalMargin`. *Inner* spacing stays in `AppSpacing.*` — only
   the edge margin changes per breakpoint.

## Conventions

- **No new package** (`responsive_framework`, `flutter_screenutil`, etc.):
  `MediaQuery`/`LayoutBuilder` are enough. Same spirit as `AGENTS.md`.
- The utility lives in `lib/shared/utils/`; names in English, comments in
  Portuguese (the repo's Flutter convention, not the Rails "English" rule).
- Web has mouse/keyboard: don't rely on swipe alone for essential actions on expanded.

## Verifying

Check with `dart analyze <files>` (not raw `flutter analyze` — SDK gotcha in
`AGENTS.md`); resize the browser at `localhost:8080`, or pin a widget test's
viewport via `tester.view.physicalSize` + `addTearDown(tester.view.resetPhysicalSize)`.

No screen uses `responsive.dart` yet. When touching one for another reason,
apply at least pattern 1; don't refactor the rest unprompted.
