import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/viikshana_app.dart';

void main() {
  // Keep bindings and runApp in the same zone to avoid "Zone mismatch".
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

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