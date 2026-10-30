import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pantalla de inicio', () {
    testWidgets('Un visitante ve la pantalla de inicio con sus dos opciones', (tester) async {
      await abrirApp(tester);

      expect(find.text('Intercambia objetos y materiales con otros estudiantes.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
    });

    testWidgets('Un visitante intenta abrir su perfil y lo mandan a iniciar sesión', (tester) async {
      await abrirApp(tester);

      await irARuta(tester, '/perfil');

      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
      expect(find.text('Mi perfil'), findsNothing);
    });
  });

  group('Iniciar sesión', () {
    testWidgets('Eudenia inicia sesión y ve su perfil', (tester) async {
      await abrirApp(tester);

      await iniciarSesion(tester, eudenia);

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
      expect(find.text('Mis publicaciones'), findsOneWidget);
    });

    testWidgets('Eudenia escribe mal su contraseña y ve el error', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Iniciar sesión');

      await escribir(tester, 'Correo', 'eudeniaflores@gmail.com');
      await escribir(tester, 'Contraseña', 'clave-equivocada');
      await tocarBoton(tester, 'Entrar');
      await esperarTexto(tester, 'Correo o contraseña incorrectos');

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      expect(find.text('Mi perfil'), findsNothing);
    });

    testWidgets('Eudenia deja los campos vacíos y la app le pide los datos', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Iniciar sesión');

      await tocarBoton(tester, 'Entrar');

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.text('Escribe tu contraseña'), findsOneWidget);
    });

    testWidgets('Eudenia cierra sesión desde su perfil', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await cerrarSesion(tester);

      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
      expect(find.text('Hola, Eudenia Flores Veizaga'), findsNothing);
    });
  });

  group('Crear cuenta', () {
    testWidgets('Ana crea su cuenta y entra a su perfil', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Crear cuenta');

      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Correo', 'ana@ejemplo.com');
      await escribir(tester, 'Teléfono (opcional, 8 dígitos)', '71234567');
      await escribir(tester, 'Contraseña', 'ana12345');
      await escribir(tester, 'Repite la contraseña', 'ana12345');
      await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
      await esperarTexto(tester, 'Mi perfil');

      expect(find.text('Hola, Ana Quispe'), findsOneWidget);
    });

    testWidgets('Ana escribe contraseñas distintas y la app se lo avisa', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Crear cuenta');

      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Correo', 'ana@ejemplo.com');
      await escribir(tester, 'Contraseña', 'ana12345');
      await escribir(tester, 'Repite la contraseña', 'otra-clave');
      await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(find.text('Mi perfil'), findsNothing);
    });

    testWidgets('Ana usa un teléfono de menos de 8 dígitos y la app lo rechaza', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Crear cuenta');

      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Correo', 'ana@ejemplo.com');
      await escribir(tester, 'Teléfono (opcional, 8 dígitos)', '123');
      await escribir(tester, 'Contraseña', 'ana12345');
      await escribir(tester, 'Repite la contraseña', 'ana12345');
      await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

      expect(find.text('El teléfono debe tener 8 dígitos'), findsOneWidget);
    });

    testWidgets('Ana intenta crear su cuenta con el correo de Eudenia y ve el error', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Crear cuenta');

      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Correo', 'eudeniaflores@gmail.com');
      await escribir(tester, 'Contraseña', 'ana12345');
      await escribir(tester, 'Repite la contraseña', 'ana12345');
      await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
      await esperarTexto(tester, 'Ya existe una cuenta con ese correo');

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
    });
  });

  group('Recuperar contraseña', () {
    testWidgets('Eudenia pide una contraseña nueva y la app le avisa que revise su correo', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Iniciar sesión');
      await tocarBoton(tester, '¿Olvidaste tu contraseña?');

      await escribir(tester, 'Correo', 'eudeniaflores@gmail.com');
      await tocarBoton(tester, 'Enviar contraseña nueva');
      await esperarTexto(tester, 'Listo. Revisa tu correo: ahí está tu contraseña nueva.');

      expect(find.text('Listo. Revisa tu correo: ahí está tu contraseña nueva.'), findsOneWidget);
    });

    testWidgets('Ana pide recuperar un correo que no existe y ve el error', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Iniciar sesión');
      await tocarBoton(tester, '¿Olvidaste tu contraseña?');

      await escribir(tester, 'Correo', 'ana@ejemplo.com');
      await tocarBoton(tester, 'Enviar contraseña nueva');
      await esperarTexto(tester, 'No existe una cuenta con ese correo');

      expect(find.text('No existe una cuenta con ese correo'), findsOneWidget);
    });

    testWidgets('Eudenia vuelve a iniciar sesión desde la pantalla de recuperar', (tester) async {
      await abrirApp(tester);
      await tocarBoton(tester, 'Iniciar sesión');
      await tocarBoton(tester, '¿Olvidaste tu contraseña?');

      await tocarBoton(tester, 'Volver a iniciar sesión');

      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    });
  });

  group('Cambiar contraseña', () {
    testWidgets('Eudenia cambia su contraseña y entra con la nueva', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Cambiar contraseña');

      await escribir(tester, 'Contraseña actual', 'eude1234');
      await escribir(tester, 'Contraseña nueva', 'nueva1234');
      await escribir(tester, 'Repite la contraseña nueva', 'nueva1234');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Contraseña actualizada.');
      await cerrarSesion(tester);
      await irARuta(tester, '/');
      await iniciarSesion(tester, ['eudeniaflores@gmail.com', 'nueva1234']);

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });

    testWidgets('Eudenia se equivoca con su contraseña actual y ve el error', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Cambiar contraseña');

      await escribir(tester, 'Contraseña actual', 'no-es-esta');
      await escribir(tester, 'Contraseña nueva', 'nueva1234');
      await escribir(tester, 'Repite la contraseña nueva', 'nueva1234');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'La contraseña actual no es correcta');

      expect(find.text('La contraseña actual no es correcta'), findsOneWidget);
    });

    testWidgets('Eudenia usa una contraseña nueva muy corta y la app se lo avisa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Cambiar contraseña');

      await escribir(tester, 'Contraseña actual', 'eude1234');
      await escribir(tester, 'Contraseña nueva', 'abc');
      await escribir(tester, 'Repite la contraseña nueva', 'abc');
      await tocarBoton(tester, 'Guardar');

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('Eudenia se arrepiente y cancela el cambio de contraseña', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Cambiar contraseña');

      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });
  });
}
