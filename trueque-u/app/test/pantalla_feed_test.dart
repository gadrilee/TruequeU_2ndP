// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_feed_publicaciones.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

Future<void> montarFeed(
  WidgetTester tester,
  ControladorAutenticacion controlador, {
  double ancho = 900,
}) {
  return montarPantallaEnRuta(tester, PantallaFeedPublicaciones(), controlador, ancho: ancho);
}

Map<String, ManejadorRuta> feedCon(List<Map<String, dynamic>> lista) {
  return {'GET /api/publicaciones': (_) => respuestaJson(lista)};
}

void main() {
  setUp(cargarEntornoDePrueba);

  group('carga del feed', () {
    testWidgets('muestra el saludo y las tarjetas', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1), publicacion(2)]));

      await montarFeed(tester, controlador);

      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('Objeto 1'), findsOneWidget);
      expect(find.text('Objeto 2'), findsOneWidget);
    });

    testWidgets('muestra un indicador mientras espera al servidor', (tester) async {
      final espera = Completer<void>();
      final cliente = MockClient((peticion) async {
        if (peticion.url.path == '/api/sesiones') return sesionAna(peticion);
        await espera.future;
        return respuestaJson([publicacion(1)]);
      });
      final controlador = await crearControlador(cliente);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');
      usarAncho(tester, 900);
      await montarWidget(tester, PantallaFeedPublicaciones(), controlador: controlador);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      espera.complete();
      await tester.pumpAndSettle();

      expect(find.text('Objeto 1'), findsOneWidget);
    });

    testWidgets('usa tres columnas en pantallas muy anchas', (tester) async {
      final controlador = await controladorConSesion(feedCon([
        publicacion(1, estadoPublicacion: 'intercambiado'),
        publicacion(2, estadoPublicacion: 'intercambiado'),
      ]));

      await montarFeed(tester, controlador, ancho: 901);

      expect(find.text('Objeto 2'), findsOneWidget);
    });

    testWidgets('usa una columna en pantallas angostas', (tester) async {
      final controlador = await controladorConSesion(feedCon([
        publicacion(1, estadoPublicacion: 'intercambiado'),
      ]));

      await montarFeed(tester, controlador, ancho: 320);

      expect(find.text('Objeto 1'), findsOneWidget);
    });

    testWidgets('usa valores por defecto si faltan datos', (tester) async {
      final controlador = await controladorConSesion(feedCon([
        {'id': 9},
      ]));

      await montarFeed(tester, controlador);

      expect(find.text('Sin título'), findsOneWidget);
      expect(find.text('Por: Usuario'), findsOneWidget);
      expect(find.text('Sin descripción detallada'), findsOneWidget);
    });

    testWidgets('sin sesion ninguna tarjeta es mia', (tester) async {
      final controlador = await crearControlador(clienteRuteado(feedCon([publicacion(1)])));

      await montarFeed(tester, controlador);

      expect(find.text('Hola, '), findsOneWidget);
      expect(find.text('Por: Beto'), findsOneWidget);
    });

    testWidgets('el boton actualizar vuelve a pedir el feed', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([publicacion(1)]), registro: registro);
      await montarFeed(tester, controlador);
      final antes = registro.where((p) => p.url.path == '/api/publicaciones').length;

      await tocar(tester, find.byTooltip('Actualizar feed'));

      final despues = registro.where((p) => p.url.path == '/api/publicaciones').length;
      expect(despues, antes + 1);
    });

    testWidgets('el boton publicar lleva al formulario', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1)]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Publicar'));

      expect(find.text('Destino /publicacion'), findsOneWidget);
    });

    testWidgets('el boton de ayuda abre y cierra el dialogo', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1)]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.byTooltip('Ayuda: ¿cómo funciona?'));
      expect(find.text('¿Cómo funciona?'), findsOneWidget);

      await tocar(tester, find.text('Entendido'));
      expect(find.text('¿Cómo funciona?'), findsNothing);
    });
  });

  group('errores y estados vacios', () {
    testWidgets('si el servidor falla muestra el error y reintentar lo recupera', (tester) async {
      var intentos = 0;
      final controlador = await controladorConSesion({
        'GET /api/publicaciones': (_) {
          intentos++;
          if (intentos == 1) return respuestaJson({'error': 'Servidor caido'}, 500);
          return respuestaJson([publicacion(1)]);
        },
      });

      await montarFeed(tester, controlador);
      expect(find.text('Servidor caido'), findsOneWidget);

      await tocar(tester, find.text('Reintentar'));

      expect(find.text('Objeto 1'), findsOneWidget);
    });

    testWidgets('una respuesta rara muestra el mensaje general', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/publicaciones': (_) => respuestaJson([1]),
      });

      await montarFeed(tester, controlador);

      expect(find.text('No se pudieron cargar las publicaciones del feed'), findsOneWidget);
    });

    testWidgets('sin publicaciones invita a crear la primera', (tester) async {
      final controlador = await controladorConSesion(feedCon([]));
      await montarFeed(tester, controlador);

      expect(find.text('No hay publicaciones disponibles'), findsOneWidget);

      await tocar(tester, find.text('Crear publicación'));

      expect(find.text('Destino /publicacion'), findsOneWidget);
    });

    testWidgets('una respuesta que no es lista cuenta como feed vacio', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/publicaciones': (_) => respuestaJson({'otro': 1}),
      });

      await montarFeed(tester, controlador);

      expect(find.text('No hay publicaciones disponibles'), findsOneWidget);
    });
  });

  group('busqueda y filtros', () {
    testWidgets('buscar sin resultados permite quitar los filtros', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/publicaciones': (peticion) {
          final hayBusqueda = peticion.url.queryParameters.containsKey('buscar');
          return respuestaJson(hayBusqueda ? [] : [publicacion(1)]);
        },
      }, registro: registro);
      await montarFeed(tester, controlador);

      await tester.enterText(find.byType(TextField), 'bicicleta');
      await tocar(tester, find.byTooltip('Buscar'));

      expect(find.text('Ninguna publicación coincide con tu búsqueda'), findsOneWidget);
      expect(find.text('Título: bicicleta'), findsOneWidget);

      await tocar(tester, find.text('Quitar filtros'));

      expect(find.text('Objeto 1'), findsOneWidget);
      expect(find.text('Título: bicicleta'), findsNothing);
    });

    testWidgets('enviar el teclado tambien busca', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([publicacion(1)]), registro: registro);
      await montarFeed(tester, controlador);

      await tester.enterText(find.byType(TextField), 'libro');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final consultas = registro
          .where((p) => p.url.path == '/api/publicaciones')
          .map((p) => p.url.queryParameters['buscar']);
      expect(consultas, contains('libro'));
    });

    testWidgets('elegir y quitar cada filtro actualiza el feed', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([publicacion(1)]), registro: registro);
      await montarFeed(tester, controlador);

      await tester.enterText(find.byType(TextField), 'libro');
      await tocar(tester, find.byTooltip('Buscar'));
      await tocar(tester, find.byTooltip('Filtrar por categoría'));
      await tocar(tester, find.text('Ropa'));
      await tocar(tester, find.byTooltip('Filtrar por condición'));
      await tocar(tester, find.text('Usado'));
      await tocar(tester, find.byTooltip('Filtrar por disponibilidad'));
      await tocar(tester, find.text('Reservado'));

      final ultima = registro.where((p) => p.url.path == '/api/publicaciones').last;
      expect(ultima.url.queryParameters, {
        'buscar': 'libro',
        'categoria': 'ropa',
        'condicion': 'usado',
        'disponibilidad': 'reservado',
      });

      for (final chip in [
        'Título: libro',
        'Categoría: Ropa',
        'Condición: Usado',
        'Disponibilidad: Reservado',
      ]) {
        final borrar = find.descendant(
          of: find.widgetWithText(InputChip, chip),
          matching: find.byTooltip('Delete'),
        );
        await tocar(tester, borrar);
        expect(find.widgetWithText(InputChip, chip), findsNothing);
      }

      final ultimaConsulta = registro.where((p) => p.url.path == '/api/publicaciones').last;
      expect(ultimaConsulta.url.queryParameters, isEmpty);
    });

    testWidgets('quitar todos limpia los filtros de una vez', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1)]));
      await montarFeed(tester, controlador);
      await tocar(tester, find.byTooltip('Filtrar por categoría'));
      await tocar(tester, find.text('Libros'));
      expect(find.widgetWithText(InputChip, 'Categoría: Libros'), findsOneWidget);

      await tocar(tester, find.text('Quitar todos'));

      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('si un filtro falla se muestra el error', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/publicaciones': (peticion) {
          if (peticion.url.queryParameters.isNotEmpty) {
            return respuestaJson({'error': 'Filtro roto'}, 500);
          }
          return respuestaJson([publicacion(1)]);
        },
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.byTooltip('Filtrar por categoría'));
      await tocar(tester, find.text('Libros'));

      expect(find.text('Filtro roto'), findsOneWidget);
    });
  });

  group('botones de las tarjetas', () {
    testWidgets('ver en mis publicaciones lleva a la lista propia', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1, idUsuario: 7)]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ver en mis publicaciones'));

      expect(find.text('Destino /mis-publicaciones'), findsOneWidget);
    });

    testWidgets('ver mis ofertas lleva a las ofertas', (tester) async {
      final controlador = await controladorConSesion(feedCon([publicacion(1, ofertaEnviada: true)]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ver mis ofertas'));

      expect(find.text('Destino /ofertas'), findsOneWidget);
    });

    testWidgets('el contacto abre WhatsApp con un mensaje', (tester) async {
      final lanzador = LanzadorWhatsappFalso();
      UrlLauncherPlatform.instance = lanzador;
      final controlador = await controladorConSesion(feedCon([
        publicacion(
          1,
          estadoPublicacion: 'reservado',
          idReserva: 7,
          nombreReserva: 'Ana Perez',
          telefonoAutor: '71234567',
        ),
      ]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('WhatsApp'));

      expect(lanzador.enlaces.single, startsWith('https://wa.me/59171234567?text='));
      expect(lanzador.enlaces.single, contains(Uri.encodeComponent('reservé "Objeto 1"')));
    });
  });

  group('reservar', () {
    testWidgets('confirmar reserva la publicacion y recarga el feed', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'PUT /api/publicaciones/1/reservado': (_) => respuestaJson({}),
      }, registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Reservar'));
      expect(find.text('Reservar publicación'), findsOneWidget);
      await confirmar(tester, 'Reservar');

      expect(find.textContaining('Reservaste "Objeto 1"'), findsOneWidget);
      expect(registro.any((p) => p.method == 'PUT' && p.url.path == '/api/publicaciones/1/reservado'), isTrue);
    });

    testWidgets('cancelar la confirmacion no reserva nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([publicacion(1)]), registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Reservar'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('sin sesion no pasa nada al reservar', (tester) async {
      final controlador = await crearControlador(clienteRuteado(feedCon([publicacion(1)])));
      await montarFeed(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Reservar'));

      expect(find.text('Reservar publicación'), findsNothing);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'PUT /api/publicaciones/1/reservado': (_) => respuestaJson({'error': 'Ya reservada'}, 409),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Reservar'));
      await confirmar(tester, 'Reservar');

      expect(find.text('Ya reservada'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(feedCon([publicacion(1)]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Reservar'));
      await confirmar(tester, 'Reservar');

      expect(find.text('Error al reservar la publicación'), findsOneWidget);
    });
  });

  group('ofrecer un objeto', () {
    final mias = [
      publicacion(20, titulo: 'Mi lampara', categoria: 'electronica', idUsuario: 7),
      publicacion(21, titulo: 'Mi libro', estadoPublicacion: 'reservado', idUsuario: 7),
    ];

    testWidgets('elegir un objeto envia la oferta', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'GET /api/publicaciones/mias': (_) => respuestaJson(mias),
        'POST /api/ofertas': (_) => respuestaJson({'mensaje': 'Oferta enviada a Beto.'}),
      }, registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));
      expect(find.text('Mi lampara'), findsOneWidget);
      expect(find.text('Mi libro'), findsNothing);
      await tocar(tester, find.text('Mi lampara'));
      await confirmar(tester, 'Enviar oferta');

      expect(find.textContaining('Oferta enviada a Beto. Revísala'), findsOneWidget);
      final oferta = registro.firstWhere((p) => p.url.path == '/api/ofertas');
      expect(oferta.body, contains('"id_publicacion_ofrecida":20'));
    });

    testWidgets('cancelar el dialogo no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'GET /api/publicaciones/mias': (_) => respuestaJson(mias),
      }, registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(registro.where((p) => p.url.path == '/api/ofertas'), isEmpty);
    });

    testWidgets('sin sesion no pasa nada al ofrecer', (tester) async {
      final controlador = await crearControlador(clienteRuteado(feedCon([publicacion(1)])));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('si no se pueden leer mis publicaciones avisa', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'GET /api/publicaciones/mias': (_) => respuestaJson({'error': 'No hay lista'}, 500),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));

      expect(find.text('No hay lista'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la oferta muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([publicacion(1)]),
        'GET /api/publicaciones/mias': (_) => respuestaJson(mias),
        'POST /api/ofertas': (_) => respuestaJson({'error': 'Oferta repetida'}, 409),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));
      await tocar(tester, find.text('Mi lampara'));
      await confirmar(tester, 'Enviar oferta');

      expect(find.text('Oferta repetida'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla({
        ...feedCon([publicacion(1)]),
        'GET /api/publicaciones/mias': (_) => respuestaJson(mias),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Ofrecer un objeto'));
      await tocar(tester, find.text('Mi lampara'));
      await confirmar(tester, 'Enviar oferta');

      expect(find.text('Error al enviar la oferta'), findsOneWidget);
    });
  });

  group('cancelar reserva', () {
    final reservadaPorMi = publicacion(
      1,
      estadoPublicacion: 'reservado',
      idReserva: 7,
      nombreReserva: 'Ana Perez',
    );

    testWidgets('confirmar libera la publicacion', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([reservadaPorMi]),
        'PUT /api/publicaciones/1/disponible': (_) => respuestaJson({}),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Cancelar reserva'));
      await confirmar(tester, 'Sí, cancelar reserva');

      expect(find.text('Reserva descartada. Publicación nuevamente disponible.'), findsOneWidget);
    });

    testWidgets('mantener la reserva no cambia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([reservadaPorMi]), registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Cancelar reserva'));
      await tocar(tester, find.text('Mantener reserva'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([reservadaPorMi]),
        'PUT /api/publicaciones/1/disponible': (_) => respuestaJson({'error': 'No se pudo'}, 409),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Cancelar reserva'));
      await confirmar(tester, 'Sí, cancelar reserva');

      expect(find.text('No se pudo'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(feedCon([reservadaPorMi]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Cancelar reserva'));
      await confirmar(tester, 'Sí, cancelar reserva');

      expect(find.text('Error al descartar la reserva'), findsOneWidget);
    });
  });

  group('completar intercambio', () {
    final reservadaPorMi = publicacion(
      1,
      estadoPublicacion: 'reservado',
      idReserva: 7,
      nombreReserva: 'Ana Perez',
    );

    testWidgets('confirmar completa el intercambio', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([reservadaPorMi]),
        'PUT /api/publicaciones/1/intercambiado': (_) => respuestaJson({}),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('¡Intercambio completado!'), findsOneWidget);
    });

    testWidgets('cancelar el dialogo no completa nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(feedCon([reservadaPorMi]), registro: registro);
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...feedCon([reservadaPorMi]),
        'PUT /api/publicaciones/1/intercambiado': (_) => respuestaJson({'error': 'Aun no'}, 409),
      });
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('Aun no'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(feedCon([reservadaPorMi]));
      await montarFeed(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('Error al completar el intercambio'), findsOneWidget);
    });
  });
}
