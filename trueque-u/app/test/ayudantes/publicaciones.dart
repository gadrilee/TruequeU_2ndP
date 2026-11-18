import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/servicios/cliente_api.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'montar.dart';

const pngPrueba =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class SelectorFotoFalso extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  SelectorFotoFalso(this.archivo);

  final XFile? archivo;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return archivo;
  }
}

void elegirArchivoFalso(Uint8List? bytes, String nombre) {
  final archivo = bytes == null ? null : XFile.fromData(bytes, name: nombre, path: nombre);
  ImagePickerPlatform.instance = SelectorFotoFalso(archivo);
}

class LanzadorWhatsappFalso extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final enlaces = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    enlaces.add(url);
    return true;
  }
}

class ControladorQueFalla extends ControladorAutenticacion {
  ControladorQueFalla(super.api, super.preferencias);

  @override
  Future<void> reservarPublicacion(int id) async => throw StateError('falla');

  @override
  Future<void> descartarReservaPublicacion(int id) async => throw StateError('falla');

  @override
  Future<void> completarIntercambio(int id) async => throw StateError('falla');

  @override
  Future<String> crearOferta({
    required int idPublicacionPedida,
    required int idPublicacionOfrecida,
  }) async => throw StateError('falla');

  @override
  Future<void> cambiarEstadoPublicacion(int id, String nuevoEstado) async =>
      throw StateError('falla');

  @override
  Future<void> editarPublicacion(
    int id, {
    required String titulo,
    String? descripcion,
    String? imagen,
    bool quitarImagen = false,
  }) async => throw StateError('falla');

  @override
  Future<void> crearPublicacion({
    required String titulo,
    String? descripcion,
    required String estado,
    required String categoria,
    String? imagen,
  }) async => throw StateError('falla');
}

Map<String, dynamic> publicacion(
  int id, {
  String? titulo,
  String? descripcion,
  String estadoPublicacion = 'disponible',
  String estado = 'nuevo',
  String categoria = 'libros',
  int idUsuario = 8,
  String nombreAutor = 'Beto',
  String? telefonoAutor,
  int? idReserva,
  String? nombreReserva,
  String? telefonoReserva,
  bool ofertaEnviada = false,
  String? imagenUrl,
}) {
  return {
    'id': id,
    'titulo': titulo ?? 'Objeto $id',
    'descripcion': descripcion,
    'estado': estado,
    'categoria': categoria,
    'estado_publicacion': estadoPublicacion,
    'id_usuario': idUsuario,
    'autor': {
      'nombre': nombreAutor,
      if (telefonoAutor != null) 'telefono': telefonoAutor,
    },
    'id_usuario_reserva': idReserva,
    'usuario_reserva': nombreReserva == null
        ? null
        : {
            'nombre': nombreReserva,
            if (telefonoReserva != null) 'telefono': telefonoReserva,
          },
    'oferta_enviada': ofertaEnviada,
    'imagen_url': imagenUrl,
  };
}

http.Response sesionAna(http.Request peticion) {
  return respuestaJson({
    'token': 'tok-prueba',
    'usuario': {'id': 7, 'nombre': 'Ana Perez', 'correo': 'ana@correo.com'},
  });
}

Future<ControladorAutenticacion> controladorConSesion(
  Map<String, ManejadorRuta> rutas, {
  List<http.Request>? registro,
}) async {
  final controlador = await crearControlador(
    clienteRuteado({'POST /api/sesiones': sesionAna, ...rutas}, registro: registro),
  );
  await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return controlador;
}

Future<ControladorQueFalla> controladorQueFalla(Map<String, ManejadorRuta> rutas) async {
  cargarEntornoDePrueba();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final controlador = ControladorQueFalla(
    ClienteApi(cliente: clienteRuteado({'POST /api/sesiones': sesionAna, ...rutas})),
    prefs,
  );
  await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return controlador;
}

Future<void> tocar(WidgetTester tester, Finder buscado) async {
  await tester.ensureVisible(buscado);
  await tester.tap(buscado);
  await tester.pumpAndSettle();
}

Future<void> confirmar(WidgetTester tester, String texto) async {
  await tester.tap(find.widgetWithText(FilledButton, texto));
  await tester.pumpAndSettle();
}

void usarAncho(WidgetTester tester, double ancho) {
  tester.view.physicalSize = Size(ancho, 2000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<GoRouter> montarPantallaEnRuta(
  WidgetTester tester,
  Widget pantalla,
  ControladorAutenticacion controlador, {
  double ancho = 900,
}) {
  usarAncho(tester, ancho);
  return montarConRuteador(
    tester,
    controlador: controlador,
    rutas: [
      GoRoute(path: '/', builder: (context, estado) => pantalla),
      rutaMarcada('/publicacion'),
      rutaMarcada('/mis-publicaciones'),
      rutaMarcada('/ofertas'),
    ],
  );
}
