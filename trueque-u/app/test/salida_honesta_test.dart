import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_registro.dart';
import 'package:trueque_u/servicios/analitica.dart';
import 'package:trueque_u/servicios/cliente_api.dart';
import 'package:trueque_u/widgets/dialogo_eliminar_cuenta.dart';

const clavesPersonales = ['correo', 'nombre', 'telefono', 'id_usuario', 'email'];

Future<ControladorAutenticacion> crearControlador(http.Client cliente) async {
  SharedPreferences.setMockInitialValues({});
  final preferencias = await SharedPreferences.getInstance();
  return ControladorAutenticacion(ClienteApi(cliente: cliente), preferencias);
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('los botones del dialogo de eliminar cuenta miden lo mismo', (tester) async {
    final controlador = await crearControlador(MockClient((_) async => http.Response('{}', 200)));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controlador,
        child: const MaterialApp(home: Scaffold(body: DialogoEliminarCuenta())),
      ),
    );

    final cancelar = find.byKey(const Key('boton-cancelar-eliminar'));
    final eliminar = find.byKey(const Key('boton-confirmar-eliminar'));
    expect(tester.widget(cancelar).runtimeType, tester.widget(eliminar).runtimeType);
    expect(tester.getSize(cancelar), tester.getSize(eliminar));
  });

  testWidgets('una contrasena incorrecta muestra el error y registra el bloqueo sin datos personales',
      (tester) async {
    final eventos = <Map<String, dynamic>>[];
    final controlador = await crearControlador(MockClient((peticion) async {
      if (peticion.url.path == '/api/eventos') {
        eventos.add(jsonDecode(peticion.body) as Map<String, dynamic>);
        return http.Response('{}', 201);
      }
      return http.Response(jsonEncode({'error': 'La contraseña no es correcta'}), 401);
    }));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controlador,
        child: const MaterialApp(home: Scaffold(body: DialogoEliminarCuenta())),
      ),
    );
    await tester.enterText(find.byType(TextField), 'mal');
    await tester.tap(find.byKey(const Key('boton-confirmar-eliminar')));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña no es correcta'), findsOneWidget);
    expect(eventos.length, 1);
    expect(eventos.first['evento'], 'eliminacion_cuenta_bloqueada');
    expect(eventos.first['props'], {'motivo': 'contrasena_incorrecta'});
  });

  testWidgets('el registro no trae casillas ni interruptores marcados de antemano', (tester) async {
    final controlador = await crearControlador(MockClient((_) async => http.Response('{}', 200)));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controlador,
        child: const MaterialApp(home: PantallaRegistro()),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      find.text('Solo lo verá la persona con la que acuerdes un trueque. Puedes dejarlo vacío.'),
      findsOneWidget,
    );
  });

  test('los eventos de este flujo no llevan datos personales', () async {
    final enviados = <Map<String, dynamic>>[];
    final api = ClienteApi(cliente: MockClient((peticion) async {
      enviados.add(jsonDecode(peticion.body) as Map<String, dynamic>);
      return http.Response('{}', 201);
    }));

    await track('datos_descargados', {'formato': 'csv'}, api);
    await track('eliminacion_cuenta_iniciada', {}, api);
    await track('eliminacion_cuenta_bloqueada', {'motivo': 'contrasena_incorrecta'}, api);

    expect(enviados.length, 3);
    for (final evento in enviados) {
      final claves = (evento['props'] as Map).keys;
      for (final clave in clavesPersonales) {
        expect(claves, isNot(contains(clave)));
      }
    }
  });
}
