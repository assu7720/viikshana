/// Current user profile from GET /auth/api/me.
class ApiUserProfile {
  const ApiUserProfile({
    required this.id,
    this.username,
    this.name,
    this.email,
    this.profileImage,
    this.channelId,
  });

  final int id;
  final String? username;
  final String? name;
  final String? email;
  final String? profileImage;
  final int? channelId;

  factory ApiUserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return ApiUserProfile(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      username: json['username']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      profileImage: json['profileImage']?.toString(),
      channelId: json['channelId'] is int
          ? json['channelId'] as int
          : int.tryParse(json['channelId']?.toString() ?? ''),
    );
  }

  /// Display name: name ?? username ?? email ?? 'User'
  String get displayName =>
      name?.trim().isNotEmpty == true
          ? name!
          : username?.trim().isNotEmpty == true
              ? username!
              : email?.trim().isNotEmpty == true
                  ? email!
                  : 'User';
}
