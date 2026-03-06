openapi: 3.0.3
info:
  title: Clips-Now API
  description: |
    Backend API for clips-now (VIIKSHANA). Session-based auth (cookies); no Bearer token.
    **Source:** All paths discovered from code scan of src/routes/* and mount points in src/index.ts.
  version: 1.0.0

servers:
  - url: /
    description: App base URL
  - url: /auth
    description: Auth router base (auth API paths under /auth/api/*)

tags:
  - name: Video feeds
  - name: Search
  - name: Channels
  - name: Comments
  - name: Likes
  - name: Watch history
  - name: Auth
  - name: Library
  - name: Notifications
  - name: Report
  - name: Analytics
  - name: Monitoring
  - name: Messages
  - name: Admin
  - name: Assets
  - name: Subscribers
  - name: Master data
  - name: Watch later (alt)
  - name: Studio

paths:
  # ---- 1. VIDEO FEEDS & PLAYBACK ----
  /api/home/videos:
    get:
      tags: [Video feeds]
      summary: Home feed videos
      operationId: getHomeVideos
      parameters:
        - $ref: '#/components/parameters/PageQuery'
        - $ref: '#/components/parameters/LimitQuery'
      responses:
        '200':
          description: Paginated home videos
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/HomeVideosResponse'

  /api/videos/{id}:
    parameters:
      - $ref: '#/components/parameters/VideoIdPath'
    get:
      tags: [Video feeds]
      summary: Get single video by ID
      operationId: getVideo
      security: []
      responses:
        '200':
          description: Video with channel; includes likedByMe, subscribedToChannel when authenticated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VideoSingleResponse'
        '404':
          $ref: '#/components/responses/NotFound'

  /api/search/videos:
    get:
      tags: [Video feeds, Search]
      summary: Search videos (OpenSearch then DB)
      operationId: searchVideos
      parameters:
        - name: q
          in: query
          required: true
          schema: { type: string }
        - $ref: '#/components/parameters/PageQuery'
        - $ref: '#/components/parameters/LimitQuery'
      responses:
        '200':
          description: Same shape as home feed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SearchVideosResponse'

  # ---- 2. SEARCH ----
  /search/suggestions:
    get:
      tags: [Search]
      summary: Search suggestions
      operationId: getSearchSuggestions
      parameters:
        - name: q
          in: query
          required: true
          schema: { type: string }
        - name: limit
          in: query
          schema: { type: integer, default: 10 }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  suggestions: { type: array, items: { type: string } }

  # ---- 3. CHANNELS ----
  /api/channels/{uniqueId}:
    get:
      tags: [Channels]
      summary: Get channel by uniqueId (path uses uniqueId, not internal id)
      operationId: getChannel
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { $ref: '#/components/schemas/Channel' }
        '404':
          $ref: '#/components/responses/NotFound'
    put:
      tags: [Channels]
      summary: Update channel (basic info, uploads)
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
      responses:
        '200':
          description: OK
    delete:
      tags: [Channels]
      summary: Delete channel
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  /api/channels/my:
    get:
      tags: [Channels]
      summary: Current user's channels
      operationId: getMyChannels
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { type: array, items: { $ref: '#/components/schemas/Channel' } }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/channels:
    post:
      tags: [Channels]
      summary: Create channel
      operationId: createChannel
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                name: { type: string }
                handle: { type: string }
                description: { type: string }
                channelPrivacy: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { $ref: '#/components/schemas/Channel' }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/subscribe/{channelId}:
    post:
      tags: [Channels]
      summary: Subscribe to channel (channelId or channelIdentifier in path)
      operationId: subscribe
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  message: { type: string }
                  subscriberCount: { type: integer }
                  isSubscribed: { type: boolean }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/unsubscribe/{channelId}:
    post:
      tags: [Channels]
      summary: Unsubscribe from channel
      operationId: unsubscribe
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  message: { type: string }
                  subscriberCount: { type: integer }
                  isSubscribed: { type: boolean, example: false }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/channels/{channelId}/subscription:
    get:
      tags: [Channels]
      summary: Check if current user is subscribed to channel
      operationId: checkSubscription
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  subscribed: { type: boolean }
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 4. COMMENTS ----
  /api/videos/{id}/comments:
    get:
      tags: [Comments]
      summary: Get video comments (paginated)
      operationId: getVideoComments
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
        - $ref: '#/components/parameters/PageQuery'
        - name: limit
          in: query
          schema: { type: integer }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  comments: { type: array, items: { $ref: '#/components/schemas/Comment' } }
                  page: { type: integer }
                  total: { type: integer }

  /api/comments:
    post:
      tags: [Comments]
      summary: Post comment (body videoId + text)
      operationId: postComment
      security: [{ session: [] }]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [videoId, text]
              properties:
                videoId: { type: string }
                text: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  comment: { $ref: '#/components/schemas/CommentMinimal' }
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/comments/reply:
    post:
      tags: [Comments]
      summary: Reply to comment
      operationId: replyComment
      security: [{ session: [] }]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [parentCommentId, text]
              properties:
                parentCommentId: { type: integer }
                text: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { $ref: '#/components/schemas/CommentMinimal' }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/comments/{id}:
    delete:
      tags: [Comments]
      summary: Delete comment
      operationId: deleteComment
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: integer }
      responses:
        '204':
          description: No content
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 5. LIKES ----
  /api/videos/{id}/like:
    post:
      tags: [Likes]
      summary: Like / toggle like
      operationId: likeVideo
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                type: { type: string }
                action: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  likes: { type: integer }
                  dislikes: { type: integer }
                  userAction: { type: string }
                  isActive: { type: boolean }
        '401':
          $ref: '#/components/responses/Unauthorized'
    delete:
      tags: [Likes]
      summary: Remove like
      operationId: removeLike
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  liked: { type: boolean, example: false }
                  likes: { type: integer }
                  dislikes: { type: integer }
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 6. WATCH HISTORY ----
  /api/videos/{videoId}/watch-time:
    post:
      tags: [Watch history]
      summary: Submit watch time
      operationId: postWatchTime
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                watchTime: { type: number }
                watchPercentage: { type: number }
                completed: { type: boolean }
                paused: { type: boolean }
                quality: { type: string }
                sessionId: { type: string, nullable: true }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  message: { type: string }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/watch-history:
    get:
      tags: [Watch history]
      summary: Get watch history
      operationId: getWatchHistory
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/PageQuery'
        - name: limit
          in: query
          schema: { type: integer }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  watchHistory: { type: array, items: { $ref: '#/components/schemas/WatchHistoryItem' } }
                  total: { type: integer }
                  page: { type: integer }
                  totalPages: { type: integer }
                  limit: { type: integer }
                  offset: { type: integer }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/me/watched:
    get:
      tags: [Watch history, Library]
      summary: Alias for watch history
      operationId: getMeWatched
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/PageQuery'
        - name: limit
          in: query
          schema: { type: integer }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  watchHistory: { type: array, items: { $ref: '#/components/schemas/WatchHistoryItem' } }
                  total: { type: integer }
                  page: { type: integer }
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 7. AUTH (actual paths under /auth - authRouter mounted at /auth) ----
  /auth/api/login:
    post:
      tags: [Auth]
      summary: API login (session + cookies)
      operationId: apiLogin
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                username: { type: string }
                password: { type: string }
      responses:
        '200':
          description: Session created, cookie set
  /auth/api/logout:
    post:
      tags: [Auth]
      summary: API logout (session invalidation)
      operationId: apiLogout
      responses:
        '200':
          description: Session invalidated
  /auth/api/me:
    get:
      tags: [Auth]
      summary: Current user profile (session required)
      operationId: getCurrentUser
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data:
                    type: object
                    properties:
                      id: { type: integer }
                      username: { type: string }
                      name: { type: string }
                      email: { type: string }
                      profileImage: { type: string, nullable: true }
                      dateOfBirth: { type: string, nullable: true }
                      gender: { type: string, nullable: true }
                      channelId: { type: integer, nullable: true }
                      createdAt: { type: string }
                      updatedAt: { type: string }
        '401':
          $ref: '#/components/responses/Unauthorized'
  /auth/api/tokens:
    get:
      tags: [Auth]
      summary: Get tokens
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /auth/api/studio-token:
    get:
      tags: [Auth]
      summary: Get studio token
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /auth/api/verify-token:
    get:
      tags: [Auth]
      summary: Verify token
      responses:
        '200':
          description: OK
  /auth/api/service-token:
    post:
      tags: [Auth]
      summary: Get service token
      responses:
        '200':
          description: OK
  /auth/api/verify-age:
    post:
      tags: [Auth]
      summary: Verify age
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /auth/api/test-auth:
    get:
      tags: [Auth]
      summary: Test auth
      security: []
      responses:
        '200':
          description: OK

  # ---- Legacy/alias (doc contract; profile actually at /auth/api/me) ----
  /api/logout:
    post:
      tags: [Auth]
      summary: Logout alias (prefer /auth/api/logout)
      operationId: logout
      responses:
        '200':
          description: Session invalidated
  /api/me:
    get:
      tags: [Auth]
      summary: Current user profile alias (actual route GET /auth/api/me)
      operationId: getMe
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data:
                    type: object
                    properties:
                      id: { type: integer }
                      username: { type: string }
                      name: { type: string }
                      email: { type: string }
                      profileImage: { type: string, nullable: true }
                      dateOfBirth: { type: string, nullable: true }
                      gender: { type: string, nullable: true }
                      channelId: { type: integer, nullable: true }
                      createdAt: { type: string }
                      updatedAt: { type: string }
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 8. UPLOAD / PROCESSING ----
  /api/videos/{id}/status:
    get:
      tags: [Video feeds]
      summary: Video processing status
      operationId: getVideoStatus
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data:
                    type: object
                    properties:
                      status: { type: string }
                      progress: { type: number, nullable: true }
                      errorMessage: { type: string, nullable: true }
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 9. LIBRARY ----
  /api/me/saved:
    get:
      tags: [Library]
      summary: Watch later list
      operationId: getMeSaved
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  videos: { type: array, items: { $ref: '#/components/schemas/VideoSummary' } }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/me/liked:
    get:
      tags: [Library]
      summary: User's liked videos
      operationId: getMeLiked
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  videoLikes: { type: array, items: { $ref: '#/components/schemas/VideoLikeItem' } }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/videos/{id}/save:
    post:
      tags: [Library]
      summary: Add to watch later
      operationId: saveVideo
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  message: { type: string }
        '401':
          $ref: '#/components/responses/Unauthorized'
    delete:
      tags: [Library]
      summary: Remove from watch later
      operationId: unsaveVideo
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      responses:
        '204':
          description: No content
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/playlists:
    get:
      tags: [Library]
      summary: User playlists
      operationId: getPlaylists
      security: [{ session: [] }]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { type: array, items: { $ref: '#/components/schemas/Playlist' } }
        '401':
          $ref: '#/components/responses/Unauthorized'
    post:
      tags: [Library]
      summary: Create playlist
      operationId: createPlaylist
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                name: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { $ref: '#/components/schemas/Playlist' }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/playlist/{id}:
    get:
      tags: [Library]
      summary: Get playlist with videos
      operationId: getPlaylist
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  data: { $ref: '#/components/schemas/PlaylistWithVideos' }
        '401':
          $ref: '#/components/responses/Unauthorized'
    put:
      tags: [Library]
      summary: Update playlist (backend uses PUT not PATCH)
      operationId: updatePlaylist
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                name: { type: string }
      responses:
        '200':
          description: Updated playlist
        '401':
          $ref: '#/components/responses/Unauthorized'
    delete:
      tags: [Library]
      summary: Delete playlist
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  /api/playlist/add-video:
    post:
      tags: [Library]
      summary: Add video to playlist (body includes playlist id + videoId)
      operationId: addVideoToPlaylist
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                playlistId: { type: integer }
                videoId: { type: integer }
      responses:
        '200':
          description: Success
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/playlist/{playlistId}/video/{videoId}:
    delete:
      tags: [Library]
      summary: Remove video from playlist
      operationId: removeVideoFromPlaylist
      security: [{ session: [] }]
      parameters:
        - name: playlistId
          in: path
          required: true
          schema: { type: string }
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '204':
          description: No content
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 10. NOTIFICATIONS (stub) ----
  /api/notifications:
    get:
      tags: [Notifications]
      summary: List notifications (stub: returns empty list)
      operationId: getNotifications
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/PageQuery'
        - name: limit
          in: query
          schema: { type: integer, default: 20 }
        - name: unreadOnly
          in: query
          schema: { type: boolean }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  notifications: { type: array, items: {} }
                  page: { type: integer }
                  hasMore: { type: boolean, example: false }
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/notifications/read:
    patch:
      tags: [Notifications]
      summary: Mark all as read (stub)
      operationId: markAllNotificationsRead
      security: [{ session: [] }]
      responses:
        '204':
          description: No content
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/notifications/{id}/read:
    patch:
      tags: [Notifications]
      summary: Mark notification as read (stub)
      operationId: markNotificationRead
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '204':
          description: No content
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ---- 11. REPORT (stub) ----
  /api/videos/{id}/report:
    post:
      tags: [Report]
      summary: Report video (stub: returns 204)
      operationId: reportVideo
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [reason]
              properties:
                reason: { type: string }
                details: { type: string }
      responses:
        '204':
          description: No content
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'

  # ========== FROM CODE SCAN (all routes in src/routes + index mount) ==========

  # Home (homeRouter @ /)
  /api/live/stream-key:
    post:
      tags: [Video feeds]
      summary: Generate stream key
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/contact:
    post:
      tags: []
      summary: Submit contact form
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/random-short:
    get:
      tags: [Video feeds]
      summary: Get random short
      responses:
        '200':
          description: OK
  /api/clips/load-more:
    get:
      tags: [Video feeds]
      summary: Load more clips
      parameters:
        - name: page
          in: query
          schema: { type: integer }
      responses:
        '200':
          description: OK
  /api/test-video-processor:
    get:
      tags: []
      summary: Test video processor (dev)
      responses:
        '200':
          description: OK

  # Video (videoRouter @ /) - additional
  /api/user-video-likes:
    get:
      tags: [Likes, Library]
      summary: User video likes (same as GET /api/me/liked)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/videos/{id}/rights:
    post:
      tags: [Video feeds]
      summary: Save video rights
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /videos:
    get:
      tags: [Video feeds]
      summary: List videos (e.g. Android)
      security: []
      responses:
        '200':
          description: OK
  /videos/{id}/view:
    post:
      tags: [Video feeds]
      summary: Record video view
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  # videoApiRouter @ /api
  /api/test:
    get:
      tags: []
      summary: API test
      responses:
        '200':
          description: OK
  /api/videos:
    get:
      tags: [Video feeds, Studio]
      summary: List all videos (studio)
      security: []
      responses:
        '200':
          description: OK
  /api/videos/user:
    get:
      tags: [Video feeds, Studio]
      summary: User's videos (studio)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/videos/create:
    post:
      tags: [Video feeds, Studio]
      summary: Create video record after upload
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/videos/{id}/publish:
    post:
      tags: [Video feeds, Studio]
      summary: Publish video
      security: [{ session: [] }]
      parameters:
        - $ref: '#/components/parameters/VideoIdPath'
      responses:
        '200':
          description: OK
  /api/video/{id}/related:
    get:
      tags: [Video feeds]
      summary: Related videos
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/scheduled-videos:
    get:
      tags: [Studio]
      summary: Scheduled videos
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/next-scheduled-publication:
    get:
      tags: [Studio]
      summary: Next scheduled publication
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics:
    get:
      tags: [Analytics, Studio]
      summary: Studio analytics summary
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Search (searchRouter @ /) - all variants
  /search:
    get:
      tags: [Search]
      summary: Search (page or redirect)
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/videos:
    get:
      tags: [Search]
      summary: Search videos (HTML or JSON)
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/channels:
    get:
      tags: [Search]
      summary: Search channels
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/all:
    get:
      tags: [Search]
      summary: Multi search
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/advanced:
    get:
      tags: [Search]
      summary: Advanced search
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/trending:
    get:
      tags: [Search]
      summary: Trending searches
      responses:
        '200':
          description: OK
  /search/trending-content:
    get:
      tags: [Search]
      summary: Trending content
      responses:
        '200':
          description: OK
  /search/facets:
    get:
      tags: [Search]
      summary: Faceted search
      parameters:
        - name: q
          in: query
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/similar/{videoId}:
    get:
      tags: [Search]
      summary: Similar videos
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /search/health:
    get:
      tags: [Search]
      summary: Search health check
      responses:
        '200':
          description: OK
  /search/debug:
    get:
      tags: [Search]
      summary: Search debug (indexes)
      responses:
        '200':
          description: OK
  /search/reindex:
    post:
      tags: [Search]
      summary: Reindex all videos
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /search/analytics:
    get:
      tags: [Search]
      summary: Search analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Subscription (subscriptionRouter @ /api) - alternate paths
  /api/subscribe/{channelIdentifier}:
    post:
      tags: [Channels]
      summary: Subscribe by identifier (handle/uniqueId)
      security: [{ session: [] }]
      parameters:
        - name: channelIdentifier
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/unsubscribe/{channelIdentifier}:
    post:
      tags: [Channels]
      summary: Unsubscribe by identifier
      security: [{ session: [] }]
      parameters:
        - name: channelIdentifier
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/check/{channelId}:
    get:
      tags: [Channels]
      summary: Check subscription (channelId or channelIdentifier in path)
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
          description: Numeric channel id or channel identifier (handle/uniqueId)
      responses:
        '200':
          description: OK
  /api/my-subscriptions:
    get:
      tags: [Channels]
      summary: User subscriptions list
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/subscriptions:
    get:
      tags: [Channels]
      summary: User subscriptions (alias)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/feed:
    get:
      tags: [Channels]
      summary: Subscription feed
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Channels (channelRouter @ /api) - extended
  /api/channels/{uniqueId}/videos:
    get:
      tags: [Channels]
      summary: Channel videos by uniqueId
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/playlists:
    get:
      tags: [Channels, Library]
      summary: Channel playlists by uniqueId
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/playlists:
    get:
      tags: [Channels, Library]
      summary: Channel playlists by numeric id
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/playlists:
    get:
      tags: [Channels, Library]
      summary: Channel playlists by numeric id
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/logo:
    patch:
      tags: [Channels]
      summary: Update channel logo
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/banner:
    patch:
      tags: [Channels]
      summary: Update channel banner
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/stats:
    patch:
      tags: [Channels]
      summary: Update channel stats
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/basic-info:
    put:
      tags: [Channels]
      summary: Update channel basic info
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/advanced:
    put:
      tags: [Channels]
      summary: Update channel advanced settings
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/upload-defaults:
    put:
      tags: [Channels]
      summary: Update upload defaults
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{uniqueId}/permissions:
    put:
      tags: [Channels]
      summary: Update channel permissions
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/check-handle/{handle}:
    get:
      tags: [Channels]
      summary: Check handle availability
      parameters:
        - name: handle
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/members:
    get:
      tags: [Channels]
      summary: Channel members
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/invite:
    post:
      tags: [Channels]
      summary: Invite user to channel
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/members/{memberId}/role:
    put:
      tags: [Channels]
      summary: Change member role
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
        - name: memberId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/members/{memberId}:
    delete:
      tags: [Channels]
      summary: Remove channel member
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
        - name: memberId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/invitations/{invitationId}/resend:
    post:
      tags: [Channels]
      summary: Resend invitation
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
        - name: invitationId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/channels/{channelId}/invitations/{invitationId}:
    delete:
      tags: [Channels]
      summary: Cancel invitation
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
        - name: invitationId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  # Comments (commentsRouter @ /) - extra
  /api/comments/analytics:
    get:
      tags: [Comments]
      summary: Comments analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/comments/bulk:
    delete:
      tags: [Comments]
      summary: Bulk delete comments
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                ids: { type: array, items: { type: integer } }
      responses:
        '200':
          description: OK
  /api/comments/export:
    get:
      tags: [Comments]
      summary: Export comments
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Playlists (playlistRouter @ /) - extra
  /api/playlists/ping:
    get:
      tags: [Library]
      summary: Playlists ping
      responses:
        '200':
          description: OK
  /api/playlists/test:
    get:
      tags: [Library]
      summary: Playlists test
      responses:
        '200':
          description: OK
  /api/playlists/public/{userId}:
    get:
      tags: [Library]
      summary: Public playlists by user
      parameters:
        - name: userId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/playlist/{id}/reorder:
    put:
      tags: [Library]
      summary: Reorder playlist videos
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK

  # Admin (adminRouter @ /)
  /api/log-watch:
    post:
      tags: [Admin]
      summary: Log watch (admin)
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /admin/active-users:
    get:
      tags: [Admin]
      summary: Active users
      responses:
        '200':
          description: OK
  /admin/active-viewers:
    get:
      tags: [Admin]
      summary: Active viewers
      responses:
        '200':
          description: OK

  # Messages (messagePageRouter @ /)
  /api/messages:
    get:
      tags: [Messages]
      summary: Conversations list
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/messages/unread-count:
    get:
      tags: [Messages]
      summary: Unread message count
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/messages/search-contacts:
    get:
      tags: [Messages]
      summary: Search contacts
      security: [{ session: [] }]
      parameters:
        - name: query
          in: query
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/messages/send:
    post:
      tags: [Messages]
      summary: Send message
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/messages/{userId}:
    get:
      tags: [Messages]
      summary: Messages with user
      security: [{ session: [] }]
      parameters:
        - name: userId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/messages/{userId}/read:
    put:
      tags: [Messages]
      summary: Mark messages as read
      security: [{ session: [] }]
      parameters:
        - name: userId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  # Analytics (analyticsRouter @ /)
  /analytics/engagement:
    post:
      tags: [Analytics]
      summary: Collect engagement
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /analytics/video/{videoId}/interaction:
    post:
      tags: [Analytics]
      summary: Video interaction
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /analytics/video/{videoId}/upload-metrics:
    post:
      tags: [Analytics]
      summary: Upload metrics (video processor)
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /analytics/search:
    post:
      tags: [Analytics]
      summary: Search analytics
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/analytics/user:
    get:
      tags: [Analytics]
      summary: User analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/historic:
    get:
      tags: [Analytics]
      summary: Historical analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/realtime:
    get:
      tags: [Analytics]
      summary: Real-time analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/traffic-sources:
    get:
      tags: [Analytics]
      summary: Traffic sources
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/views:
    get:
      tags: [Analytics]
      summary: Views over time
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/subscribers:
    get:
      tags: [Analytics]
      summary: Subscriber growth
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/channels/{uniqueId}:
    get:
      tags: [Analytics]
      summary: Channel analytics
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/analytics/channels/{uniqueId}/audience:
    get:
      tags: [Analytics]
      summary: Channel audience
      security: [{ session: [] }]
      parameters:
        - name: uniqueId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/analytics/video/{videoId}:
    get:
      tags: [Analytics]
      summary: Video analytics
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/analytics/aggregate/video/{videoId}:
    post:
      tags: [Analytics]
      summary: Aggregate video engagement
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/analytics/aggregate/all:
    post:
      tags: [Analytics]
      summary: Aggregate all engagement
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/analytics/platform:
    get:
      tags: [Analytics]
      summary: Platform analytics
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /analytics/collector/status:
    get:
      tags: [Analytics]
      summary: Collector status
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Monitoring (monitoringRouter @ /)
  /api/monitoring/health:
    get:
      tags: [Monitoring]
      summary: Health check (no auth)
      security: []
      responses:
        '200':
          description: OK
  /api/monitoring/services:
    get:
      tags: [Monitoring]
      summary: Services status
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/monitoring/services/{serviceName}:
    get:
      tags: [Monitoring]
      summary: Single service status
      security: [{ session: [] }]
      parameters:
        - name: serviceName
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/monitoring/errors:
    get:
      tags: [Monitoring]
      summary: Errors
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/monitoring/performance:
    get:
      tags: [Monitoring]
      summary: Performance
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/monitoring/logs/search:
    post:
      tags: [Monitoring]
      summary: Search logs
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/monitoring/logs/export:
    post:
      tags: [Monitoring]
      summary: Export logs
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/monitoring/dashboard:
    get:
      tags: [Monitoring]
      summary: Monitoring dashboard
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/monitoring/video-errors/{videoId}:
    get:
      tags: [Monitoring]
      summary: Video errors
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  # Master data (masterDataRouter @ /api/master-data)
  /api/master-data/all:
    get:
      tags: [Master data]
      summary: All master data
      responses:
        '200':
          description: OK
  /api/master-data/categories:
    get:
      tags: [Master data]
      summary: Categories
      responses:
        '200':
          description: OK
  /api/master-data/languages:
    get:
      tags: [Master data]
      summary: Languages
      responses:
        '200':
          description: OK
  /api/master-data/countries:
    get:
      tags: [Master data]
      summary: Countries
      responses:
        '200':
          description: OK

  # Watch later alternate (watchLaterRouter @ /api/watch-later)
  /api/watch-later/add/{videoId}:
    post:
      tags: [Watch later (alt), Library]
      summary: Add to watch later (alt path)
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/watch-later/remove/{videoId}:
    delete:
      tags: [Watch later (alt), Library]
      summary: Remove from watch later (alt path)
      security: [{ session: [] }]
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/watch-later/list:
    get:
      tags: [Watch later (alt), Library]
      summary: Watch later list (alt path)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/watch-later/check/{videoId}:
    get:
      tags: [Watch later (alt), Library]
      summary: Check if in watch later
      security: []
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

  # Watch history (watchHistoryRouter @ /api/watch-history) - remove/clear
  /api/watch-history/remove:
    post:
      tags: [Watch history]
      summary: Remove from watch history
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                videoId: { type: integer }
      responses:
        '200':
          description: OK
  /api/watch-history/clear:
    delete:
      tags: [Watch history]
      summary: Clear all watch history
      security: [{ session: [] }]
      responses:
        '200':
          description: OK

  # Video watch tracking (videoWatchTrackingRouter @ /api/video-watch)
  /api/video-watch/start:
    post:
      tags: [Watch history]
      summary: Start watch session
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/video-watch/update/{sessionId}:
    put:
      tags: [Watch history]
      summary: Update watch session
      parameters:
        - name: sessionId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/video-watch/end/{sessionId}:
    post:
      tags: [Watch history]
      summary: End watch session
      parameters:
        - name: sessionId
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/video-watch/session/{sessionId}:
    get:
      tags: [Watch history]
      summary: Get watch session
      parameters:
        - name: sessionId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/video-watch/history:
    get:
      tags: [Watch history]
      summary: Watch history (video-watch)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/video-watch/analytics/{videoId}:
    get:
      tags: [Watch history, Analytics]
      summary: Video watch analytics
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/video-watch/realtime/{videoId}:
    get:
      tags: [Watch history]
      summary: Realtime viewers
      parameters:
        - name: videoId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/video-watch/batch-update:
    post:
      tags: [Watch history]
      summary: Batch update watch sessions
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK

  # Assets (assetRouter @ /)
  /api/assets/exclusive:
    get:
      tags: [Assets]
      summary: List exclusive assets
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
    post:
      tags: [Assets]
      summary: Create exclusive asset
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/assets/exclusive/{id}:
    put:
      tags: [Assets]
      summary: Update exclusive asset
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
    delete:
      tags: [Assets]
      summary: Delete exclusive asset
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/assets/non-exclusive:
    get:
      tags: [Assets]
      summary: List non-exclusive assets
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
    post:
      tags: [Assets]
      summary: Create non-exclusive asset
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/assets/non-exclusive/{id}:
    put:
      tags: [Assets]
      summary: Update non-exclusive asset
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
    delete:
      tags: [Assets]
      summary: Delete non-exclusive asset
      security: [{ session: [] }]
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK
  /api/assets/exclusive/send-otp:
    post:
      tags: [Assets]
      summary: Send OTP for asset verification
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK
  /api/assets/exclusive/verify-otp:
    post:
      tags: [Assets]
      summary: Verify OTP
      security: [{ session: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: OK

  # Subscribers (subscribersRouter @ /)
  /api/subscribers:
    get:
      tags: [Subscribers]
      summary: All subscribers (user's channels)
      security: [{ session: [] }]
      responses:
        '200':
          description: OK
  /api/subscribers/channel/{channelId}:
    get:
      tags: [Subscribers]
      summary: Channel subscribers
      security: [{ session: [] }]
      parameters:
        - name: channelId
          in: path
          required: true
          schema: { type: string }
      responses:
        '200':
          description: OK

components:
  securitySchemes:
    session:
      type: apiKey
      in: cookie
      name: connect.sid
      description: Session cookie (express-session). No Bearer token.

  parameters:
    PageQuery:
      name: page
      in: query
      schema: { type: integer, minimum: 1, default: 1 }
    LimitQuery:
      name: limit
      in: query
      schema: { type: integer, minimum: 1, maximum: 100, default: 20 }
    VideoIdPath:
      name: id
      in: path
      required: true
      schema: { type: string }
      description: Video ID (numeric string)

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            type: object
            properties:
              success: { type: boolean, example: false }
              error: { type: string }
    Unauthorized:
      description: Unauthorized; 401 body may include requiresLogin true
      content:
        application/json:
          schema:
            type: object
            properties:
              success: { type: boolean, example: false }
              requiresLogin: { type: boolean, example: true }
              message: { type: string }
    NotFound:
      description: Not found
      content:
        application/json:
          schema:
            type: object
            properties:
              success: { type: boolean, example: false }
              message: { type: string }

  schemas:
    Channel:
      type: object
      properties:
        internalId: { type: integer }
        id: { type: integer }
        uniqueId: { type: string }
        name: { type: string }
        handle: { type: string }
        description: { type: string, nullable: true }
        logo: { type: string, nullable: true }
        banner: { type: string, nullable: true }
        channelPrivacy: { type: string }
        subscriberCount: { type: integer }
        videoCount: { type: integer }
        totalViews: { type: integer }
        ownerId: { type: integer }
        createdAt: { type: string }
        updatedAt: { type: string }

    ChannelMinimal:
      type: object
      properties:
        id: { type: integer }
        name: { type: string }
        handle: { type: string, nullable: true }
        uniqueId: { type: string, nullable: true }
        logo: { type: string, nullable: true }
        subscriberCount: { type: integer }

    VideoSummary:
      type: object
      properties:
        id: { type: integer }
        title: { type: string }
        thumbnail: { type: string }
        thumbnailHome: { type: string, nullable: true }
        views: { type: integer }
        duration: { type: integer }
        isShort: { type: boolean }
        addedAt: { type: string }
        channel: { $ref: '#/components/schemas/ChannelMinimal' }

    VideoFull:
      allOf:
        - $ref: '#/components/schemas/VideoSummary'
        - type: object
          properties:
            description: { type: string }
            hlsPath: { type: string, nullable: true }
            mp4Path: { type: string, nullable: true }
            likes: { type: integer }
            commentCount: { type: integer }
            status: { type: string }
            visibility: { type: string }
            channelId: { type: integer }
            channel: { $ref: '#/components/schemas/Channel' }
            likedByMe: { type: boolean, nullable: true }
            subscribedToChannel: { type: boolean, nullable: true }
            createdAt: { type: string }
            updatedAt: { type: string }

    HomeVideosResponse:
      type: object
      properties:
        success: { type: boolean }
        regularVideos: { type: array, items: { $ref: '#/components/schemas/VideoFull' } }
        hasMore: { type: boolean }
        nextPage: { type: integer, nullable: true }

    SearchVideosResponse:
      type: object
      properties:
        success: { type: boolean }
        data: { type: array, items: { $ref: '#/components/schemas/VideoFull' } }
        hasMore: { type: boolean }
        nextPage: { type: integer, nullable: true }

    VideoSingleResponse:
      type: object
      properties:
        success: { type: boolean }
        data: { $ref: '#/components/schemas/VideoFull' }

    Comment:
      type: object
      properties:
        id: { type: integer }
        videoId: { type: integer }
        userId: { type: integer }
        username: { type: string }
        text: { type: string }
        parentCommentId: { type: integer, nullable: true }
        createdAt: { type: string }
        updatedAt: { type: string }
        replies: { type: array, items: { $ref: '#/components/schemas/Comment' } }

    CommentMinimal:
      type: object
      properties:
        id: { type: integer }
        text: { type: string }
        createdAt: { type: string }
        username: { type: string }
        parentCommentId: { type: integer, nullable: true }

    WatchHistoryItem:
      type: object
      properties:
        id: { type: integer }
        sessionId: { type: string, nullable: true }
        videoId: { type: integer }
        videoTitle: { type: string }
        videoThumbnail: { type: string }
        watchDuration: { type: number }
        watchPercentage: { type: number }
        completed: { type: boolean }
        startedAt: { type: string }
        endedAt: { type: string }
        channel: { $ref: '#/components/schemas/ChannelMinimal' }

    VideoLikeItem:
      type: object
      properties:
        videoId: { type: integer }
        type: { type: string }
        title: { type: string }
        thumbnail: { type: string }
        channel: { $ref: '#/components/schemas/ChannelMinimal' }

    Playlist:
      type: object
      properties:
        id: { type: integer }
        name: { type: string }
        userId: { type: integer }
        createdAt: { type: string }
        updatedAt: { type: string }

    PlaylistWithVideos:
      allOf:
        - $ref: '#/components/schemas/Playlist'
        - type: object
          properties:
            videos: { type: array, items: { $ref: '#/components/schemas/VideoSummary' } }

security:
  - session: []
