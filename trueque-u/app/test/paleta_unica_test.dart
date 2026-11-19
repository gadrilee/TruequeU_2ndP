import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';

import 'roles_esquema.dart';

final paleta = <Color>{
  TemaTruequeU.azul,
  TemaTruequeU.azulOscuro,
  TemaTruequeU.azulClaro,
  TemaTruequeU.rojo,
  TemaTruequeU.rojoClaro,
  TemaTruequeU.rojoOscuro,
  TemaTruequeU.fondo,
  TemaTruequeU.borde,
  TemaTruequeU.verdeClaro,
  TemaTruequeU.verdeOscuro,
  TemaTruequeU.blanco,
  TemaTruequeU.texto,
  TemaTruequeU.textoSuave,
  TemaTruequeU.contorno,
  TemaTruequeU.superficieAlta,
};

Color sinAlfa(Color c) => c.withValues(alpha: 1);

final prohibidos = <String, RegExp>{
  'colorScheme': RegExp(r'colorScheme'),
  'Colors.': RegExp(r'\bColors\.'),
  'Color(': RegExp(r'\bColor\('),
  'Color.from': RegExp(r'\bColor\.from'),
};

void main() {
  test('el codigo de la app solo usa colores de TemaTruequeU', () {
    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((a) => a.path.endsWith('.dart'))
        .where((a) => !a.path.replaceAll('\\', '/').endsWith('lib/tema.dart'));

    expect(archivos, isNotEmpty);
    final encontrados = <String>[];
    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        prohibidos.forEach((nombre, patron) {
          if (patron.hasMatch(lineas[i])) {
            encontrados.add('${archivo.path}:${i + 1} usa $nombre');
          }
        });
      }
    }
    expect(encontrados, isEmpty);
  });

  test('cada rol del ColorScheme es un color de TemaTruequeU', () {
    final roles = rolesDe(TemaTruequeU.claro().colorScheme);

    expect(roles.length, 46);
    roles.forEach((rol, color) {
      expect(paleta.contains(sinAlfa(color)), true, reason: rol);
    });
  });

  test('los colores de los temas de componentes son de TemaTruequeU', () {
    final tema = TemaTruequeU.claro();
    final colores = <String, Color?>{
      'scaffoldBackgroundColor': tema.scaffoldBackgroundColor,
      'canvasColor': tema.canvasColor,
      'cardColor': tema.cardColor,
      'primaryColor': tema.primaryColor,
      'primaryColorLight': tema.primaryColorLight,
      'primaryColorDark': tema.primaryColorDark,
      'secondaryHeaderColor': tema.secondaryHeaderColor,
      'shadowColor': tema.shadowColor,
      'dividerColor': tema.dividerColor,
      'disabledColor': tema.disabledColor,
      'hintColor': tema.hintColor,
      'unselectedWidgetColor': tema.unselectedWidgetColor,
      'focusColor': tema.focusColor,
      'hoverColor': tema.hoverColor,
      'highlightColor': tema.highlightColor,
      'splashColor': tema.splashColor,
      'iconTheme': tema.iconTheme.color,
      'primaryIconTheme': tema.primaryIconTheme.color,
      'dividerTheme': tema.dividerTheme.color,
      'dialogTheme.backgroundColor': tema.dialogTheme.backgroundColor,
      'dialogTheme.iconColor': tema.dialogTheme.iconColor,
      'dialogTheme.barrierColor': tema.dialogTheme.barrierColor,
      'snackBarTheme.backgroundColor': tema.snackBarTheme.backgroundColor,
      'snackBarTheme.actionTextColor': tema.snackBarTheme.actionTextColor,
      'snackBarTheme.closeIconColor': tema.snackBarTheme.closeIconColor,
      'popupMenuTheme': tema.popupMenuTheme.color,
      'progressIndicatorTheme': tema.progressIndicatorTheme.color,
      'appBarTheme.backgroundColor': tema.appBarTheme.backgroundColor,
      'appBarTheme.foregroundColor': tema.appBarTheme.foregroundColor,
      'inputDecorationTheme.fillColor': tema.inputDecorationTheme.fillColor,
      'floatingActionButtonTheme.backgroundColor':
          tema.floatingActionButtonTheme.backgroundColor,
      'floatingActionButtonTheme.foregroundColor':
          tema.floatingActionButtonTheme.foregroundColor,
      'cardTheme': tema.cardTheme.color,
      'navigationBarTheme.backgroundColor':
          tema.navigationBarTheme.backgroundColor,
      'navigationBarTheme.indicatorColor':
          tema.navigationBarTheme.indicatorColor,
    };

    colores.forEach((nombre, color) {
      expect(color, isNotNull, reason: nombre);
      expect(paleta.contains(sinAlfa(color!)), true, reason: nombre);
    });
  });
}
