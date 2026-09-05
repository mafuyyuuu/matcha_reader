import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    scaffoldBackgroundColor: AppColors.paperWhite,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.matchaGreen),
    useMaterial3: true,
  );
}
