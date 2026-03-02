import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppPlatform { androidMobile, iosMobile, tablet, tv }

class PlatformInfo {
  static AppPlatform resolve({
    required double shortestSide,
    required double width,
  }) {
    // TV heuristic: Android + very large width (tune later)
    if (!kIsWeb && Platform.isAndroid && width >= 960) return AppPlatform.tv;

    // Tablet heuristic: shortestSide >= 600dp
    if (shortestSide >= 600) return AppPlatform.tablet;

    // Mobile
    if (!kIsWeb && Platform.isIOS) return AppPlatform.iosMobile;
    return AppPlatform.androidMobile;
  }
}