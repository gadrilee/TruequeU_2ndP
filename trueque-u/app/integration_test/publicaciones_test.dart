import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Publicar un objeto', () {
    testWidgets('Eudenia publica un libro usado y lo ve en sus publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Crear nueva publicación');

      await escribir(tester, 'Nombre del objeto', 'Algebra Lineal - Lay');
      await escribir(tester, 'Descripción (opcional)', 'Cuarta edicion, sin subrayar');
      await tocar(tester, find.text('Nuevo'));
      await tocar(tester, find.text('Usado').last);
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.text('Libros').last);
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación guardada exitosamente');

      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Algebra Lineal - Lay');

      expect(find.text('Total: 4'), findsOneWidget);
      expect(find.text('Cuarta edicion, sin subrayar'), findsOneWidget);
    });

    testWidgets('Eudenia deja el nombre vacío y la app se lo pide', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Crear nueva publicación');

      await tocarBoton(tester, 'Guardar');

      expect(find.text('Escribe el nombre del objeto'), findsOneWidget);
    });

    testWidgets('Eudenia cancela la publicación y vuelve a su perfil', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Crear nueva publicación');

      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });
  });

  group('Mis publicaciones', () {
    testWidgets('Eudenia ve sus tres publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      expect(find.text('Calculo I - Stewart'), findsOneWidget);
      expect(find.text('Calculadora Casio fx-991'), findsOneWidget);
      expect(find.text('Chompa de la U talla M'), findsOneWidget);
    });

    testWidgets('Ana todavía no publicó nada y ve el mensaje de lista vacía', (tester) async {
      await abrirApp(tester);
      await crearCuenta(tester, 'Ana Quispe', 'ana@ejemplo.com', 'ana12345');

      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Aún no tienes publicaciones');

      expect(find.text('Crear nueva publicación'), findsOneWidget);
    });

    testWidgets('Eudenia corrige el título de su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await escribir(tester, 'Nombre del objeto', 'Chompa de la U talla L');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');

      expect(find.text('Chompa de la U talla L'), findsOneWidget);
      expect(find.text('Chompa de la U talla M'), findsNothing);
    });

    testWidgets('Eudenia cancela la edición y su chompa queda igual', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await escribir(tester, 'Nombre del objeto', 'Otro nombre');
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Otro nombre'), findsNothing);
    });

    testWidgets('Eudenia no puede editar la calculadora porque Job la reservó', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      expect(find.text('Reservado por: Job Contreras'), findsOneWidget);
      expect(enTarjeta('Calculadora Casio fx-991', find.byTooltip('Editar información')), findsNothing);
      expect(enTarjeta('Calculadora Casio fx-991', find.byTooltip('Eliminar definitivamente')), findsNothing);
    });

    testWidgets('Eudenia oculta su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Ocultar publicación'));
      await esperarTexto(tester, 'Tu publicación ahora está oculta (solo tú la ves)');

      expect(enTarjeta('Chompa de la U talla M', find.text('Oculto')), findsOneWidget);
    });

    testWidgets('Eudenia marca su chompa como no disponible', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Marcar como No disponible'));
      await esperarTexto(tester, 'Tu publicación ahora está no disponible (nadie puede reservarla)');

      expect(enTarjeta('Chompa de la U talla M', find.text('No disponible')), findsOneWidget);
    });

    testWidgets('Eudenia oculta su chompa y después la vuelve a dejar disponible', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');
      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Ocultar publicación'));
      await esperarTexto(tester, 'Tu publicación ahora está oculta (solo tú la ves)');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Marcar como Disponible'));
      await esperarTexto(tester, 'Tu publicación ahora está disponible');

      expect(enTarjeta('Chompa de la U talla M', find.text('Disponible')), findsOneWidget);
    });

    testWidgets('Eudenia no puede ocultar su libro de cálculo porque tiene una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculo I - Stewart', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Ocultar publicación'));
      await esperarTexto(
        tester,
        'No puedes ocultar una publicación con una oferta pendiente. Responde o cancela la oferta primero',
      );

      expect(enTarjeta('Calculo I - Stewart', find.text('Disponible')), findsOneWidget);
    });

    testWidgets('Eudenia elimina su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Eliminar definitivamente')));
      await tocarBoton(tester, 'Eliminar');
      await esperarTexto(tester, 'Publicación eliminada');
      await esperarTexto(tester, 'Total: 2');

      expect(find.text('Chompa de la U talla M'), findsNothing);
    });

    testWidgets('Eudenia se arrepiente y no elimina su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Eliminar definitivamente')));
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Total: 3'), findsOneWidget);
    });

    testWidgets('Eudenia no puede eliminar su libro de cálculo porque tiene una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculo I - Stewart', find.byTooltip('Eliminar definitivamente')));
      await tocarBoton(tester, 'Eliminar');
      await esperarTexto(
        tester,
        'No puedes eliminar una publicación con una oferta pendiente. Responde o cancela la oferta primero',
      );

      expect(find.text('Calculo I - Stewart'), findsOneWidget);
    });

    testWidgets('Eudenia completa el intercambio de su calculadora reservada', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculadora Casio fx-991', find.text('Completar intercambio')));
      await tocarBoton(tester, 'Completar');
      await esperarTexto(tester, '¡Intercambio completado!');
      await esperarTexto(tester, 'Total: 2');

      expect(find.text('Calculadora Casio fx-991'), findsNothing);
    });

    testWidgets('Eudenia sale de sus publicaciones con el botón de volver al perfil', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocarBoton(tester, 'Volver al perfil');

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });
  });
}
