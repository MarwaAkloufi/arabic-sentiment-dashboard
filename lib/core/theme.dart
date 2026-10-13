import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Palette {
  const Palette._();

  static const Color bg = Color(0xFFF6F9FC);
  static const Color border = Color(0xFFDDE7F0);
  static const Color ink = Color(0xFF0B2942);
  static const Color muted = Color(0xFF4F6B82);

  static const Color sky = Color(0xFF0A84D6);

  /// سماوي فاتح للتفاصيل والأيقونات
  static const Color skyBright = Color(0xFF27AEF5);
  static const Color skyDark = Color(0xFF0A5FA6);
  static const Color skySoft = Color(0xFFE3F2FD);

  static const Color positive = Color(0xFF12A06E);
  static const Color positiveDark = Color(0xFF0B7F57);
  static const Color negative = Color(0xFFE5484D);
  static const Color negativeDark = Color(0xFFC42F36);
}

Color tint(Color c, double opacity) => c.withAlpha((opacity * 255).round());

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.sky,
    onPrimary: Colors.white,
    secondary: Palette.skyBright,
    onSecondary: Colors.white,
    error: Palette.negative,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Palette.ink,
  );

  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
  );

  return base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme)
        .apply(bodyColor: Palette.ink, displayColor: Palette.ink),
    dividerColor: Palette.border,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Palette.skySoft,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
