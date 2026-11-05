import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Intercambios completados', () {
    testWidgets('Job ve que entregó sus audífonos a Carlos', (tester) async {
      await abrirAppConSesion(tester, job);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Audifonos con cable');

      expect(find.text('Lo entregaste a: Carlos Mamani'), findsOneWidget);
      expect(find.text('Categoría: Electrónica'), findsOneWidget);
    });

    testWidgets('Carlos ve que recibió los audífonos de Job', (tester) async {
      await abrirAppConSesion(tester, carlos);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Audifonos con cable');

      expect(find.text('Lo recibiste de: Job Contreras'), findsOneWidget);
    });

    testWidgets('Eudenia todavía no completó ningún intercambio', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Aún no tienes intercambios completados');

      expect(find.text('Aún no tienes intercambios completados'), findsOneWidget);
    });

    testWidgets('Eudenia acepta la oferta de Carlos, los dos confirman y ve el intercambio completado', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Ofertas de trueque');
      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, mensajeAceptar);
      await confirmarEntrega(tester, mensajePrimeraConfirmacion);
      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, carlos);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));
      await confirmarEntrega(tester, mensajeCompletado);
      await irARuta(tester, '/perfil');
      await cambiarDeUsuario(tester, eudenia);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Calculo I - Stewart');

      expect(find.text('Lo entregaste a: Carlos Mamani'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsOneWidget);
      expect(find.text('Lo recibiste de: Carlos Mamani'), findsOneWidget);
    });

    testWidgets('Job vuelve al perfil desde sus intercambios', (tester) async {
      await abrirAppConSesion(tester, job);
      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Audifonos con cable');

      await tocarBoton(tester, 'Volver al perfil');

      expect(find.text('Hola, Job Contreras'), findsOneWidget);
    });
  });

  group('Historial', () {
    testWidgets('Job ve sus tres movimientos de ejemplo', (tester) async {
      await abrirAppConSesion(tester, job);

      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Reservaste «Calculadora Casio fx-991» de Eudenia Flores Veizaga');

      expect(find.text('Carlos Mamani reservó tu «Audifonos con cable»'), findsOneWidget);
      expect(find.text('Completaste el intercambio de «Audifonos con cable» con Carlos Mamani'), findsOneWidget);
    });

    testWidgets('Eudenia ve que Job reservó su calculadora', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Job Contreras reservó tu «Calculadora Casio fx-991»');

      expect(find.textContaining('Reservado'), findsOneWidget);
    });

    testWidgets('Job filtra su historial por reservas', (tester) async {
      await abrirAppConSesion(tester, job);
      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Reservaste «Calculadora Casio fx-991» de Eudenia Flores Veizaga');

      await tocar(tester, find.text('Reservas'));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Mamani reservó tu «Audifonos con cable»'), findsOneWidget);
      expect(find.text('Completaste el intercambio de «Audifonos con cable» con Carlos Mamani'), findsNothing);
    });

    testWidgets('Job filtra su historial por completados', (tester) async {
      await abrirAppConSesion(tester, job);
      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Reservaste «Calculadora Casio fx-991» de Eudenia Flores Veizaga');

      await tocar(tester, find.text('Completados'));
      await tester.pumpAndSettle();

      expect(find.text('Completaste el intercambio de «Audifonos con cable» con Carlos Mamani'), findsOneWidget);
      expect(find.text('Carlos Mamani reservó tu «Audifonos con cable»'), findsNothing);
    });

    testWidgets('Job abre el detalle de un movimiento y lo cierra', (tester) async {
      await abrirAppConSesion(tester, job);
      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Completaste el intercambio de «Audifonos con cable» con Carlos Mamani');

      await tocar(tester, find.text('Completaste el intercambio de «Audifonos con cable» con Carlos Mamani'));

      expect(find.text('Estado: Completado'), findsOneWidget);
      expect(find.text('Categoría: Electrónica'), findsOneWidget);
      expect(find.text('Con: Carlos Mamani'), findsOneWidget);

      await tocarBoton(tester, 'Cerrar');

      expect(find.text('Estado: Completado'), findsNothing);
    });

    testWidgets('Ana todavía no tiene movimientos en su historial', (tester) async {
      await abrirApp(tester);
      await crearCuenta(tester, 'Ana Quispe', 'ana@ejemplo.com', 'ana12345');

      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Aún no tienes movimientos');

      await tocar(tester, find.text('Reservas'));

      expect(find.text('No hay reservas'), findsOneWidget);
    });

    testWidgets('Eudenia reserva el libro de Física y lo ve en su historial', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');
      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');
      await tocar(tester, find.byTooltip('Volver al perfil'));

      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Reservaste «Fisica General - Serway» de Job Contreras');

      expect(find.text('Reservaste «Fisica General - Serway» de Job Contreras'), findsOneWidget);
    });

    testWidgets('Eudenia cancela su reserva y el historial lo registra', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Fisica');
      await tocarBoton(tester, 'Reservar');
      await tocarBoton(tester, 'Reservar');
      await esperarTexto(tester, 'Reservado por ti');
      await tocarBoton(tester, 'Cancelar reserva');
      await tocarBoton(tester, 'Sí, cancelar reserva');
      await esperarTexto(tester, 'Reserva descartada. Publicación nuevamente disponible.');
      await tocar(tester, find.byTooltip('Volver al perfil'));

      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Cancelaste tu reserva de «Fisica General - Serway»');

      expect(find.text('Reservaste «Fisica General - Serway» de Job Contreras'), findsOneWidget);
    });

    testWidgets('Eudenia vuelve al perfil desde su historial', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await tocarBoton(tester, 'Historial');
      await esperarTexto(tester, 'Job Contreras reservó tu «Calculadora Casio fx-991»');

      await tocarBoton(tester, 'Volver al perfil');

      expect(find.text('Hola, Eudenia Flores Veizaga'), findsOneWidget);
    });
  });
}
