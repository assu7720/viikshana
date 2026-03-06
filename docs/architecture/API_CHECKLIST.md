# VIIKSHANA — FULL REQUIRED API LIST

Complete list of APIs required to implement all functionality described in:
- **docs/REQUIREMENTS.md**, **docs/MILESTONES.md**, **docs/architecture/API.md**, **docs/architecture/UI.md**, **docs/architecture/STATE.md**, **agent-instructions.md**

**Status:** ✅ In use | 🟡 Pending backend | ❌ To be built  
**Token:** **Mandatory** = `Authorization: Bearer <token>` required; **Optional** = token accepted, response may vary; **No** = anonymous OK.

---

## 1. VIDEO FEEDS & PLAYBACK

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 1.1 | GET | /api/home/videos | No | Query: `page` (1), `limit` (max 100) | `{ "videos" \| "regularVideos": [{ id, title, thumbnailUrl, channelId, channelName, viewCount, ... }], "page", "limit", "hasMore", "nextPage"? }` | ✅ |
| 1.2 | GET | /api/videos/{id} | Optional | Path: `id` | `{ "id", "title", "description"?, "hashtags"?, "thumbnailUrl", "channelId", "channelName", "channel"?: { "id", "name", "avatarUrl", "subscriberCount" }, "viewCount", "durationSeconds", "publishedAt", "hlsUrl", "likeCount", "commentCount", "dislikeCount"? }`. When authenticated include **likedByMe**, **dislikedByMe**? (bool), **subscribedToChannel** (bool). | 🟡 |
| 1.3 | GET | /api/search/videos | No | Query: `q`, `page`, `limit` | Same shape as 1.1 (video list + pagination). | ❌ |
| 1.4 | GET | /api/videos/{id}/related or /api/recommendations?videoId= | Optional | Path: `id` or Query: `videoId`. Query: `limit`? | Same shape as 1.1 (video list for “Related” / “Up next” on video play screen). | ❌ |

---

## 2. SEARCH

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 2.1 | GET | /search/suggestions | No | Query: `q`, `limit` (e.g. 8) | `["suggestion1", ...]` or `{ "suggestions" \| "data": [...] }` | ✅ |
| 2.2 | GET | /api/search/videos | No | Query: `q`, `page`, `limit` | Same as 1.1. | ❌ |

---

## 3. CHANNELS

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 3.1 | GET | /api/channels/{id} | No | Path: `id` | `{ "id", "name", "avatarUrl"?, "subscriberCount"?, "description"?, ... }` | ❌ |
| 3.2 | GET | /api/me/channel or /api/channels/me | **Mandatory** | — | Channel object (as 3.1) or 404/null if no channel. | ❌ |
| 3.3 | POST | /api/channels | **Mandatory** | Body: `{ "name"?, "description"? }` | `{ "id", "name", ... }` (created channel). | ❌ |
| 3.4 | POST | /api/subscribe/{channelId} | **Mandatory** | Path: `channelId` | `{ "success": true }` or 204. Optional: `requiresLogin` if missing token. | ❌ |
| 3.5 | POST | /api/unsubscribe/{channelId} | **Mandatory** | Path: `channelId` | `{ "success": true }` or 204. | ❌ |
| 3.6 | GET | /api/channels/{channelId}/subscription | **Mandatory** | Path: `channelId` | `{ "subscribed": true \| false }`. Optional if 1.2 returns subscribedToChannel. | ❌ |

---

## 4. COMMENTS

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 4.1 | GET | /api/videos/{videoId}/comments | No | Path: `videoId`. Query: `page`, `limit`? | `{ "comments": [{ "id", "videoId", "authorId", "authorName"?, "text", "parentId"?, "createdAt", "likeCount"?, "replies"?: [...] }], "page", "hasMore" }` | ❌ |
| 4.2 | POST | /api/comments or /comment/{videoId} | **Mandatory** | Body: `{ "videoId", "text", "parentId"?: "<commentId>" }` (or videoId in path) | `{ "id", "videoId", "text", "createdAt", ... }`. On auth missing: `{ "requiresLogin": true }`. | ❌ |
| 4.3 | POST | /api/comments/reply | **Mandatory** | Body: `{ "parentCommentId", "text" }` or `{ "parentId", "text", "videoId" }` | Same as single comment object. | ❌ |
| 4.4 | DELETE | /api/comments/{id} | **Mandatory** | Path: `id` | 204 or `{ "success": true }`. Optional. | ❌ |

---

