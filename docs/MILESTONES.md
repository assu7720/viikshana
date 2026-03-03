# VIIKSHANA — MILESTONES & GATING

This file defines the build milestones and the gating protocol between Agent 1 (Developer) and Agent 2 (Reviewer).

## Status (done / next)

| Milestone | Status |
|-----------|--------|
| M1 — Theme + Design Tokens | **DONE** |
| M2 — Mobile/Tablet Navigation Shell | **DONE** |
| M3 — Android TV Navigation Shell | **DONE** |
| M4 — API Client + Models | **DONE** |
| M5 — Home Screen (Anonymous) | **DONE** |
| M6 — Video Player Core | Next |
| M7–M11 | Pending |

## Gating Protocol (MANDATORY)

After each milestone, Agent 1 MUST:
1. Run:
   - flutter analyze
   - flutter test
2. Commit with message format:
   - feat(mX): <milestone name>
3. Post a short summary:
   - What changed
   - How to test
   - Known limitations

Then Agent 1 MUST STOP and wait for Agent 2.

Agent 2 MUST respond with exactly one of:
- **GO AHEAD — Milestone Mx approved.**
- **NO GO — Fix required before proceeding.**

Agent 2 must also add a report file:
- docs/reviews/YYYY-MM-DD_Mx_<short-title>.md
Including:
- Commit hash
- Test results
- Issues (P0/P1/P2)
- Repro steps
- Suggested fix

---

## Milestones (LOCKED ORDER)

### M1 — Theme + Design Tokens
**Status: DONE**
Deliverables:
- Dark theme + orange accent aligned to viikshana.com
- Typography scale, spacing tokens, reusable components base
Acceptance:
- App launches on Android emulator
- No UI regressions
- flutter analyze/test green

### M2 — Mobile/Tablet Navigation Shell
**Status: DONE**
Deliverables:
- Bottom nav (5 tabs): Home, Clips, Upload, Search, Account
- Each tab keeps its own navigation stack
- State preserved between tab switches
- Bottom nav hidden during full-screen playback only (stub OK)
Acceptance:
- Switching tabs preserves state
- flutter analyze/test green

### M3 — Android TV Navigation Shell
**Status: DONE**
Deliverables:
- Left sidebar menu per requirements
- D-pad focus navigation + visible focus highlight
- Upload absent on TV
Acceptance:
- All menu items focusable via keyboard arrows
- flutter analyze/test green

### M4 — API Client + Models (Home + Video)
**Status: DONE**
Deliverables:
- HTTP client + base URL config
- Models for /videos/home and /videos/{id}
- Error handling + retries (non-blocking)
Acceptance:
- Unit tests for parsing
- flutter analyze/test green

### M5 — Home Screen (Anonymous)
**Status: DONE**
Deliverables:
- Responsive grid (phone/tablet)
- Infinite scroll using /videos/home
- Video card component
Acceptance:
- Loads home feed, scroll works
- flutter analyze/test green

### M6 — Video Player Core
Deliverables:
- HLS playback (.m3u8)
- Fullscreen + basic controls
- Resume from local history (Hive)
Acceptance:
- Plays sample HLS URL
- flutter analyze/test green

### M7 — Search + History
Deliverables:
- Debounced search (300–500ms)
- Search history (max 10)
Acceptance:
- Search results visible, history persists
- flutter analyze/test green

### M8 — Auth (Firebase) + Gating
Deliverables:
- Email/password login
- Anonymous restrictions enforced (like/comment/subscribe/upload)
Acceptance:
- Restricted actions prompt login
- flutter analyze/test green

### M9 — Engagement (Like/Comment/Subscribe)
Deliverables:
- Like/unlike
- Comment/reply
- Subscribe/unsubscribe
Acceptance:
- Auth required, optimistic UI OK, reconciles response
- flutter analyze/test green

### M10 — Upload (Mobile/Tablet Only)
Deliverables:
- Auth check → channel check → pick/record video
- Optional audio replacement UI (processing can be stub)
- Metadata entry + progress UI
Acceptance:
- Upload entry reachable only on mobile/tablet
- flutter analyze/test green

### M11 — Library (Logged-in)
Deliverables:
- Watched/Liked/Playlists/Saved/Notifications UI
- Pagination + backend hooks where available
Acceptance:
- Navigation to library works, placeholders allowed for missing APIs
- flutter analyze/test green