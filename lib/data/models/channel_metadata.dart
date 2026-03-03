/// Channel info for video detail.
class ChannelMetadata {
  const ChannelMetadata({
    required this.id,
    this.name,
    this.avatarUrl,
  });

  final String id;
  final String? name;
  final String? avatarUrl;

  factory ChannelMetadata.fromJson(Map<String, dynamic> json) {
    return ChannelMetadata(
      id: _stringFromJson(json['id']) ?? '',
      name: _stringFromJson(json['name']),
      avatarUrl: _stringFromJson(json['avatarUrl'] ?? json['logo']),
    );
  }

  static String? _stringFromJson(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is int || v is double) return v.toString();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
