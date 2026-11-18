import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/widgets/bloque_calificacion.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

Future<void> montarBloque(WidgetTester tester, ControladorAutenticacion controlador) async {
  usarPantallaGrande(tester);
  await montarWidget(
    tester,
    Scaffold(body: BloqueCalificacion(idOferta: 3, nombreOtra: 'Beto')),
    controlador: controlador,
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> miCalificacion(int puntaje, [String? comentario]) {
  return {
    'mia': {'puntaje': puntaje, 'comentario': comentario},
  };
}

void main() {
  setUp(cargarEntornoDePrueba);

  testWidgets('con una calificacion hecha la muestra con sus estrellas y comentario', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/calificaciones': (_) => respuestaJson(miCalificacion(4, 'Muy amable')),
    });

    await montarBloque(tester, controlador);

    expect(find.text('Calificaste a Beto: 4 de 5'), findsOneWidget);
    expect(find.text('"Muy amable"'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });

  testWidgets('sin comentario no muestra comillas', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/calificaciones': (_) => respuestaJson(miCalificacion(5)),
    });

    await montarBloque(tester, controlador);

    expect(find.text('Calificaste a Beto: 5 de 5'), findsOneWidget);
    expect(find.textContaining('"'), findsNothing);
  });

  testWidgets('un error del servidor se muestra en el bloque', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/calificaciones': (_) => respuestaJson({'error': 'Sin servicio'}, 503),
    });

    await montarBloque(tester, controlador);

    expect(find.text('Sin servicio'), findsOneWidget);
  });

  group('sin calificar', () {
    Map<String, ManejadorRuta> rutas({List<http.Request>? cuerpos, bool falla = false}) {
      var calificada = false;
      return {
        'GET /api/calificaciones': (_) =>
            respuestaJson(calificada ? miCalificacion(5, 'Genial') : {'mia': null}),
        'POST /api/calificaciones': (peticion) {
          cuerpos?.add(peticion);
          if (falla) return respuestaJson({'error': 'Ya calificaste'}, 409);
          calificada = true;
          return respuestaJson({'mensaje': 'Gracias por calificar'});
        },
      };
    }

    testWidgets('ofrece calificar a la otra persona', (tester) async {
      final controlador = await controladorConSesion(rutas());

      await montarBloque(tester, controlador);

      expect(find.text('Todavía no calificas a Beto'), findsOneWidget);
    });

    testWidgets('calificar envia el puntaje y muestra el resultado', (tester) async {
      final cuerpos = <http.Request>[];
      final controlador = await controladorConSesion(rutas(cuerpos: cuerpos));
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Calificar'));
      await tocar(tester, find.byKey(ValueKey('estrella-5')));
      await tester.enterText(find.byType(TextFormField), 'Genial');
      await confirmar(tester, 'Enviar calificación');

      expect(cuerpos.single.body, contains('"puntaje":5'));
      expect(cuerpos.single.body, contains('"comentario":"Genial"'));
      expect(find.text('Gracias por calificar'), findsOneWidget);
      expect(find.text('Calificaste a Beto: 5 de 5'), findsOneWidget);
    });

    testWidgets('volver del dialogo no envia nada', (tester) async {
      final cuerpos = <http.Request>[];
      final controlador = await controladorConSesion(rutas(cuerpos: cuerpos));
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Calificar'));
      await tocar(tester, find.text('Volver'));

      expect(cuerpos, isEmpty);
      expect(find.text('Todavía no calificas a Beto'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la calificacion muestra el aviso', (tester) async {
      final controlador = await controladorConSesion(rutas(falla: true));
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Calificar'));
      await tocar(tester, find.byKey(ValueKey('estrella-2')));
      await confirmar(tester, 'Enviar calificación');

      expect(find.text('Ya calificaste'), findsOneWidget);
      expect(find.text('Calificar'), findsOneWidget);
    });
  });
}
