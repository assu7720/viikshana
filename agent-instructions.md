YOU ARE AGENT 1 (DEVELOPER / BUILD).

Repo: C:\Users\yogis\viikshana
Baseline commit: 2b2b51c

AUTHORITATIVE DOCS (must obey):
- docs/REQUIREMENTS.md
- docs/architecture/API.md
- docs/architecture/UI.md
- docs/architecture/STATE.md

NON-NEGOTIABLE RULES:
1) Do not rename the project. It is Viikshana (double i).
2) Do not implement Windows desktop specific UX. Target platforms: Android phone/tablet, iOS/iPad, Android TV.
3) Preserve the architecture shell:
   - Keep lib/app, lib/core/platform, lib/navigation as the source of platform routing.
   - No direct platform checks inside feature widgets; use core/platform.
4) Navigation requirements:
   - Mobile/Tablet: bottom nav with 5 items: Home, Clips, Upload, Search, Account
   - Bottom nav hidden only during full-screen playback
   - Each tab keeps its own navigation stack (state preserved)
   - Android TV: left sidebar, D-pad focus, NO upload
5) Auth:
   - Anonymous can browse, search, play, view channels/comments
   - Logged-in required for upload, like/comment/subscribe, library, notifications
6) Watch history:
   - Anonymous: local only (Hive)
   - Logged-in: local + sync to backend (best effort, non-blocking)
   - Resume priority: same device first, then most recent cross-device
   - Device ID: Android ANDROID_ID, iOS identifierForVendor, fallback UUIDv4
7) API:
   - Do NOT invent endpoints. Use API.md / OpenAPI contract only.
8) Tests:
   - Add unit/widget tests as you implement
   - Run: flutter test
   - Do not commit unless tests pass

WORK STYLE:
- Implement in this order (each as separate commits):
  1) App theme + UI tokens to match viikshana.com (dark + orange accent) per UI.md
  2) Mobile/Tablet navigation shell with 5 tabs + nested stacks
  3) Android TV shell: left sidebar + focus navigation stubs
  4) API client layer (Dio or http) + models for /videos/home and /videos/{id}
  5) Home screen: responsive grid + infinite scroll (anonymous supported)
  6) Video player: HLS playback + fullscreen + mini player + resume
  7) Search screen: debounce + history (Hive)
  8) Auth (Firebase email/password) + gating actions
  9) Engagement: like/comment/subscribe (logged-in only)
  10) Upload flow (mobile/tablet only): select/record + optional audio replace + metadata + progress UI
  11) Library (logged-in): watched/liked/playlists/saved/notifications (UI + API stubs if not available)

COMMANDS:
- Use flutter run -d emulator-5554 for Android testing
- Use flutter test frequently
- Commit after each working feature with clear message.

Start now with step (1): implement Theme + Color tokens + base typography per UI.md and ensure app compiles/tests pass.













YOU ARE AGENT 2 (TESTER / REVIEWER).

Repo: C:\Users\yogis\viikshana
Baseline commit: 2b2b51c

YOUR JOB:
- Validate Agent 1 commits for correctness and doc compliance.
- Run flutter analyze and flutter test after each significant commit.
- Review UX against docs/architecture/UI.md (especially nav placement, tab stacks, TV sidebar).
- Verify auth gating rules and watch history rules.
- Validate Android TV focus and D-pad navigation (where implemented).

RULES:
1) Never break working code.
2) Do not refactor large areas unless necessary to fix a bug.
3) File feedback as Markdown in: docs/reviews/YYYY-MM-DD_<short-title>.md
   Each report must include:
   - Commit hash reviewed
   - What works
   - Issues (with repro steps)
   - Severity (P0/P1/P2)
   - Suggested fix
4) If you apply a fix:
   - Keep it minimal
   - Add/adjust tests
   - Commit with message: "testfix: <short>"

START PROCESS:
- Monitor git log for new commits.
- When new commit appears:
  1) flutter analyze
  2) flutter test
  3) Add review note in docs/reviews/
Begin now by checking current repo health (flutter analyze + flutter test) and writing an initial baseline report for commit 2b2b51c.