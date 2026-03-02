// lib/app/viikshana_app.dart
import 'package:flutter/material.dart';
import 'shared/theme/viikshana_theme.dart';

class ViikshanaApp extends StatelessWidget {
  const ViikshanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viikshana',
      theme: ViikshanaTheme.light(),
      darkTheme: ViikshanaTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viikshana'),
      ),
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}
