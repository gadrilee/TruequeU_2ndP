import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/configuracion.dart';
import 'package:trueque_u/main.dart' as app;
import 'package:trueque_u/pantallas/pantalla_inicio.dart';

void simularEnv(WidgetTester tester, String contenido) {
  rootBundle.evict('.env');
  tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (mensaje) async {
    final clave = utf8.decode(mensaje!.buffer.asUint8List(mensaje.offsetInBytes, mensaje.lengthInBytes));
    if (clave != '.env') return null;
    final bytes = utf8.encode(contenido);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null));
}

void main() {
  testWidgets('main arranca la app con el servidor del .env y sin sesion guardada', (tester) async {
    SharedPreferences.setMockInitialValues({});
    simularEnv(tester, 'API_URL=https://servidor.test');

    await tester.runAsync(app.main);
    await tester.pumpAndSettle();

    expect(ConfiguracionEntorno.urlBase, 'https://servidor.test/api');
    expect(find.byType(app.AplicacionTruequeU), findsOneWidget);
    expect(find.byType(PantallaInicio), findsOneWidget);
    expect(Localizations.localeOf(tester.element(find.byType(PantallaInicio))).languageCode, 'es');
    app.manejadorSemantica.dispose();
  });

  testWidgets('main avisa cuando el .env no trae API_URL', (tester) async {
    SharedPreferences.setMockInitialValues({});
    simularEnv(tester, 'OTRA=1');

    await tester.runAsync(app.main);
    await tester.pumpAndSettle();

    expect(ConfiguracionEntorno.usaServidorLocal, true);
    expect(find.byType(app.AplicacionTruequeU), findsOneWidget);
    app.manejadorSemantica.dispose();
  });
}
