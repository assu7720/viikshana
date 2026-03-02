import 'package:flutter/material.dart';
import '../core/platform/platform_info.dart';
import 'mobile_shell.dart';
import 'tv_shell.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final p = PlatformInfo.resolve(
      shortestSide: mq.size.shortestSide,
      width: mq.size.width,
    );

    switch (p) {
      case AppPlatform.tv:
        return const TvShell();
      default:
        return const MobileShell();
    }
  }
}