import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/home_screen.dart';

class MatchaReader extends StatelessWidget {
  const MatchaReader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matcha Reader',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
