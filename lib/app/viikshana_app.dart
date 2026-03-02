import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class ViikshanaApp extends StatelessWidget {
  const ViikshanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viikshana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const AppRouter(),
    );
  }
}