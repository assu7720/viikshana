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
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
