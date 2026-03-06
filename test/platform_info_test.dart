import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/core/platform/platform_info.dart';

void main() {
  tearDown(() {
    PlatformInfo.overrideForTesting = null;
  });

  group('PlatformInfo', () {
    test('resolve returns override when set', () {
      PlatformInfo.overrideForTesting = AppPlatform.tv;
      expect(
        PlatformInfo.resolve(shortestSide: 400, width: 800),
        AppPlatform.tv,
      );
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      expect(
        PlatformInfo.resolve(shortestSide: 400, width: 800),
        AppPlatform.tablet,
      );
      PlatformInfo.overrideForTesting = AppPlatform.iosMobile;
      expect(
        PlatformInfo.resolve(shortestSide: 400, width: 800),
        AppPlatform.iosMobile,
      );
      PlatformInfo.overrideForTesting = AppPlatform.androidMobile;
      expect(
        PlatformInfo.resolve(shortestSide: 400, width: 800),
        AppPlatform.androidMobile,
      );
    });

    test('resolve uses tablet when override is tablet', () {
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      expect(
        PlatformInfo.resolve(shortestSide: 600, width: 1024),
        AppPlatform.tablet,
      );
    });

    test('resolve returns consistent result when override is null', () {
      PlatformInfo.overrideForTesting = null;
      final result = PlatformInfo.resolve(shortestSide: 400, width: 800);
      expect(AppPlatform.values, contains(result));
    });

    test('AppPlatform has expected values', () {
      expect(AppPlatform.values.length, 4);
      expect(AppPlatform.values, contains(AppPlatform.androidMobile));
      expect(AppPlatform.values, contains(AppPlatform.iosMobile));
      expect(AppPlatform.values, contains(AppPlatform.tablet));
      expect(AppPlatform.values, contains(AppPlatform.tv));
    });
  });
}
