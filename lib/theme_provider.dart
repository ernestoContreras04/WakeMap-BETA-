import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeManager.themeMode;
  Locale _locale = const Locale('es', '');
  
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  
  String get currentThemeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setTheme(String theme) async {
    await ThemeManager.setTheme(theme);
    
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
    
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode, '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    notifyListeners();
  }

  Future<void> initialize() async {
    await ThemeManager.initialize();
    _themeMode = ThemeManager.themeMode;
    
    // Cargar idioma guardado
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language') ?? 'es';
    _locale = Locale(savedLanguage, '');
    
    notifyListeners();
  }
}
