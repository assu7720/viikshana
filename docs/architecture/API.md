# VIIKSHANA — API CONTRACT

This app integrates with the **ClipsNow backend**.
The provided OpenAPI spec is the single source of truth.

---

## 1. VIDEO FEEDS

### Home Feed
GET /videos/home  
Backend: GET /api/home/videos

Used for:
- Mobile Home
- TV Home rows

Pagination:
- page (1-based)
- limit (max 100)

---

## 2. VIDEO DETAILS & PLAYBACK

### Get Video
GET /videos/{id}  
Backend: GET /api/videos/{id}

Fields required by client:
- HLS playlist URL (.m3u8)
- Duration
- Channel metadata
- Like count
- Comment count

---

## 3. SEARCH

GET /videos/search  
Backend: GET /search or /search/videos

Rules:
- Debounced (300–500ms)
- Empty query returns empty list
- Results may include videos + channels

---

## 4. WATCH HISTORY

### Record Watch Time
POST /watch-history  
Backend: POST /api/videos/{videoId}/watch-time

Sent only when:
- User is logged in

Payload must include:
- videoId
- watchTime (seconds)
- watchPercentage
- completed
- deviceId
- platform

Anonymous users:
- Local only
- Never sent to backend

---

## 5. ENGAGEMENT

### Likes
POST /likes  
Backend: POST /api/videos/{id}/like

Auth required.

---

### Comments
POST /comments  
Backend:
- POST /comment/{videoId}
- POST /api/comments/reply

Auth required.
Channel may require subscription.

---

### Subscriptions
POST /subscribe  
Backend:
- POST /api/subscribe/{channelId}
- POST /api/unsubscribe/{channelId}

Auth required.

---

## 6. ERROR HANDLING

If response includes:
requiresLogin = true

→ Client must prompt authentication.