## 5. LIKES

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 5.1 | POST | /api/videos/{id}/like | **Mandatory** | Path: `id`. Body: empty or `{ "action": "like" \| "unlike" }` if toggle | `{ "liked": true }` or 204. On auth missing: `{ "requiresLogin": true }`. | ❌ |
| 5.2 | DELETE | /api/videos/{id}/like | **Mandatory** | Path: `id` | 204 or `{ "liked": false }`. (Omit if 5.1 is toggle.) | ❌ |
| 5.3 | — | (in 1.2) | Optional | — | **likedByMe** (bool) in GET /api/videos/{id} when token present. | ❌ |
| 5.4 | POST | /api/videos/{id}/dislike | **Mandatory** | Path: `id`. Body: empty or `{ "action": "dislike" \| "neutral" }` if toggle | `{ "disliked": true }` or 204. Optional if product has no dislike. | ❌ |
| 5.5 | DELETE | /api/videos/{id}/dislike | **Mandatory** | Path: `id` | 204 or `{ "disliked": false }`. (Omit if 5.4 is toggle.) | ❌ |
| 5.6 | — | (in 1.2) | Optional | — | **dislikeCount**, **dislikedByMe** (bool) in GET /api/videos/{id} when supported. | ❌ |

---

## 6. WATCH HISTORY

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 6.1 | POST | /api/videos/{videoId}/watch-time | **Mandatory** | Path: `videoId`. Body: `{ "watchTime" (seconds), "watchPercentage" (0–100), "completed" (bool), "deviceId", "platform" }` | 204 or `{ "success": true }`. Sent only when logged in. | ❌ |
| 6.2 | GET | /api/me/watched or /api/watch-history | **Mandatory** | Query: `page`, `limit` | `{ "items": [{ "videoId", "video"?: {...}, "watchTime", "watchedAt", "deviceId"?, ... }], "page", "hasMore" }`. | ❌ |

---

## 7. AUTHENTICATION (M8)

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 7.1 | — | (Firebase or backend) | — | Email/password (or token refresh). | Id token / access token for `Authorization: Bearer <token>`. | 🟡 |
| 7.2 | POST | /api/logout | Optional | — | 204 or invalidate server session. | ❌ |
| 7.3 | GET | /api/me or /api/profile | **Mandatory** | — | `{ "id", "email"?, "displayName", "avatarUrl"?, "channelId"?, ... }` | ❌ |
| 7.4 | — | (any endpoint) | — | — | When action requires auth and token missing/invalid: response body may include **requiresLogin: true**; client prompts login. | ❌ |

---

## 8. UPLOAD (M10)

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 8.1 | GET | /api/me/channel or /api/channels/me | **Mandatory** | — | Same as 3.2. | ❌ |
| 8.2 | POST | /api/channels | **Mandatory** | Same as 3.3. | Same as 3.3. | ❌ |
| 8.3 | POST | /api/upload or /api/videos/upload | **Mandatory** | Body: metadata `{ "title", "description"?, "channelId"?, ... }`; or multipart form with file + metadata. | `{ "videoId", "uploadUrl"?, "uploadId"? }` (e.g. for resumable/signed URL) or 201 with video id. | ❌ |
| 8.4 | GET | /api/videos/{id}/processing | **Mandatory** | Path: `id` | `{ "status": "pending" \| "processing" \| "ready" \| "failed", "progress"?: 0–100 }`. Optional. | ❌ |

---

## 9. LIBRARY (M11)

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 9.1 | GET | /api/me/watched | **Mandatory** | Same as 6.2. | Same as 6.2. | ❌ |
| 9.2 | GET | /api/me/liked or /api/likes | **Mandatory** | Query: `page`, `limit` | `{ "videos": [...], "page", "hasMore" }` (same video shape as 1.1). | ❌ |
| 9.3 | GET | /api/me/playlists or /api/playlists | **Mandatory** | Query: `page`, `limit` | `{ "playlists": [{ "id", "name", "videoCount"?, "thumbnailUrl"?, ... }], "page", "hasMore" }` | ❌ |
| 9.4 | GET | /api/playlists/{id} | **Mandatory** | Path: `id` | `{ "id", "name", "videos": [{ ...video item... }], "page"?, "hasMore"? }` | ❌ |
| 9.5 | POST | /api/playlists | **Mandatory** | Body: `{ "name", "visibility"?: "private" \| "public" }` | `{ "id", "name", ... }` | ❌ |
| 9.6 | PATCH | /api/playlists/{id} | **Mandatory** | Body: `{ "name"?, "visibility"? }` | Updated playlist. Optional. | ❌ |
| 9.7 | POST | /api/playlists/{id}/videos | **Mandatory** | Path: `id`. Body: `{ "videoId" }` | 204 or `{ "success": true }` | ❌ |
| 9.8 | DELETE | /api/playlists/{id}/videos/{videoId} | **Mandatory** | Path: `id`, `videoId` | 204. Optional. | ❌ |
| 9.9 | GET | /api/me/saved | **Mandatory** | Query: `page`, `limit` | `{ "videos" \| "items": [...], "page", "hasMore" }` | ❌ |
| 9.10 | POST | /api/videos/{id}/save or /api/save | **Mandatory** | Path: `id` or Body: `{ "videoId" }` | 204 or `{ "success": true }` | ❌ |
| 9.11 | DELETE | /api/videos/{id}/save or /api/unsave | **Mandatory** | Path: `id` | 204 | ❌ |

