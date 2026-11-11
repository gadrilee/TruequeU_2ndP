import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

const mensajeCalificacion = 'Calificación enviada. Gracias por tu opinión';
const errorRepetida = 'Ya calificaste este intercambio';
const errorCancelado = 'Un intercambio cancelado no se puede calificar';
const errorSinCompletar = 'Solo se puede calificar un intercambio completado';

Future<void> completarIntercambio(int idOferta, List<String> receptor, List<String> oferente) async {
  expect((await pedirApi('PUT', '/ofertas/$idOferta/aceptada', receptor)).statusCode, 200);
  expect((await pedirApi('PUT', '/ofertas/$idOferta/entrega', receptor)).statusCode, 200);
  expect((await pedirApi('PUT', '/ofertas/$idOferta/entrega', oferente)).statusCode, 200);
}

Future<int> calificar(List<String> persona, int idOferta, Object? puntaje, [Object? comentario]) async {
  final respuesta = await pedirApi('POST', '/calificaciones', persona, {
    'id_oferta': idOferta,
    'puntaje': puntaje,
    if (comentario != null) 'comentario': comentario,
  });
  return respuesta.statusCode;
}

Future<Map<String, dynamic>> resumenDe(List<String> persona, int idUsuario) async {
  final respuesta = await pedirApi('GET', '/calificaciones/resumen?id_usuario=$idUsuario', persona);
  return jsonDecode(respuesta.body) as Map<String, dynamic>;
}

Future<String> errorDe(List<String> persona, int idOferta, Object? puntaje) async {
  final respuesta = await pedirApi('POST', '/calificaciones', persona, {
    'id_oferta': idOferta,
    'puntaje': puntaje,
  });
  return jsonDecode(respuesta.body)['error'] as String;
}

Future<void> calificarConEstrellas(WidgetTester tester, int estrellas, {String? comentario}) async {
  await tocarBoton(tester, 'Calificar');
  await tocar(tester, find.byKey(ValueKey('estrella-$estrellas')));
  if (comentario != null) await escribir(tester, 'Comentario (opcional)', comentario);
  await tocarBoton(tester, 'Enviar calificación');
  await esperarTexto(tester, mensajeCalificacion);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Calificar un intercambio completado', () {
    testWidgets('Ambas partes califican con estrellas y el perfil muestra el promedio y la cantidad', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);
      await iniciarSesion(tester, eudenia);

      await abrirOfertas(tester);
      await esperarTexto(tester, 'Todavía no calificas a Carlos Mamani');
      await calificarConEstrellas(tester, 4, comentario: 'Llegó puntual');
      expect(find.text('Calificaste a Carlos Mamani: 4 de 5'), findsOneWidget);
      expect(find.text('"Llegó puntual"'), findsOneWidget);
      expect(find.text('Calificar'), findsNothing);

      await irARuta(tester, '/perfil');
      await esperarTexto(tester, 'Aún no tienes calificaciones');

      await cambiarDeUsuario(tester, carlos);
      await esperarTexto(tester, '4.0 de 5 · 1 calificación');
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));
      await esperarTexto(tester, 'Todavía no calificas a Eudenia Flores Veizaga');
      await calificarConEstrellas(tester, 5);
      expect(find.text('Calificaste a Eudenia Flores Veizaga: 5 de 5'), findsOneWidget);

      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, eudenia);
      await esperarTexto(tester, '5.0 de 5 · 1 calificación');

      await recargarApp(tester);
      await irARuta(tester, '/ofertas');
      await esperarTexto(tester, 'Calificaste a Carlos Mamani: 4 de 5');
    });

    testWidgets('El perfil promedia todas las calificaciones que recibe', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);
      final nueva = await pedirApi('POST', '/ofertas', job, {
        'id_publicacion_pedida': 3,
        'id_publicacion_ofrecida': 6,
      });
      expect(nueva.statusCode, 201);
      final idSegunda = jsonDecode(nueva.body)['oferta']['id'] as int;
      await completarIntercambio(idSegunda, eudenia, job);

      expect(await calificar(carlos, 1, 5), 201);
      expect(await calificar(job, idSegunda, 4, 'Todo bien'), 201);

      final resumen = await resumenDe(eudenia, 1);
      expect(resumen['cantidad'], 2);
      expect(resumen['promedio'], 4.5);

      await iniciarSesion(tester, eudenia);
      await esperarTexto(tester, '4.5 de 5 · 2 calificaciones');
    });
  });

  group('Reglas de la calificación por la API', () {
    testWidgets('Cada parte califica una sola vez y la segunda calificación se rechaza', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);

      expect(await calificar(eudenia, 1, 5), 201);
      expect(await calificar(eudenia, 1, 1, 'Cambié de opinión'), 409);
      expect(await errorDe(eudenia, 1, 2), errorRepetida);

      final mia = jsonDecode((await pedirApi('GET', '/calificaciones?id_oferta=1', eudenia)).body)['mia'];
      expect(mia['puntaje'], 5);

      final deCarlos = await resumenDe(carlos, 3);
      expect(deCarlos['cantidad'], 1);
      expect(deCarlos['promedio'], 5);

      expect(await calificar(carlos, 1, 3), 201);
      expect(await errorDe(carlos, 1, 1), errorRepetida);
      expect((await resumenDe(eudenia, 1))['promedio'], 3);
    });

    testWidgets('Un intercambio cancelado o sin completar no se califica', (tester) async {
      await abrirApp(tester);

      expect(await calificar(eudenia, 1, 5), 409);
      expect(await errorDe(eudenia, 1, 5), errorSinCompletar);

      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);
      expect(await errorDe(carlos, 1, 5), errorSinCompletar);

      await pedirApi('PUT', '/ofertas/1/anulada', carlos, {'motivo': 'No pude ir'});
      expect(await calificar(eudenia, 1, 5), 409);
      expect(await errorDe(eudenia, 1, 5), errorCancelado);
      expect(await calificar(carlos, 1, 5), 409);
      expect(await errorDe(carlos, 1, 5), errorCancelado);

      expect((await resumenDe(eudenia, 1))['cantidad'], 0);
      expect((await resumenDe(carlos, 3))['cantidad'], 0);

      await iniciarSesion(tester, eudenia);
      await abrirOfertas(tester);
      expect(find.text('Intercambio cancelado'), findsOneWidget);
      expect(find.text('Calificar'), findsNothing);
      expect(find.text('Calificación'), findsNothing);
    });

    testWidgets('Solo las dos partes califican y el puntaje es de 1 a 5', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);

      expect(await calificar(job, 1, 5), 403);
      expect(await errorDe(job, 1, 5), 'Solo quienes participan en el intercambio pueden calificarlo');

      for (final puntaje in [0, 6, 3.5, '4', null]) {
        expect(await calificar(eudenia, 1, puntaje), 400);
      }
      expect(await calificar(eudenia, 1, 5, 'a' * 201), 400);

      expect((await resumenDe(carlos, 3))['cantidad'], 0);
      expect(await calificar(eudenia, 1, 5, 'a' * 200), 201);
    });
  });
}
