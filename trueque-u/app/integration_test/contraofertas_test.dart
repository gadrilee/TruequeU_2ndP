import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ayudantes.dart';

const mensajeContraoferta =
    'Contraoferta enviada. La otra persona puede aceptarla, rechazarla o responder';

Future<void> contraofertar(WidgetTester tester, String pedido, String objeto) async {
  await tocarBoton(tester, 'Contraofertar');
  await esperarTexto(tester, '¿Qué otro objeto propones por «$pedido»?');
  await tocar(tester, find.text(objeto));
  await tocarBoton(tester, 'Enviar contraoferta');
  await esperarTexto(tester, mensajeContraoferta);
  await tester.pumpAndSettle();
}

Future<void> volverYCambiarDeUsuario(WidgetTester tester, List<String> persona) async {
  await irARuta(tester, '/perfil');
  await cambiarDeUsuario(tester, persona);
  await abrirOfertas(tester);
}

Future<void> eudeniaContraofertaConElMandil(WidgetTester tester) async {
  await abrirAppConSesion(tester, eudenia);
  await abrirOfertas(tester);
  await contraofertar(tester, 'Calculo I - Stewart', 'Mandil de laboratorio');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Responder con una contraoferta', () {
    testWidgets('Eudenia responde la oferta de Carlos con una contraoferta', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);

      await contraofertar(tester, 'Calculo I - Stewart', 'Mandil de laboratorio');

      expect(find.text('Nadie te ha ofrecido un trueque'), findsOneWidget);

      await tocar(tester, find.text('Enviadas'));

      expect(find.text('Para: Carlos Mamani'), findsOneWidget);
      expect(find.text('Ofrece: Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Ronda 2'), findsOneWidget);
      expect(find.text('Cancelar oferta'), findsOneWidget);
    });

    testWidgets('Eudenia solo ve los objetos disponibles de Carlos al contraofertar', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);

      await tocarBoton(tester, 'Contraofertar');
      await esperarTexto(tester, '¿Qué otro objeto propones por «Calculo I - Stewart»?');

      expect(find.text('Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Mouse inalambrico'), findsNothing);
      expect(find.text('Cuadernos cuadriculados x5'), findsNothing);
      expect(find.text('Fisica General - Serway'), findsNothing);
    });

    testWidgets('Eudenia cierra el cuadro de contraoferta sin enviar nada', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);
      await tocarBoton(tester, 'Contraofertar');
      await esperarTexto(tester, '¿Qué otro objeto propones por «Calculo I - Stewart»?');

      await tocarBoton(tester, 'Cancelar');

      expect(find.text('Ronda 1'), findsOneWidget);
      expect(find.text('Contraofertar'), findsOneWidget);
    });

    testWidgets('Carlos recibe la contraoferta de Eudenia y puede responderla', (tester) async {
      await eudeniaContraofertaConElMandil(tester);

      await volverYCambiarDeUsuario(tester, carlos);

      expect(find.text('De: Eudenia Flores Veizaga'), findsOneWidget);
      expect(find.text('Ofrece: Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Ronda 2'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Contraofertar'), findsOneWidget);
    });
  });

  group('Historial de la negociación', () {
    testWidgets('Carlos ve el historial de la negociacion con Eudenia', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await volverYCambiarDeUsuario(tester, carlos);

      await tocarBoton(tester, 'Ver historial');
      await esperarTexto(tester, 'Historial de la negociación');

      expect(find.text('Se negocia: Calculo I - Stewart'), findsOneWidget);
      expect(find.text('Ronda 1: Carlos Mamani propone Mouse inalambrico'), findsOneWidget);
      expect(find.text('Ronda 2: Eudenia Flores Veizaga propone Mandil de laboratorio'), findsOneWidget);
      expect(find.textContaining('Contraofertada ·'), findsOneWidget);
      expect(find.textContaining('Pendiente ·'), findsOneWidget);

      await tocarBoton(tester, 'Cerrar');

      expect(find.text('Historial de la negociación'), findsNothing);
    });

    testWidgets('Eudenia también ve el historial desde sus ofertas enviadas', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await tocar(tester, find.text('Enviadas'));

      await tocarBoton(tester, 'Ver historial');
      await esperarTexto(tester, 'Historial de la negociación');

      expect(find.text('Ronda 1: Carlos Mamani propone Mouse inalambrico'), findsOneWidget);
      expect(find.text('Ronda 2: Eudenia Flores Veizaga propone Mandil de laboratorio'), findsOneWidget);
    });

    testWidgets('Job no puede ver la negociacion entre Eudenia y Carlos', (tester) async {
      await abrirApp(tester);

      final respuesta = await pedirApi('GET', '/ofertas/1/historial', job);

      expect(respuesta.statusCode, 403);
      expect(jsonDecode(respuesta.body)['error'], contains('Solo quienes participan'));
    });
  });

  group('Cerrar la negociación', () {
    testWidgets('Carlos acepta la contraoferta y la negociacion se cierra', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await volverYCambiarDeUsuario(tester, carlos);

      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, 'Aceptaste el trueque. Ahora cada uno confirma la entrega');

      expect(find.text('Aceptada'), findsOneWidget);
      expect(find.text('Contraofertar'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);

      await confirmarEntrega(tester, mensajePrimeraConfirmacion);
      await volverYCambiarDeUsuario(tester, eudenia);
      await tocar(tester, find.text('Enviadas'));
      await confirmarEntrega(tester, mensajeCompletado);

      await irARuta(tester, '/intercambios');
      await esperarTexto(tester, 'Calculo I - Stewart');

      expect(find.text('Lo entregaste a: Carlos Mamani'), findsOneWidget);
      expect(find.text('Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Lo recibiste de: Carlos Mamani'), findsOneWidget);
    });

    testWidgets('Carlos rechaza la contraoferta de Eudenia', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await volverYCambiarDeUsuario(tester, carlos);

      await tocarBoton(tester, 'Rechazar');
      await tocarBoton(tester, 'Rechazar');
      await esperarTexto(tester, 'Rechazaste la oferta');

      expect(find.text('Rechazada'), findsOneWidget);
      expect(find.text('Contraofertar'), findsNothing);
    });

    testWidgets('Eudenia no puede aceptar su propia contraoferta', (tester) async {
      await eudeniaContraofertaConElMandil(tester);

      final respuesta = await pedirApi('PUT', '/ofertas/2/aceptada', eudenia);

      expect(respuesta.statusCode, 403);
      expect(jsonDecode(respuesta.body)['error'], 'Solo quien recibe la oferta puede aceptarla');
    });

    testWidgets('Nadie puede contraofertar una negociacion cerrada', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);
      await tocarBoton(tester, 'Rechazar');
      await tocarBoton(tester, 'Rechazar');
      await esperarTexto(tester, 'Rechazaste la oferta');

      expect(find.text('Rechazada'), findsOneWidget);
      expect(find.text('Contraofertar'), findsNothing);

      final deEudenia = await pedirApi('POST', '/ofertas/1/contraoferta', eudenia, {
        'id_publicacion_ofrecida': 7,
      });
      final deCarlos = await pedirApi('POST', '/ofertas/1/contraoferta', carlos, {
        'id_publicacion_ofrecida': 7,
      });
      final aceptar = await pedirApi('PUT', '/ofertas/1/aceptada', eudenia);

      expect(deEudenia.statusCode, 409);
      expect(deCarlos.statusCode, 409);
      expect(aceptar.statusCode, 409);
      expect(jsonDecode(deEudenia.body)['error'], contains('cerrada'));
    });

    testWidgets('Nadie puede contraofertar una negociacion ya aceptada', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      await abrirOfertas(tester);
      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, 'Aceptaste el trueque. Ahora cada uno confirma la entrega');

      final respuesta = await pedirApi('POST', '/ofertas/1/contraoferta', carlos, {
        'id_publicacion_ofrecida': 7,
      });

      expect(find.text('Contraofertar'), findsNothing);
      expect(respuesta.statusCode, 409);
    });

    testWidgets('Job no puede contraofertar la negociacion de Eudenia y Carlos', (tester) async {
      await abrirApp(tester);

      final respuesta = await pedirApi('POST', '/ofertas/1/contraoferta', job, {
        'id_publicacion_ofrecida': 6,
      });

      expect(respuesta.statusCode, 403);
    });
  });

  group('Varias rondas', () {
    testWidgets('Eudenia y Carlos negocian tres rondas', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await volverYCambiarDeUsuario(tester, carlos);

      await contraofertar(tester, 'Calculo I - Stewart', 'Mouse inalambrico');
      await volverYCambiarDeUsuario(tester, eudenia);

      expect(find.text('Ronda 3'), findsOneWidget);
      expect(find.text('De: Carlos Mamani'), findsOneWidget);
      expect(find.text('Ofrece: Mouse inalambrico'), findsOneWidget);

      await tocarBoton(tester, 'Ver historial');
      await esperarTexto(tester, 'Historial de la negociación');

      expect(find.text('Ronda 1: Carlos Mamani propone Mouse inalambrico'), findsOneWidget);
      expect(find.text('Ronda 2: Eudenia Flores Veizaga propone Mandil de laboratorio'), findsOneWidget);
      expect(find.text('Ronda 3: Carlos Mamani propone Mouse inalambrico'), findsOneWidget);

      await tocarBoton(tester, 'Cerrar');
      await tocarBoton(tester, 'Aceptar');
      await tocarBoton(tester, 'Aceptar');
      await esperarTexto(tester, 'Aceptaste el trueque. Ahora cada uno confirma la entrega');

      expect(find.text('Aceptada'), findsOneWidget);
    });

    testWidgets('Carlos cancela su contraoferta', (tester) async {
      await eudeniaContraofertaConElMandil(tester);
      await volverYCambiarDeUsuario(tester, carlos);
      await contraofertar(tester, 'Calculo I - Stewart', 'Mouse inalambrico');
      await tocar(tester, find.text('Enviadas'));

      await tocarBoton(tester, 'Cancelar oferta');
      await tocarBoton(tester, 'Cancelar oferta');
      await esperarTexto(tester, 'Cancelaste la oferta');

      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('Cancelar oferta'), findsNothing);

      await volverYCambiarDeUsuario(tester, eudenia);

      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('Contraofertar'), findsNothing);
    });

    testWidgets('Carlos no puede reusar un objeto que ya está en otra oferta pendiente', (tester) async {
      await abrirAppConSesion(tester, eudenia);
      final otraOferta = await pedirApi('POST', '/ofertas', carlos, {
        'id_publicacion_pedida': 4,
        'id_publicacion_ofrecida': 7,
      });
      await abrirOfertas(tester);
      await tocarBoton(tester, 'Contraofertar');
      await esperarTexto(tester, '¿Qué otro objeto propones por «Calculo I - Stewart»?');
      await tocar(tester, find.text('Mandil de laboratorio'));
      await tocarBoton(tester, 'Enviar contraoferta');
      await esperarTexto(tester, 'Ese objeto ya está en otra oferta pendiente');

      expect(otraOferta.statusCode, 201);
      expect(find.text('Ronda 1'), findsOneWidget);
    });
  });
}
