import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: DurakApp()));
}

class DurakApp extends StatelessWidget {
  const DurakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дурак',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B3D2E), useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
