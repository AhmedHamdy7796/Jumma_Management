import 'package:flutter/material.dart';
import '../resources/app_colors.dart';

class AppThemeData {
  static const String _fontFamily = 'Cairo';

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.lightGrey,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryAccent,
          surface: AppColors.white,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontFamily: _fontFamily,
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily),
          bodyMedium: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily),
          bodySmall: TextStyle(color: AppColors.darkGrey, fontFamily: _fontFamily),
          titleLarge: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily),
          labelLarge: TextStyle(color: AppColors.primary, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          labelStyle: const TextStyle(color: AppColors.darkGrey, fontFamily: _fontFamily),
          hintStyle: const TextStyle(color: AppColors.darkGrey, fontFamily: _fontFamily),
          prefixIconColor: AppColors.primary,
          suffixIconColor: AppColors.primary,
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkGrey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.darkGrey.withValues(alpha: 0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.primary,
          titleTextStyle: TextStyle(color: AppColors.secondary, fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          subtitleTextStyle: TextStyle(color: AppColors.darkGrey, fontFamily: _fontFamily, fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryAccent,
        scaffoldBackgroundColor: AppColors.black,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryAccent,
          secondary: AppColors.accent,
          surface: AppColors.cardDark,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontFamily: _fontFamily,
          ),
          backgroundColor: AppColors.secondary,
          centerTitle: true,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.white, fontFamily: _fontFamily),
          bodyMedium: TextStyle(color: AppColors.white, fontFamily: _fontFamily),
          bodySmall: TextStyle(color: AppColors.lightGrey, fontFamily: _fontFamily),
          titleLarge: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.white, fontFamily: _fontFamily),
          labelLarge: TextStyle(color: AppColors.primaryAccent, fontFamily: _fontFamily, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          labelStyle: const TextStyle(color: AppColors.lightGrey, fontFamily: _fontFamily),
          hintStyle: const TextStyle(color: AppColors.lightGrey, fontFamily: _fontFamily),
          prefixIconColor: AppColors.white,
          suffixIconColor: AppColors.white,
          filled: true,
          fillColor: AppColors.cardDark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGrey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.white,
          titleTextStyle: TextStyle(color: AppColors.white, fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          subtitleTextStyle: TextStyle(color: AppColors.lightGrey, fontFamily: _fontFamily, fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      );
}
