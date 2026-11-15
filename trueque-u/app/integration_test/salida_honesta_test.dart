import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';
import 'calificar_intercambio_test.dart' show calificar, completarIntercambio, resumenDe;

const mensajeCuentaEliminada = 'Tu cuenta fue eliminada. Gracias por haber usado Trueque U.';
const motivoCuentaEliminada = 'Cuenta del usuario eliminada';
const clavesPersonales = ['correo', 'nombre', 'telefono', 'id_usuario', 'email'];

Future<int> totalEvento(String evento) async {
  final respuesta = await pedirApi('GET', '/analitica', job);
  final filas = jsonDecode(respuesta.body) as List;
  final fila = filas.firstWhere((f) => f['evento'] == evento, orElse: () => {'total': 0});
  return fila['total'] as int;
}

Future<void> esperarTotalEvento(WidgetTester tester, String evento, int esperado) async {
  for (var i = 0; i < 50; i++) {
    if (await totalEvento(evento) == esperado) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('El evento "$evento" no llegó a $esperado');
}

Future<void> eliminarCuentaDesdePerfil(WidgetTester tester, String contrasena) async {
  await tocar(tester, find.text('Eliminar cuenta'));
  await tester.enterText(find.byType(TextField), contrasena);
  await tester.pumpAndSettle();
  await tocar(tester, find.byKey(const Key('boton-confirmar-eliminar')));
}

Future<http.Response> eliminarCuentaPorApi(List<String> persona, String contrasena) async {
  final sesion = await http.post(
    Uri.parse('http://localhost:3000/api/sesiones'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'correo': persona[0], 'contrasena': persona[1]}),
  );
  final token = jsonDecode(sesion.body)['token'];
  final peticion = http.Request('DELETE', Uri.parse('http://localhost:3000/api/usuarios/yo'))
    ..headers.addAll({'Content-Type': 'application/json', 'Authorization': 'Bearer $token'})
    ..body = jsonEncode({'contrasena': contrasena});
  return http.Response.fromStream(await peticion.send());
}

