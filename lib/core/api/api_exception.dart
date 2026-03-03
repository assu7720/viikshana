/// API error with optional [requiresLogin] from backend.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.requiresLogin = false,
  });

  final String message;
  final int? statusCode;
  final bool requiresLogin;

  @override
  String toString() => 'ApiException: $message'
      '${statusCode != null ? ' (statusCode: $statusCode)' : ''}'
      '${requiresLogin ? ' [requiresLogin]' : ''}';
}
