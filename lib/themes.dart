import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  textTheme: TextTheme(
    bodyMedium: TextStyle(fontSize: 20, color: Colors.white),
  ),
  cardTheme: CardTheme(color: Colors.black.withOpacity(0.3), elevation: 4),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  textTheme: TextTheme(
    bodyMedium: TextStyle(fontSize: 20, color: Colors.black),
  ),
  cardTheme: CardTheme(color: Colors.white54, elevation: 4),
);

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
