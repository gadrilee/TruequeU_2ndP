import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';

String hex(Color color) {
  final valor = color.toARGB32() & 0xFFFFFF;
  return '#${valor.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

int peso(TextStyle estilo) => (estilo.fontWeight ?? FontWeight.w400).value;

final colores = <String, Color>{
  'azul': TemaTruequeU.azul,
  'azulOscuro': TemaTruequeU.azulOscuro,
  'azulClaro': TemaTruequeU.azulClaro,
  'rojo': TemaTruequeU.rojo,
  'rojoClaro': TemaTruequeU.rojoClaro,
  'rojoOscuro': TemaTruequeU.rojoOscuro,
  'fondo': TemaTruequeU.fondo,
  'borde': TemaTruequeU.borde,
  'verdeClaro': TemaTruequeU.verdeClaro,
  'verdeOscuro': TemaTruequeU.verdeOscuro,
  'blanco': TemaTruequeU.blanco,
  'texto': TemaTruequeU.texto,
  'textoSuave': TemaTruequeU.textoSuave,
  'contorno': TemaTruequeU.contorno,
  'superficieAlta': TemaTruequeU.superficieAlta,
};

final espacios = <String, double>{
  'e2': Espacios.e2,
  'e4': Espacios.e4,
  'e6': Espacios.e6,
  'e8': Espacios.e8,
  'e10': Espacios.e10,
  'e12': Espacios.e12,
  'e16': Espacios.e16,
  'e20': Espacios.e20,
  'e24': Espacios.e24,
  'e32': Espacios.e32,
  'e40': Espacios.e40,
};

final radios = <String, double>{
  'r8': Radios.r8,
  'r12': Radios.r12,
  'r14': Radios.r14,
  'r16': Radios.r16,
  'r20': Radios.r20,
  'r28': Radios.r28,
  'r36': Radios.r36,
};

final tipos = <String, double>{
  't11': Tipos.t11,
  't12': Tipos.t12,
  't13': Tipos.t13,
  't14': Tipos.t14,
  't16': Tipos.t16,
  't17': Tipos.t17,
  't18': Tipos.t18,
  't26': Tipos.t26,
};

final textos = <String, TextStyle>{
  'titulo': TextosTruequeU.titulo,
  'subtitulo': TextosTruequeU.subtitulo,
  'tituloTarjeta': TextosTruequeU.tituloTarjeta,
  'tituloItem': TextosTruequeU.tituloItem,
  'cuerpo': TextosTruequeU.cuerpo,
  'detalle': TextosTruequeU.detalle,
  'etiqueta': TextosTruequeU.etiqueta,
  'ayuda': TextosTruequeU.ayuda,
  'chip': TextosTruequeU.chip,
  'chipDestacado': TextosTruequeU.chipDestacado,
  'pie': TextosTruequeU.pie,
};

Map<String, dynamic> seccion(Map<String, dynamic> json, String nombre) =>
    json[nombre] as Map<String, dynamic>;

void main() {
  final json = jsonDecode(
    File('../../design/figma-plugin/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final esquema = TemaTruequeU.claro().colorScheme;
  final rolesEsquema = <String, Color>{
    'primary': esquema.primary,
    'onPrimary': esquema.onPrimary,
    'primaryContainer': esquema.primaryContainer,
    'onPrimaryContainer': esquema.onPrimaryContainer,
    'secondary': esquema.secondary,
    'onSecondary': esquema.onSecondary,
    'secondaryContainer': esquema.secondaryContainer,
    'onSecondaryContainer': esquema.onSecondaryContainer,
    'tertiary': esquema.tertiary,
    'onTertiary': esquema.onTertiary,
    'tertiaryContainer': esquema.tertiaryContainer,
    'onTertiaryContainer': esquema.onTertiaryContainer,
    'error': esquema.error,
    'onError': esquema.onError,
    'errorContainer': esquema.errorContainer,
    'onErrorContainer': esquema.onErrorContainer,
    'surface': esquema.surface,
    'onSurface': esquema.onSurface,
    'onSurfaceVariant': esquema.onSurfaceVariant,
    'outline': esquema.outline,
    'outlineVariant': esquema.outlineVariant,
    'surfaceContainerHighest': esquema.surfaceContainerHighest,
  };

  test('el JSON tiene exactamente las secciones esperadas', () {
    expect(
      json.keys.toSet(),
      {
        'TemaTruequeU',
        'ColorScheme',
        'Espacios',
        'Radios',
        'Tipos',
        'TextosTruequeU',
        'TextTheme',
        'TextoDerivado',
        'Contextos',
      },
    );
  });

  test('colores de TemaTruequeU coinciden en nombre y hex', () {
    final tokens = seccion(json, 'TemaTruequeU');

    expect(tokens.keys.toSet(), colores.keys.toSet());
    colores.forEach((nombre, color) {
      expect(tokens[nombre], hex(color), reason: nombre);
    });
  });

  test('roles del ColorScheme apuntan al color del tema', () {
    final roles = seccion(json, 'ColorScheme');

    expect(roles.keys.toSet(), rolesEsquema.keys.toSet());
    rolesEsquema.forEach((rol, color) {
      final alias = roles[rol] as String;
      expect(alias.startsWith('TemaTruequeU/'), true, reason: rol);
      final destino = alias.substring('TemaTruequeU/'.length);
      expect(colores.containsKey(destino), true, reason: rol);
      expect(color, colores[destino], reason: rol);
    });
  });

  test('espacios, radios y tipos coinciden en nombre y valor', () {
    final porSeccion = {
      'Espacios': espacios,
      'Radios': radios,
      'Tipos': tipos,
    };

    porSeccion.forEach((nombre, valores) {
      final tokens = seccion(json, nombre);
      expect(tokens.keys.toSet(), valores.keys.toSet(), reason: nombre);
      valores.forEach((clave, valor) {
        expect((tokens[clave] as num).toDouble(), valor, reason: '$nombre/$clave');
      });
    });
  });

  test('estilos de texto coinciden en tamano y peso', () {
    final tokens = seccion(json, 'TextosTruequeU');

    expect(tokens.keys.toSet(), textos.keys.toSet());
    textos.forEach((nombre, estilo) {
      final token = tokens[nombre] as Map<String, dynamic>;
      final alias = token['fontSize'] as String;
      expect(alias.startsWith('Tipos/'), true, reason: nombre);
      final destino = alias.substring('Tipos/'.length);
      expect(tipos[destino], estilo.fontSize, reason: nombre);
      expect(token['fontWeight'], peso(estilo), reason: nombre);
    });
  });
}
