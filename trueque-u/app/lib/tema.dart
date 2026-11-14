import 'package:flutter/material.dart';

class TemaTruequeU {
  static const azul = Color(0xFF2A3964);
  static const azulOscuro = Color(0xFF1B2645);
  static const azulClaro = Color(0xFFDDE3F2);
  static const rojo = Color(0xFFCC100C);
  static const rojoClaro = Color(0xFFFBE3E2);
  static const rojoOscuro = Color(0xFF8F0B08);
  static const fondo = Color(0xFFFAF7F2);
  static const borde = Color(0xFFE7E5E4);
  static const verdeClaro = Color(0xFFDCF2E3);
  static const verdeOscuro = Color(0xFF14532D);

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(seedColor: azul).copyWith(
      primary: azul,
      onPrimary: Colors.white,
      primaryContainer: azulClaro,
      onPrimaryContainer: azulOscuro,
      secondary: rojo,
      onSecondary: Colors.white,
      secondaryContainer: rojoClaro,
      onSecondaryContainer: rojoOscuro,
      tertiary: verdeOscuro,
      tertiaryContainer: verdeClaro,
      onTertiaryContainer: verdeOscuro,
      error: rojo,
      errorContainer: rojoClaro,
      onErrorContainer: rojoOscuro,
      surface: fondo,
      outlineVariant: borde,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: borde),
    );
    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: azulOscuro,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: azul, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: formaBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azul,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: borde),
          shape: formaBoton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: azul),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: rojo,
        foregroundColor: Colors.white,
        shape: formaBoton,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borde),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: azulClaro,
      ),
    );
  }
}
