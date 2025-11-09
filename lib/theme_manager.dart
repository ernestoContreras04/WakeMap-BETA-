import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _themeKey = 'selected_theme';
  static const String _systemThemeKey = 'system_theme_enabled';
  
  static ThemeMode _themeMode = ThemeMode.system;
  static bool _systemThemeEnabled = true;
  
  static ThemeMode get themeMode => _themeMode;
  static bool get systemThemeEnabled => _systemThemeEnabled;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'system';
    _systemThemeEnabled = prefs.getBool(_systemThemeKey) ?? true;
    
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
  }

  static Future<void> setSystemThemeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, enabled);
    _systemThemeEnabled = enabled;
  }

  static ThemeData getLightTheme() {
    const primaryColor = Color(0xFF2514A3); // Azul puro y vibrante
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: Colors.white,
        onSurface: Colors.black87,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w700,
          fontSize: 57,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w700,
          fontSize: 45,
          color: Colors.black87,
        ),
        displaySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 36,
          color: Colors.black87,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 32,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 28,
          color: Colors.black87,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: Colors.black87,
        ),
        titleMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.black87,
        ),
        titleSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.black87,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: Colors.black54,
        ),
        labelLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
        labelMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Colors.black45,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: Colors.black45,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4F46E5); // Azul más claro y vibrante para mejor contraste
          }
          return Colors.grey[300];
        }),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.black54,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.black45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: Colors.grey[400]!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: Colors.white,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.black87,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    const seedColor = Color(0xFF0A84FF);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor, 
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1C1E),
        surfaceContainerHighest: const Color(0xFF2C2C2E),
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w700,
          fontSize: 57,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w700,
          fontSize: 45,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 36,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 32,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 28,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.white70,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: Colors.white60,
        ),
        labelLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Colors.white54,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: Colors.white54,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return Colors.grey[800];
        }),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: seedColor,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.white70,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.white54,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A), // Azul como el widget del tiempo
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: seedColor,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: Colors.white,
        overlayColor: seedColor.withOpacity(0.2),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF1C1C1E)),
          elevation: WidgetStateProperty.all(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          color: Colors.white,
        ),
      ),
    );
  }

  static void updateSystemUIOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark 
            ? const Color(0xFF121212) 
            : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }
}
