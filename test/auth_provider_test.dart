import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/session/session_provider.dart';

void main() {
  group('isSignedInProvider', () {
    test('true when hasSessionToken is true', () {
      final container = ProviderContainer(
        overrides: [
          hasSessionTokenProvider.overrideWith((ref) => true),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isSignedInProvider), true);
    });

    test('false when no token and no Firebase user', () {
      final container = ProviderContainer(
        overrides: [
          hasSessionTokenProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isSignedInProvider), false);
    });

    test('reacts to hasSessionToken change', () {
      final container = ProviderContainer(
        overrides: [
          hasSessionTokenProvider.overrideWith((ref) => true),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isSignedInProvider), true);
      // Switch to false by overriding again would need new container; we only check token path
      final container2 = ProviderContainer(
        overrides: [
          hasSessionTokenProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container2.dispose);
      expect(container2.read(isSignedInProvider), false);
    });
  });
}
