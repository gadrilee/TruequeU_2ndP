import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';
import 'calificar_intercambio_test.dart' show completarIntercambio, mensajeCalificacion;

Future<int> totalDe(String evento) async {
  final respuesta = await pedirApi('GET', '/analitica', eudenia);
  final filas = jsonDecode(respuesta.body) as List;
  final fila = filas.firstWhere((f) => f['evento'] == evento, orElse: () => {'total': 0});
  return fila['total'] as int;
}

Future<void> esperarTotal(WidgetTester tester, String evento, int esperado) async {
  for (var i = 0; i < 50; i++) {
    if (await totalDe(evento) == esperado) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('El evento "$evento" no llegó a $esperado');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analítica de la calificación', () {
    testWidgets('Calificar registra calificacion_iniciada y calificacion_enviada', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);
      final iniciadas = await totalDe('calificacion_iniciada');
      final enviadas = await totalDe('calificacion_enviada');

      await iniciarSesion(tester, eudenia);
      await abrirOfertas(tester);
      await esperarTexto(tester, 'Todavía no calificas a Carlos Mamani');
      await tocarBoton(tester, 'Calificar');
      await esperarTotal(tester, 'calificacion_iniciada', iniciadas + 1);
      expect(await totalDe('calificacion_enviada'), enviadas);

      await tocar(tester, find.byKey(const ValueKey('estrella-3')));
      await tocarBoton(tester, 'Enviar calificación');
      await esperarTexto(tester, mensajeCalificacion);

      await esperarTotal(tester, 'calificacion_enviada', enviadas + 1);
      expect(await totalDe('calificacion_iniciada'), iniciadas + 1);
    });

    testWidgets('Cerrar el diálogo sin enviar solo registra calificacion_iniciada', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);
      final iniciadas = await totalDe('calificacion_iniciada');
      final enviadas = await totalDe('calificacion_enviada');

      await iniciarSesion(tester, eudenia);
      await abrirOfertas(tester);
      await esperarTexto(tester, 'Todavía no calificas a Carlos Mamani');
      await tocarBoton(tester, 'Calificar');
      await tocarBoton(tester, 'Volver');

      await esperarTotal(tester, 'calificacion_iniciada', iniciadas + 1);
      expect(await totalDe('calificacion_enviada'), enviadas);
      expect(find.text('Calificar'), findsOneWidget);
    });
  });
}
