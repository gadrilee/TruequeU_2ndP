import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

Future<void> aceptarOfertaDeCarlos(WidgetTester tester) async {
  await abrirOfertas(tester);
  await tocar(tester, enTarjeta('De: Carlos Mamani', find.text('Aceptar')));
  await tocarBoton(tester, 'Aceptar');
  await esperarTexto(tester, mensajeAceptar);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Confirmar la entrega', () {
    testWidgets('Eudenia confirma primero y el intercambio todavía no se completa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await aceptarOfertaDeCarlos(tester);

      expect(find.text('Tu entrega: pendiente'), findsOneWidget);
      expect(find.text('La otra persona: pendiente'), findsOneWidget);

      await confirmarEntrega(tester, mensajePrimeraConfirmacion);

      expect(find.text('Tu entrega: confirmada'), findsOneWidget);
      expect(find.text('La otra persona: pendiente'), findsOneWidget);
      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar entrega'));
      expect(boton.onPressed, isNull);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Aún no tienes intercambios completados');
    });

    testWidgets('Carlos confirma después y el intercambio queda completado', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await aceptarOfertaDeCarlos(tester);
      await confirmarEntrega(tester, mensajePrimeraConfirmacion);
      await irARuta(tester, '/perfil');

      await cambiarDeUsuario(tester, carlos);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));

      expect(find.text('La otra persona: confirmada'), findsOneWidget);

      await confirmarEntrega(tester, mensajeCompletado);

      expect(find.text('Intercambio completado'), findsOneWidget);
      expect(find.text('Confirmar entrega'), findsNothing);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Mouse inalambrico');

      expect(find.text('Lo entregaste a: Eudenia Flores Veizaga'), findsOneWidget);
    });
  });

  group('Cancelar un intercambio acordado', () {
    testWidgets('Eudenia cancela con motivo y su libro vuelve a estar disponible', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      final ofertaDeJob = await pedirApi('POST', '/ofertas', job, {
        'id_publicacion_pedida': 1,
        'id_publicacion_ofrecida': 4,
      });
      expect(ofertaDeJob.statusCode, 201);

      await aceptarOfertaDeCarlos(tester);
      await tocarBoton(tester, 'Cancelar intercambio');
      expect(find.text('Sí, cancelar'), findsOneWidget);
      await escribir(tester, 'Motivo', 'No pude ir a la entrega');
      await tocarBoton(tester, 'Sí, cancelar');
      await esperarTexto(
        tester,
        'Cancelaste el intercambio. Las dos publicaciones vuelven a estar disponibles',
      );

      expect(find.text('Intercambio cancelado'), findsOneWidget);
      expect(find.text('Motivo: No pude ir a la entrega'), findsOneWidget);

      await tocarBoton(tester, 'Volver al perfil');
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Calculo');

      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('Cancelar no reactiva las ofertas anteriores y conserva el historial', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await pedirApi('POST', '/ofertas', job, {
        'id_publicacion_pedida': 1,
        'id_publicacion_ofrecida': 4,
      });
      await aceptarOfertaDeCarlos(tester);

      final cancelar = await pedirApi('PUT', '/ofertas/1/anulada', carlos, {'motivo': 'Cambié de idea'});
      expect(cancelar.statusCode, 200);

      final enviadasDeJob = await pedirApi('GET', '/ofertas/enviadas', job);
      final ofertaJob = (jsonDecode(enviadasDeJob.body) as List).first;
      expect(ofertaJob['estado'], 'cancelada');

      final historial = await pedirApi('GET', '/ofertas/1/historial', eudenia);
      final propuestas = jsonDecode(historial.body)['propuestas'] as List;
      expect(propuestas.single['estado'], 'anulada');
      expect(propuestas.single['motivo_cancelacion'], 'Cambié de idea');
    });

    testWidgets('Cancelar sin escribir el motivo no deja enviar', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await aceptarOfertaDeCarlos(tester);

      await tocarBoton(tester, 'Cancelar intercambio');

      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Sí, cancelar'));
      expect(boton.onPressed, isNull);

      await tocarBoton(tester, 'Volver');

      expect(find.text('Intercambio cancelado'), findsNothing);
    });
  });

  group('Reglas del intercambio acordado por la API', () {
    testWidgets('Solo participan las dos partes y cada una confirma una vez', (tester) async {
      await abrirApp(tester);
      expect((await pedirApi('PUT', '/ofertas/1/aceptada', eudenia)).statusCode, 200);

      final tercero = await pedirApi('PUT', '/ofertas/1/entrega', job);
      expect(tercero.statusCode, 403);

      expect((await pedirApi('PUT', '/ofertas/1/entrega', eudenia)).statusCode, 200);
      final repetida = await pedirApi('PUT', '/ofertas/1/entrega', eudenia);
      expect(repetida.statusCode, 409);
      expect(jsonDecode(repetida.body)['error'], 'Ya confirmaste tu entrega');
    });

    testWidgets('Cancelar exige motivo y después ya no se puede confirmar', (tester) async {
      await abrirApp(tester);
      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);
      await pedirApi('PUT', '/ofertas/1/entrega', eudenia);

      final sinMotivo = await pedirApi('PUT', '/ofertas/1/anulada', carlos, {});
      expect(sinMotivo.statusCode, 400);

      final tercero = await pedirApi('PUT', '/ofertas/1/anulada', job, {'motivo': 'Quiero cancelar'});
      expect(tercero.statusCode, 403);

      expect((await pedirApi('PUT', '/ofertas/1/anulada', carlos, {'motivo': 'No puedo ir'})).statusCode, 200);

      final confirmar = await pedirApi('PUT', '/ofertas/1/entrega', carlos);
      expect(confirmar.statusCode, 409);
    });

    testWidgets('Una publicación acordada no se reserva ni se edita', (tester) async {
      await abrirApp(tester);
      await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);

      final reservar = await pedirApi('PUT', '/publicaciones/1/reservado', job);
      expect(reservar.statusCode, 409);

      final editar = await pedirApi('PUT', '/publicaciones/1', eudenia, {'titulo': 'Otro título'});
      expect(editar.statusCode, 409);
      expect(
        jsonDecode(editar.body)['error'],
        'No puedes editar una publicación con un intercambio acordado',
      );
    });
  });
}
