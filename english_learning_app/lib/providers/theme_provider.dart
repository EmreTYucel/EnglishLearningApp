import 'package:flutter/material.dart';

// Tema yönetimi provider sınıfı
class ThemeProvider extends ChangeNotifier {
  // Tema modu değişkeni (varsayılan: sistem teması)
  ThemeMode _themeMode = ThemeMode.system;

  // Getter metodları
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Tema modunu değiştir (açık/koyu tema arası geçiş)
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
} 