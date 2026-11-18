// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/servicios/cliente_api.dart';
import 'package:trueque_u/widgets/bloque_entrega.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

Map<String, dynamic> propuesta(
  int id, {
  int idUsuario = 8,
  String nombre = 'Beto',
  String estado = 'pendiente',
  String lugar = 'Biblioteca',
}) {
  return {
    'id': id,
    'id_usuario': idUsuario,
    'fecha': '2030-06-15',
    'hora': '15:30',
    'lugar': lugar,
    'estado': estado,
    'proponente': {'nombre': nombre},
  };
}

Map<String, dynamic> entrega({
  Map<String, dynamic>? vigente,
  Map<String, dynamic>? pendiente,
  List<Map<String, dynamic>>? propuestas,
}) {
  return {
    'vigente': vigente,
    'pendiente': pendiente,
    'propuestas': propuestas ?? [if (vigente != null) vigente, if (pendiente != null) pendiente],
  };
}

Future<void> montarBloque(WidgetTester tester, ControladorAutenticacion controlador) async {
  usarPantallaGrande(tester);
  await montarWidget(
    tester,
    Scaffold(body: SingleChildScrollView(child: BloqueEntrega(idOferta: 3, idYo: 7))),
    controlador: controlador,
  );
  await tester.pumpAndSettle();
}

String fechaFutura() {
  final fecha = DateTime.now().add(Duration(days: 30));
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

Future<void> llenarDialogo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), fechaFutura());
  await tester.enterText(find.byType(TextFormField).at(1), '16:00');
  await tester.enterText(find.byType(TextFormField).at(2), 'Cafeteria');
}

