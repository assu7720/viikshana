import 'package:flutter/material.dart';
import '../navigation/app_router.dart'; // Fix import paths

class ViikshanaApp extends StatelessWidget {
  const ViikshanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viikshana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true), // Correct Material3 theme
      home: const AppRouter(), // Restore platform routing
    );
  }
}
