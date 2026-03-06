/// Single comment from GET /api/videos/{id}/comments.
class Comment {
  const Comment({
    required this.id,
    required this.videoId,
    required this.userId,
    this.username,
    required this.text,
    this.parentCommentId,
    this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  final int id;
  final String videoId;
  final int userId;
  final String? username;
  final String text;
  final int? parentCommentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Comment> replies;

  static String? _string(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is int || v is double) return v.toString();
    return null;
  }

  static int _int(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'];
    final List<Comment> repliesList = repliesRaw is List
        ? repliesRaw
            .map((e) => e is Map<String, dynamic> ? Comment.fromJson(e) : null)
            .whereType<Comment>()
            .toList()
        : <Comment>[];
    return Comment(
      id: _int(json['id'], 0),
      videoId: _string(json['videoId']) ?? '',
      userId: _int(json['userId'], 0),
      username: _string(json['username'] ?? json['userName']),
      text: _string(json['text']) ?? '',
      parentCommentId: json['parentCommentId'] != null
          ? _int(json['parentCommentId'], 0)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(_string(json['createdAt']) ?? '')
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(_string(json['updatedAt']) ?? '')
          : null,
      replies: repliesList,
    );
  }
}

/// Response for GET /api/videos/{id}/comments.
class VideoCommentsResponse {
  const VideoCommentsResponse({
    this.comments = const [],
    this.page = 1,
    this.total,
  });

  final List<Comment> comments;
  final int page;
  final int? total;

  factory VideoCommentsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['comments'] ?? json['data'];
    final List<Comment> commentsList = list is List
        ? list
            .map((e) => e is Map<String, dynamic> ? Comment.fromJson(e) : null)
            .whereType<Comment>()
            .toList()
        : <Comment>[];
    int parsePage(dynamic v, int f) {
      if (v == null) return f;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? f;
      return f;
    }
    final page = parsePage(json['page'], 1);
    final total = json['total'] != null ? parsePage(json['total'], 0) : null;
    return VideoCommentsResponse(
      comments: commentsList,
      page: page,
      total: total,
    );
  }
}
