import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/widgets/dialogo_editar_publicacion.dart';
import 'package:trueque_u/widgets/foto_publicacion.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

const fotoInicial = 'data:image/png;base64,$pngPrueba';

class Resultado {
  bool? valor;
}

Future<Resultado> abrirDialogo(
  WidgetTester tester,
  ControladorAutenticacion controlador, {
  String? descripcion,
  String? imagen,
}) async {
  usarPantallaGrande(tester);
  final resultado = Resultado();
  await montarWidget(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          resultado.valor = await showDialog<bool>(
            context: context,
            builder: (ctx) => DialogoEditarPublicacion(
              id: 3,
              tituloInicial: 'Bici vieja',
              descripcionInicial: descripcion,
              imagenInicial: imagen,
            ),
          );
        },
        child: Text('Abrir'),
      ),
    ),
    controlador: controlador,
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

Map<String, ManejadorRuta> guardarOk() {
  return {'PUT /api/publicaciones/3': (_) => respuestaJson({})};
}

Finder campoTitulo() => find.widgetWithText(TextFormField, 'Nombre del objeto');

void main() {
  setUp(cargarEntornoDePrueba);

  group('formulario', () {
    testWidgets('muestra los datos iniciales', (tester) async {
      final controlador = await controladorConSesion({});

      await abrirDialogo(tester, controlador, descripcion: 'Con luces');

      expect(find.text('Bici vieja'), findsOneWidget);
      expect(find.text('Con luces'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('valida el nombre', (tester) async {
      final controlador = await controladorConSesion({});
      await abrirDialogo(tester, controlador);

      await tester.enterText(campoTitulo(), '   ');
      await confirmar(tester, 'Guardar');
      expect(find.text('Escribe el nombre del objeto'), findsOneWidget);

      await tester.enterText(campoTitulo(), 'a');
      await confirmar(tester, 'Guardar');
      expect(find.text('Mínimo 2 letras'), findsOneWidget);

      await tester.enterText(campoTitulo(), 'a' * 151);
      await confirmar(tester, 'Guardar');
      expect(find.text('Máximo 150 caracteres'), findsOneWidget);
    });

    testWidgets('cancelar cierra con false', (tester) async {
      final controlador = await controladorConSesion({});
      final resultado = await abrirDialogo(tester, controlador);

      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));

      expect(resultado.valor, isFalse);
    });
  });

  group('guardar', () {
    testWidgets('guarda y cierra con true', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(guardarOk(), registro: registro);
      final resultado = await abrirDialogo(tester, controlador);

      await tester.enterText(campoTitulo(), 'Bici nueva');
      await confirmar(tester, 'Guardar');

      expect(resultado.valor, isTrue);
      final peticion = registro.firstWhere((p) => p.method == 'PUT');
      expect(jsonDecode(peticion.body), {'titulo': 'Bici nueva', 'descripcion': null});
    });

    testWidgets('mientras guarda bloquea los botones y muestra progreso', (tester) async {
      final espera = Completer<void>();
      final cliente = MockClient((peticion) async {
        if (peticion.url.path == '/api/sesiones') return sesionAna(peticion);
        await espera.future;
        return respuestaJson({});
      });
      final controlador = await crearControlador(cliente);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');
      await abrirDialogo(tester, controlador);

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar')).onPressed, isNull);

      espera.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('si el servidor rechaza muestra el error y permite reintentar', (tester) async {
      final controlador = await controladorConSesion({
        'PUT /api/publicaciones/3': (_) => respuestaJson({'error': 'Publicación reservada'}, 409),
      });
      final resultado = await abrirDialogo(tester, controlador);

      await confirmar(tester, 'Guardar');

      expect(find.text('Publicación reservada'), findsOneWidget);
      expect(resultado.valor, isNull);
      expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);
    });

    testWidgets('un fallo inesperado muestra el mensaje general', (tester) async {
      final controlador = await controladorQueFalla({});
      await abrirDialogo(tester, controlador);

      await confirmar(tester, 'Guardar');

      expect(find.text('Ocurrió un error al actualizar la publicación'), findsOneWidget);
    });
  });

  group('foto', () {
    testWidgets('elegir una foto nueva la muestra y la envia', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(guardarOk(), registro: registro);
      await abrirDialogo(tester, controlador);
      elegirArchivoFalso(base64Decode(pngPrueba), 'foto.png');

      await tocar(tester, find.text('Cambiar foto'));

      expect(find.text('Quitar foto'), findsOneWidget);
      expect(tester.widget<FotoPublicacion>(find.byType(FotoPublicacion)).url, startsWith('data:image/png'));

      await confirmar(tester, 'Guardar');

      final peticion = registro.firstWhere((p) => p.method == 'PUT');
      expect(jsonDecode(peticion.body)['imagen'], 'data:image/png;base64,$pngPrueba');
    });

    testWidgets('quitar la foto actual avisa al servidor', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(guardarOk(), registro: registro);
      await abrirDialogo(tester, controlador, imagen: fotoInicial);

      await tocar(tester, find.text('Quitar foto'));

      expect(find.text('Quitar foto'), findsNothing);
      await confirmar(tester, 'Guardar');

      final peticion = registro.firstWhere((p) => p.method == 'PUT');
      expect(jsonDecode(peticion.body)['quitar_imagen'], isTrue);
    });

    testWidgets('elegir una foto despues de quitarla ya no quita nada', (tester) async {
      final registro = <http.Request>[];
      final controlador = await controladorConSesion(guardarOk(), registro: registro);
      await abrirDialogo(tester, controlador, imagen: fotoInicial);
      await tocar(tester, find.text('Quitar foto'));
      elegirArchivoFalso(base64Decode(pngPrueba), 'otra.jpg');

      await tocar(tester, find.text('Cambiar foto'));
      await confirmar(tester, 'Guardar');

      final cuerpo = jsonDecode(registro.firstWhere((p) => p.method == 'PUT').body);
      expect(cuerpo.containsKey('quitar_imagen'), isFalse);
      expect(cuerpo['imagen'], startsWith('data:image/jpeg;base64,'));
    });

    testWidgets('quitar una foto recien elegida vuelve a no tener foto', (tester) async {
      final controlador = await controladorConSesion({});
      await abrirDialogo(tester, controlador);
      elegirArchivoFalso(base64Decode(pngPrueba), 'foto.png');
      await tocar(tester, find.text('Cambiar foto'));

      await tocar(tester, find.text('Quitar foto'));

      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('si no se elige nada la foto sigue igual', (tester) async {
      final controlador = await controladorConSesion({});
      await abrirDialogo(tester, controlador);
      elegirArchivoFalso(null, '');

      await tocar(tester, find.text('Cambiar foto'));

      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('una foto que no es jpg ni png muestra el error', (tester) async {
      final controlador = await controladorConSesion({});
      await abrirDialogo(tester, controlador);
      elegirArchivoFalso(Uint8List.fromList([1]), 'foto.gif');

      await tocar(tester, find.text('Cambiar foto'));

      expect(find.text('La foto tiene que ser jpg o png'), findsOneWidget);
    });
  });
}
