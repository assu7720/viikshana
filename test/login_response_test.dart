import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/data/models/login_response.dart';

void main() {
  group('LoginResponseUser.fromJson', () {
    test('parses id, email, username', () {
      final user = LoginResponseUser.fromJson({
        'id': 42,
        'email': 'u@test.com',
        'username': 'user42',
      });
      expect(user.id, 42);
      expect(user.email, 'u@test.com');
      expect(user.username, 'user42');
    });

    test('parses string id as int', () {
      final user = LoginResponseUser.fromJson({'id': '99', 'email': 'e@x.com'});
      expect(user.id, 99);
    });

    test('handles missing fields', () {
      final user = LoginResponseUser.fromJson({});
      expect(user.id, isNull);
      expect(user.email, isNull);
      expect(user.username, isNull);
    });

    test('invalid id string yields null id', () {
      final user = LoginResponseUser.fromJson({'id': 'not-a-number', 'email': 'e@x.com'});
      expect(user.id, isNull);
    });
  });

  group('LoginResponse.fromJson', () {
    test('parses success and data.tokens (accessToken, refreshToken)', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'data': {
          'user': {'id': 1, 'email': 'a@b.com', 'username': 'ab'},
          'tokens': {
            'accessToken': 'access-xyz',
            'refreshToken': 'refresh-abc',
          },
        },
      });
      expect(res.success, true);
      expect(res.accessToken, 'access-xyz');
      expect(res.refreshToken, 'refresh-abc');
      expect(res.user?.id, 1);
      expect(res.user?.email, 'a@b.com');
      expect(res.user?.username, 'ab');
    });

    test('parses data.accessToken / data.refreshToken fallback', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'data': {
          'accessToken': 'at-only',
          'refresh_token': 'rt-snake',
        },
      });
      expect(res.accessToken, 'at-only');
      expect(res.refreshToken, 'rt-snake');
    });

    test('parses top-level accessToken and refreshToken', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'accessToken': 'top-access',
        'refreshToken': 'top-refresh',
      });
      expect(res.accessToken, 'top-access');
      expect(res.refreshToken, 'top-refresh');
    });

    test('parses snake_case tokens in data.tokens', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'data': {
          'tokens': {
            'access_token': 'snake-access',
            'refresh_token': 'snake-refresh',
          },
        },
      });
      expect(res.accessToken, 'snake-access');
      expect(res.refreshToken, 'snake-refresh');
    });

    test('success false when key is false', () {
      final res = LoginResponse.fromJson({'success': false, 'data': {}});
      expect(res.success, false);
    });

    test('empty or whitespace tokens become null', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'data': {
          'tokens': {'accessToken': '  ', 'refreshToken': ''},
        },
      });
      expect(res.accessToken, isNull);
      expect(res.refreshToken, isNull);
    });

    test('handles missing data', () {
      final res = LoginResponse.fromJson({'success': true});
      expect(res.user, isNull);
      expect(res.accessToken, isNull);
      expect(res.refreshToken, isNull);
    });

    test('parses data.tokens.token as access token fallback', () {
      final res = LoginResponse.fromJson({
        'success': true,
        'data': {
          'tokens': {'token': 'single-token', 'refresh_token': 'rt'},
        },
      });
      expect(res.accessToken, 'single-token');
      expect(res.refreshToken, 'rt');
    });

    test('success is false when success key is missing', () {
      final res = LoginResponse.fromJson({'data': {'tokens': {'accessToken': 'x'}}});
      expect(res.success, false);
      expect(res.accessToken, 'x');
    });
  });
}
