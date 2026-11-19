import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';

void main() {
  group('TemaTruequeU', () {
    test('el tema claro usa Material 3 y los colores de la marca', () {
      final tema = TemaTruequeU.claro();

      expect(tema.useMaterial3, true);
      expect(tema.colorScheme.primary, TemaTruequeU.azul);
      expect(tema.colorScheme.secondary, TemaTruequeU.rojo);
      expect(tema.scaffoldBackgroundColor, TemaTruequeU.fondo);
    });

    test('los campos y botones tienen bordes redondeados', () {
      final tema = TemaTruequeU.claro();

      expect(tema.inputDecorationTheme.filled, true);
      expect(tema.inputDecorationTheme.border, isA<OutlineInputBorder>());
      expect(tema.filledButtonTheme.style, isNotNull);
      expect(tema.outlinedButtonTheme.style, isNotNull);
      expect(tema.textButtonTheme.style, isNotNull);
      expect(tema.floatingActionButtonTheme.backgroundColor, TemaTruequeU.rojo);
      expect(tema.navigationBarTheme.indicatorColor, TemaTruequeU.azulClaro);
    });

    test('los roles derivados del seed son explicitos', () {
      final esquema = TemaTruequeU.claro().colorScheme;

      expect(TemaTruequeU.blanco, const Color(0xFFFFFFFF));
      expect(TemaTruequeU.texto, const Color(0xFF1C1917));
      expect(TemaTruequeU.textoSuave, const Color(0xFF57534E));
      expect(TemaTruequeU.contorno, const Color(0xFF78716C));
      expect(TemaTruequeU.superficieAlta, const Color(0xFFF1ECE5));
      expect(esquema.onPrimary, TemaTruequeU.blanco);
      expect(esquema.onSecondary, TemaTruequeU.blanco);
      expect(esquema.onTertiary, TemaTruequeU.blanco);
      expect(esquema.onError, TemaTruequeU.blanco);
      expect(esquema.onSurface, TemaTruequeU.texto);
      expect(esquema.onSurfaceVariant, TemaTruequeU.textoSuave);
      expect(esquema.outline, TemaTruequeU.contorno);
      expect(esquema.surfaceContainerHighest, TemaTruequeU.superficieAlta);
    });

    test('los roles que antes derivaba el seed son colores de la paleta', () {
      final esquema = TemaTruequeU.claro().colorScheme;

      expect(esquema.brightness, Brightness.light);
      expect(esquema.surfaceContainerLowest, TemaTruequeU.blanco);
      expect(esquema.surfaceContainerLow, TemaTruequeU.fondo);
      expect(esquema.surfaceContainer, TemaTruequeU.superficieAlta);
      expect(esquema.surfaceContainerHigh, TemaTruequeU.superficieAlta);
      expect(esquema.surfaceDim, TemaTruequeU.borde);
      expect(esquema.surfaceBright, TemaTruequeU.blanco);
      expect(esquema.inverseSurface, TemaTruequeU.azulOscuro);
      expect(esquema.onInverseSurface, TemaTruequeU.blanco);
      expect(esquema.inversePrimary, TemaTruequeU.azulClaro);
      expect(esquema.surfaceTint, TemaTruequeU.azul);
      expect(esquema.shadow, TemaTruequeU.texto);
      expect(esquema.scrim, TemaTruequeU.texto);
    });

    test('los temas de componentes usan colores de la paleta', () {
      final tema = TemaTruequeU.claro();

      expect(tema.iconTheme.color, TemaTruequeU.texto);
      expect(tema.dividerTheme.color, TemaTruequeU.borde);
      expect(tema.dialogTheme.backgroundColor, TemaTruequeU.superficieAlta);
      expect(tema.snackBarTheme.backgroundColor, TemaTruequeU.azulOscuro);
      expect(tema.popupMenuTheme.color, TemaTruequeU.superficieAlta);
      expect(tema.progressIndicatorTheme.color, TemaTruequeU.azul);
    });

    test('la fuente de la marca se llama Roboto', () {
      expect(TemaTruequeU.fuente, 'Roboto');
    });

    test('los tokens de espacio, radio y tipo tienen su valor', () {
      expect(Espacios.e2, 2);
      expect(Espacios.e4, 4);
      expect(Espacios.e6, 6);
      expect(Espacios.e8, 8);
      expect(Espacios.e10, 10);
      expect(Espacios.e12, 12);
      expect(Espacios.e16, 16);
      expect(Espacios.e20, 20);
      expect(Espacios.e24, 24);
      expect(Espacios.e32, 32);
      expect(Espacios.e40, 40);
      expect(Radios.r8, 8);
      expect(Radios.r12, 12);
      expect(Radios.r14, 14);
      expect(Radios.r16, 16);
      expect(Radios.r20, 20);
      expect(Radios.r28, 28);
      expect(Radios.r36, 36);
      expect(Tipos.t11, 11);
      expect(Tipos.t12, 12);
      expect(Tipos.t13, 13);
      expect(Tipos.t14, 14);
      expect(Tipos.t16, 16);
      expect(Tipos.t17, 17);
      expect(Tipos.t18, 18);
      expect(Tipos.t26, 26);
    });

    test('los estilos de texto usan los tamanos de Tipos', () {
      expect(TextosTruequeU.titulo.fontSize, Tipos.t26);
      expect(TextosTruequeU.titulo.fontWeight, FontWeight.bold);
      expect(TextosTruequeU.subtitulo.fontSize, Tipos.t18);
      expect(TextosTruequeU.tituloTarjeta.fontSize, Tipos.t17);
      expect(TextosTruequeU.tituloItem.fontSize, Tipos.t16);
      expect(TextosTruequeU.cuerpo.fontSize, Tipos.t14);
      expect(TextosTruequeU.detalle.fontSize, Tipos.t13);
      expect(TextosTruequeU.etiqueta.fontWeight, FontWeight.w500);
      expect(TextosTruequeU.ayuda.fontSize, Tipos.t12);
      expect(TextosTruequeU.chip.fontSize, Tipos.t11);
      expect(TextosTruequeU.chipDestacado.fontWeight, FontWeight.bold);
      expect(TextosTruequeU.pie.fontSize, Tipos.t11);
    });
  });
}
