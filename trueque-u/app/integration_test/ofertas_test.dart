import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

Future<void> ofrecerDesdeElFeed(
  WidgetTester tester,
  String objetoDeseado,
  String objetoPropio,
) async {
  await abrirFeed(tester);
  await buscarEnElFeed(tester, objetoDeseado);
  await tocarBoton(tester, 'Ofrecer un objeto');
  await tocar(tester, find.text(objetoPropio));
  await tocarBoton(tester, 'Enviar oferta');
}

Future<void> abrirOfertas(WidgetTester tester) async {
  await tocarBoton(tester, 'Ofertas de trueque');
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Enviar una oferta', () {
    testWidgets('Job envía una oferta por la chompa de Eudenia con su libro de Física', (tester) async {
      await abrirAppConSesion(tester, job);

      await ofrecerDesdeElFeed(tester, 'Chompa', 'Fisica General - Serway');
      await esperarTexto(
        tester,
        'Oferta enviada. El dueño puede aceptarla o rechazarla Revísala en Ofertas de trueque.',
      );

      expect(find.text('Ofrecer un objeto'), findsOneWidget);
    });

    testWidgets('Job ve su oferta en la lista de enviadas', (tester) async {
      await abrirAppConSesion(tester, job);
      await ofrecerDesdeElFeed(tester, 'Chompa', 'Fisica General - Serway');
      await esperarTexto(
        tester,
        'Oferta enviada. El dueño puede aceptarla o rechazarla Revísala en Ofertas de trueque.',
      );
      await tocar(tester, find.byTooltip('Volver al perfil'));

      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));

      expect(find.text('Para: Eudenia Flores Veizaga'), findsOneWidget);
      expect(find.text('Quiere: Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Ofrece: Fisica General - Serway'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('Eudenia recibe la oferta que Job le envió por su chompa', (tester) async {
      await abrirAppConSesion(tester, job);
      await ofrecerDesdeElFeed(tester, 'Chompa', 'Fisica General - Serway');
      await esperarTexto(
        tester,
        'Oferta enviada. El dueño puede aceptarla o rechazarla Revísala en Ofertas de trueque.',
      );
      await tocar(tester, find.byTooltip('Volver al perfil'));

      await cambiarDeUsuario(tester, eudenia);
      await abrirOfertas(tester);

      expect(find.text('De: Job Contreras'), findsOneWidget);
      expect(find.text('Quiere: Chompa de la U talla M'), findsOneWidget);
      expect(find.text('Ofrece: Fisica General - Serway'), findsOneWidget);
    });

    testWidgets('Job se arrepiente y cierra el cuadro de oferta sin enviar nada', (tester) async {
      await abrirAppConSesion(tester, job);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Chompa');

      await tocarBoton(tester, 'Ofrecer un objeto');
      expect(find.text('¿Qué objeto tuyo ofreces por «Chompa de la U talla M»?'), findsOneWidget);
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Ofrecer un objeto'), findsOneWidget);
      expect(find.textContaining('Oferta enviada'), findsNothing);
    });

    testWidgets('Job no puede enviar la oferta hasta elegir uno de sus objetos', (tester) async {
      await abrirAppConSesion(tester, job);
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Chompa');

      await tocarBoton(tester, 'Ofrecer un objeto');

      final enviar = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enviar oferta'));
      expect(enviar.onPressed, isNull);
    });

    testWidgets('Job usa el mismo libro en dos ofertas y la app le avisa', (tester) async {
      await abrirAppConSesion(tester, job);
      await ofrecerDesdeElFeed(tester, 'Chompa', 'Fisica General - Serway');
      await esperarTexto(
        tester,
        'Oferta enviada. El dueño puede aceptarla o rechazarla Revísala en Ofertas de trueque.',
      );

      await buscarEnElFeed(tester, 'Mandil');
      await tocarBoton(tester, 'Ofrecer un objeto');
      await tocar(tester, find.text('Fisica General - Serway'));
      await tocarBoton(tester, 'Enviar oferta');
      await esperarTexto(
        tester,
        'Ese objeto ya está en otra oferta pendiente. Cancélala si quieres usarlo en otra',
      );

      expect(find.textContaining('otra oferta pendiente'), findsOneWidget);
    });

    testWidgets('Ana no tiene objetos para ofrecer y la app le propone crear uno', (tester) async {
      await abrirApp(tester);
      await crearCuenta(tester, 'Ana Quispe', 'ana@ejemplo.com', 'ana12345');
      await abrirFeed(tester);
      await buscarEnElFeed(tester, 'Mouse');

      await tocarBoton(tester, 'Ofrecer un objeto');

      expect(find.textContaining('No tienes publicaciones disponibles para ofrecer'), findsOneWidget);

      await tocarBoton(tester, 'Crear publicación');

      expect(find.text('Nueva publicación'), findsOneWidget);
    });
  });

  group('Ofertas recibidas', () {
    testWidgets('Eudenia ve la oferta de Carlos por su libro de Cálculo', (tester) async {
      await abrirAppConSesion(tester, eudenia);

      await abrirOfertas(tester);

      expect(find.text('De: Carlos Mamani'), findsOneWidget);
      expect(find.text('Quiere: Calculo I - Stewart'), findsOneWidget);
      expect(find.text('Ofrece: Mouse inalambrico'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('Eudenia acepta la oferta de Carlos', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);

      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, 'Aceptaste el trueque. Las dos publicaciones quedaron intercambiadas');

      expect(find.text('Aceptada'), findsOneWidget);
      expect(find.text('Rechazar'), findsNothing);
    });

    testWidgets('Eudenia rechaza la oferta de Carlos', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);

      await tocarBoton(tester, 'Rechazar');
      await tocarBoton(tester, 'Rechazar');
      await esperarTexto(tester, 'Rechazaste la oferta');

      expect(find.text('Rechazada'), findsOneWidget);
      expect(find.text('Aceptar'), findsNothing);
    });

    testWidgets('Eudenia piensa en la oferta de Carlos y decide no responder todavía', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);

      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
    });

    testWidgets('Job no recibió ofertas y la app le sugiere explorar publicaciones', (tester) async {
      await abrirAppConSesion(tester, job);

      await abrirOfertas(tester);

      expect(find.text('Nadie te ha ofrecido un trueque'), findsOneWidget);

      await tocarBoton(tester, 'Explorar publicaciones');
      await esperarTexto(tester, 'Publicaciones');

      expect(find.byTooltip('Ayuda: ¿cómo funciona?'), findsOneWidget);
    });

    testWidgets('Job ve cancelada su oferta cuando Eudenia acepta la de Carlos', (tester) async {
      await abrirAppConSesion(tester, job);
      await ofrecerDesdeElFeed(tester, 'Calculo', 'Fisica General - Serway');
      await esperarTexto(
        tester,
        'Oferta enviada. El dueño puede aceptarla o rechazarla Revísala en Ofertas de trueque.',
      );
      await tocar(tester, find.byTooltip('Volver al perfil'));

      await cambiarDeUsuario(tester, eudenia);
      await abrirOfertas(tester);
      await tocar(tester, enTarjeta('De: Carlos Mamani', find.text('Aceptar')));
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, 'Aceptaste el trueque. Las dos publicaciones quedaron intercambiadas');
      await tocarBoton(tester, 'Volver al perfil');

      await cambiarDeUsuario(tester, job);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));

      expect(find.text('Cancelada'), findsOneWidget);
    });
  });

  group('Ofertas enviadas', () {
    testWidgets('Carlos ve la oferta que envió a Eudenia', (tester) async {
      await abrirAppConSesion(tester, carlos);
      await abrirOfertas(tester);

      await tocar(tester, find.text('Enviadas'));

      expect(find.text('Para: Eudenia Flores Veizaga'), findsOneWidget);
      expect(find.text('Quiere: Calculo I - Stewart'), findsOneWidget);
      expect(find.text('Ofrece: Mouse inalambrico'), findsOneWidget);
      expect(find.text('Cancelar oferta'), findsOneWidget);
    });

    testWidgets('Carlos cancela la oferta que envió', (tester) async {
      await abrirAppConSesion(tester, carlos);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));

      await tocarBoton(tester, 'Cancelar oferta');
      await tocarBoton(tester, 'Cancelar oferta');
      await esperarTexto(tester, 'Cancelaste la oferta');

      expect(find.text('Cancelada'), findsOneWidget);
    });

    testWidgets('Carlos cancela la oferta y Eudenia ya no puede aceptarla', (tester) async {
      await abrirAppConSesion(tester, carlos);
      await abrirOfertas(tester);
      await tocar(tester, find.text('Enviadas'));
      await tocarBoton(tester, 'Cancelar oferta');
      await tocarBoton(tester, 'Cancelar oferta');
      await esperarTexto(tester, 'Cancelaste la oferta');
      await tocarBoton(tester, 'Volver al perfil');

      await cambiarDeUsuario(tester, eudenia);
      await abrirOfertas(tester);

      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('Aceptar'), findsNothing);
    });

    testWidgets('Job todavía no envió ofertas y la app se lo cuenta', (tester) async {
      await abrirAppConSesion(tester, job);
      await abrirOfertas(tester);

      await tocar(tester, find.text('Enviadas'));

      expect(find.text('Todavía no envías ofertas'), findsOneWidget);
    });

    testWidgets('Carlos vuelve al perfil desde las ofertas', (tester) async {
      await abrirAppConSesion(tester, carlos);
      await abrirOfertas(tester);

      await tocarBoton(tester, 'Volver al perfil');

      expect(find.text('Hola, Carlos Mamani'), findsOneWidget);
    });
  });
}
