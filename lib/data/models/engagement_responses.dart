/// Result of POST /api/videos/{id}/like or DELETE (remove like).
class LikeVideoResult {
  const LikeVideoResult({
    required this.likes,
    this.dislikes = 0,
    this.liked = false,
  });

  final int likes;
  final int dislikes;
  final bool liked;

  factory LikeVideoResult.fromJson(Map<String, dynamic> json) {
    final liked = json['liked'] ?? json['isActive'] ?? json['userAction'] == 'like';
    return LikeVideoResult(
      likes: _int(json['likes'], 0),
      dislikes: _int(json['dislikes'], 0),
      liked: liked is bool ? liked : liked == true,
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}

/// Result of POST /api/videos/{id}/dislike or DELETE (remove dislike).
class DislikeVideoResult {
  const DislikeVideoResult({
    this.likes = 0,
    required this.dislikes,
    this.disliked = false,
  });

  final int likes;
  final int dislikes;
  final bool disliked;

  factory DislikeVideoResult.fromJson(Map<String, dynamic> json) {
    final disliked = json['disliked'] ?? json['userAction'] == 'dislike';
    return DislikeVideoResult(
      likes: _int(json['likes'], 0),
      dislikes: _int(json['dislikes'], 0),
      disliked: disliked is bool ? disliked : disliked == true,
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}

/// Result of POST /api/subscribe or /api/unsubscribe.
class SubscribeResult {
  const SubscribeResult({
    this.subscriberCount = 0,
    this.isSubscribed = false,
  });

  final int subscriberCount;
  final bool isSubscribed;

  factory SubscribeResult.fromJson(Map<String, dynamic> json) {
    return SubscribeResult(
      subscriberCount: SubscribeResult._int(json['subscriberCount'], 0),
      isSubscribed: json['isSubscribed'] == true,
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
