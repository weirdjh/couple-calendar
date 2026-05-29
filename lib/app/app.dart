import 'package:flutter/material.dart';

import 'presentation/app_shell.dart';
import 'theme/app_theme.dart';

class CoupleCalendarApp extends StatelessWidget {
  const CoupleCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Calendar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
