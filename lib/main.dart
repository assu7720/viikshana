import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:viikshana/app/viikshana_app.dart';
import 'package:viikshana/core/watch_history/watch_history_repository.dart';
import 'package:viikshana/data/hive/watch_history_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WatchHistoryEntryAdapter());
  await initWatchHistoryBox();

  runZonedGuarded<void>(
    () {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      runApp(const ViikshanaApp());
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Unhandled error: $error');
        debugPrint(stack.toString());
      }
    },
  );
}