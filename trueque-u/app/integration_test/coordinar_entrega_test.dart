import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

String _dos(int numero) => numero.toString().padLeft(2, '0');

String fechaEscrita(int dias) {
  final fecha = DateTime.now().add(Duration(days: dias));
  return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';
}

String fechaIso(int dias) {
  final fecha = DateTime.now().add(Duration(days: dias));
  return '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';
}

const mensajePropuesta = 'Propuesta enviada. La otra persona puede aceptarla o contraproponer';
const mensajeContrapropuesta = 'Contrapropuesta enviada. La otra persona puede aceptarla o contraproponer';
const mensajeAcuerdo = 'Aceptaste la propuesta. Ya tienen fecha y lugar para la entrega';
const mensajeCambio = 'Propuesta de reprogramación enviada. Mientras no la acepten, sigue el acuerdo anterior';
const mensajeCambioAceptado = 'Aceptaste la reprogramación. Esa es ahora la fecha y el lugar de la entrega';
const pendienteExistente = 'Ya hay una propuesta esperando respuesta. Respóndela antes de hacer otra';

Future<void> llenarEntrega(WidgetTester tester, String fecha, String hora, String lugar) async {
  await escribir(tester, 'Fecha (dd/mm/aaaa)', fecha);
  await escribir(tester, 'Hora (hh:mm)', hora);
  await escribir(tester, 'Lugar', lugar);
}

Future<void> enviarEntrega(
  WidgetTester tester, {
  required String abre,
  required String envia,
  required String fecha,
  required String hora,
  required String lugar,
  required String mensaje,
}) async {
  await tocarBoton(tester, abre);
  await llenarEntrega(tester, fecha, hora, lugar);
  await tocarBoton(tester, envia);
  await esperarTexto(tester, mensaje);
}

Future<void> verEnviadas(WidgetTester tester) async {
  await abrirOfertas(tester);
  await tocar(tester, find.text('Enviadas'));
}

Map<String, dynamic> datosApi(int dias, String lugar, {int oferta = 1, String hora = '15:00'}) {
  return {'id_oferta': oferta, 'fecha': fechaIso(dias), 'hora': hora, 'lugar': lugar};
}

