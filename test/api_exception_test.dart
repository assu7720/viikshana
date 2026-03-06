import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/core/api/api_exception.dart';

void main() {
  group('ApiException', () {
    test('toString includes message', () {
      const e = ApiException('Something failed');
      expect(e.toString(), contains('Something failed'));
      expect(e.message, 'Something failed');
    });

    test('toString includes statusCode when set', () {
      const e = ApiException('Request failed', statusCode: 404);
      expect(e.toString(), contains('404'));
      expect(e.statusCode, 404);
    });

    test('toString omits statusCode when null', () {
      const e = ApiException('Error');
      expect(e.toString(), isNot(contains('statusCode')));
      expect(e.statusCode, isNull);
    });

    test('toString includes requiresLogin when true', () {
      const e = ApiException('Unauthorized', statusCode: 401, requiresLogin: true);
      expect(e.toString(), contains('requiresLogin'));
      expect(e.requiresLogin, true);
    });

    test('toString omits requiresLogin when false', () {
      const e = ApiException('Error', requiresLogin: false);
      expect(e.toString(), isNot(contains('requiresLogin')));
    });

    test('implements Exception', () {
      const e = ApiException('x');
      expect(e, isA<Exception>());
    });
  });
}
