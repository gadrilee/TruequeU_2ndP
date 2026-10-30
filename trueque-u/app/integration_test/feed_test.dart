import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Explorar el feed', () {
    testWidgets('Eudenia abre el feed y ve las publicaciones recientes', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await abrirFeed(tester);
      await esperarTexto(tester, 'Mouse inalambrico');

      expect(find.text('Mouse inalambrico'), findsOneWidget);
      expect(find.text('Cuadernos cuadriculados x5'), findsNothing);
      expect(find.text('Audifonos con cable'), findsNothing);
    });

    testWidgets('Eudenia vuelve al perfil desde el feed', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Volver al perfil'));

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });

    testWidgets('Eudenia lee la ayuda del feed y la cierra', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Ayuda: ¿cómo funciona?'));

      expect(find.text('¿Cómo funciona?'), findsOneWidget);
      expect(find.text('Estados'), findsOneWidget);
      expect(find.textContaining('Ofrecer un objeto'), findsWidgets);

      await tocarBoton(tester, 'Entendido');

      expect(find.text('¿Cómo funciona?'), findsNothing);
    });
  });

  group('Buscar y filtrar', () {
    testWidgets('Eudenia busca "Fisica" y solo ve el libro de Job', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await buscarEnElFeed(tester, 'Fisica');

      expect(find.text('Fisica General - Serway'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);
    });

    testWidgets('Eudenia busca algo que no existe y quita el filtro', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await buscarEnElFeed(tester, 'bicicleta');

      expect(find.text('Ninguna publicación coincide con tu búsqueda'), findsOneWidget);

      await tocarBoton(tester, 'Quitar filtros');
      await esperarTexto(tester, 'Mouse inalambrico');

      expect(find.text('Mouse inalambrico'), findsOneWidget);
    });

    testWidgets('Eudenia filtra por la categoría Ropa', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Filtrar por categoría'));
      await tocar(tester, find.text('Ropa').last);
      await esperarTexto(tester, 'Categoría: Ropa');
      await tester.pumpAndSettle();

      expect(find.text('Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);
    });

    testWidgets('Eudenia filtra por la condición Nuevo', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Filtrar por condición'));
      await tocar(tester, find.text('Nuevo').last);
      await esperarTexto(tester, 'Condición: Nuevo');
      await tester.pumpAndSettle();

      expect(find.text('Juego de reglas y escuadras'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);
    });

    testWidgets('Eudenia filtra por disponibilidad Intercambiado y ve los audífonos de Job', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Filtrar por disponibilidad'));
      await tocar(tester, find.text('Intercambiado').last);
      await esperarTexto(tester, 'Disponibilidad: Intercambiado');
      await tester.pumpAndSettle();

      expect(find.text('Audifonos con cable'), findsOneWidget);
      expect(find.text('Intercambio completado'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);
    });

    testWidgets('Eudenia combina dos filtros y luego los quita todos', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);

      await tocar(tester, find.byTooltip('Filtrar por categoría'));
      await tocar(tester, find.text('Libros').last);
      await esperarTexto(tester, 'Categoría: Libros');
      await tocar(tester, find.byTooltip('Filtrar por condición'));
      await tocar(tester, find.text('Usado').last);
      await esperarTexto(tester, 'Condición: Usado');
      await tester.pumpAndSettle();

      expect(find.text('Fisica General - Serway'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);

      await tocarBoton(tester, 'Quitar todos');
      await esperarTexto(tester, 'Mouse inalambrico');

      expect(find.byType(InputChip), findsNothing);
    });
  });

  group('Reservar', () {
    testWidgets('Eudenia reserva el libro de Física de Job', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');

      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');

      expect(find.textContaining('Reservaste "Fisica General - Serway"'), findsOneWidget);
      expect(find.text('Cancelar reserva'), findsOneWidget);
    });

    testWidgets('Eudenia reserva el libro de Física y después cancela su reserva', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');
      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');

      await tocarBoton(tester, 'Cancelar reserva');
      await tocarBoton(tester, 'Sí, cancelar reserva');
      await esperarTexto(tester, 'Reserva descartada. Publicación nuevamente disponible.');
      await esperarTexto(tester, 'Disponible');

      expect(find.text('Reservado por ti'), findsNothing);
      expect(find.text('Ofrecer un objeto'), findsOneWidget);
    });

    testWidgets('Eudenia piensa cancelar su reserva pero decide mantenerla', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');
      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');

      await tocarBoton(tester, 'Cancelar reserva');
      await tocarBoton(tester, 'Mantener reserva');

      expect(find.text('Reservado por ti'), findsOneWidget);
    });

    testWidgets('Eudenia reserva el libro de Física y completa el intercambio desde el feed', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');
      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');

      await tocarBoton(tester, 'Completar intercambio');
      await tocarBoton(tester, 'Completar');
      await esperarTexto(tester, '¡Intercambio completado!');
      await esperarTexto(tester, 'Ninguna publicación coincide con tu búsqueda');

      expect(find.text('Fisica General - Serway'), findsNothing);
    });

    testWidgets('Job intenta reservar el libro de Cálculo pero tiene una oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, job);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Calculo');

      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(
        tester,
        'Esta publicación tiene una oferta de trueque pendiente. El dueño debe aceptarla o rechazarla antes de reservarla',
      );

      expect(find.text('Reservado por ti'), findsNothing);
    });

    testWidgets('Job ve que ya reservó la calculadora de Eudenia', (tester) async {
      await abrirAppConSesion(tester, job);
      await abrirFeed(tester);

      await buscarEnElFeed(tester, 'Calculadora');

      expect(find.text('Reservado por ti'), findsOneWidget);
      expect(find.text('Cancelar reserva'), findsOneWidget);
      expect(find.text('Completar intercambio'), findsOneWidget);
    });

    testWidgets('Carlos ve la calculadora reservada por otra persona sin poder reservarla', (tester) async {
      await abrirAppConSesion(tester, carlos);
      await abrirFeed(tester);

      await buscarEnElFeed(tester, 'Calculadora');

      expect(find.widgetWithText(FilledButton, 'Reservado'), findsOneWidget);
    });

    testWidgets('Eudenia ve su propia publicación y salta a Mis publicaciones', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Chompa');

      expect(find.text('Publicado por ti'), findsOneWidget);

      await tocar(tester, find.text('Ver en mis publicaciones'));
      await esperarTexto(tester, 'Total: 3');

      expect(find.text('Chompa de la U talla M'), findsOneWidget);
    });
  });
}
