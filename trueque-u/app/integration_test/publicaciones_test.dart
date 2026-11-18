import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Publicar un objeto', () {
    testWidgets('Eudenia publica un libro usado y lo ve en sus publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);

      await escribir(tester, 'Nombre del objeto', 'Algebra Lineal - Lay');
      await escribir(tester, 'Descripción (opcional)', 'Cuarta edicion, sin subrayar');
      await tocar(tester, find.text('Nuevo'));
      await tocar(tester, find.text('Usado').last);
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.text('Libros').last);
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación guardada exitosamente');

      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Algebra Lineal - Lay');

      expect(find.text('Total: 4'), findsOneWidget);
      expect(find.text('Cuarta edicion, sin subrayar'), findsOneWidget);
    });

    testWidgets('Eudenia deja el nombre vacío y la app se lo pide', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);

      await tocarBoton(tester, 'Guardar');

      expect(find.text('Escribe el nombre del objeto'), findsOneWidget);
    });

    testWidgets('Eudenia cancela la publicación y vuelve a sus publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);

      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Total: 3'), findsOneWidget);
    });
  });

  group('Fotos de la publicación', () {
    Future<String?> fotoGuardada(String titulo) async {
      final respuesta = await pedirApi('GET', '/publicaciones/mias', eudenia);
      final lista = jsonDecode(respuesta.body) as List;
      final fila = lista.where((p) => p['titulo'] == titulo);
      return fila.isEmpty ? null : fila.first['imagen_url'] as String?;
    }

    testWidgets('Eudenia publica un libro con foto y el servidor la entrega', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);
      elegirArchivoFalso(base64Decode(pngMinimo), 'portada.png');

      await escribir(tester, 'Nombre del objeto', 'Libro con foto');
      await tocarBoton(tester, 'Elegir foto');
      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsOneWidget);
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación guardada exitosamente');
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Libro con foto');

      expect(fotoDelServidor(), findsOneWidget);
      final url = await fotoGuardada('Libro con foto');
      final descarga = await http.get(Uri.parse(url!));
      expect(descarga.statusCode, 200);
      expect(descarga.bodyBytes, base64Decode(pngMinimo));
    });

    testWidgets('Eudenia elige una foto, se arrepiente y publica sin ella', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);
      elegirArchivoFalso(base64Decode(pngMinimo), 'portada.png');

      await escribir(tester, 'Nombre del objeto', 'Libro sin foto');
      await tocarBoton(tester, 'Elegir foto');
      await tocarBoton(tester, 'Quitar foto');
      expect(find.text('Elegir foto'), findsOneWidget);
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación guardada exitosamente');

      expect(await fotoGuardada('Libro sin foto'), isNull);
    });

    testWidgets('Eudenia elige una foto que no es jpg ni png y la app se lo avisa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);
      elegirArchivoFalso(base64Decode(pngMinimo), 'dibujo.gif');

      await tocarBoton(tester, 'Elegir foto');

      expect(find.text('La foto tiene que ser jpg o png'), findsOneWidget);
      expect(find.text('Elegir foto'), findsOneWidget);
    });

    testWidgets('Eudenia elige una foto de más de 2 MB y la app se lo avisa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirNuevaPublicacion(tester);
      elegirArchivoFalso(Uint8List(2 * 1024 * 1024 + 1), 'enorme.png');

      await tocarBoton(tester, 'Elegir foto');

      expect(find.text('La foto puede pesar hasta 2 MB'), findsOneWidget);
      expect(find.text('Elegir foto'), findsOneWidget);
    });

    testWidgets('El servidor rechaza una foto que no es una imagen y no crea la publicación', (tester) async {
      await abrirApp(tester);

      final respuesta = await pedirApi('POST', '/publicaciones', eudenia, {
        'titulo': 'Falsa foto',
        'estado': 'usado',
        'imagen': 'data:image/png;base64,${base64Encode(utf8.encode('esto no es una imagen'))}',
      });

      expect(respuesta.statusCode, 400);
      expect(jsonDecode(respuesta.body)['error'], 'La foto tiene que ser jpg o png');
      expect(await fotoGuardada('Falsa foto'), isNull);
    });

    testWidgets('Eudenia agrega una foto a su chompa al editarla y después la quita', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');
      elegirArchivoFalso(base64Decode(pngMinimo), 'chompa.png');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await tocarBoton(tester, 'Cambiar foto');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');

      expect(fotoDelServidor(), findsOneWidget);
      expect(await fotoGuardada('Chompa de la U talla M'), startsWith('http://localhost:3000/uploads/'));

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await tocarBoton(tester, 'Quitar foto');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');

      expect(fotoDelServidor(), findsNothing);
      expect(await fotoGuardada('Chompa de la U talla M'), isNull);
    });

    testWidgets('Eudenia reemplaza la foto de su chompa por otra', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');
      elegirArchivoFalso(base64Decode(pngMinimo), 'primera.png');
      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await tocarBoton(tester, 'Cambiar foto');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');
      final primera = await fotoGuardada('Chompa de la U talla M');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await tocarBoton(tester, 'Cambiar foto');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');
      final segunda = await fotoGuardada('Chompa de la U talla M');

      expect(segunda, isNot(primera));
      expect((await http.get(Uri.parse(primera!))).statusCode, 404);
      expect((await http.get(Uri.parse(segunda!))).statusCode, 200);
    });

    testWidgets('Eudenia elige una foto de más de 2 MB al editar y la app se lo avisa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');
      elegirArchivoFalso(Uint8List(2 * 1024 * 1024 + 1), 'enorme.png');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await tocarBoton(tester, 'Cambiar foto');

      expect(find.text('La foto puede pesar hasta 2 MB'), findsOneWidget);
    });
  });

  group('Mis publicaciones', () {
    testWidgets('Eudenia ve sus tres publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      expect(find.text('Calculo I - Stewart'), findsOneWidget);
      expect(find.text('Calculadora Casio fx-991'), findsOneWidget);
      expect(find.text('Chompa de la U talla M'), findsOneWidget);
    });

    testWidgets('Ana todavía no publicó nada y ve el mensaje de lista vacía', (tester) async {
      await abrirApp(tester);
      await crearCuenta(tester, 'Ana Quispe', 'ana@ejemplo.com', 'ana12345');

      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Aún no tienes publicaciones');

      expect(find.text('Crear nueva publicación'), findsOneWidget);
    });

    testWidgets('Eudenia corrige el título de su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
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
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Editar información')));
      await escribir(tester, 'Nombre del objeto', 'Otro nombre');
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Otro nombre'), findsNothing);
    });

    testWidgets('Eudenia no puede editar la calculadora porque Job la reservó', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      expect(find.text('Reservado por: Job Contreras'), findsOneWidget);
      expect(enTarjeta('Calculadora Casio fx-991', find.byTooltip('Editar información')), findsNothing);
      expect(enTarjeta('Calculadora Casio fx-991', find.byTooltip('Eliminar definitivamente')), findsNothing);
    });

    testWidgets('Eudenia oculta su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Ocultar publicación'));
      await esperarTexto(tester, 'Tu publicación ahora está oculta (solo tú la ves)');

      expect(enTarjeta('Chompa de la U talla M', find.text('Oculto')), findsOneWidget);
    });

    testWidgets('Eudenia marca su chompa como no disponible', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Marcar como No disponible'));
      await esperarTexto(tester, 'Tu publicación ahora está no disponible (nadie puede reservarla)');

      expect(enTarjeta('Chompa de la U talla M', find.text('No disponible')), findsOneWidget);
    });

    testWidgets('Eudenia oculta su chompa y después la vuelve a dejar disponible', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
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
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculo I - Stewart', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Ocultar publicación'));
      await esperarTexto(
        tester,
        'No puedes ocultar una publicación con una oferta pendiente. Responde o cancela la oferta primero',
      );

      expect(enTarjeta('Calculo I - Stewart', find.text('Disponible')), findsOneWidget);
    });

    testWidgets('Eudenia no puede marcar su libro de cálculo como no disponible porque tiene una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculo I - Stewart', find.byTooltip('Cambiar estado de la publicación')));
      await tocar(tester, find.text('Marcar como No disponible'));
      await esperarTexto(
        tester,
        'No puedes marcar como no disponible una publicación con una oferta pendiente. Responde o cancela la oferta primero',
      );

      expect(enTarjeta('Calculo I - Stewart', find.text('Disponible')), findsOneWidget);
    });

    testWidgets('Eudenia puede corregir el título de su libro de cálculo aunque tenga una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculo I - Stewart', find.byTooltip('Editar información')));
      await escribir(tester, 'Nombre del objeto', 'Calculo I - Stewart 7ma');
      await tocarBoton(tester, 'Guardar');
      await esperarTexto(tester, 'Publicación actualizada correctamente');

      expect(find.text('Calculo I - Stewart 7ma'), findsOneWidget);
    });

    testWidgets('Eudenia elimina su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Eliminar definitivamente')));
      await tocarBoton(tester, 'Eliminar');
      await esperarTexto(tester, 'Publicación eliminada');
      await esperarTexto(tester, 'Total: 2');

      expect(find.text('Chompa de la U talla M'), findsNothing);
    });

    testWidgets('Eudenia se arrepiente y no elimina su chompa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Chompa de la U talla M', find.byTooltip('Eliminar definitivamente')));
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Total: 3'), findsOneWidget);
    });

    testWidgets('Eudenia no puede eliminar su libro de cálculo porque tiene una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
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
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await tocar(tester, enTarjeta('Calculadora Casio fx-991', find.text('Completar intercambio')));
      await tocarBoton(tester, 'Completar');
      await esperarTexto(tester, '¡Intercambio completado!');
      await esperarTexto(tester, 'Total: 2');

      expect(find.text('Calculadora Casio fx-991'), findsNothing);
    });

    testWidgets('Eudenia sale de sus publicaciones con la barra inferior', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirPestana(tester, 'Mis publicaciones');
      await esperarTexto(tester, 'Total: 3');

      await abrirPestana(tester, 'Perfil');

      expect(find.text('Eudenia Flores Veizaga'), findsOneWidget);
    });
  });
}
