// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_mis_publicaciones.dart';
import 'package:trueque_u/widgets/tarjeta_mi_publicacion.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

Future<void> montarLista(WidgetTester tester, ControladorAutenticacion controlador) {
  return montarPantallaEnRuta(tester, PantallaMisPublicaciones(), controlador);
}

Map<String, ManejadorRuta> miasCon(List<Map<String, dynamic>> lista) {
  return {'GET /api/publicaciones/mias': (_) => respuestaJson(lista)};
}

TarjetaMiPublicacion tarjeta(WidgetTester tester) {
  return tester.widget<TarjetaMiPublicacion>(find.byType(TarjetaMiPublicacion));
}

void main() {
  setUp(cargarEntornoDePrueba);

  final disponible = publicacion(1, idUsuario: 7);
  final reservada = publicacion(
    1,
    idUsuario: 7,
    estadoPublicacion: 'reservado',
    idReserva: 8,
    nombreReserva: 'Beto',
  );

  group('lista', () {
    testWidgets('muestra el total y las tarjetas', (tester) async {
      final controlador = await controladorConSesion(miasCon([disponible, publicacion(2, idUsuario: 7)]));

      await montarLista(tester, controlador);

      expect(find.text('Total: 2'), findsOneWidget);
      expect(find.text('Objeto 1'), findsOneWidget);
    });

    testWidgets('sin publicaciones invita a crear una', (tester) async {
      final controlador = await controladorConSesion(miasCon([]));
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Crear nueva publicación'));

      expect(find.text('Destino /publicacion'), findsOneWidget);
    });

    testWidgets('una respuesta que no es lista cuenta como vacia', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/publicaciones/mias': (_) => respuestaJson({'otro': 1}),
      });

      await montarLista(tester, controlador);

      expect(find.text('Aún no tienes publicaciones'), findsOneWidget);
    });

    testWidgets('el error del servidor se puede reintentar', (tester) async {
      var intentos = 0;
      final controlador = await controladorConSesion({
        'GET /api/publicaciones/mias': (_) {
          intentos++;
          if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
          return respuestaJson([disponible]);
        },
      });
      await montarLista(tester, controlador);
      expect(find.text('Sin servicio'), findsOneWidget);

      await tocar(tester, find.text('Reintentar'));

      expect(find.text('Objeto 1'), findsOneWidget);
    });

    testWidgets('una respuesta rara muestra el mensaje general', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/publicaciones/mias': (_) => respuestaJson([1]),
      });

      await montarLista(tester, controlador);

      expect(find.text('No se pudieron cargar tus publicaciones'), findsOneWidget);
    });

    testWidgets('el boton actualizar vuelve a pedir la lista', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(miasCon([disponible]), registro: registro);
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Actualizar'));

      expect(registro.where((p) => p.url.path == '/api/publicaciones/mias').length, 2);
    });

    testWidgets('el boton publicar lleva al formulario', (tester) async {
      final controlador = await controladorConSesion(miasCon([disponible]));
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Publicar'));

      expect(find.text('Destino /publicacion'), findsOneWidget);
    });

    testWidgets('usa valores por defecto si faltan datos', (tester) async {
      final controlador = await controladorConSesion(miasCon([
        {'id': 5},
      ]));

      await montarLista(tester, controlador);

      expect(find.text('Sin título'), findsOneWidget);
      expect(find.text('Usado'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
    });
  });

  group('eliminar', () {
    testWidgets('confirmar elimina la publicacion', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'DELETE /api/publicaciones/1': (_) => respuestaJson({}),
      }, registro: registro);
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Eliminar definitivamente'));
      await confirmar(tester, 'Eliminar');

      expect(find.text('Publicación eliminada'), findsOneWidget);
      expect(registro.any((p) => p.method == 'DELETE'), isTrue);
    });

    testWidgets('sin titulo el dialogo habla de esta publicacion', (tester) async {
      final controlador = await controladorConSesion(miasCon([
        {'id': 5},
      ]));
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Eliminar definitivamente'));

      expect(find.textContaining('"esta publicación"'), findsOneWidget);
    });

    testWidgets('cancelar no elimina nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(miasCon([disponible]), registro: registro);
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Eliminar definitivamente'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(registro.where((p) => p.method == 'DELETE'), isEmpty);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'DELETE /api/publicaciones/1': (_) => respuestaJson({'error': 'No se puede borrar'}, 409),
      });
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Eliminar definitivamente'));
      await confirmar(tester, 'Eliminar');

      expect(find.text('No se puede borrar'), findsOneWidget);
    });
  });

  group('cambiar estado', () {
    Future<void> elegirOpcion(WidgetTester tester, String opcion) async {
      await tocar(tester, find.byTooltip('Cambiar estado de la publicación'));
      await tocar(tester, find.text(opcion));
    }

    testWidgets('ocultar avisa que solo la ve el dueno', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'PUT /api/publicaciones/1/oculto': (_) => respuestaJson({}),
      });
      await montarLista(tester, controlador);

      await elegirOpcion(tester, 'Ocultar publicación');

      expect(find.text('Tu publicación ahora está oculta (solo tú la ves)'), findsOneWidget);
    });

    testWidgets('marcar no disponible avisa que nadie puede reservarla', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'PUT /api/publicaciones/1/no-disponible': (_) => respuestaJson({}),
      });
      await montarLista(tester, controlador);

      await elegirOpcion(tester, 'Marcar como No disponible');

      expect(
        find.text('Tu publicación ahora está no disponible (nadie puede reservarla)'),
        findsOneWidget,
      );
    });

    testWidgets('marcar disponible vuelve a liberarla', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'PUT /api/publicaciones/1/disponible': (_) => respuestaJson({}),
      });
      await montarLista(tester, controlador);

      await elegirOpcion(tester, 'Marcar como Disponible');

      expect(find.text('Tu publicación ahora está disponible'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'PUT /api/publicaciones/1/oculto': (_) => respuestaJson({'error': 'Cambio no permitido'}, 409),
      });
      await montarLista(tester, controlador);

      await elegirOpcion(tester, 'Ocultar publicación');

      expect(find.text('Cambio no permitido'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(miasCon([disponible]));
      await montarLista(tester, controlador);

      await elegirOpcion(tester, 'Ocultar publicación');

      expect(find.text('Error al cambiar el estado'), findsOneWidget);
    });
  });

  group('descartar reserva', () {
    testWidgets('libera la publicacion reservada', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([reservada]),
        'PUT /api/publicaciones/1/disponible': (_) => respuestaJson({}),
      });
      await montarLista(tester, controlador);

      tarjeta(tester).alDescartarReserva();
      await tester.pumpAndSettle();

      expect(find.text('Reserva descartada. Publicación ahora disponible.'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([reservada]),
        'PUT /api/publicaciones/1/disponible': (_) => respuestaJson({'error': 'Ya estaba libre'}, 409),
      });
      await montarLista(tester, controlador);

      tarjeta(tester).alDescartarReserva();
      await tester.pumpAndSettle();

      expect(find.text('Ya estaba libre'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(miasCon([reservada]));
      await montarLista(tester, controlador);

      tarjeta(tester).alDescartarReserva();
      await tester.pumpAndSettle();

      expect(find.text('Error al descartar la reserva'), findsOneWidget);
    });
  });

  group('completar intercambio', () {
    testWidgets('confirmar completa el intercambio', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([reservada]),
        'PUT /api/publicaciones/1/intercambiado': (_) => respuestaJson({}),
      });
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('¡Intercambio completado!'), findsOneWidget);
    });

    testWidgets('si no esta reservada explica por que no se puede', (tester) async {
      final controlador = await controladorConSesion(miasCon([disponible]));
      await montarLista(tester, controlador);

      tarjeta(tester).alCompletar();
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo se puede completar un intercambio'), findsOneWidget);
    });

    testWidgets('cancelar el dialogo no completa nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(miasCon([reservada]), registro: registro);
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('si el servidor rechaza muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...miasCon([reservada]),
        'PUT /api/publicaciones/1/intercambiado': (_) => respuestaJson({'error': 'Aun no'}, 409),
      });
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('Aun no'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla(miasCon([reservada]));
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Completar intercambio'));
      await confirmar(tester, 'Completar');

      expect(find.text('Error al completar el intercambio'), findsOneWidget);
    });
  });

  group('whatsapp', () {
    testWidgets('con intercambio acordado abre el chat de quien reservo', (tester) async {
      final lanzador = LanzadorWhatsappFalso();
      UrlLauncherPlatform.instance = lanzador;
      final controlador = await controladorConSesion(miasCon([
        publicacion(
          1,
          idUsuario: 7,
          estadoPublicacion: 'acordado',
          nombreReserva: 'Beto',
          telefonoReserva: '70011223',
        ),
      ]));
      await montarLista(tester, controlador);

      await tocar(tester, find.text('Escribir por WhatsApp'));

      expect(lanzador.enlaces.single, 'https://wa.me/59170011223');
    });
  });

  group('editar', () {
    testWidgets('guardar cambios actualiza la lista', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...miasCon([disponible]),
        'PUT /api/publicaciones/1': (_) => respuestaJson({}),
      }, registro: registro);
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Editar información'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del objeto'), 'Titulo nuevo');
      await confirmar(tester, 'Guardar');

      expect(find.text('Publicación actualizada correctamente'), findsOneWidget);
      final peticion = registro.firstWhere((p) => p.method == 'PUT');
      expect(peticion.body, contains('"titulo":"Titulo nuevo"'));
    });

    testWidgets('cancelar el dialogo no muestra aviso', (tester) async {
      final controlador = await controladorConSesion(miasCon([disponible]));
      await montarLista(tester, controlador);

      await tocar(tester, find.byTooltip('Editar información'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(find.text('Publicación actualizada correctamente'), findsNothing);
    });

    testWidgets('una publicacion reservada no se puede editar', (tester) async {
      final controlador = await controladorConSesion(miasCon([reservada]));
      await montarLista(tester, controlador);

      tarjeta(tester).alEditar();
      await tester.pumpAndSettle();

      expect(find.text('No puedes editar una publicación que ya fue reservada'), findsOneWidget);
    });
  });
}
