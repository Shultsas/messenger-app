import 'package:flutter/material.dart';

class PixelTheme {
  static const Color background = Color(0xFF1a1a2e);
  static const Color surface = Color(0xFF16213e);
  static const Color accent = Color(0xFFe94560);
  static const Color secondary = Color(0xFF0f3460);
  static const Color border = Colors.white;
  static const Color text = Colors.white;
  static const Color textSecondary = Colors.grey;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: surface,
      fontFamily: 'PressStart2P',
      
      // 👇 ГЛОБАЛЬНЫЙ ШРИФТ ДЛЯ ВСЕХ ТЕКСТОВ
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 24, color: text),
        displayMedium: TextStyle(fontFamily: 'PressStart2P', fontSize: 20, color: text),
        displaySmall: TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: text),
        headlineLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 18, color: text),
        headlineMedium: TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: text),
        headlineSmall: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: text),
        titleLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: text),
        titleMedium: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: text),
        titleSmall: TextStyle(fontFamily: 'PressStart2P', fontSize: 12, color: text),
        bodyLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: text),
        bodyMedium: TextStyle(fontFamily: 'PressStart2P', fontSize: 12, color: text),
        bodySmall: TextStyle(fontFamily: 'PressStart2P', fontSize: 10, color: text),
        labelLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: text),
        labelMedium: TextStyle(fontFamily: 'PressStart2P', fontSize: 12, color: text),
        labelSmall: TextStyle(fontFamily: 'PressStart2P', fontSize: 10, color: text),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 14,
          fontFamily: 'PressStart2P',
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          side: const BorderSide(color: border, width: 2),
          textStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 10,
          ),
        ),
      ),
      
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        hintStyle: TextStyle(color: textSecondary, fontFamily: 'PressStart2P', fontSize: 10),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'PressStart2P', fontSize: 10),
      ),
      
      // 👇 СТИЛИ ДЛЯ СПИСКОВ
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: text),
        subtitleTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 8, color: textSecondary),
      ),
      
      // 👇 ИСПРАВЛЕНО: CardThemeData вместо CardTheme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: text,
      ),
      
      // 👇 ЦВЕТОВАЯ СХЕМА (исправлены deprecated поля)
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        surface: surface,
        // background убран (устарел)
        onPrimary: text,
        onSecondary: text,
        onSurface: text,
        // onBackground заменён на onSurface
      ),
    );
  }
}