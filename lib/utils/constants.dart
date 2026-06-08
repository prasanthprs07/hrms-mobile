import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppConstants {
  static const String appName = 'Expense Manager';
  static const String appVersion = '1.0.0';

  static const String dbName = 'expense_manager.db';
  static const int dbVersion = 1;

  static const String prefsKeyOnboarding = 'onboarding_done';
  static const String prefsKeyTheme = 'theme_mode';
  static const String prefsKeyFirstLaunch = 'first_launch';

  static List<Color> categoryColors = [
    const Color(0xFFFF6B35),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
    const Color(0xFF4CAF50),
    const Color(0xFFF44336),
    const Color(0xFF607D8B),
  ];
}

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42DB);
  static const Color accent = Color(0xFFFF6B35);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF16213E);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color borderLight = Color(0xFFE8E8E8);
  static const Color borderDark = Color(0xFF2D3436);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
