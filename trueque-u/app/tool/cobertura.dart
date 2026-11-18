// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> argumentos) {
  final minimo = argumentos.isEmpty ? 100.0 : double.parse(argumentos.first);
  final archivo = File('coverage/lcov.info');
  if (!archivo.existsSync()) {
    stderr.writeln('No existe coverage/lcov.info. Ejecuta flutter test --coverage.');
    exit(2);
  }

  var totalLineas = 0;
  var totalCubiertas = 0;
  var archivoActual = '';
  var sinCubrir = <int>[];
  final incompletos = <String, List<int>>{};

  for (final linea in archivo.readAsLinesSync()) {
    if (linea.startsWith('SF:')) {
      archivoActual = linea.substring(3);
      sinCubrir = [];
    } else if (linea.startsWith('DA:')) {
      final partes = linea.substring(3).split(',');
      if (int.parse(partes[1]) == 0) sinCubrir.add(int.parse(partes[0]));
    } else if (linea.startsWith('LF:')) {
      totalLineas += int.parse(linea.substring(3));
    } else if (linea.startsWith('LH:')) {
      totalCubiertas += int.parse(linea.substring(3));
    } else if (linea == 'end_of_record') {
      if (sinCubrir.isNotEmpty) incompletos[archivoActual] = sinCubrir;
    }
  }

  for (final entrada in incompletos.entries) {
    print('${entrada.key}: faltan ${entrada.value.length} lineas (${entrada.value.join(', ')})');
  }

  final porcentaje = totalLineas == 0 ? 100.0 : totalCubiertas * 100 / totalLineas;
  print('Cobertura total: ${porcentaje.toStringAsFixed(2)}% ($totalCubiertas/$totalLineas lineas)');

  if (porcentaje < minimo) {
    stderr.writeln('La cobertura ${porcentaje.toStringAsFixed(2)}% es menor que el minimo $minimo%.');
    exit(1);
  }
}
