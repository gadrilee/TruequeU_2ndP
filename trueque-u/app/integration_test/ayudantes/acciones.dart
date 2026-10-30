import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Espera a que la UI deje de animar (incluye respuestas de red cortas).
Future<void> esperarPantalla(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

/// Toca un texto visible y espera a que la pantalla responda.
Future<void> tocar(WidgetTester tester, String texto) async {
  final boton = find.text(texto);
  expect(boton, findsWidgets, reason: 'No aparece el texto "$texto"');
  await tester.ensureVisible(boton.first);
  await tester.tap(boton.first);
  await esperarPantalla(tester);
}

/// Campo de texto identificado por su etiqueta (label del InputDecoration).
Finder campoConEtiqueta(String etiqueta) {
  return find.byWidgetPredicate((widget) {
    if (widget is! TextField) return false;
    return widget.decoration?.labelText == etiqueta;
  });
}

/// Escribe en un campo de texto por su etiqueta.
Future<void> escribir(
  WidgetTester tester, {
  required String etiqueta,
  required String valor,
}) async {
  final campo = campoConEtiqueta(etiqueta);
  expect(campo, findsOneWidget, reason: 'No hay campo "$etiqueta"');
  await tester.ensureVisible(campo);
  await tester.enterText(campo, valor);
  await tester.pump();
}

/// Elige una opción de un desplegable (Estado o Categoría).
Future<void> elegirEnDesplegable(
  WidgetTester tester, {
  required String etiquetaActual,
  required String opcion,
}) async {
  await tester.tap(find.text(etiquetaActual).last);
  await esperarPantalla(tester);
  await tester.tap(find.text(opcion).last);
  await esperarPantalla(tester);
}

/// Inicia sesión con un usuario de prueba.
Future<void> iniciarSesion(
  WidgetTester tester, {
  required String correo,
  required String contrasena,
}) async {
  await tocar(tester, 'Iniciar sesión');
  await escribir(tester, etiqueta: 'Correo', valor: correo);
  await escribir(tester, etiqueta: 'Contraseña', valor: contrasena);
  await tocar(tester, 'Entrar');
  expect(find.text('Mi perfil'), findsOneWidget);
}
