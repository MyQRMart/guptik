import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../models/home_control/theme_models.dart';

class HomeThemeProvider extends ChangeNotifier {
  ThemeSettings _settings = const ThemeSettings(themeType: ThemeType.basic);
  ThemeSettings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;

  HomeThemeProvider() { _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('theme_settings');
    if (json != null) {
      _settings = ThemeSettings.fromJson(jsonDecode(json));
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _settings = _settings.copyWith(isDarkMode: isDark, themeType: ThemeType.basic);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_settings', jsonEncode(_settings.toJson()));
    notifyListeners();
  }
  
  Future<void> setThemeType(ThemeType type) async {
    _settings = _settings.copyWith(themeType: type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_settings', jsonEncode(_settings.toJson()));
    notifyListeners();
  }
}