# VIIKSHANA — UI REQUIREMENTS

Design reference: viikshana.com  
Theme consistency required (colors, contrast, typography).

---

## 1. MOBILE & TABLET (ANDROID + iOS)

### Navigation
- Persistent bottom navigation bar
- 5 tabs:
  1. Home
  2. Clips
  3. Upload
  4. Search
  5. Account

Rules:
- Hidden during full-screen playback
- Each tab maintains its own navigation stack
- Active tab clearly highlighted

---

### Home Screen
- Responsive grid
- Adaptive columns:
  - Phone: 2–3
  - Tablet: 4–6
- Infinite scroll
- Thumbnail + title + channel + views

---

### Upload Flow (Mobile/Tablet only)
1. Auth check
2. Channel check
3. Video select OR record
4. Optional audio replacement
5. Metadata entry
6. Upload progress screen

Advanced channel settings → redirect message to desktop.

---

### Video Player
- Full screen
- Mini player
- Background audio
- PiP (Android)

---

### Video play screen (target — reference: provided samples)

Beyond playback-only: the screen should present full video context and engagement, consistent with the reference layouts (tablet/mobile).

**Layout (below the player):**

1. **Video info**
   - Title (full or truncated with “…more”).
   - Views count and relative time (e.g. “2 wk ago”, “4 hr ago”).
   - Expandable description / hashtags (e.g. “#Tag …more”).

2. **Channel row**
   - Channel avatar/logo.
   - Channel name.
   - Subscriber count (e.g. “7.68 lakh”).
   - **Subscribe** button (state: subscribed / not subscribed; auth required to change).

3. **Engagement row** (icons + labels/counts)
   - **Like** (thumbs-up) with count; **Dislike** (thumbs-down) with count if supported.
   - **Share** (open system share / copy link; may not need backend).
   - **Download** (if supported by backend).
   - **Save** (add to saved/playlist; auth required).
   - **Thanks** / tip (optional; auth + payment).
   - **Report** (auth required).

4. **Comments**
   - Header: “Comments &lt;count&gt;” (from video detail).
   - List of comments: avatar, author name, text, time, optional like/reply.
   - Input: “Comment…” with post (auth required); support replies.

5. **Related / recommended videos**
   - List or grid of video cards (thumbnail, title, channel, views, duration, optional “LIVE”).
   - Tapping opens that video (same play screen).
   - On tablet: can be a right-hand rail; on phone: below comments.

**Current state:** Only video playback is implemented. Above elements are the target; APIs and UI to be added per MILESTONES (e.g. M9 engagement, related-videos endpoint).

---

## 2. ANDROID TV

### Navigation
- Left sidebar
- D-pad only
- No upload

Sidebar items:
- Home
- Clips
- Notifications
- Watched
- Liked
- Playlists
- Saved
- About
- Community Guidelines
- Terms
- Contact

---

### Home (TV)
- Horizontal rows
- Large cards
- Clear focus highlight
- 10-foot readable typography

---

## 3. ACCESSIBILITY
- Minimum contrast ratios
- Focus visibility
- Text scaling support