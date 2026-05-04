import 'package:flutter/material.dart';

import 'presentation/app_shell.dart';

class CoupleCalendarApp extends StatelessWidget {
  const CoupleCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D7C8A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7F4),
      ),
      home: const AppShell(),
    );
  }
}
