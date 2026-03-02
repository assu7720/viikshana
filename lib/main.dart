import 'package:flutter/material.dart';
import 'bootstrap/bootstrap.dart';

void main() async {
  await bootstrap();
  runApp(const ViikshanaApp());
}

class ViikshanaApp extends StatelessWidget {
  const ViikshanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}