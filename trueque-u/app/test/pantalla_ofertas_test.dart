import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_ofertas.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';
import 'ayudantes/trueques.dart';

Map<String, dynamic> oferta(
  int id, {
  String estado = 'pendiente',
  bool recibida = true,
  bool confirmaPedida = false,
  bool confirmaOfrecida = false,
  String? motivo,
  int ronda = 1,
}) {
  final yo = {'nombre': 'Ana Perez'};
  final otra = {'nombre': 'Beto'};
  return {
    'id': id,
    'estado': estado,
    'ronda': ronda,
    'id_usuario': recibida ? 8 : 7,
    'confirma_pedida': confirmaPedida,
    'confirma_ofrecida': confirmaOfrecida,
    'motivo_cancelacion': motivo,
    'pedida': {
      'id': 100 + id,
      'titulo': 'Libro $id',
      'id_usuario': recibida ? 7 : 8,
      'autor': recibida ? yo : otra,
    },
    'ofrecida': {
      'id': 200 + id,
      'titulo': 'Mouse $id',
      'id_usuario': recibida ? 8 : 7,
      'autor': recibida ? otra : yo,
    },
    'oferente': recibida ? otra : yo,
  };
}

Map<String, ManejadorRuta> listas({
  List<Map<String, dynamic>> recibidas = const [],
  List<Map<String, dynamic>> enviadas = const [],
}) {
  return {
    'GET /api/ofertas/recibidas': (_) => respuestaJson(recibidas),
    'GET /api/ofertas/enviadas': (_) => respuestaJson(enviadas),
    'GET /api/propuestas-entrega': (_) => respuestaJson({}),
    'GET /api/calificaciones': (_) => respuestaJson({'mia': null}),
  };
}

Future<void> montarOfertas(WidgetTester tester, ControladorAutenticacion controlador) {
  return montarPantallaEnRuta(
    tester,
    PantallaOfertas(),
    controlador,
    rutasExtra: ['/feed'],
  );
}

