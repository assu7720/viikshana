import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppPlatform { androidMobile, iosMobile, tablet, tv }

class PlatformInfo {
  /// Test-only override. When non-null, [resolve] returns this instead of computing.
  /// Set to null in tearDown to avoid affecting other tests.
  static AppPlatform? overrideForTesting;

  static AppPlatform resolve({
    required double shortestSide,
    required double width,
  }) {
    if (overrideForTesting != null) return overrideForTesting!;

    // TV: Android only, large width (10-foot UI). Tablets in landscape often 960–1280; use 1920 so they get MobileShell + home feed.
    if (!kIsWeb && Platform.isAndroid && width >= 1920) return AppPlatform.tv;

    // Tablet heuristic: shortestSide >= 600dp
    if (shortestSide >= 600) return AppPlatform.tablet;

    // Mobile
    if (!kIsWeb && Platform.isIOS) return AppPlatform.iosMobile;
    return AppPlatform.androidMobile;
  }
}