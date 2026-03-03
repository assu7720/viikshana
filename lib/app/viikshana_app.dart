import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:viikshana/navigation/app_router.dart';
import 'package:viikshana/shared/theme/viikshana_theme.dart';

class ViikshanaApp extends StatelessWidget {
  const ViikshanaApp({super.key, this.overrides});

  /// Provider overrides (e.g. for tests). Pass to [ProviderScope].
  final List<Override>? overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        title: 'Viikshana',
        debugShowCheckedModeBanner: false,
        theme: ViikshanaTheme.dark(),
        darkTheme: ViikshanaTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const AppRouter(),
      ),
    );
  }
}
