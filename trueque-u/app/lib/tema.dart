import 'package:flutter/material.dart';

class TemaTruequeU {
  static const fuente = 'Roboto';

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
  static const blanco = Color(0xFFFFFFFF);
  static const texto = Color(0xFF1C1917);
  static const textoSuave = Color(0xFF57534E);
  static const contorno = Color(0xFF78716C);
  static const superficieAlta = Color(0xFFF1ECE5);

  static ThemeData claro() {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: azul,
      onPrimary: blanco,
      primaryContainer: azulClaro,
      onPrimaryContainer: azulOscuro,
      primaryFixed: azulClaro,
      primaryFixedDim: azulClaro,
      onPrimaryFixed: azulOscuro,
      onPrimaryFixedVariant: azul,
      secondary: rojo,
      onSecondary: blanco,
      secondaryContainer: rojoClaro,
      onSecondaryContainer: rojoOscuro,
      secondaryFixed: rojoClaro,
      secondaryFixedDim: rojoClaro,
      onSecondaryFixed: rojoOscuro,
      onSecondaryFixedVariant: rojo,
      tertiary: verdeOscuro,
      onTertiary: blanco,
      tertiaryContainer: verdeClaro,
      onTertiaryContainer: verdeOscuro,
      tertiaryFixed: verdeClaro,
      tertiaryFixedDim: verdeClaro,
      onTertiaryFixed: verdeOscuro,
      onTertiaryFixedVariant: verdeOscuro,
      error: rojo,
      onError: blanco,
      errorContainer: rojoClaro,
      onErrorContainer: rojoOscuro,
      surface: fondo,
      onSurface: texto,
      surfaceDim: borde,
      surfaceBright: blanco,
      surfaceContainerLowest: blanco,
      surfaceContainerLow: fondo,
      surfaceContainer: superficieAlta,
      surfaceContainerHigh: superficieAlta,
      surfaceContainerHighest: superficieAlta,
      onSurfaceVariant: textoSuave,
      outline: contorno,
      outlineVariant: borde,
      shadow: texto,
      scrim: texto,
      inverseSurface: azulOscuro,
      onInverseSurface: blanco,
      inversePrimary: azulClaro,
      surfaceTint: azul,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radios.r14),
      borderSide: const BorderSide(color: contorno),
    );
    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radios.r28),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      canvasColor: fondo,
      cardColor: fondo,
      primaryColor: azul,
      primaryColorLight: azulClaro,
      primaryColorDark: azulOscuro,
      secondaryHeaderColor: azulClaro,
      shadowColor: texto,
      dividerColor: contorno,
      disabledColor: texto.withValues(alpha: 0.38),
      hintColor: texto.withValues(alpha: 0.6),
      unselectedWidgetColor: texto.withValues(alpha: 0.54),
      focusColor: texto.withValues(alpha: 0.12),
      hoverColor: texto.withValues(alpha: 0.04),
      highlightColor: texto.withValues(alpha: 0.1),
      splashColor: texto.withValues(alpha: 0.12),
      iconTheme: const IconThemeData(color: texto),
      primaryIconTheme: const IconThemeData(color: blanco),
      dividerTheme: const DividerThemeData(color: borde),
      dialogTheme: DialogThemeData(
        backgroundColor: superficieAlta,
        iconColor: textoSuave,
        barrierColor: texto.withValues(alpha: 0.54),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: azulOscuro,
        actionTextColor: azulClaro,
        closeIconColor: blanco,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: superficieAlta,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: azul,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: azulOscuro,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: blanco,
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
          side: const BorderSide(color: contorno),
          shape: formaBoton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: azul),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: rojo,
        foregroundColor: blanco,
        shape: formaBoton,
      ),
      cardTheme: CardThemeData(
        color: blanco,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.r20),
          side: const BorderSide(color: borde),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: blanco,
        indicatorColor: azulClaro,
      ),
    );
  }
}

class Espacios {
  static const e2 = 2.0;
  static const e4 = 4.0;
  static const e6 = 6.0;
  static const e8 = 8.0;
  static const e10 = 10.0;
  static const e12 = 12.0;
  static const e16 = 16.0;
  static const e20 = 20.0;
  static const e24 = 24.0;
  static const e32 = 32.0;
  static const e40 = 40.0;
}

class Radios {
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r28 = 28.0;
  static const r36 = 36.0;
}

class Tipos {
  static const t11 = 11.0;
  static const t12 = 12.0;
  static const t13 = 13.0;
  static const t14 = 14.0;
  static const t16 = 16.0;
  static const t17 = 17.0;
  static const t18 = 18.0;
  static const t26 = 26.0;
}

class TextosTruequeU {
  static const titulo = TextStyle(fontSize: Tipos.t26, fontWeight: FontWeight.bold);
  static const subtitulo = TextStyle(fontSize: Tipos.t18, fontWeight: FontWeight.bold);
  static const tituloTarjeta = TextStyle(fontSize: Tipos.t17, fontWeight: FontWeight.bold);
  static const tituloItem = TextStyle(fontSize: Tipos.t16, fontWeight: FontWeight.bold);
  static const cuerpo = TextStyle(fontSize: Tipos.t14);
  static const detalle = TextStyle(fontSize: Tipos.t13);
  static const etiqueta = TextStyle(fontSize: Tipos.t12, fontWeight: FontWeight.w500);
  static const ayuda = TextStyle(fontSize: Tipos.t12);
  static const chip = TextStyle(fontSize: Tipos.t11, fontWeight: FontWeight.w500);
  static const chipDestacado = TextStyle(fontSize: Tipos.t11, fontWeight: FontWeight.bold);
  static const pie = TextStyle(fontSize: Tipos.t11);
}
