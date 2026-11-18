// ignore_for_file: prefer_const_constructors
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_perfil.dart';
import 'package:trueque_u/widgets/dialogo_eliminar_cuenta.dart';

import 'ayudantes/montar.dart';

Future<ControladorAutenticacion> conSesion({
  String nombre = 'Ana Perez',
  String? correo = 'ana@correo.com',
  Map<String, ManejadorRuta> rutas = const {},
  List<http.Request>? registro,
}) async {
  final cliente = clienteRuteado({
    'POST /api/sesiones': (_) => respuestaJson({
      'token': 'tok-prueba',
      'usuario': {'id': 7, 'nombre': nombre, 'correo': correo},
    }),
    'GET /api/calificaciones/resumen': (_) => respuestaJson({'cantidad': 0, 'promedio': 0}),
    'POST /api/eventos': (_) => respuestaJson({}),
    ...rutas,
  }, registro: registro);
  final controlador = await crearControlador(cliente);
  await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return controlador;
}

Future<GoRouter> montarPerfil(WidgetTester tester, ControladorAutenticacion controlador) {
  usarPantallaGrande(tester);
  return montarConRuteador(
    tester,
    inicial: '/perfil',
    controlador: controlador,
    rutas: [
      GoRoute(path: '/perfil', builder: (context, estado) => PantallaPerfil()),
      for (final ruta in [
        '/',
        '/intercambios',
        '/historial',
        '/avisos',
        '/mis-datos',
        '/cambiar-contrasena',
      ])
        rutaMarcada(ruta),
    ],
  );
}

Future<void> abrirDialogo(WidgetTester tester) async {
  await tester.tap(find.text('Eliminar cuenta'));
  await tester.pumpAndSettle();
}

