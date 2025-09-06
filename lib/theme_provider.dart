import 'package:flutter/material.dart';
import 'theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeManager.themeMode;
  
  ThemeMode get themeMode => _themeMode;
  
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

  Future<void> initialize() async {
    await ThemeManager.initialize();
    _themeMode = ThemeManager.themeMode;
    notifyListeners();
  }
}
