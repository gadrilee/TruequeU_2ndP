import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

const ana = ['ana.quispe@ejemplo.com', 'ana12345'];
const beto = ['beto.rojas@ejemplo.com', 'beto12345'];

Future<void> prepararOfertaDeBeto() async {
  await crearCuentaPorApi('Ana Quispe', ana[0], ana[1], '71234567');
  await crearCuentaPorApi('Beto Rojas', beto[0], beto[1], '76543210');
  final bicicleta = await pedirApi('POST', '/publicaciones', ana, {
    'titulo': 'Bicicleta de Ana',
    'estado': 'usado',
  });
  final guitarra = await pedirApi('POST', '/publicaciones', beto, {
    'titulo': 'Guitarra de Beto',
    'estado': 'usado',
  });
  final idBicicleta = jsonDecode(bicicleta.body)['id'] as int;
  final idGuitarra = jsonDecode(guitarra.body)['id'] as int;
  final oferta = await pedirApi('POST', '/ofertas', beto, {
    'id_publicacion_pedida': idBicicleta,
    'id_publicacion_ofrecida': idGuitarra,
  });
  expect(oferta.statusCode, 201);
}

Future<void> aceptarOfertaDeBetoPorApi() async {
  final ofertas = await pedirApi('GET', '/ofertas/enviadas', beto);
  final idOferta = (jsonDecode(ofertas.body) as List).first['id'];
  final aceptada = await pedirApi('PUT', '/ofertas/$idOferta/aceptada', ana);
  expect(aceptada.statusCode, 200);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Contacto por WhatsApp', () {
    testWidgets('Ana todavía no ve el botón de WhatsApp mientras la oferta de Beto está pendiente', (tester) async {
      await abrirApp(tester);
      await prepararOfertaDeBeto();

      await iniciarSesion(tester, ana);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Bicicleta de Ana');

      expect(find.text('Escribir por WhatsApp'), findsNothing);
    });

    testWidgets('Ana acepta la oferta y escribe por WhatsApp al teléfono de Beto', (tester) async {
      final lanzador = usarLanzadorFalso();
      await abrirApp(tester);
      await prepararOfertaDeBeto();

      await iniciarSesion(tester, ana);
      await abrirOfertas(tester);
      await tocar(tester, enTarjeta('De: Beto Rojas', find.text('Aceptar')));
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, mensajeAceptar);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Escribir por WhatsApp');
      await tocar(tester, find.text('Escribir por WhatsApp'));

      expect(lanzador.enlaces, ['https://wa.me/59176543210']);
    });

    testWidgets('Beto también ve el botón y escribe por WhatsApp al teléfono de Ana', (tester) async {
      final lanzador = usarLanzadorFalso();
      await abrirApp(tester);
      await prepararOfertaDeBeto();
      await aceptarOfertaDeBetoPorApi();

      await iniciarSesion(tester, beto);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Escribir por WhatsApp');
      await tocar(tester, find.text('Escribir por WhatsApp'));

      expect(lanzador.enlaces, ['https://wa.me/59171234567']);
    });

    testWidgets('Carlos no recibe los teléfonos de un trueque acordado entre otras dos personas', (tester) async {
      await abrirApp(tester);
      await prepararOfertaDeBeto();
      await aceptarOfertaDeBetoPorApi();

      final feed = await pedirApi('GET', '/publicaciones', carlos);

      final acordadas = (jsonDecode(feed.body) as List).where((p) => p['estado_publicacion'] == 'acordado');
      expect(acordadas, hasLength(2));
      for (final publicacion in acordadas) {
        expect(publicacion['id_usuario_reserva'], isNull);
        expect(publicacion['usuario_reserva'], isNull);
        expect(publicacion['autor'].containsKey('telefono'), isFalse);
      }
    });
  });
}
