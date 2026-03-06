import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/user_profile_provider.dart';

void main() {
  group('currentUserProfileProvider', () {
    test('returns null when not signed in', () async {
      final container = ProviderContainer(
        overrides: [
          isSignedInProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(currentUserProfileProvider.future);
      expect(profile, isNull);
    });

    test('returns profile when signed in and getMe succeeds', () async {
      final mockClient = _MockClient((request) async {
        if (request.url.path == '/auth/api/me') {
          return http.Response(
            jsonEncode({
              'data': {'id': 42, 'email': 'p@test.com', 'username': 'pro'},
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final container = ProviderContainer(
        overrides: [
          isSignedInProvider.overrideWith((ref) => true),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://api.test'),
              client: mockClient,
              getAccessToken: () => 'token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(currentUserProfileProvider.future);
      expect(profile, isNotNull);
      expect(profile!.id, 42);
      expect(profile.email, 'p@test.com');
      expect(profile.username, 'pro');
    });

    test('returns null when signed in but getMe throws', () async {
      final container = ProviderContainer(
        overrides: [
          isSignedInProvider.overrideWith((ref) => true),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://api.test'),
              client: _MockClient((_) async => http.Response('', 500)),
              getAccessToken: () => 't',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(currentUserProfileProvider.future);
      expect(profile, isNull);
    });
  });
}

class _MockClient extends http.BaseClient {
  _MockClient(this._fn);
  final Future<http.Response> Function(http.BaseRequest) _fn;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _fn(request);
    return http.StreamedResponse(
      Stream.value(r.bodyBytes),
      r.statusCode,
      headers: r.headers,
    );
  }
}