---

## 10. NOTIFICATIONS

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 10.1 | GET | /api/notifications or /api/me/notifications | **Mandatory** | Query: `page`, `limit`, `unreadOnly`? | `{ "notifications": [{ "id", "type", "title", "body"?, "createdAt", "read"?, "videoId"?, "channelId"?, ... }], "page", "hasMore" }` | ❌ |
| 10.2 | PATCH | /api/notifications/{id}/read or bulk | **Mandatory** | Path: `id` or Body: `{ "ids": [...] }` | 204. Optional. | ❌ |

---

## 11. REPORT

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 11.1 | POST | /api/videos/{id}/report or /api/reports | **Mandatory** | Path: `id`. Body: `{ "reason" (enum or string), "details"?: "text" }` | 204 or `{ "success": true }`. On auth missing: `{ "requiresLogin": true }`. | ❌ |

---

## 12. STATIC / LEGAL (optional)

| # | Method | Path | Token | Request | Response | Status |
|---|--------|------|--------|---------|----------|--------|
| 12.1 | GET | /api/content/about, /terms, /guidelines, /contact | No | — | HTML or `{ "title", "body" }`. Optional; can be in-app static. | ❌ |

---

## SUMMARY — TOKEN & BODIES

| Domain | Method | Path | Token | Request body / Query | Response (key) |
|--------|--------|------|--------|------------------------|----------------|
| Feeds | GET | /api/home/videos | No | page, limit | videos[], page, hasMore |
| | GET | /api/videos/{id} | Optional | — | video + description?, hashtags?, channel.subscriberCount, likedByMe?, dislikedByMe?, subscribedToChannel? (when auth) |
| | GET | /api/search/videos | No | q, page, limit | same as home |
| | GET | /api/videos/{id}/related | Optional | limit? | video list (Related/Up next) |
| Search | GET | /search/suggestions | No | q, limit | string[] or { suggestions } |
| Channels | GET | /api/channels/{id} | No | — | channel object |
| | GET | /api/me/channel | **Mandatory** | — | channel or 404 |
| | POST | /api/channels | **Mandatory** | name?, description? | channel |
| | POST | /api/subscribe/{channelId} | **Mandatory** | — | success |
| | POST | /api/unsubscribe/{channelId} | **Mandatory** | — | success |
| | GET | /api/channels/{id}/subscription | **Mandatory** | — | { subscribed } |
| Comments | GET | /api/videos/{videoId}/comments | No | page?, limit? | comments[], page, hasMore |
| | POST | /api/comments | **Mandatory** | videoId, text, parentId? | comment |
| | POST | /api/comments/reply | **Mandatory** | parentCommentId, text | comment |
| Likes | POST | /api/videos/{id}/like | **Mandatory** | — or { action } | liked / 204 |
| | DELETE | /api/videos/{id}/like | **Mandatory** | — | 204 |
| | POST | /api/videos/{id}/dislike | **Mandatory** | — or { action } | disliked / 204 *(optional)* |
| | DELETE | /api/videos/{id}/dislike | **Mandatory** | — | 204 *(optional)* |
| Watch | POST | /api/videos/{videoId}/watch-time | **Mandatory** | watchTime, watchPercentage, completed, deviceId, platform | 204 |
| | GET | /api/me/watched | **Mandatory** | page, limit | items[], page, hasMore |
| Auth | GET | /api/me | **Mandatory** | — | profile |
| Upload | POST | /api/upload or /api/videos/upload | **Mandatory** | metadata or multipart | videoId, uploadUrl? |
| Library | GET | /api/me/liked | **Mandatory** | page, limit | videos[] |
| | GET | /api/me/playlists | **Mandatory** | page, limit | playlists[] |
| | GET | /api/playlists/{id} | **Mandatory** | — | playlist + videos |
| | POST | /api/playlists | **Mandatory** | name, visibility? | playlist |
| | POST | /api/playlists/{id}/videos | **Mandatory** | videoId | 204 |
| | GET | /api/me/saved | **Mandatory** | page, limit | videos[] |
| | POST | /api/videos/{id}/save | **Mandatory** | — | 204 |
| | DELETE | /api/videos/{id}/save | **Mandatory** | — | 204 |
| Notifications | GET | /api/notifications | **Mandatory** | page, limit | notifications[] |
| Report | POST | /api/videos/{id}/report | **Mandatory** | reason, details? | 204 |

---

## TOKEN USAGE (CLIENT)

- **Where token is Mandatory:** Send header `Authorization: Bearer <access_token>` (or `Bearer <id_token>` per backend contract). If missing or invalid, backend may return 401 and/or `{ "requiresLogin": true }`; client must prompt login.
- **Where token is Optional:** Same header when user is logged in; backend may return extra fields (e.g. likedByMe, subscribedToChannel in GET /api/videos/{id}).
- **Where token is No:** Anonymous access; no header required.

*Contract details align with **docs/architecture/API.md** and the OpenAPI spec.*
