import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

typedef ManejadorRuta = http.Response Function(http.Request peticion);

http.Response respuestaJson(Object? cuerpo, [int estado = 200]) {
  return http.Response(
    jsonEncode(cuerpo),
    estado,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

MockClient clienteRuteado(Map<String, ManejadorRuta> rutas, {List<http.Request>? registro}) {
  return MockClient((peticion) async {
    registro?.add(peticion);
    final manejador = rutas['${peticion.method} ${peticion.url.path}'];
    if (manejador == null) return respuestaJson({'error': 'Ruta no definida'}, 404);
    return manejador(peticion);
  });
}

void cargarEntornoDePrueba() {
  dotenv.testLoad(fileInput: 'API_URL=http://servidor.test');
}

Future<ControladorAutenticacion> crearControlador(
  http.Client cliente, {
  Map<String, Object> preferencias = const {},
}) async {
  cargarEntornoDePrueba();
  SharedPreferences.setMockInitialValues(preferencias);
  final prefs = await SharedPreferences.getInstance();
  return ControladorAutenticacion(ClienteApi(cliente: cliente), prefs);
}

Future<ControladorAutenticacion> controladorSinRed({Map<String, Object> preferencias = const {}}) {
  return crearControlador(clienteRuteado({}), preferencias: preferencias);
}

Future<void> montarWidget(
  WidgetTester tester,
  Widget hijo, {
  ControladorAutenticacion? controlador,
}) async {
  controlador ??= await controladorSinRed();
  await tester.pumpWidget(
    ChangeNotifierProvider<ControladorAutenticacion>.value(
      value: controlador,
      child: MaterialApp(home: hijo),
    ),
  );
}

Future<GoRouter> montarConRuteador(
  WidgetTester tester, {
  required List<GoRoute> rutas,
  String inicial = '/',
  ControladorAutenticacion? controlador,
}) async {
  controlador ??= await controladorSinRed();
  final ruteador = GoRouter(initialLocation: inicial, routes: rutas);
  await tester.pumpWidget(
    ChangeNotifierProvider<ControladorAutenticacion>.value(
      value: controlador,
      child: MaterialApp.router(routerConfig: ruteador),
    ),
  );
  await tester.pumpAndSettle();
  return ruteador;
}

void usarPantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

GoRoute rutaMarcada(String ruta) {
  return GoRoute(
    path: ruta,
    builder: (context, estado) => Scaffold(body: Text('Destino $ruta')),
  );
}
