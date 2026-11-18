import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/pantallas/pantalla_avisos.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';
import 'ayudantes/trueques.dart';

void main() {
  setUp(cargarEntornoDePrueba);

  testWidgets('muestra los avisos y marca como leidos los nuevos', (tester) async {
    final registro = <http.Request>[];
    final controlador = await controladorConSesion({
      'GET /api/notificaciones': (_) => respuestaJson([
        {'id': 1, 'mensaje': 'Te ofrecieron un trueque', 'leida': false, 'creado_en': '2026-03-15T12:00:00Z'},
        {'id': 2, 'mensaje': 'Aviso viejo', 'leida': true, 'creado_en': '2026-03-10T12:00:00Z'},
        {'id': 3, 'creado_en': 'no es fecha'},
      ]),
      'PUT /api/notificaciones/1/leida': (_) => respuestaJson({}),
      'PUT /api/notificaciones/3/leida': (_) => respuestaJson({'error': 'Falla'}, 500),
    }, registro: registro);

    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);

    expect(find.text('Te ofrecieron un trueque'), findsOneWidget);
    expect(find.text(fechaLocal('2026-03-15T12:00:00Z')), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsNWidgets(2));
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    final marcadas = registro.where((p) => p.method == 'PUT').map((p) => p.url.path).toList();
    expect(marcadas, ['/api/notificaciones/1/leida', '/api/notificaciones/3/leida']);
  });

  testWidgets('sin avisos explica que no hay nada', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/notificaciones': (_) => respuestaJson({'otro': 1}),
    });

    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);

    expect(find.text('No tienes avisos'), findsOneWidget);
  });

  testWidgets('un error del servidor se muestra y se puede reintentar', (tester) async {
    var intentos = 0;
    final controlador = await controladorConSesion({
      'GET /api/notificaciones': (_) {
        intentos++;
        if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
        return respuestaJson([]);
      },
    });
    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);
    expect(find.text('Sin servicio'), findsOneWidget);

    await tocar(tester, find.text('Reintentar'));

    expect(find.text('No tienes avisos'), findsOneWidget);
  });

  testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
    final controlador = await controladorConFallas({});
    controlador.fallan.add('avisos');

    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);

    expect(find.text('No se pudieron cargar tus avisos'), findsOneWidget);
  });

  testWidgets('el boton de texto vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/notificaciones': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);

    await tocar(tester, find.text('Volver al perfil'));

    expect(find.text('Destino /perfil'), findsOneWidget);
  });

  testWidgets('la flecha de la barra vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/notificaciones': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaAvisos(), controlador);

    await tocarIcono(tester, Icons.arrow_back);

    expect(find.text('Destino /perfil'), findsOneWidget);
  });
}
