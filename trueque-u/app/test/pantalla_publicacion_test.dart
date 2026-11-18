// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/Publicacion.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

Future<void> montarFormulario(WidgetTester tester, ControladorAutenticacion controlador) {
  return montarPantallaEnRuta(tester, PantallaPublicacion(), controlador);
}

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Map<String, ManejadorRuta> crearOk() {
  return {'POST /api/publicaciones': (_) => respuestaJson({})};
}

void main() {
  setUp(cargarEntornoDePrueba);

  group('validacion', () {
    testWidgets('el nombre es obligatorio y tiene limites', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);

      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Escribe el nombre del objeto'), findsOneWidget);

      await tester.enterText(campo('Nombre del objeto'), 'a');
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Mínimo 2 letras'), findsOneWidget);

      await tester.enterText(campo('Nombre del objeto'), 'a' * 151);
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Máximo 150 caracteres'), findsOneWidget);
    });
  });

  group('guardar', () {
    testWidgets('crea la publicacion con estado y categoria elegidos', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(crearOk(), registro: registro);
      await montarFormulario(tester, controlador);

      await tester.enterText(campo('Nombre del objeto'), 'Chaqueta');
      await tester.enterText(campo('Descripción (opcional)'), 'Talla M');
      await tocar(tester, find.text('Nuevo'));
      await tocar(tester, find.text('Usado').last);
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.text('Ropa').last);
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(find.text('Destino /mis-publicaciones'), findsOneWidget);
      final peticion = registro.firstWhere((p) => p.url.path == '/api/publicaciones' && p.method == 'POST');
      expect(jsonDecode(peticion.body), {
        'titulo': 'Chaqueta',
        'descripcion': 'Talla M',
        'estado': 'usado',
        'categoria': 'ropa',
      });
    });

    testWidgets('si el servidor rechaza muestra el error', (tester) async {
      final controlador = await controladorConSesion({
        'POST /api/publicaciones': (_) => respuestaJson({'error': 'Titulo repetido'}, 409),
      });
      await montarFormulario(tester, controlador);

      await tester.enterText(campo('Nombre del objeto'), 'Chaqueta');
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(find.text('Titulo repetido'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla({});
      await montarFormulario(tester, controlador);

      await tester.enterText(campo('Nombre del objeto'), 'Chaqueta');
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(find.text('Ocurrió un error al guardar la publicación'), findsOneWidget);
    });
  });

  group('foto', () {
    testWidgets('elegir, cambiar y quitar la foto', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(crearOk(), registro: registro);
      await montarFormulario(tester, controlador);
      elegirArchivoFalso(base64Decode(pngPrueba), 'foto.png');

      await tocar(tester, find.text('Elegir foto'));
      expect(find.text('Cambiar foto'), findsOneWidget);

      await tester.enterText(campo('Nombre del objeto'), 'Chaqueta');
      await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
      final peticion = registro.firstWhere((p) => p.url.path == '/api/publicaciones' && p.method == 'POST');
      expect(jsonDecode(peticion.body)['imagen'], 'data:image/png;base64,$pngPrueba');
    });

    testWidgets('quitar foto vuelve al estado sin foto', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);
      elegirArchivoFalso(base64Decode(pngPrueba), 'foto.png');
      await tocar(tester, find.text('Elegir foto'));

      await tocar(tester, find.text('Quitar foto'));

      expect(find.text('Elegir foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('si no se elige nada no cambia nada', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);
      elegirArchivoFalso(null, '');

      await tocar(tester, find.text('Elegir foto'));

      expect(find.text('Elegir foto'), findsOneWidget);
    });

    testWidgets('una foto que no es jpg ni png muestra el error', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);
      elegirArchivoFalso(Uint8List.fromList([1]), 'foto.gif');

      await tocar(tester, find.text('Elegir foto'));

      expect(find.text('La foto tiene que ser jpg o png'), findsOneWidget);
    });
  });

  group('salir', () {
    testWidgets('cancelar vuelve a mis publicaciones', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(find.text('Destino /mis-publicaciones'), findsOneWidget);
    });

    testWidgets('la flecha vuelve a mis publicaciones', (tester) async {
      final controlador = await controladorConSesion({});
      await montarFormulario(tester, controlador);

      await tocar(tester, find.byIcon(Icons.arrow_back));

      expect(find.text('Destino /mis-publicaciones'), findsOneWidget);
    });
  });
}
