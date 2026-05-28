import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF5C2E0E);      // dark brown
  static const Color primaryLight = Color(0xFF8B4513);
  static const Color accent = Color(0xFFE07B39);        // orange accent
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFAF3ED);        // warm cream for cards
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB00020);
  static const Color divider = Color(0xFFE8E0D8);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D5CC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D5CC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE8E0D8)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: Color(0xFFAAAAAA),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}

class ItemImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final Widget? placeholder;

  const ItemImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        Container(
          color: AppTheme.cardBg,
          child: const Center(
            child: Icon(
              Icons.inventory_2_rounded,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
        );

    if (imagePath == null || imagePath!.isEmpty) return fallback;

    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: fit,
        width: double.infinity,
        errorBuilder: (ctx, error, stackTrace) => fallback,
      );
    }

    return Image.file(
      File(imagePath!),
      fit: fit,
      width: double.infinity,
      errorBuilder: (ctx, error, stackTrace) => fallback,
    );
  }
}
