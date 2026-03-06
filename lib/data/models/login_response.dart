/// Response from POST /auth/api/login.
/// { "success": true, "data": { "user": { "id", "email", "username" }, "tokens": { "accessToken", "refreshToken" } } }
class LoginResponse {
  const LoginResponse({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  final bool success;
  final LoginResponseUser? user;
  final String? accessToken;
  final String? refreshToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;
    final userMap = dataMap?['user'];
    final tokensMap = dataMap?['tokens'];
    // Accept data.tokens.accessToken, or data.accessToken, or top-level (camel or snake_case), or single "token"
    String? access = tokensMap is Map ? tokensMap['accessToken']?.toString() : null;
    access ??= tokensMap is Map ? tokensMap['access_token']?.toString() : null;
    access ??= tokensMap is Map ? tokensMap['token']?.toString() : null;
    access ??= dataMap?['accessToken']?.toString();
    access ??= dataMap?['access_token']?.toString();
    access ??= dataMap?['token']?.toString();
    access ??= json['accessToken']?.toString();
    access ??= json['access_token']?.toString();
    access ??= json['token']?.toString();
    String? refresh = tokensMap is Map ? tokensMap['refreshToken']?.toString() : null;
    refresh ??= tokensMap is Map ? tokensMap['refresh_token']?.toString() : null;
    refresh ??= dataMap?['refreshToken']?.toString();
    refresh ??= dataMap?['refresh_token']?.toString();
    refresh ??= json['refreshToken']?.toString();
    refresh ??= json['refresh_token']?.toString();
    return LoginResponse(
      success: json['success'] == true,
      user: userMap is Map<String, dynamic> ? LoginResponseUser.fromJson(userMap) : null,
      accessToken: access?.trim().isNotEmpty == true ? access : null,
      refreshToken: refresh?.trim().isNotEmpty == true ? refresh : null,
    );
  }
}

class LoginResponseUser {
  const LoginResponseUser({
    this.id,
    this.email,
    this.username,
  });

  final int? id;
  final String? email;
  final String? username;

  factory LoginResponseUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return LoginResponseUser(
      id: id is int ? id : int.tryParse(id?.toString() ?? ''),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
    );
  }
}
