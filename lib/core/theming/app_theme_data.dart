// core/theme/app_theme_data.dart
import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData get lightTheme => ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontFamily: 'Arial',
      ),
      backgroundColor: Colors.indigo,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      displayMedium: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      displaySmall: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      bodyLarge: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      bodyMedium: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      bodySmall: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      titleLarge: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      titleMedium: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      titleSmall: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      labelLarge: TextStyle(color: Colors.black, fontFamily: 'Arial'),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      labelStyle: const TextStyle(color: Colors.black),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIconColor: Colors.black,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.black, fontFamily: 'Arial'),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontFamily: 'Arial',
      ),
      backgroundColor: Colors.black,
      centerTitle: true,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      displayMedium: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      displaySmall: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      bodySmall: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      titleLarge: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      titleMedium: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      titleSmall: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      labelLarge: TextStyle(color: Colors.white, fontFamily: 'Arial'),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIconColor: Colors.white,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.white, fontFamily: 'Arial'),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