Future<int> proponerPorApi(List<String> persona, Map<String, dynamic> datos) async {
  final respuesta = await pedirApi('POST', '/propuestas-entrega', persona, datos);
  expect(respuesta.statusCode, 201);
  return jsonDecode(respuesta.body)['propuesta']['id'] as int;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Coordinar la entrega de un intercambio acordado', () {
    testWidgets('propuesta, contrapropuesta, aceptación y una reprogramación aceptada', (tester) async {
      final primera = fechaEscrita(3);
      final segunda = fechaEscrita(4);
      final tercera = fechaEscrita(7);

      await abrirAppConSesion(tester, eudenia);
      await aceptarOfertaDeCarlos(tester);
      expect(find.text('Todavía no acordaron fecha ni lugar'), findsOneWidget);

      await enviarEntrega(
        tester,
        abre: 'Proponer fecha y lugar',
        envia: 'Enviar propuesta',
        fecha: primera,
        hora: '15:00',
        lugar: 'Biblioteca central',
        mensaje: mensajePropuesta,
      );
      expect(
        find.text('Tu propuesta espera respuesta: $primera a las 15:00 en Biblioteca central'),
        findsOneWidget,
      );
      expect(find.text('Aceptar propuesta'), findsNothing);
      expect(find.text('Proponer fecha y lugar'), findsNothing);

      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, carlos);
      await verEnviadas(tester);
      expect(
        find.text('Eudenia Flores Veizaga propone: $primera a las 15:00 en Biblioteca central'),
        findsOneWidget,
      );

      await enviarEntrega(
        tester,
        abre: 'Contraproponer',
        envia: 'Enviar contrapropuesta',
        fecha: segunda,
        hora: '10:30',
        lugar: 'Cafetería',
        mensaje: mensajeContrapropuesta,
      );
      expect(find.text('Tu propuesta espera respuesta: $segunda a las 10:30 en Cafetería'), findsOneWidget);

      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, eudenia);
      await abrirOfertas(tester);
      expect(find.text('Carlos Mamani propone: $segunda a las 10:30 en Cafetería'), findsOneWidget);

      await tocarBoton(tester, 'Aceptar propuesta');
      await esperarTexto(tester, mensajeAcuerdo);
      expect(find.text('Acordado: $segunda a las 10:30 en Cafetería'), findsOneWidget);

      await recargarApp(tester);
      await irARuta(tester, '/ofertas');
      expect(find.text('Acordado: $segunda a las 10:30 en Cafetería'), findsOneWidget);

      await enviarEntrega(
        tester,
        abre: 'Reprogramar',
        envia: 'Enviar reprogramación',
        fecha: tercera,
        hora: '16:00',
        lugar: 'Portería',
        mensaje: mensajeCambio,
      );
      expect(find.text('Acordado: $segunda a las 10:30 en Cafetería'), findsOneWidget);
      expect(find.text('Tu cambio espera respuesta: $tercera a las 16:00 en Portería'), findsOneWidget);
      expect(find.text('Mientras tanto sigue vigente el acuerdo anterior.'), findsOneWidget);
      expect(find.text('Reprogramar'), findsNothing);

      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, carlos);
      await verEnviadas(tester);
      expect(
        find.text('Eudenia Flores Veizaga propone cambiar a: $tercera a las 16:00 en Portería'),
        findsOneWidget,
      );
      expect(find.text('Acordado: $segunda a las 10:30 en Cafetería'), findsOneWidget);

      await tocarBoton(tester, 'Aceptar propuesta');
      await esperarTexto(tester, mensajeCambioAceptado);
      expect(find.text('Acordado: $tercera a las 16:00 en Portería'), findsOneWidget);
      expect(find.text('Aceptar propuesta'), findsNothing);

      await recargarApp(tester);
      await irARuta(tester, '/ofertas');
      await tocar(tester, find.text('Enviadas'));
      expect(find.text('Acordado: $tercera a las 16:00 en Portería'), findsOneWidget);

      await tocarBoton(tester, 'Historial de entrega');
      expect(find.text('Se respondió con otra propuesta'), findsOneWidget);
      expect(find.text('Reemplazada por una reprogramación'), findsOneWidget);
      expect(find.text('Acuerdo vigente'), findsOneWidget);
      expect(
        find.text('Eudenia Flores Veizaga propone: $primera a las 15:00 en Biblioteca central'),
        findsOneWidget,
      );
      expect(find.text('Carlos Mamani propone: $segunda a las 10:30 en Cafetería'), findsOneWidget);
    });
  });

  group('Restricciones de la coordinación de la entrega', () {
    testWidgets('Solo las dos partes participan y nadie responde su propia propuesta', (tester) async {
      await abrirApp(tester);
      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);
      final id = await proponerPorApi(eudenia, datosApi(3, 'Biblioteca'));

      expect((await pedirApi('GET', '/propuestas-entrega?id_oferta=1', job)).statusCode, 403);
      expect((await pedirApi('POST', '/propuestas-entrega', job, datosApi(4, 'Cafetería'))).statusCode, 403);
      expect((await pedirApi('PUT', '/propuestas-entrega/$id/aceptada', job)).statusCode, 403);
      final contraTercero = await pedirApi(
        'POST',
        '/propuestas-entrega/$id/contrapropuesta',
        job,
        datosApi(4, 'Cafetería'),
      );
      expect(contraTercero.statusCode, 403);

      final propia = await pedirApi('PUT', '/propuestas-entrega/$id/aceptada', eudenia);
      expect(propia.statusCode, 403);
      expect(jsonDecode(propia.body)['error'], 'Tu propuesta espera la respuesta de la otra persona');
    });

    testWidgets('Solo hay una propuesta pendiente y el acuerdo vigente no cambia hasta aceptar', (tester) async {
      await abrirApp(tester);
      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);
      final primera = await proponerPorApi(eudenia, datosApi(3, 'Biblioteca'));

      final repetida = await pedirApi('POST', '/propuestas-entrega', eudenia, datosApi(4, 'Cafetería'));
      expect(repetida.statusCode, 409);
      expect(jsonDecode(repetida.body)['error'], pendienteExistente);
      final deLaOtra = await pedirApi('POST', '/propuestas-entrega', carlos, datosApi(4, 'Cafetería'));
      expect(deLaOtra.statusCode, 409);

      expect((await pedirApi('PUT', '/propuestas-entrega/$primera/aceptada', carlos)).statusCode, 200);
      final cambio = await proponerPorApi(eudenia, datosApi(5, 'Portería'));

      final antes = jsonDecode((await pedirApi('GET', '/propuestas-entrega?id_oferta=1', carlos)).body);
      expect(antes['vigente']['id'], primera);
      expect(antes['pendiente']['id'], cambio);

      final igual = await pedirApi('POST', '/propuestas-entrega', carlos, datosApi(3, 'Biblioteca'));
      expect(igual.statusCode, 409);

      expect((await pedirApi('PUT', '/propuestas-entrega/$cambio/aceptada', carlos)).statusCode, 200);
      final despues = jsonDecode((await pedirApi('GET', '/propuestas-entrega?id_oferta=1', carlos)).body);
      expect(despues['vigente']['id'], cambio);
      expect(despues['pendiente'], isNull);
      final estados = (despues['propuestas'] as List).map((p) => p['estado']).toList();
      expect(estados, ['reemplazada', 'aceptada']);
    });

    testWidgets('No se coordina antes de aceptar la oferta ni después de terminar el intercambio', (tester) async {
      await abrirApp(tester);

      final sinAceptar = await pedirApi('POST', '/propuestas-entrega', eudenia, datosApi(3, 'Biblioteca'));
      expect(sinAceptar.statusCode, 409);

      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);
      final id = await proponerPorApi(eudenia, datosApi(3, 'Biblioteca'));
      await pedirApi('PUT', '/ofertas/1/entrega', eudenia);
      await pedirApi('PUT', '/ofertas/1/entrega', carlos);

      expect((await pedirApi('PUT', '/propuestas-entrega/$id/aceptada', carlos)).statusCode, 409);
      expect((await pedirApi('POST', '/propuestas-entrega', eudenia, datosApi(4, 'Cafetería'))).statusCode, 409);
    });

    testWidgets('Datos incompletos o una fecha pasada no se envían', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await aceptarOfertaDeCarlos(tester);

      await tocarBoton(tester, 'Proponer fecha y lugar');
      await tocarBoton(tester, 'Enviar propuesta');
      expect(find.text('Escribe una fecha válida, por ejemplo 15/06/2030'), findsOneWidget);
      expect(find.text('Escribe una hora válida, por ejemplo 15:30'), findsOneWidget);
      expect(find.text('Escribe el lugar de la entrega'), findsOneWidget);

      await llenarEntrega(tester, '01/01/2020', '10:00', 'Biblioteca');
      await tocarBoton(tester, 'Enviar propuesta');
      expect(find.text('La fecha ya pasó, elige otra'), findsOneWidget);

      await tocarBoton(tester, 'Volver');
      expect(find.text('Todavía no acordaron fecha ni lugar'), findsOneWidget);

      final lista = jsonDecode((await pedirApi('GET', '/propuestas-entrega?id_oferta=1', eudenia)).body);
      expect(lista['propuestas'], isEmpty);

      final pasada = await pedirApi('POST', '/propuestas-entrega', eudenia, {
        'id_oferta': 1,
        'fecha': '2020-01-01',
        'hora': '10:00',
        'lugar': 'Biblioteca',
      });
      expect(pasada.statusCode, 400);
    });
  });
}
