import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';

import 'ayudantes/pares_contraste.dart';

void main() {
  test('la razon de contraste coincide con valores conocidos de WCAG', () {
    expect(razonContraste(Colors.black, Colors.white), closeTo(21, 0.001));
    expect(razonContraste(Colors.white, Colors.white), closeTo(1, 0.001));
    expect(razonContraste(const Color(0xFF777777), Colors.white), closeTo(4.48, 0.01));
  });

  for (final par in paresContraste) {
    test('${par.nombre} (${par.donde}) cumple ${par.minimo}:1', () {
      expect(par.razon, greaterThanOrEqualTo(par.minimo));
    });
  }

  for (final par in paresDelEsquema(TemaTruequeU.claro().colorScheme)) {
    test('esquema ${par.nombre} cumple 4.5:1', () {
      expect(par.razon, greaterThanOrEqualTo(4.5));
    });
  }

  test('los bordes de los controles usan el color que cumple 3:1', () {
    final tema = TemaTruequeU.claro();
    final campo = tema.inputDecorationTheme;
    final borde = (campo.enabledBorder as OutlineInputBorder).borderSide.color;
    final contorno = tema.outlinedButtonTheme.style!.side!.resolve({})!.color;

    expect(borde, TemaTruequeU.contorno);
    expect(contorno, TemaTruequeU.contorno);
    expect(razonContraste(borde, campo.fillColor!), greaterThanOrEqualTo(3));
    expect(razonContraste(contorno, tema.scaffoldBackgroundColor), greaterThanOrEqualTo(3));
  });

  test('los pares que antes fallaban ahora cumplen y se conoce su razon anterior', () {
    final cambiados = paresContraste.where((p) => p.primerPlanoAntes != null);

    expect(cambiados, isNotEmpty);
    for (final par in cambiados) {
      expect(par.razonAntes!, lessThan(par.minimo));
      expect(par.razon, greaterThanOrEqualTo(par.minimo));
    }
  });
}
