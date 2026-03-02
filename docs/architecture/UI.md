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