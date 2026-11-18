// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/main.dart';
import 'package:trueque_u/pantallas/Publicacion.dart';
import 'package:trueque_u/pantallas/pantalla_avisos.dart';
import 'package:trueque_u/pantallas/pantalla_cambiar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_feed_publicaciones.dart';
import 'package:trueque_u/pantallas/pantalla_historial.dart';
import 'package:trueque_u/pantallas/pantalla_iniciar_sesion.dart';
import 'package:trueque_u/pantallas/pantalla_inicio.dart';
import 'package:trueque_u/pantallas/pantalla_intercambios.dart';
import 'package:trueque_u/pantallas/pantalla_mis_datos.dart';
import 'package:trueque_u/pantallas/pantalla_mis_publicaciones.dart';
import 'package:trueque_u/pantallas/pantalla_ofertas.dart';
import 'package:trueque_u/pantallas/pantalla_perfil.dart';
import 'package:trueque_u/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_registro.dart';
import 'package:trueque_u/rutas.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

import 'ayudantes/montar.dart';

MockClient servidorVacio() {
  return MockClient((peticion) async {
    if (peticion.method == 'POST' && peticion.url.path == '/api/sesiones') {
      return respuestaJson({
        'token': 'tok-prueba',
        'usuario': {'id': 7, 'nombre': 'Ana Perez', 'correo': 'ana@correo.com'},
      });
    }
    if (peticion.method == 'DELETE') return respuestaJson({});
    return respuestaJson([]);
  });
}

Future<ControladorAutenticacion> controlador({bool conSesion = false}) async {
  final controlador = await crearControlador(servidorVacio());
  if (conSesion) await controlador.iniciarSesion('ana@correo.com', 'secreto1');
  return controlador;
}

Future<GoRouter> montarRutas(WidgetTester tester, ControladorAutenticacion auth) async {
  usarPantallaGrande(tester);
  final ruteador = construirRutas(auth);
  await tester.pumpWidget(
    ChangeNotifierProvider<ControladorAutenticacion>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: ruteador),
    ),
  );
  await tester.pumpAndSettle();
  return ruteador;
}

Future<void> irA(WidgetTester tester, GoRouter ruteador, String ruta) async {
  ruteador.go(ruta);
  await tester.pumpAndSettle();
}

void main() {
  group('rutas publicas', () {
    testWidgets('empieza en el inicio', (tester) async {
      await montarRutas(tester, await controlador());

      expect(find.byType(PantallaInicio), findsOneWidget);
    });

    testWidgets('abre iniciar sesion, registro y recuperar sin sesion', (tester) async {
      final ruteador = await montarRutas(tester, await controlador());

      await irA(tester, ruteador, '/iniciar-sesion');
      expect(find.byType(PantallaIniciarSesion), findsOneWidget);

      await irA(tester, ruteador, '/registro');
      expect(find.byType(PantallaRegistro), findsOneWidget);

      await irA(tester, ruteador, '/recuperar-contrasena');
      expect(find.byType(PantallaRecuperarContrasena), findsOneWidget);
    });
  });

  group('rutas privadas sin sesion', () {
    for (final ruta in [
      '/perfil',
      '/cambiar-contrasena',
      '/publicacion',
      '/mis-publicaciones',
      '/feed',
      '/intercambios',
      '/ofertas',
      '/historial',
      '/mis-datos',
      '/avisos',
    ]) {
      testWidgets('$ruta redirige a iniciar sesion', (tester) async {
        final ruteador = await montarRutas(tester, await controlador());

        await irA(tester, ruteador, ruta);

        expect(find.byType(PantallaIniciarSesion), findsOneWidget);
      });
    }
  });

  group('rutas solo para invitados con sesion', () {
    for (final ruta in ['/iniciar-sesion', '/registro']) {
      testWidgets('$ruta redirige al feed', (tester) async {
        final ruteador = await montarRutas(tester, await controlador(conSesion: true));

        await irA(tester, ruteador, ruta);

        expect(find.byType(PantallaFeedPublicaciones), findsOneWidget);
      });
    }

    testWidgets('el inicio y recuperar contrasena siguen abiertos', (tester) async {
      final ruteador = await montarRutas(tester, await controlador(conSesion: true));

      expect(find.byType(PantallaInicio), findsOneWidget);
      await irA(tester, ruteador, '/recuperar-contrasena');
      expect(find.byType(PantallaRecuperarContrasena), findsOneWidget);
    });
  });

  group('rutas privadas con sesion', () {
    final pantallas = <String, Type>{
      '/cambiar-contrasena': PantallaCambiarContrasena,
      '/publicacion': PantallaPublicacion,
      '/intercambios': PantallaIntercambios,
      '/historial': PantallaHistorial,
      '/mis-datos': PantallaMisDatos,
      '/avisos': PantallaAvisos,
    };

    pantallas.forEach((ruta, tipo) {
      testWidgets('$ruta abre su pantalla', (tester) async {
        final ruteador = await montarRutas(tester, await controlador(conSesion: true));

        await irA(tester, ruteador, ruta);

        expect(find.byType(tipo), findsOneWidget);
      });
    });

    testWidgets('la barra inferior recorre las cuatro ramas', (tester) async {
      final ruteador = await montarRutas(tester, await controlador(conSesion: true));
      await irA(tester, ruteador, '/feed');
      expect(find.byType(PantallaFeedPublicaciones), findsOneWidget);

      await tester.tap(find.text('Mis publicaciones'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaMisPublicaciones), findsOneWidget);

      await tester.tap(find.text('Ofertas'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaOfertas), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaPerfil), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaPerfil), findsOneWidget);

      await tester.tap(find.text('Explorar'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaFeedPublicaciones), findsOneWidget);
    });

    testWidgets('al cerrar sesion en una ruta privada vuelve a iniciar sesion', (tester) async {
      final auth = await controlador(conSesion: true);
      final ruteador = await montarRutas(tester, auth);
      await irA(tester, ruteador, '/perfil');
      expect(find.byType(PantallaPerfil), findsOneWidget);

      await auth.cerrarSesion();
      await tester.pumpAndSettle();

      expect(find.byType(PantallaIniciarSesion), findsOneWidget);
    });
  });

  group('AplicacionTruequeU', () {
    testWidgets('muestra el inicio con el titulo y el tema de la app', (tester) async {
      final auth = await controlador();
      await tester.pumpWidget(AplicacionTruequeU(autenticacion: auth));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Trueque U');
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(find.byType(PantallaInicio), findsOneWidget);
      final contexto = tester.element(find.byType(PantallaInicio));
      expect(Provider.of<ControladorAutenticacion>(contexto, listen: false), same(auth));
    });

    testWidgets('con sesion restaurada permite entrar al feed', (tester) async {
      usarPantallaGrande(tester);
      cargarEntornoDePrueba();
      SharedPreferences.setMockInitialValues({'trueque_token': 'tok-guardado'});
      final prefs = await SharedPreferences.getInstance();
      final cliente = MockClient((peticion) async {
        if (peticion.url.path == '/api/sesiones/actual') {
          return respuestaJson({
            'usuario': {'id': 7, 'nombre': 'Ana Perez'},
          });
        }
        return respuestaJson([]);
      });
      final auth = ControladorAutenticacion(ClienteApi(cliente: cliente), prefs);
      await auth.restaurarSesion();

      await tester.pumpWidget(AplicacionTruequeU(autenticacion: auth));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(PantallaInicio))).go('/feed');
      await tester.pumpAndSettle();

      expect(find.byType(PantallaFeedPublicaciones), findsOneWidget);
    });
  });
}
