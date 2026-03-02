# VIIKSHANA — STATE MANAGEMENT

State management: Riverpod

---

## 1. GLOBAL APP STATE

- AuthState
- UserProfileState
- DeviceState
- ThemeState

---

## 2. CONTENT STATE

- HomeFeedProvider
- VideoDetailsProvider(videoId)
- ChannelProvider(channelId)
- SearchProvider(query)
- CommentsProvider(videoId)

---

## 3. PLAYER STATE

- CurrentVideo
- PlaybackPosition
- QualitySelection
- IsFullscreen
- IsPiP
- IsMiniPlayer

---

## 4. WATCH HISTORY STATE

### Device Identification
- Android → ANDROID_ID
- iOS → identifierForVendor
- Fallback → UUID v4

---

### Storage Rules
Anonymous:
- Local (Hive only)

Logged-in:
- Local + backend sync

Resume priority:
1. Same device
2. Most recent cross-device

---

## 5. OFFLINE STORAGE

Hive boxes:
- watch_history
- search_history
- cached_videos
- cached_channels

---

## 6. ERROR & LOADING STATES

All providers must expose:
- loading
- success
- error