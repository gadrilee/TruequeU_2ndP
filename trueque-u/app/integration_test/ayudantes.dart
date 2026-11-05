import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/main.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

const eudenia = ['eudeniaflores@gmail.com', 'eude1234'];
const job = ['contrerasjob123@gmail.com', 'contreras123'];
const carlos = ['carlosmamani@ejemplo.com', 'carlos1234'];

Future<void> reiniciarBase() async {
  final respuesta = await http.post(Uri.parse('http://localhost:3100/reiniciar'));
  if (respuesta.statusCode != 200) {
    throw TestFailure('No se pudo reiniciar la base de datos');
  }
}

Future<void> abrirApp(WidgetTester tester) async {
  await reiniciarBase();
  SharedPreferences.setMockInitialValues({});
  dotenv.testLoad(fileInput: 'api_url=http://localhost:3000');
  final preferencias = await SharedPreferences.getInstance();
  final autenticacion = ControladorAutenticacion(ClienteApi(), preferencias);
  await autenticacion.restaurarSesion();
  await tester.pumpWidget(AplicacionTruequeU(autenticacion: autenticacion));
  await tester.pumpAndSettle();
}

Future<void> esperarTexto(WidgetTester tester, String texto) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(texto).evaluate().isNotEmpty) return;
  }
  throw TestFailure('No apareció el texto "$texto"');
}

Future<void> tocar(WidgetTester tester, Finder boton) async {
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<void> tocarBoton(WidgetTester tester, String texto) async {
  final tipos = [FilledButton, OutlinedButton, TextButton];
  for (final tipo in tipos) {
    final boton = find.widgetWithText(tipo, texto);
    if (boton.evaluate().isNotEmpty) {
      await tocar(tester, boton.last);
      return;
    }
  }
  await tocar(tester, find.text(texto).last);
}

Future<void> escribir(WidgetTester tester, String campo, String texto) async {
  final caja = find.widgetWithText(TextFormField, campo);
  await tester.ensureVisible(caja);
  await tester.enterText(caja, texto);
  await tester.pumpAndSettle();
}

Future<void> irARuta(WidgetTester tester, String ruta) async {
  final contexto = tester.element(find.byType(Scaffold).first);
  GoRouter.of(contexto).go(ruta);
  await tester.pumpAndSettle();
}

Future<void> iniciarSesion(WidgetTester tester, List<String> persona) async {
  await tocarBoton(tester, 'Iniciar sesión');
  await escribir(tester, 'Correo', persona[0]);
  await escribir(tester, 'Contraseña', persona[1]);
  await tocarBoton(tester, 'Entrar');
  await esperarTexto(tester, 'Mi perfil');
  await tester.pumpAndSettle();
}

Future<void> abrirAppConSesion(WidgetTester tester, List<String> persona) async {
  await abrirApp(tester);
  await iniciarSesion(tester, persona);
}

Future<void> cerrarSesion(WidgetTester tester) async {
  await tocarBoton(tester, 'Cerrar sesión');
  await esperarTexto(tester, 'Entrar');
}

Future<void> buscarEnElFeed(WidgetTester tester, String titulo) async {
  final caja = find.widgetWithText(TextField, 'Buscar por título');
  await tocar(tester, caja);
  await tester.enterText(caja, titulo);
  await tester.pumpAndSettle();
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
  await esperarTexto(tester, 'Título: $titulo');
  await tester.pumpAndSettle();
}

Future<void> abrirFeed(WidgetTester tester) async {
  await tocarBoton(tester, 'Explorar publicaciones');
  await esperarTexto(tester, 'Publicaciones');
  await tester.pumpAndSettle();
}

Finder enTarjeta(String texto, Finder buscado) {
  return find.descendant(of: find.widgetWithText(Card, texto), matching: buscado);
}

Future<void> crearCuenta(
  WidgetTester tester,
  String nombre,
  String correo,
  String contrasena,
) async {
  await tocarBoton(tester, 'Crear cuenta');
  await escribir(tester, 'Nombre completo', nombre);
  await escribir(tester, 'Correo', correo);
  await escribir(tester, 'Contraseña', contrasena);
  await escribir(tester, 'Repite la contraseña', contrasena);
  await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
  await esperarTexto(tester, 'Mi perfil');
  await tester.pumpAndSettle();
}

Future<void> cambiarDeUsuario(WidgetTester tester, List<String> persona) async {
  await cerrarSesion(tester);
  await irARuta(tester, '/');
  await iniciarSesion(tester, persona);
}

Future<void> abrirOfertas(WidgetTester tester) async {
  await tocarBoton(tester, 'Ofertas de trueque');
  await tester.pumpAndSettle();
}

const mensajeAceptar = 'Aceptaste el trueque. Ahora cada uno confirma la entrega';
const mensajePrimeraConfirmacion = 'Confirmaste tu entrega. Falta que la otra persona confirme';
const mensajeCompletado = 'Intercambio completado. Las dos partes confirmaron la entrega';

Future<void> confirmarEntrega(WidgetTester tester, String mensaje) async {
  await tocarBoton(tester, 'Confirmar entrega');
  await tocarBoton(tester, 'Confirmar');
  await esperarTexto(tester, mensaje);
}

Future<http.Response> pedirApi(
  String metodo,
  String ruta,
  List<String> persona, [
  Map<String, dynamic>? cuerpo,
]) async {
  const cabeceras = {'Content-Type': 'application/json'};
  final sesion = await http.post(
    Uri.parse('http://localhost:3000/api/sesiones'),
    headers: cabeceras,
    body: jsonEncode({'correo': persona[0], 'contrasena': persona[1]}),
  );
  final token = jsonDecode(sesion.body)['token'];
  final conToken = {...cabeceras, 'Authorization': 'Bearer $token'};
  final direccion = Uri.parse('http://localhost:3000/api$ruta');
  if (metodo == 'GET') return http.get(direccion, headers: conToken);
  if (metodo == 'PUT') return http.put(direccion, headers: conToken, body: jsonEncode(cuerpo ?? {}));
  return http.post(direccion, headers: conToken, body: jsonEncode(cuerpo ?? {}));
}
