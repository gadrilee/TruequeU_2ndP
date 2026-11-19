import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/ayudantes/pares_contraste.dart';

String _hex(Color? c) {
  final valor = c!.toARGB32() & 0xFFFFFF;
  return '#${valor.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

void main() {
  test('escribe la tabla de contraste en docs/accesibilidad/contraste.md', () {
    const destino = '../../docs/accesibilidad/contraste.md';
    final lineas = StringBuffer()
      ..writeln('# Contraste WCAG 2.x AA de la paleta TemaTruequeU')
      ..writeln()
      ..writeln(
          'Generado con `flutter test tool/contraste_tabla_test.dart` a partir de `test/ayudantes/pares_contraste.dart`, el mismo listado que verifica `test/contraste_aa_test.dart`.')
      ..writeln()
      ..writeln(
          'Criterios: texto normal 4.5:1 (1.4.3), texto grande 3:1 (1.4.3) y elementos de interfaz o bordes de controles 3:1 (1.4.11). La razón es (L1+0.05)/(L2+0.05) con la luminancia relativa de WCAG.')
      ..writeln()
      ..writeln(
          '| Par (primer plano / fondo) | Colores | Dónde se usa | Tipo | Mínimo | Antes | Después | Resultado |')
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
    var fallan = 0;
    for (final par in paresContraste) {
      final antes = par.razonAntes ?? par.razon;
      final tipo = switch (par.tipo) {
        TipoContraste.texto => 'Texto',
        TipoContraste.textoGrande => 'Texto grande',
        TipoContraste.interfaz => 'Interfaz',
      };
      final cumple = par.razon >= par.minimo;
      if (!cumple) fallan++;
      final colores = par.primerPlanoAntes == null
          ? '${_hex(par.primerPlano)} sobre ${_hex(par.fondo)}'
          : '${_hex(par.primerPlanoAntes)} a ${_hex(par.primerPlano)} sobre ${_hex(par.fondo)}';
      lineas.writeln(
        '| ${par.nombre} | $colores | ${par.donde} | $tipo | ${par.minimo}:1 | ${antes.toStringAsFixed(2)}:1 | ${par.razon.toStringAsFixed(2)}:1 | ${cumple ? 'Cumple' : 'No cumple'} |',
      );
    }
    lineas
      ..writeln()
      ..writeln('Pares que no cumplen después de la corrección: $fallan.');
    File(destino).writeAsStringSync(lineas.toString());
    expect(fallan, 0);
  });
}
