import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:viikshana/app/viikshana_app.dart';
import 'package:viikshana/core/search_history/search_history_repository.dart';
import 'package:viikshana/core/session/session_repository.dart';
import 'package:viikshana/core/watch_history/watch_history_repository.dart';
import 'package:viikshana/data/hive/watch_history_adapter.dart';

void main() {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await Firebase.initializeApp();
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('Firebase init skipped (add google-services.json / run flutterfire configure): $e');
          debugPrint(stack.toString());
        }
      }

      await Hive.initFlutter();
      Hive.registerAdapter(WatchHistoryEntryAdapter());
      await initWatchHistoryBox();
      await initSearchHistoryBox();
      await initSessionBox();

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
        debugPrint('Unhandled exception: $error');
        debugPrint(stack.toString());
      }
    },
  );
}