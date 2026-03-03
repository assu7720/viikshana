# M5 — Home Screen (Anonymous) Verification

**Date:** 2025-03-03  
**Scope:** UI/requirements check + test cases for all device types.

## Requirements vs implementation

| Requirement (MILESTONES.md / REQUIREMENTS.md) | Implementation | Status |
|---------------------------------------------|----------------|--------|
| Responsive grid (phone/tablet) | `HomeScreen._crossAxisCount`: width ≥900→6, ≥600→4, ≥400→3, else 2 | ✓ |
| Infinite scroll using /videos/home | `HomeFeedNotifier` uses `getHomeFeed(page, limit)`, `loadMore()` when &lt;200px from bottom | ✓ |
| Video card component | `VideoCard`: thumbnail (16:9), title, channel, views (K/M format) | ✓ |
| Loads home feed, scroll works | `loadInitial()` in initState; GridView.builder with `itemCount` + loading footer when `hasMore` | ✓ |
| Anonymous can view Home (REQUIREMENTS) | No auth; home feed is public | ✓ |
| Pull-to-refresh | `RefreshIndicator` → `refresh()` | ✓ |
| Loading state | Empty + loading → `CircularProgressIndicator` in center | ✓ |
| Error state | `error != null && items.isEmpty` → `_ErrorView` with message + Retry button | ✓ |
| Material 3 / single codebase | Theme + shared components | ✓ |

**TV (Android TV):** M5 deliverable is "Responsive grid (phone/tablet)". On TV, `TvShell` shows a placeholder for the Home menu item (center text "Home"), not the full home feed grid. That aligns with M5 scope; TV home content can be added later.

## Device types — test coverage

| Device | Test (widget_test.dart) | What is asserted |
|--------|-------------------------|------------------|
| Android mobile | Home screen (M5) per device type: Android mobile | HomeScreen, GridView, mock feed |
| iOS mobile | Home screen (M5) per device type: iOS mobile | HomeScreen, GridView, mock feed |
| Android tablet | Home screen (M5) per device type: Android tablet | HomeScreen, GridView, mock feed |
| iPad | Home screen (M5) per device type: iPad | HomeScreen, GridView, mock feed |
| Android TV | Home screen (M5) per device type: Android TV | TvShell, Home menu selected, placeholder content |

## How to re-check

- `flutter analyze` — may report pre-existing issues (theme URIs, deprecated `window`/physicalSize in tests).
- `flutter test` — all tests must pass (79 as of 2025-03-03).