void main() {
  group('PantallaPerfil', () {
    testWidgets('muestra nombre, correo e iniciales', (tester) async {
      await montarPerfil(tester, await conSesion());

      expect(find.text('Ana Perez'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsOneWidget);
      expect(find.text('AP'), findsOneWidget);
      expect(find.text('Aún no tienes calificaciones'), findsOneWidget);
    });

    testWidgets('con un solo nombre usa una inicial y sin correo no lo muestra', (tester) async {
      await montarPerfil(tester, await conSesion(nombre: 'luis', correo: null));

      expect(find.text('L'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('con nombre vacio muestra el signo de pregunta', (tester) async {
      await montarPerfil(tester, await conSesion(nombre: '   '));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('sin sesion no muestra nada', (tester) async {
      await montarPerfil(tester, await controladorSinRed());

      expect(find.text('Mi perfil'), findsNothing);
    });

    testWidgets('muestra el resumen de calificaciones', (tester) async {
      final controlador = await conSesion(
        rutas: {
          'GET /api/calificaciones/resumen': (_) =>
              respuestaJson({'cantidad': 2, 'promedio': 4.5}),
        },
      );
      await montarPerfil(tester, controlador);

      expect(find.text('4.5 de 5 · 2 calificaciones'), findsOneWidget);
    });

    for (final (texto, ruta) in [
      ('Intercambios completados', '/intercambios'),
      ('Historial', '/historial'),
      ('Avisos', '/avisos'),
      ('Mis datos', '/mis-datos'),
      ('Cambiar contraseña', '/cambiar-contrasena'),
    ]) {
      testWidgets('la opcion $texto lleva a $ruta', (tester) async {
        await montarPerfil(tester, await conSesion());

        await tester.tap(find.text(texto));
        await tester.pumpAndSettle();

        expect(find.text('Destino $ruta'), findsOneWidget);
      });
    }

    testWidgets('Cerrar sesion limpia la sesion', (tester) async {
      final controlador = await conSesion(
        rutas: {'DELETE /api/sesiones/actual': (_) => respuestaJson({})},
      );
      await montarPerfil(tester, controlador);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(controlador.autenticado, isFalse);
      expect(find.text('Mi perfil'), findsNothing);
    });

    testWidgets('cancelar el dialogo de eliminar deja la cuenta', (tester) async {
      final registro = <http.Request>[];
      final controlador = await conSesion(registro: registro);
      await montarPerfil(tester, controlador);

      await abrirDialogo(tester);
      await tester.tap(find.byKey(const Key('boton-cancelar-eliminar')));
      await tester.pumpAndSettle();

      expect(controlador.autenticado, isTrue);
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(registro.any((p) => p.url.path == '/api/eventos'), isTrue);
    });

    testWidgets('eliminar la cuenta cierra la sesion, va al inicio y avisa', (tester) async {
      final controlador = await conSesion(
        rutas: {
          'DELETE /api/usuarios/yo': (_) => respuestaJson({'trueques_cancelados': 2}),
        },
      );
      await montarPerfil(tester, controlador);

      await abrirDialogo(tester);
      await tester.enterText(find.byType(TextField), 'secreto1');
      await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
      await tester.pumpAndSettle();

      expect(controlador.autenticado, isFalse);
      expect(find.text('Destino /'), findsOneWidget);
      expect(find.textContaining('Tu cuenta fue eliminada'), findsOneWidget);
    });
  });

  group('DialogoEliminarCuenta', () {
    Future<List<http.Request>> montarDialogo(
      WidgetTester tester,
      Map<String, ManejadorRuta> rutas,
      List<Object?> resultados,
    ) async {
      final registro = <http.Request>[];
      final controlador = await conSesion(rutas: rutas, registro: registro);
      await montarWidget(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultados.add(
                  await showDialog<int>(
                    context: context,
                    builder: (_) => DialogoEliminarCuenta(),
                  ),
                );
              },
              child: Text('Abrir'),
            ),
          ),
        ),
        controlador: controlador,
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      return registro;
    }

    testWidgets('sin contrasena pide escribirla y no llama al servidor', (tester) async {
      final resultados = <Object?>[];
      final registro = await montarDialogo(tester, {}, resultados);

      await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu contraseña'), findsOneWidget);
      expect(registro.where((p) => p.method == 'DELETE'), isEmpty);
      expect(resultados, isEmpty);
    });

    testWidgets('con la contrasena correcta devuelve los trueques cancelados', (tester) async {
      final resultados = <Object?>[];
      final registro = await montarDialogo(tester, {
        'DELETE /api/usuarios/yo': (_) => respuestaJson({'trueques_cancelados': 4}),
      }, resultados);

      await tester.enterText(find.byType(TextField), 'secreto1');
      await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
      await tester.pumpAndSettle();

      expect(resultados, [4]);
      final borrado = registro.firstWhere((p) => p.method == 'DELETE');
      expect(jsonDecode(borrado.body), {'contrasena': 'secreto1'});
    });

    testWidgets('con contrasena incorrecta muestra el error y registra el intento', (tester) async {
      final resultados = <Object?>[];
      final registro = await montarDialogo(tester, {
        'DELETE /api/usuarios/yo': (_) => respuestaJson({'error': 'Contraseña incorrecta'}, 401),
      }, resultados);

      await tester.enterText(find.byType(TextField), 'mala');
      await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
      await tester.pumpAndSettle();

      expect(find.text('Contraseña incorrecta'), findsOneWidget);
      expect(resultados, isEmpty);
      final evento = registro.lastWhere((p) => p.url.path == '/api/eventos');
      expect(jsonDecode(evento.body)['evento'], 'eliminacion_cuenta_bloqueada');
    });

    testWidgets('con otro error muestra el mensaje sin registrar bloqueo', (tester) async {
      final resultados = <Object?>[];
      final registro = await montarDialogo(tester, {
        'DELETE /api/usuarios/yo': (_) => respuestaJson({'error': 'Servidor caido'}, 500),
      }, resultados);

      await tester.enterText(find.byType(TextField), 'secreto1');
      await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
      await tester.pumpAndSettle();

      expect(find.text('Servidor caido'), findsOneWidget);
      expect(registro.where((p) => p.url.path == '/api/eventos'), isEmpty);
    });

    testWidgets('enviar desde el teclado elimina la cuenta', (tester) async {
      final resultados = <Object?>[];
      await montarDialogo(tester, {
        'DELETE /api/usuarios/yo': (_) => respuestaJson({'trueques_cancelados': 0}),
      }, resultados);

      await tester.enterText(find.byType(TextField), 'secreto1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(resultados, [0]);
    });

    testWidgets('Cancelar cierra el dialogo sin resultado', (tester) async {
      final resultados = <Object?>[];
      await montarDialogo(tester, {}, resultados);

      await tester.tap(find.byKey(const Key('boton-cancelar-eliminar')));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar cuenta'), findsNothing);
      expect(resultados, [null]);
    });
  });
}