Future<List<dynamic>> eventosGuardados() async {
  final respuesta = await http.get(Uri.parse('http://localhost:3100/eventos'));
  return jsonDecode(respuesta.body) as List;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mis datos', () {
    testWidgets('Eudenia ve sus datos y al descargarlos se registra datos_descargados', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      final antes = await totalEvento('datos_descargados');

      await tocar(tester, find.text('Mis datos'));
      await esperarTexto(tester, 'Tu perfil');
      expect(find.text('Descargar JSON'), findsOneWidget);
      expect(find.text('Descargar CSV'), findsOneWidget);
      expect(find.text('Nombre: Eudenia Flores Veizaga'), findsOneWidget);

      await tocarBoton(tester, 'Descargar JSON');
      await esperarTotalEvento(tester, 'datos_descargados', antes + 1);
    });
  });

  group('Eliminar la cuenta', () {
    testWidgets('Eudenia se equivoca de contraseña, no se borra nada y se registra el bloqueo', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      final iniciadas = await totalEvento('eliminacion_cuenta_iniciada');
      final bloqueadas = await totalEvento('eliminacion_cuenta_bloqueada');

      await eliminarCuentaDesdePerfil(tester, 'incorrecta');
      await esperarTexto(tester, 'La contraseña no es correcta');

      await esperarTotalEvento(tester, 'eliminacion_cuenta_iniciada', iniciadas + 1);
      await esperarTotalEvento(tester, 'eliminacion_cuenta_bloqueada', bloqueadas + 1);
      expect((await pedirApi('GET', '/sesiones/actual', eudenia)).statusCode, 200);
    });

    testWidgets('Eudenia elimina su cuenta con un trueque acordado y Carlos recibe el aviso', (tester) async {
      await abrirApp(tester);
      expect((await pedirApi('PUT', '/ofertas/1/aceptada', eudenia)).statusCode, 200);
      await iniciarSesion(tester, eudenia);
      final iniciadas = await totalEvento('eliminacion_cuenta_iniciada');
      final eliminadas = await totalEvento('cuenta_eliminada');

      await eliminarCuentaDesdePerfil(tester, eudenia[1]);
      await esperarTexto(tester, mensajeCuentaEliminada);
      expect(find.text('Iniciar sesión'), findsOneWidget);

      await esperarTotalEvento(tester, 'eliminacion_cuenta_iniciada', iniciadas + 1);
      await esperarTotalEvento(tester, 'cuenta_eliminada', eliminadas + 1);

      final avisos = jsonDecode((await pedirApi('GET', '/notificaciones', carlos)).body) as List;
      expect(avisos.length, 1);
      expect(
        avisos.first['mensaje'],
        'Tu trueque por "Calculo I - Stewart" se canceló porque la otra persona eliminó su cuenta.',
      );

      final enviadas = jsonDecode((await pedirApi('GET', '/ofertas/enviadas', carlos)).body) as List;
      final oferta = enviadas.firstWhere((o) => o['id'] == 1);
      expect(oferta['estado'], 'anulada');
      expect(oferta['motivo_cancelacion'], motivoCuentaEliminada);

      await iniciarSesion(tester, carlos);
      await tocar(tester, find.text('Avisos'));
      await esperarTexto(
        tester,
        'Tu trueque por "Calculo I - Stewart" se canceló porque la otra persona eliminó su cuenta.',
      );
    });

    testWidgets('Quien eliminó su cuenta ya no puede iniciar sesión', (tester) async {
      await abrirApp(tester);
      expect((await eliminarCuentaPorApi(eudenia, eudenia[1])).statusCode, 200);

      final intento = await http.post(
        Uri.parse('http://localhost:3000/api/sesiones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': eudenia[0], 'contrasena': eudenia[1]}),
      );
      expect(intento.statusCode, 401);
    });

    testWidgets('La calificación de una cuenta eliminada queda y Carlos ve Usuario eliminado', (tester) async {
      await abrirApp(tester);
      await completarIntercambio(1, eudenia, carlos);
      expect(await calificar(eudenia, 1, 5, 'Todo bien'), 201);
      expect((await eliminarCuentaPorApi(eudenia, eudenia[1])).statusCode, 200);

      final resumen = await resumenDe(carlos, 3);
      expect(resumen['cantidad'], 1);

      await iniciarSesion(tester, carlos);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));
      await esperarTexto(tester, 'Todavía no calificas a Usuario eliminado');
      expect(find.textContaining('Eudenia'), findsNothing);
    });
  });

  group('Eventos sin datos personales', () {
    testWidgets('El servidor rechaza un evento con datos personales y no los guarda', (tester) async {
      await abrirApp(tester);

      for (final clave in clavesPersonales) {
        final respuesta = await pedirApi('POST', '/eventos', eudenia, {
          'evento': 'prueba_pii',
          'props': {clave: 'dato'},
        });
        expect(respuesta.statusCode, 400);
      }
      expect(await totalEvento('prueba_pii'), 0);
    });

    testWidgets('Los eventos de este flujo guardados no tienen claves personales', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocar(tester, find.text('Mis datos'));
      await esperarTexto(tester, 'Tu perfil');
      await tocarBoton(tester, 'Descargar CSV');
      await irARuta(tester, '/perfil');
      await eliminarCuentaDesdePerfil(tester, eudenia[1]);
      await esperarTexto(tester, mensajeCuentaEliminada);

      final guardados = await eventosGuardados();
      expect(guardados, isNotEmpty);
      for (final props in guardados) {
        if (props is! Map) continue;
        for (final clave in clavesPersonales) {
          expect(props.containsKey(clave), false, reason: 'props con "$clave": $props');
        }
      }
    });
  });
}
