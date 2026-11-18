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
  });
}
