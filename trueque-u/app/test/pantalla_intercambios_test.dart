import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/pantallas/pantalla_intercambios.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';
import 'ayudantes/trueques.dart';

void main() {
  setUp(cargarEntornoDePrueba);

  testWidgets('muestra una tarjeta por intercambio', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/publicaciones/intercambiadas': (_) => respuestaJson([
        publicacion(1, idUsuario: 7, estadoPublicacion: 'intercambiado', idReserva: 8, nombreReserva: 'Carla'),
        publicacion(2, idUsuario: 8, estadoPublicacion: 'intercambiado'),
      ]),
    });

    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);

    expect(find.text('Lo entregaste a: Carla'), findsOneWidget);
    expect(find.text('Lo recibiste de: Beto'), findsOneWidget);
  });

  testWidgets('sin intercambios lo explica', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/publicaciones/intercambiadas': (_) => respuestaJson([]),
    });

    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);

    expect(find.text('Aún no tienes intercambios completados'), findsOneWidget);
  });

  testWidgets('un error del servidor se puede reintentar con el icono de actualizar', (tester) async {
    var intentos = 0;
    final controlador = await controladorConSesion({
      'GET /api/publicaciones/intercambiadas': (_) {
        intentos++;
        if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
        return respuestaJson([]);
      },
    });
    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);
    expect(find.text('Sin servicio'), findsOneWidget);

    await tocarIcono(tester, Icons.refresh);

    expect(find.text('Aún no tienes intercambios completados'), findsOneWidget);
  });

  testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
    final controlador = await controladorConFallas({});
    controlador.fallan.add('intercambios');

    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);

    expect(find.text('No se pudieron cargar tus intercambios'), findsOneWidget);
  });

  testWidgets('el boton de texto vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/publicaciones/intercambiadas': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);

    await tocar(tester, find.text('Volver al perfil'));

    expect(find.text('Destino /perfil'), findsOneWidget);
  });

  testWidgets('la flecha de la barra vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/publicaciones/intercambiadas': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaIntercambios(), controlador);

    await tocarIcono(tester, Icons.arrow_back);

    expect(find.text('Destino /perfil'), findsOneWidget);
  });
}
