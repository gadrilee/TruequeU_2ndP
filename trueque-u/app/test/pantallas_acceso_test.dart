// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_cambiar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_iniciar_sesion.dart';
import 'package:trueque_u/pantallas/pantalla_inicio.dart';
import 'package:trueque_u/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_registro.dart';

import 'ayudantes/montar.dart';

Future<GoRouter> montarPantalla(
  WidgetTester tester,
  String ruta,
  Widget pantalla, {
  ControladorAutenticacion? controlador,
}) {
  usarPantallaGrande(tester);
  return montarConRuteador(
    tester,
    inicial: ruta,
    controlador: controlador,
    rutas: [
      GoRoute(path: ruta, builder: (context, estado) => pantalla),
      for (final destino in [
        '/iniciar-sesion',
        '/registro',
        '/recuperar-contrasena',
        '/feed',
        '/perfil',
      ])
        if (destino != ruta) rutaMarcada(destino),
    ],
  );
}

Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
  await tester.enterText(find.widgetWithText(TextFormField, etiqueta), texto);
}

Future<void> tocarBoton(WidgetTester tester, String texto) async {
  final boton = find.widgetWithText(FilledButton, texto);
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<ControladorAutenticacion> controladorConRespuesta(
  String metodo,
  String ruta,
  http.Response Function() respuesta,
) {
  return crearControlador(clienteRuteado({'$metodo $ruta': (_) => respuesta()}));
}

void main() {
  setUp(cargarEntornoDePrueba);

  group('PantallaInicio', () {
    testWidgets('muestra la presentacion y los dos botones', (tester) async {
      await montarPantalla(tester, '/', PantallaInicio());

      expect(find.text('Trueque U'), findsWidgets);
      expect(find.textContaining('Intercambia objetos'), findsOneWidget);
    });

    testWidgets('Iniciar sesion lleva al login', (tester) async {
      await montarPantalla(tester, '/', PantallaInicio());

      await tocarBoton(tester, 'Iniciar sesión');

      expect(find.text('Destino /iniciar-sesion'), findsOneWidget);
    });

    testWidgets('Crear cuenta lleva al registro', (tester) async {
      await montarPantalla(tester, '/', PantallaInicio());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /registro'), findsOneWidget);
    });
  });

  group('PantallaIniciarSesion', () {
    testWidgets('valida los campos vacios', (tester) async {
      await montarPantalla(tester, '/iniciar-sesion', PantallaIniciarSesion());

      await tocarBoton(tester, 'Iniciar sesión');

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.text('Escribe tu contraseña'), findsOneWidget);
    });

    testWidgets('rechaza un correo con formato invalido', (tester) async {
      await montarPantalla(tester, '/iniciar-sesion', PantallaIniciarSesion());

      await escribir(tester, 'Correo', 'sin-arroba');
      await escribir(tester, 'Contraseña', 'secreto1');
      await tocarBoton(tester, 'Iniciar sesión');

      expect(find.text('Correo no válido'), findsOneWidget);
    });

    testWidgets('con datos correctos entra y va al feed', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/sesiones',
        () => respuestaJson({
          'token': 'tok',
          'usuario': {'id': 7, 'nombre': 'Ana'},
        }),
      );
      await montarPantalla(
        tester,
        '/iniciar-sesion',
        PantallaIniciarSesion(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'secreto1');
      await tocarBoton(tester, 'Iniciar sesión');

      expect(controlador.autenticado, isTrue);
      expect(find.text('Destino /feed'), findsOneWidget);
    });

    testWidgets('con error del servidor muestra el mensaje y se queda', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/sesiones',
        () => respuestaJson({'error': 'Datos incorrectos'}, 401),
      );
      await montarPantalla(
        tester,
        '/iniciar-sesion',
        PantallaIniciarSesion(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'mala');
      await tocarBoton(tester, 'Iniciar sesión');

      expect(find.text('Datos incorrectos'), findsOneWidget);
      expect(find.text('Destino /feed'), findsNothing);
      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('mientras espera deshabilita el boton y muestra el indicador', (tester) async {
      final espera = Completer<http.Response>();
      final controlador = await crearControlador(MockClient((_) => espera.future));
      await montarPantalla(
        tester,
        '/iniciar-sesion',
        PantallaIniciarSesion(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'secreto1');
      final boton = find.byType(FilledButton);
      await tester.tap(boton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);

      espera.complete(respuestaJson({'error': 'Datos incorrectos'}, 401));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('enviar desde el teclado inicia sesion', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/sesiones',
        () => respuestaJson({
          'token': 'tok',
          'usuario': {'id': 7, 'nombre': 'Ana'},
        }),
      );
      await montarPantalla(
        tester,
        '/iniciar-sesion',
        PantallaIniciarSesion(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'secreto1');
      await tester.tap(find.widgetWithText(TextFormField, 'Contraseña'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Destino /feed'), findsOneWidget);
    });

    testWidgets('el enlace de contrasena olvidada lleva a recuperar', (tester) async {
      await montarPantalla(tester, '/iniciar-sesion', PantallaIniciarSesion());

      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /recuperar-contrasena'), findsOneWidget);
    });

    testWidgets('el enlace del pie lleva al registro', (tester) async {
      await montarPantalla(tester, '/iniciar-sesion', PantallaIniciarSesion());

      await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /registro'), findsOneWidget);
    });

    testWidgets('el ojo muestra y oculta la contrasena', (tester) async {
      await montarPantalla(tester, '/iniciar-sesion', PantallaIniciarSesion());

      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();

      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });
  });

  group('PantallaRegistro', () {
    Future<void> llenar(WidgetTester tester, {String telefono = '', String repetida = 'secreto1'}) async {
      await escribir(tester, 'Nombre completo', 'Ana Perez');
      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Teléfono (opcional, 8 dígitos)', telefono);
      await escribir(tester, 'Contraseña', 'secreto1');
      await escribir(tester, 'Repite la contraseña', repetida);
    }

    testWidgets('valida los campos vacios', (tester) async {
      await montarPantalla(tester, '/registro', PantallaRegistro());

      await tocarBoton(tester, 'Crear cuenta');

      expect(find.text('Escribe tu nombre'), findsOneWidget);
      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('valida telefono y contrasenas distintas', (tester) async {
      await montarPantalla(tester, '/registro', PantallaRegistro());

      await llenar(tester, telefono: '123', repetida: 'otra-cosa');
      await tocarBoton(tester, 'Crear cuenta');

      expect(find.text('El teléfono debe tener 8 dígitos'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('con datos validos crea la cuenta y va al feed', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/usuarios',
        () => respuestaJson({
          'token': 'tok',
          'usuario': {'id': 7, 'nombre': 'Ana Perez'},
        }, 201),
      );
      await montarPantalla(tester, '/registro', PantallaRegistro(), controlador: controlador);

      await llenar(tester, telefono: '12345678');
      await tocarBoton(tester, 'Crear cuenta');

      expect(controlador.autenticado, isTrue);
      expect(find.text('Destino /feed'), findsOneWidget);
    });

    testWidgets('con error del servidor muestra el mensaje', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/usuarios',
        () => respuestaJson({'error': 'Ese correo ya existe'}, 409),
      );
      await montarPantalla(tester, '/registro', PantallaRegistro(), controlador: controlador);

      await llenar(tester);
      await tocarBoton(tester, 'Crear cuenta');

      expect(find.text('Ese correo ya existe'), findsOneWidget);
      expect(find.text('Destino /feed'), findsNothing);
    });

    testWidgets('enviar desde el teclado crea la cuenta', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/usuarios',
        () => respuestaJson({
          'token': 'tok',
          'usuario': {'id': 7, 'nombre': 'Ana Perez'},
        }, 201),
      );
      await montarPantalla(tester, '/registro', PantallaRegistro(), controlador: controlador);

      await llenar(tester);
      await tester.tap(find.widgetWithText(TextFormField, 'Repite la contraseña'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Destino /feed'), findsOneWidget);
    });

    testWidgets('la flecha y el enlace del pie llevan al login', (tester) async {
      await montarPantalla(tester, '/registro', PantallaRegistro());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Destino /iniciar-sesion'), findsOneWidget);
    });

    testWidgets('el enlace Inicia sesion lleva al login', (tester) async {
      await montarPantalla(tester, '/registro', PantallaRegistro());

      await tester.tap(find.widgetWithText(TextButton, 'Inicia sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /iniciar-sesion'), findsOneWidget);
    });
  });

  group('PantallaRecuperarContrasena', () {
    testWidgets('valida el correo', (tester) async {
      await montarPantalla(tester, '/recuperar-contrasena', PantallaRecuperarContrasena());

      await tocarBoton(tester, 'Enviar contraseña nueva');

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.textContaining('Listo. Revisa tu correo'), findsNothing);
    });

    testWidgets('con correo valido muestra el aviso de enviado', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/recuperaciones',
        () => respuestaJson({'mensaje': 'ok'}),
      );
      await montarPantalla(
        tester,
        '/recuperar-contrasena',
        PantallaRecuperarContrasena(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await tocarBoton(tester, 'Enviar contraseña nueva');

      expect(find.textContaining('Listo. Revisa tu correo'), findsOneWidget);
    });

    testWidgets('con error del servidor muestra el mensaje', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/recuperaciones',
        () => respuestaJson({'error': 'No existe esa cuenta'}, 404),
      );
      await montarPantalla(
        tester,
        '/recuperar-contrasena',
        PantallaRecuperarContrasena(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await tocarBoton(tester, 'Enviar contraseña nueva');

      expect(find.text('No existe esa cuenta'), findsOneWidget);
      expect(find.textContaining('Listo. Revisa tu correo'), findsNothing);
    });

    testWidgets('enviar desde el teclado pide la contrasena nueva', (tester) async {
      final controlador = await controladorConRespuesta(
        'POST',
        '/api/recuperaciones',
        () => respuestaJson({'mensaje': 'ok'}),
      );
      await montarPantalla(
        tester,
        '/recuperar-contrasena',
        PantallaRecuperarContrasena(),
        controlador: controlador,
      );

      await escribir(tester, 'Correo', 'ana@correo.com');
      await tester.tap(find.widgetWithText(TextFormField, 'Correo'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.textContaining('Listo. Revisa tu correo'), findsOneWidget);
    });

    testWidgets('la flecha y el boton del pie vuelven al login', (tester) async {
      final ruteador = await montarPantalla(
        tester,
        '/recuperar-contrasena',
        PantallaRecuperarContrasena(),
      );

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(find.text('Destino /iniciar-sesion'), findsOneWidget);

      ruteador.go('/recuperar-contrasena');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver a iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Destino /iniciar-sesion'), findsOneWidget);
    });
  });

  group('PantallaCambiarContrasena', () {
    Future<void> llenar(WidgetTester tester, {String repetida = 'nueva123'}) async {
      await escribir(tester, 'Contraseña actual', 'vieja123');
      await escribir(tester, 'Contraseña nueva', 'nueva123');
      await escribir(tester, 'Repite la contraseña nueva', repetida);
    }

    testWidgets('valida los campos', (tester) async {
      await montarPantalla(tester, '/cambiar-contrasena', PantallaCambiarContrasena());

      await tocarBoton(tester, 'Guardar');

      expect(find.text('Escribe tu contraseña actual'), findsOneWidget);
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('valida que las nuevas coincidan', (tester) async {
      await montarPantalla(tester, '/cambiar-contrasena', PantallaCambiarContrasena());

      await llenar(tester, repetida: 'distinta1');
      await tocarBoton(tester, 'Guardar');

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('al guardar avisa y vuelve al perfil', (tester) async {
      final controlador = await controladorConRespuesta(
        'PUT',
        '/api/usuarios/contrasena',
        () => respuestaJson({'mensaje': 'ok'}),
      );
      await montarPantalla(
        tester,
        '/cambiar-contrasena',
        PantallaCambiarContrasena(),
        controlador: controlador,
      );

      await llenar(tester);
      await tocarBoton(tester, 'Guardar');

      expect(find.text('Destino /perfil'), findsOneWidget);
      expect(find.text('Contraseña actualizada.'), findsOneWidget);
    });

    testWidgets('con error del servidor muestra el mensaje', (tester) async {
      final controlador = await controladorConRespuesta(
        'PUT',
        '/api/usuarios/contrasena',
        () => respuestaJson({'error': 'La contraseña actual no coincide'}, 401),
      );
      await montarPantalla(
        tester,
        '/cambiar-contrasena',
        PantallaCambiarContrasena(),
        controlador: controlador,
      );

      await llenar(tester);
      await tocarBoton(tester, 'Guardar');

      expect(find.text('La contraseña actual no coincide'), findsOneWidget);
      expect(find.text('Destino /perfil'), findsNothing);
    });

    testWidgets('enviar desde el teclado guarda el cambio', (tester) async {
      final controlador = await controladorConRespuesta(
        'PUT',
        '/api/usuarios/contrasena',
        () => respuestaJson({'mensaje': 'ok'}),
      );
      await montarPantalla(
        tester,
        '/cambiar-contrasena',
        PantallaCambiarContrasena(),
        controlador: controlador,
      );

      await llenar(tester);
      await tester.tap(find.widgetWithText(TextFormField, 'Repite la contraseña nueva'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Destino /perfil'), findsOneWidget);
    });

    testWidgets('Cancelar vuelve al perfil', (tester) async {
      await montarPantalla(tester, '/cambiar-contrasena', PantallaCambiarContrasena());

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /perfil'), findsOneWidget);
    });
  });
}