void main() {
  setUp(cargarEntornoDePrueba);

  group('lectura', () {
    testWidgets('sin acuerdo ni propuestas permite proponer', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson({}),
      });

      await montarBloque(tester, controlador);

      expect(find.text('Todavía no acordaron fecha ni lugar'), findsOneWidget);
      expect(find.text('Proponer fecha y lugar'), findsOneWidget);
      expect(find.text('Historial de entrega'), findsNothing);
    });

    testWidgets('con acuerdo vigente permite reprogramar', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(vigente: propuesta(1, estado: 'aceptada')),
        ),
      });

      await montarBloque(tester, controlador);

      expect(find.text('Acordado: 15/06/2030 a las 15:30 en Biblioteca'), findsOneWidget);
      expect(find.text('Reprogramar'), findsOneWidget);
    });

    testWidgets('mi propuesta pendiente espera respuesta', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(pendiente: propuesta(1, idUsuario: 7, nombre: 'Ana')),
        ),
      });

      await montarBloque(tester, controlador);

      expect(
        find.text('Tu propuesta espera respuesta: 15/06/2030 a las 15:30 en Biblioteca'),
        findsOneWidget,
      );
      expect(find.text('Mientras tanto sigue vigente el acuerdo anterior.'), findsNothing);
      expect(find.text('Aceptar propuesta'), findsNothing);
    });

    testWidgets('mi cambio pendiente deja vigente el acuerdo anterior', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(
            vigente: propuesta(1, estado: 'aceptada'),
            pendiente: propuesta(2, idUsuario: 7, nombre: 'Ana', lugar: 'Plaza'),
          ),
        ),
      });

      await montarBloque(tester, controlador);

      expect(
        find.text('Tu cambio espera respuesta: 15/06/2030 a las 15:30 en Plaza'),
        findsOneWidget,
      );
      expect(find.text('Mientras tanto sigue vigente el acuerdo anterior.'), findsOneWidget);
    });

    testWidgets('la propuesta de la otra persona se puede aceptar o contraproponer', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(entrega(pendiente: propuesta(1))),
      });

      await montarBloque(tester, controlador);

      expect(find.text('Beto propone: 15/06/2030 a las 15:30 en Biblioteca'), findsOneWidget);
      expect(find.text('Aceptar propuesta'), findsOneWidget);
      expect(find.text('Contraproponer'), findsOneWidget);
    });

    testWidgets('un cambio de la otra persona aclara que sigue el acuerdo anterior', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(
            vigente: propuesta(1, estado: 'aceptada'),
            pendiente: propuesta(2, lugar: 'Plaza'),
          ),
        ),
      });

      await montarBloque(tester, controlador);

      expect(find.text('Beto propone cambiar a: 15/06/2030 a las 15:30 en Plaza'), findsOneWidget);
      expect(find.text('Mientras tanto sigue vigente el acuerdo anterior.'), findsOneWidget);
    });

    testWidgets('un error del servidor se muestra en el bloque', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson({'error': 'Sin servicio'}, 503),
      });

      await montarBloque(tester, controlador);

      expect(find.text('Sin servicio'), findsOneWidget);
    });

    testWidgets('el historial lista cada propuesta con su estado', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(
            vigente: propuesta(1, estado: 'aceptada'),
            propuestas: [
              propuesta(1, estado: 'aceptada'),
              propuesta(2, estado: 'contrapuesta', nombre: 'Carla'),
              propuesta(3, estado: 'reemplazada'),
              propuesta(4, estado: 'pendiente'),
            ],
          ),
        ),
      });
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Historial de entrega'));

      expect(find.text('Acuerdo vigente'), findsOneWidget);
      expect(find.text('Se respondió con otra propuesta'), findsOneWidget);
      expect(find.text('Reemplazada por una reprogramación'), findsOneWidget);
      expect(find.text('Esperando respuesta'), findsOneWidget);
      expect(find.text('Carla propone: 15/06/2030 a las 15:30 en Biblioteca'), findsOneWidget);

      await tocar(tester, find.text('Cerrar'));
      expect(find.text('Acuerdo vigente'), findsNothing);
    });
  });

  group('acciones', () {
    testWidgets('proponer envia la fecha y lugar y recarga', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson({}),
        'POST /api/propuestas-entrega': (_) => respuestaJson({'mensaje': 'Propuesta enviada al otro'}),
      }, registro: registro);
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Proponer fecha y lugar'));
      await llenarDialogo(tester);
      await confirmar(tester, 'Enviar propuesta');

      final envio = registro.firstWhere((p) => p.method == 'POST' && p.url.path == '/api/propuestas-entrega');
      expect(envio.body, contains('"id_oferta":3'));
      expect(envio.body, contains('"hora":"16:00"'));
      expect(envio.body, contains('"lugar":"Cafeteria"'));
      expect(find.text('Propuesta enviada al otro'), findsOneWidget);
      expect(registro.where((p) => p.method == 'GET' && p.url.path == '/api/propuestas-entrega').length, 2);
    });

    testWidgets('reprogramar parte de los datos vigentes', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(
          entrega(vigente: propuesta(1, estado: 'aceptada')),
        ),
      });
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Reprogramar'));

      expect(find.text('Reprogramar la entrega'), findsOneWidget);
      expect(find.text('15/06/2030'), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Enviar reprogramación'), findsOneWidget);
    });

    testWidgets('cerrar el dialogo de proponer no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson({}),
      }, registro: registro);
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Proponer fecha y lugar'));
      await tocar(tester, find.text('Volver'));

      expect(registro.where((p) => p.method == 'POST' && p.url.path != '/api/sesiones'), isEmpty);
    });

    testWidgets('aceptar la propuesta de la otra persona avisa y recarga', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(entrega(pendiente: propuesta(5))),
        'PUT /api/propuestas-entrega/5/aceptada': (_) => respuestaJson({'mensaje': 'Quedó acordado'}),
      }, registro: registro);
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Aceptar propuesta'));

      expect(find.text('Quedó acordado'), findsOneWidget);
      expect(registro.any((p) => p.method == 'PUT' && p.url.path == '/api/propuestas-entrega/5/aceptada'), isTrue);
    });

    testWidgets('si el servidor rechaza la accion muestra el aviso', (tester) async {
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(entrega(pendiente: propuesta(5))),
        'PUT /api/propuestas-entrega/5/aceptada': (_) => respuestaJson({'error': 'Ya no está vigente'}, 409),
      });
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Aceptar propuesta'));

      expect(find.text('Ya no está vigente'), findsOneWidget);
      expect(find.text('Aceptar propuesta'), findsOneWidget);
    });

    testWidgets('contraproponer envia los nuevos datos a esa propuesta', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(entrega(pendiente: propuesta(5))),
        'POST /api/propuestas-entrega/5/contrapropuesta': (_) =>
            respuestaJson({'mensaje': 'Contrapropuesta enviada'}),
      }, registro: registro);
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Contraproponer'));
      expect(find.text('Biblioteca'), findsOneWidget);
      await llenarDialogo(tester);
      await confirmar(tester, 'Enviar contrapropuesta');

      final envio = registro.firstWhere((p) => p.url.path == '/api/propuestas-entrega/5/contrapropuesta');
      expect(envio.body, contains('"lugar":"Cafeteria"'));
      expect(find.text('Contrapropuesta enviada'), findsOneWidget);
    });

    testWidgets('cerrar el dialogo de contraproponer no envia nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion({
        'GET /api/propuestas-entrega': (_) => respuestaJson(entrega(pendiente: propuesta(5))),
      }, registro: registro);
      await montarBloque(tester, controlador);

      await tocar(tester, find.text('Contraproponer'));
      await tocar(tester, find.text('Volver'));

      expect(registro.where((p) => p.url.path.contains('contrapropuesta')), isEmpty);
    });
  });

  group('mientras envia', () {
    Future<(ControladorAutenticacion, Completer<http.Response>)> controladorLento(
      Map<String, dynamic> datosEntrega,
      String metodo,
    ) async {
      cargarEntornoDePrueba();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final espera = Completer<http.Response>();
      final cliente = MockClient((peticion) {
        final clave = '${peticion.method} ${peticion.url.path}';
        if (clave == 'POST /api/sesiones') return Future.value(sesionAna(peticion));
        if (clave == 'GET /api/propuestas-entrega') return Future.value(respuestaJson(datosEntrega));
        if (peticion.method == metodo) return espera.future;
        return Future.value(respuestaJson({}));
      });
      final controlador = ControladorAutenticacion(ClienteApi(cliente: cliente), prefs);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');
      return (controlador, espera);
    }

    testWidgets('al aceptar cambia los botones por un indicador', (tester) async {
      final (controlador, espera) = await controladorLento(entrega(pendiente: propuesta(5)), 'PUT');
      await montarBloque(tester, controlador);

      await tester.tap(find.text('Aceptar propuesta'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Aceptar propuesta'), findsNothing);

      espera.complete(respuestaJson({'mensaje': 'Listo'}));
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets('al proponer se oculta el boton hasta que responde', (tester) async {
      final (controlador, espera) = await controladorLento({}, 'POST');
      await montarBloque(tester, controlador);
      await tocar(tester, find.text('Proponer fecha y lugar'));
      await llenarDialogo(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar propuesta'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 500));

      expect(find.text('Proponer fecha y lugar'), findsNothing);

      espera.complete(respuestaJson({'mensaje': 'Listo'}));
      await tester.pumpAndSettle();
      expect(find.text('Proponer fecha y lugar'), findsOneWidget);
    });
  });
}
