import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

import 'montar.dart';
import 'publicaciones.dart';

class ControladorConFallas extends ControladorAutenticacion {
  ControladorConFallas(super.api, super.preferencias);

  final fallan = <String>{};

  T _revisar<T>(String nombre, T Function() normal) {
    if (fallan.contains(nombre)) throw StateError('falla');
    return normal();
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerAvisos() async =>
      _revisar('avisos', () => super.obtenerAvisos());

  @override
  Future<List<Map<String, dynamic>>> obtenerHistorial({String? tipo}) async =>
      _revisar('historial', () => super.obtenerHistorial(tipo: tipo));

  @override
  Future<List<Map<String, dynamic>>> obtenerIntercambios() async =>
      _revisar('intercambios', () => super.obtenerIntercambios());

  @override
  Future<Map<String, dynamic>> obtenerMisDatos() async =>
      _revisar('datos', () => super.obtenerMisDatos());

  @override
  Future<List<Map<String, dynamic>>> obtenerOfertasRecibidas() async =>
      _revisar('recibidas', () => super.obtenerOfertasRecibidas());

  @override
  Future<String> aceptarOferta(int id) async =>
      _revisar('aceptar', () => super.aceptarOferta(id));
}

Future<ControladorConFallas> controladorConFallas(Map<String, ManejadorRuta> rutas) async {
  cargarEntornoDePrueba();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final controlador = ControladorConFallas(
    ClienteApi(cliente: clienteRuteado({'POST /api/sesiones': sesionAna, ...rutas})),
    prefs,
  );
  await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return controlador;
}

Future<void> montarPerfilYDestinos(
  WidgetTester tester,
  Widget pantalla,
  ControladorAutenticacion controlador,
) async {
  await montarPantallaEnRuta(
    tester,
    pantalla,
    controlador,
    rutasExtra: ['/perfil', '/feed'],
  );
}

String fechaLocal(String iso) {
  final fecha = DateTime.parse(iso).toLocal();
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

Future<void> tocarIcono(WidgetTester tester, IconData icono) async {
  await tester.tap(find.byIcon(icono).first);
  await tester.pumpAndSettle();
}

Future<(ControladorAutenticacion, Completer<http.Response>)> controladorLento(
  Map<String, ManejadorRuta> rutas,
  String claveLenta,
) async {
  cargarEntornoDePrueba();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final espera = Completer<http.Response>();
  final cliente = MockClient((peticion) {
    final clave = '${peticion.method} ${peticion.url.path}';
    if (clave == claveLenta) return espera.future;
    if (clave == 'POST /api/sesiones') return Future.value(sesionAna(peticion));
    final manejador = rutas[clave];
    if (manejador == null) return Future.value(respuestaJson({}));
    return Future.value(manejador(peticion));
  });
  final controlador = ControladorAutenticacion(ClienteApi(cliente: cliente), prefs);
  await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return (controlador, espera);
}
