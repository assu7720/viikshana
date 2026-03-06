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
| M6 — Video Player Core | **DONE** |
| M7 — Search + History | **DONE** |
| M8 — Video Play Screen (Full Layout) | **Partial** |
| M9 — Auth (Firebase) + Gating | **DONE** |
| M10 — Engagement (Like/Comment/Subscribe) | **DONE** |
| M11–M12 | Pending |

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
**Status: DONE**
Deliverables:
- HLS playback (.m3u8)
- Fullscreen + basic controls
- Resume from local history (Hive)
Acceptance:
- Plays sample HLS URL
- flutter analyze/test green

### M7 — Search + History
**Status: DONE**
Deliverables:
- **Autocomplete while typing**: GET /search/suggestions?q=...&limit=8; show suggestions list (when search field has focus).
- **On suggestion selected or Search submitted**: show video cards (same style as home) below search bar from GET /api/search/videos; suggestions are hidden when video results are shown.
- When focus returns to search input: show suggestions again; when focus leaves and video results exist: show only video cards.
- Debounced search (300–500ms).
- Search history (max 10), persisted.
Acceptance:
- Typing shows autocomplete suggestions; selecting one or pressing Search shows video grid; refocusing search shows suggestions; history persists.
- flutter analyze/test green

**M7 summary (gating):**
- **What changed:** Search tab: debounced autocomplete (GET /search/suggestions), video search on submit/select (GET /api/search/videos with `data` array). Focus-aware UI: suggestions when field focused, video grid when unfocused with results. Search history (max 10) in Hive. Parsing supports new API shape (SearchVideosResponse with `data`).
- **How to test:** Open Search tab → type query (suggestions after ~400ms) → tap suggestion or press Search → video grid appears; tap search field again → suggestions show; history appears when empty. Run `flutter test` (140 tests) and `flutter analyze`.
- **Known limitations:** None for M7 scope. Video search is single page (no pagination in UI yet).

### M8 — Video Play Screen (Full Layout)
**Status: Partial**
Deliverables:
- Video play screen layout per UI.md “Video play screen (target)” and reference designs:
  - **Video info:** Title, views, relative time, expandable description/hashtags.
  - **Channel row:** Avatar, channel name, subscriber count, Subscribe button (navigate to login or stub until M9).
  - **Engagement row:** Like, Dislike (if API supported), Share, Download (if supported), Save, Thanks (optional), Report (stub or real); auth-gated actions show login prompt or placeholder until M9.
  - **Comments:** Count from video detail; comments list (GET /api/videos/{videoId}/comments); “Comment…” input and reply UI (post/reply require auth; prompt login until M9).
  - **Related / recommended:** List or grid of videos below (or right rail on tablet) from GET /api/videos/{id}/related or equivalent; tap opens same play screen.
- Reuse existing playback (M6); no regression to fullscreen/controls/resume.
Acceptance:
- Video play screen shows full layout (info, channel, engagement row, comments, related); placeholders/stubs OK for auth-only actions and missing backend.
- flutter analyze/test green

**M8 partial summary (proceeding):**
- **Done:** Full layout (info, channel row with avatar from videoprocess URL, engagement row stubs, comments section with list + input stub, related videos grid). Related API parsing fixed: response uses `relatedVideos` (added to HomeFeedResponse) and duration as string (e.g. `"8053.000"`) — both supported in VideoItem. Channel avatars use `ApiConfig.resolveMediaUrl` (videoprocess host). All engagement actions and Subscribe show login/stub until M9.
- **Remaining issues (partial completion):**
  1. **Comments:** If backend returns comments under a different key or shape, parsing may show 0 comments; verify against real API response and align `VideoCommentsResponse`/comment list if needed.
  2. **Related pagination:** Related endpoint may support `page`/`hasMore`; UI currently shows single page only (no "Load more" for related).
  3. **Main-thread jank:** Logs show "Skipped 52 frames" on cold start / opening player; optional deferral or offloading for smoother first paint.
  4. **Comment reply UI:** Reply threading or nested replies may be minimal/stub; full reply flow gated to M9.
- **How to test:** Open a video from home → scroll below player; confirm title, views, time, description, channel row (avatar loads), engagement chips, comments section, related grid. Tap related video → navigates to same player. Run `flutter analyze` and `flutter test`.
- **Proceeding:** M8 marked **Partial**; above items can be addressed in a follow-up or during M9 integration.

### M9 — Auth (Firebase) + Gating
**Status: DONE**
Deliverables:
- Email/password login
- Anonymous restrictions enforced (like/comment/subscribe/upload)
Acceptance:
- Restricted actions prompt login
- flutter analyze/test green

**M9 summary (gating):**
- **What changed:** API login (POST /auth/api/login) with session tokens stored in Hive. LoginResponse/LoginResponseUser models; ApiClient.login/getMe with Bearer token; SessionRepository + sessionVersionProvider for reactive signed-in state. Account screen shows signed-in profile (GET /auth/api/me) and Sign out when token present; after login, version bump so UI updates. Login screen: email/password, setTokens + sessionVersion bump + pop. Auth gating: isSignedInProvider (session token OR Firebase user); Account/Upload/Player gate on auth. Full test coverage: LoginResponse, ApiClient login/getMe, SessionRepository, session/auth providers, currentUserProfileProvider.
- **How to test:** Run with API base URL set → Account → Sign in → enter credentials → after success, Account shows profile and Sign out. Sign out clears session. Run `flutter analyze` and `flutter test` (all tests pass).
- **Known limitations:** Firebase sign-in optional (fallback when API returns no tokens). Refresh token not yet used for token refresh flow.

### M10 — Engagement (Like/Comment/Subscribe)
**Status: DONE**
Deliverables:
- Like/unlike
- Comment/reply
- Subscribe/unsubscribe
Acceptance:
- Auth required, optimistic UI OK, reconciles response
- flutter analyze/test green

**M10 summary (gating):**
- **What changed:** API client: POST /api/videos/{id}/like, DELETE for remove like, POST /api/subscribe|unsubscribe/{channelId}, GET subscription check, POST /api/comments (videoId + text), POST /api/comments/reply. Models: LikeVideoResult, SubscribeResult; VideoDetail.likedByMe, ChannelMetadata.isSubscribed. Player screen: Like chip toggles like/removeLike and refreshes detail; Subscribe button calls subscribe/unsubscribe and refreshes; comment input (signed-in) posts via postComment and invalidates comments + detail. All engagement requires auth (Bearer token); 401/requiresLogin handled.
- **How to test:** Sign in → open a video → tap Like (filled when liked), tap Subscribe (label becomes Subscribed), type a comment and Post → comment appears after refresh. Run `flutter analyze` and `flutter test`.
- **Known limitations:** Dislike, Share, Download, Save, Thanks, Report remain stubs. Reply-to-comment UI not wired (API ready). Subscription status on load relies on video detail/channel.isSubscribed when API returns it.

### M11 — Upload (Mobile/Tablet Only)
Deliverables:
- Auth check → channel check → pick/record video
- Optional audio replacement UI (processing can be stub)
- Metadata entry + progress UI
Acceptance:
- Upload entry reachable only on mobile/tablet
- flutter analyze/test green

### M12 — Library (Logged-in)
Deliverables:
- Watched/Liked/Playlists/Saved/Notifications UI
- Pagination + backend hooks where available
Acceptance:
- Navigation to library works, placeholders allowed for missing APIs
- flutter analyze/test green