Future<void> confirmarEnDialogo(WidgetTester tester, String texto) async {
  final boton = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, texto),
  );
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<void> verEnviadas(WidgetTester tester) async {
  await tester.tap(find.text('Enviadas'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(cargarEntornoDePrueba);

  group('listas', () {
    testWidgets('las recibidas muestran quien ofrece y que', (tester) async {
      final controlador = await controladorConSesion(listas(recibidas: [oferta(1, ronda: 2)]));

      await montarOfertas(tester, controlador);

      expect(find.text('De: Beto'), findsOneWidget);
      expect(find.text('Ronda 2'), findsOneWidget);
      expect(find.text('Quiere: Libro 1'), findsOneWidget);
      expect(find.text('Ofrece: Mouse 1'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('las enviadas muestran a quien se las envie', (tester) async {
      final controlador = await controladorConSesion(
        listas(enviadas: [oferta(1, recibida: false)]),
      );
      await montarOfertas(tester, controlador);

      await verEnviadas(tester);

      expect(find.text('Para: Beto'), findsOneWidget);
      expect(find.text('Cancelar oferta'), findsOneWidget);
      expect(find.text('Contraofertar'), findsNothing);
    });

    testWidgets('si el oferente fue otro persona el receptor es el autor de lo ofrecido', (tester) async {
      final datos = oferta(1, recibida: false);
      datos['id_usuario'] = 8;
      datos['pedida']['id_usuario'] = 8;
      final controlador = await controladorConSesion(listas(enviadas: [datos]));
      await montarOfertas(tester, controlador);

      await verEnviadas(tester);

      expect(find.text('Para: Ana Perez'), findsOneWidget);
    });

    testWidgets('cada estado tiene su etiqueta', (tester) async {
      final estados = {
        'contraofertada': 'Contraofertada',
        'aceptada': 'Aceptada',
        'completada': 'Intercambio completado',
        'anulada': 'Intercambio cancelado',
        'rechazada': 'Rechazada',
        'cancelada': 'Cancelada',
      };
      final controlador = await controladorConSesion(
        listas(
          recibidas: [
            for (final (i, estado) in estados.keys.indexed) oferta(i + 1, estado: estado, motivo: 'Cambio de planes'),
          ],
        ),
      );

      await montarOfertas(tester, controlador);

      for (final etiqueta in estados.values) {
        expect(find.text(etiqueta), findsWidgets);
      }
      expect(find.text('Motivo: Cambio de planes'), findsNWidgets(2));
    });

    testWidgets('una oferta sin datos usa valores por defecto', (tester) async {
      final controlador = await controladorConSesion(
        listas(recibidas: [{'id': 1}], enviadas: [{'id': 2}]),
      );

      await montarOfertas(tester, controlador);
      expect(find.text('De: Alguien'), findsOneWidget);
      expect(find.text('Quiere: un objeto'), findsOneWidget);
      expect(find.text('Ofrece: un objeto'), findsOneWidget);
      expect(find.text('Ronda 1'), findsOneWidget);

      await verEnviadas(tester);
      expect(find.text('Para: la otra persona'), findsOneWidget);
    });

    testWidgets('sin ofertas recibidas invita a explorar', (tester) async {
      final controlador = await controladorConSesion(listas());
      await montarOfertas(tester, controlador);
      expect(find.text('Nadie te ha ofrecido un trueque'), findsOneWidget);

      await tocar(tester, find.text('Explorar publicaciones'));

      expect(find.text('Destino /feed'), findsOneWidget);
    });

    testWidgets('sin ofertas enviadas lo explica', (tester) async {
      final controlador = await controladorConSesion(listas());
      await montarOfertas(tester, controlador);

      await verEnviadas(tester);

      expect(find.text('Todavía no envías ofertas'), findsOneWidget);
    });

    testWidgets('un error del servidor se puede reintentar', (tester) async {
      var intentos = 0;
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/ofertas/recibidas': (_) {
          intentos++;
          if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
          return respuestaJson([oferta(1)]);
        },
      });
      await montarOfertas(tester, controlador);
      expect(find.text('Sin servicio'), findsOneWidget);

      await tocar(tester, find.text('Reintentar'));

      expect(find.text('De: Beto'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
      final controlador = await controladorConFallas(listas());
      controlador.fallan.add('recibidas');

      await montarOfertas(tester, controlador);

      expect(find.text('No se pudieron cargar las ofertas'), findsOneWidget);
    });

    testWidgets('el icono de actualizar vuelve a pedir las ofertas', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(listas(), registro: registro);
      await montarOfertas(tester, controlador);

      await tocarIcono(tester, Icons.refresh);

      expect(registro.where((p) => p.url.path == '/api/ofertas/recibidas').length, 2);
    });
  });

  group('responder', () {
    testWidgets('aceptar pide confirmacion, avisa y recarga', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'PUT /api/ofertas/1/aceptada': (_) => respuestaJson({'mensaje': 'Trueque aceptado'}),
      }, registro: registro);
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(FilledButton, 'Aceptar'));
      expect(find.text('Aceptar trueque'), findsOneWidget);
      await confirmarEnDialogo(tester, 'Aceptar');

      expect(find.text('Trueque aceptado'), findsOneWidget);
      expect(registro.any((p) => p.method == 'PUT' && p.url.path == '/api/ofertas/1/aceptada'), isTrue);
      expect(registro.where((p) => p.url.path == '/api/ofertas/recibidas').length, 2);
      expect(registro.any((p) => p.url.path == '/api/eventos'), isTrue);
    });

    testWidgets('cancelar la confirmacion no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(listas(recibidas: [oferta(1)]), registro: registro);
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(FilledButton, 'Aceptar'));
      await tocar(tester, find.text('Cancelar'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('rechazar usa su ruta', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'PUT /api/ofertas/1/rechazada': (_) => respuestaJson({'mensaje': 'Oferta rechazada ok'}),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Rechazar'));
      await confirmarEnDialogo(tester, 'Rechazar');

      expect(find.text('Oferta rechazada ok'), findsOneWidget);
    });

    testWidgets('cancelar una oferta enviada usa su ruta', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(enviadas: [oferta(1, recibida: false)]),
        'PUT /api/ofertas/1/cancelada': (_) => respuestaJson({'mensaje': 'Oferta cancelada ok'}),
      });
      await montarOfertas(tester, controlador);
      await verEnviadas(tester);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Cancelar oferta'));
      await confirmarEnDialogo(tester, 'Sí, cancelar oferta');

      expect(find.text('Oferta cancelada ok'), findsOneWidget);
    });

    testWidgets('confirmar la entrega usa su ruta', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1, estado: 'aceptada', confirmaOfrecida: true)]),
        'PUT /api/ofertas/1/entrega': (_) => respuestaJson({'mensaje': 'Entrega registrada'}),
      });
      await montarOfertas(tester, controlador);
      expect(find.text('Tu entrega: pendiente'), findsOneWidget);
      expect(find.text('La otra persona: confirmada'), findsOneWidget);

      await tocar(tester, find.widgetWithText(FilledButton, 'Confirmar entrega'));
      await confirmarEnDialogo(tester, 'Confirmar');

      expect(find.text('Entrega registrada'), findsOneWidget);
    });

    testWidgets('con mi entrega confirmada el boton queda apagado', (tester) async {
      final controlador = await controladorConSesion(
        listas(recibidas: [oferta(1, estado: 'aceptada', confirmaPedida: true)]),
      );

      await montarOfertas(tester, controlador);

      expect(find.text('Tu entrega: confirmada'), findsOneWidget);
      expect(find.text('La otra persona: pendiente'), findsOneWidget);
      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar entrega'));
      expect(boton.onPressed, isNull);
    });

    testWidgets('si el servidor rechaza la accion muestra su mensaje', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'PUT /api/ofertas/1/aceptada': (_) => respuestaJson({'error': 'La oferta ya cambió'}, 409),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(FilledButton, 'Aceptar'));
      await confirmarEnDialogo(tester, 'Aceptar');

      expect(find.text('La oferta ya cambió'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Aceptar'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
      final controlador = await controladorConFallas(listas(recibidas: [oferta(1)]));
      controlador.fallan.add('aceptar');
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(FilledButton, 'Aceptar'));
      await confirmarEnDialogo(tester, 'Aceptar');

      expect(find.text('No se pudo actualizar la oferta'), findsOneWidget);
    });

    testWidgets('mientras se acepta una oferta pendiente se muestra un indicador', (tester) async {
      final (controlador, espera) = await controladorLento(
        listas(recibidas: [oferta(1)]),
        'PUT /api/ofertas/1/aceptada',
      );
      await montarOfertas(tester, controlador);
      await tocar(tester, find.widgetWithText(FilledButton, 'Aceptar'));

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Aceptar'),
      ));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 500));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Aceptar'), findsNothing);

      espera.complete(respuestaJson({'mensaje': 'Listo'}));
      await tester.pumpAndSettle();
    });

    testWidgets('mientras se confirma la entrega se muestra un indicador', (tester) async {
      final (controlador, espera) = await controladorLento(
        listas(recibidas: [oferta(1, estado: 'aceptada')]),
        'PUT /api/ofertas/1/entrega',
      );
      await montarOfertas(tester, controlador);
      await tocar(tester, find.widgetWithText(FilledButton, 'Confirmar entrega'));

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Confirmar'),
      ));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 500));

      expect(find.widgetWithText(OutlinedButton, 'Cancelar intercambio'), findsNothing);

      espera.complete(respuestaJson({'mensaje': 'Listo'}));
      await tester.pumpAndSettle();
    });
  });

  group('cancelar intercambio', () {
    Future<void> escribirMotivo(WidgetTester tester) async {
      await tester.enterText(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)),
        'Ya no puedo ir',
      );
      await tester.pump();
    }

    testWidgets('pide el motivo, lo envia y recarga', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1, estado: 'aceptada')]),
        'PUT /api/ofertas/1/anulada': (_) => respuestaJson({'mensaje': 'Intercambio anulado'}),
      }, registro: registro);
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Cancelar intercambio'));
      await escribirMotivo(tester);
      await confirmarEnDialogo(tester, 'Sí, cancelar');

      final envio = registro.firstWhere((p) => p.url.path == '/api/ofertas/1/anulada');
      expect(envio.body, contains('"motivo":"Ya no puedo ir"'));
      expect(find.text('Intercambio anulado'), findsOneWidget);
    });

    testWidgets('volver del dialogo no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(
        listas(recibidas: [oferta(1, estado: 'aceptada')]),
        registro: registro,
      );
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Cancelar intercambio'));
      await tocar(tester, find.text('Volver'));

      expect(registro.where((p) => p.method == 'PUT'), isEmpty);
    });

    testWidgets('si el servidor lo rechaza muestra el aviso', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1, estado: 'aceptada')]),
        'PUT /api/ofertas/1/anulada': (_) => respuestaJson({'error': 'Ya estaba cancelado'}, 409),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Cancelar intercambio'));
      await escribirMotivo(tester);
      await confirmarEnDialogo(tester, 'Sí, cancelar');

      expect(find.text('Ya estaba cancelado'), findsOneWidget);
    });
  });

  group('contraofertar', () {
    final disponibles = [
      publicacion(201, idUsuario: 8, titulo: 'Mouse 1'),
      publicacion(300, idUsuario: 8, titulo: 'Teclado'),
      publicacion(400, idUsuario: 9, titulo: 'Ajeno'),
    ];

    testWidgets('ofrece los otros objetos del oferente y envia la eleccion', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/publicaciones': (_) => respuestaJson(disponibles),
        'POST /api/ofertas/1/contraoferta': (_) => respuestaJson({'mensaje': 'Contraoferta enviada ok'}),
      }, registro: registro);
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Contraofertar'));
      expect(find.text('¿Qué otro objeto propones por «Libro 1»?'), findsOneWidget);
      expect(find.text('Teclado'), findsOneWidget);
      expect(find.text('Ajeno'), findsNothing);
      await tocar(tester, find.text('Teclado'));
      await confirmarEnDialogo(tester, 'Enviar contraoferta');

      final envio = registro.firstWhere((p) => p.url.path == '/api/ofertas/1/contraoferta');
      expect(envio.body, contains('"id_publicacion_ofrecida":300'));
      expect(find.text('Contraoferta enviada ok'), findsOneWidget);
    });

    testWidgets('cancelar el dialogo no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/publicaciones': (_) => respuestaJson(disponibles),
      }, registro: registro);
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Contraofertar'));
      await tocar(tester, find.text('Cancelar'));

      expect(registro.where((p) => p.method == 'POST' && p.url.path.contains('contraoferta')), isEmpty);
    });

    testWidgets('si no se pueden pedir los objetos muestra el aviso', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/publicaciones': (_) => respuestaJson({'error': 'Feed caido'}, 503),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Contraofertar'));

      expect(find.text('Feed caido'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la contraoferta muestra el aviso', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/publicaciones': (_) => respuestaJson(disponibles),
        'POST /api/ofertas/1/contraoferta': (_) => respuestaJson({'error': 'Ya no se puede'}, 409),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Contraofertar'));
      await tocar(tester, find.text('Teclado'));
      await confirmarEnDialogo(tester, 'Enviar contraoferta');

      expect(find.text('Ya no se puede'), findsOneWidget);
    });

    testWidgets('sin pedido con titulo usa un texto por defecto', (tester) async {
      final datos = oferta(1);
      datos['pedida'] = {...(datos['pedida'] as Map), 'titulo': null};
      final controlador = await controladorConSesion({
        ...listas(recibidas: [datos]),
        'GET /api/publicaciones': (_) => respuestaJson([]),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Contraofertar'));

      expect(find.text('No hay otro objeto disponible para proponer en esta negociación.'), findsOneWidget);
    });
  });

  group('historial de la negociacion', () {
    Map<String, dynamic> ronda(int numero, String estado, {String? motivo, String? creado}) {
      return {
        'ronda': numero,
        'estado': estado,
        'creado_en': creado,
        'motivo_cancelacion': motivo,
        'oferente': {'nombre': 'Beto'},
        'ofrecida': {'titulo': 'Mouse $numero'},
      };
    }

    testWidgets('lista cada ronda con su estado y motivo', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/ofertas/1/historial': (_) => respuestaJson({
          'propuestas': [
            ronda(1, 'contraofertada', creado: '2026-03-15T12:00:00Z'),
            ronda(2, 'aceptada'),
            ronda(3, 'completada'),
            ronda(4, 'anulada', motivo: 'Cambio de planes'),
            ronda(5, 'rechazada'),
            ronda(6, 'cancelada'),
            ronda(7, 'pendiente'),
          ],
        }),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Ver historial'));

      expect(find.text('Se negocia: Libro 1'), findsOneWidget);
      expect(find.text('Ronda 1: Beto propone Mouse 1'), findsOneWidget);
      expect(find.textContaining('Contraofertada · '), findsOneWidget);
      expect(find.text('Aceptada · '), findsOneWidget);
      expect(find.text('Intercambio completado · '), findsOneWidget);
      expect(find.text('Intercambio cancelado · '), findsOneWidget);
      expect(find.text('Rechazada · '), findsOneWidget);
      expect(find.text('Cancelada · '), findsOneWidget);
      expect(find.text('Pendiente · '), findsOneWidget);
      expect(find.text('Motivo: Cambio de planes'), findsOneWidget);

      await tocar(tester, find.text('Cerrar'));
      expect(find.text('Se negocia: Libro 1'), findsNothing);
    });

    testWidgets('si no se puede pedir muestra el aviso', (tester) async {
      final controlador = await controladorConSesion({
        ...listas(recibidas: [oferta(1)]),
        'GET /api/ofertas/1/historial': (_) => respuestaJson({'error': 'Historial caido'}, 503),
      });
      await montarOfertas(tester, controlador);

      await tocar(tester, find.text('Ver historial'));

      expect(find.text('Historial caido'), findsOneWidget);
    });
  });
}
