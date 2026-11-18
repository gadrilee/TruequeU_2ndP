// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/pantallas/pantalla_mis_datos.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';
import 'ayudantes/trueques.dart';

Map<String, dynamic> datosCompletos({String? telefono = '70000000'}) {
  return {
    'perfil': {
      'nombre': 'Ana Perez',
      'correo': 'ana@correo.com',
      'telefono': telefono,
      'creado_en': '2026-01-20T10:00:00.000Z',
    },
    'publicaciones': [
      {'titulo': 'Libro de calculo', 'estado_publicacion': 'disponible'},
    ],
    'ofertas_hechas': [
      {'objeto_ofrecido': 'Mouse', 'objeto_pedido': 'Teclado', 'estado': 'pendiente'},
    ],
    'ofertas_recibidas': [
      {'objeto_ofrecido': 'Cable', 'objeto_pedido': 'Libro', 'estado': 'aceptada'},
    ],
    'calificaciones_dadas': [
      {'puntaje': 5, 'creado_en': '2026-02-01T10:00:00.000Z', 'comentario': 'Excelente'},
      {'puntaje': 3, 'creado_en': '2026-02-02T10:00:00.000Z', 'comentario': ''},
    ],
    'calificaciones_recibidas': [
      {'puntaje': 4, 'creado_en': '2026-02-03T10:00:00.000Z'},
    ],
    'historial': [
      {'titulo': 'Libro', 'tipo': 'reservo', 'creado_en': '2026-02-04T10:00:00.000Z'},
    ],
  };
}

Future<void> montarMisDatos(WidgetTester tester, ControladorAutenticacion controlador) {
  return montarPerfilYDestinos(tester, PantallaMisDatos(), controlador);
}

void main() {
  setUp(cargarEntornoDePrueba);

  testWidgets('muestra todo lo que la app guarda de la persona', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datosCompletos()),
    });

    await montarMisDatos(tester, controlador);

    expect(find.text('Nombre: Ana Perez'), findsOneWidget);
    expect(find.text('Teléfono: 70000000'), findsOneWidget);
    expect(find.text('Cuenta creada: 2026-01-20'), findsOneWidget);
    expect(find.text('Libro de calculo · disponible'), findsOneWidget);
    expect(find.text('Ofreciste "Mouse" por "Teclado" · pendiente'), findsOneWidget);
    expect(find.text('Te ofrecieron "Cable" por "Libro" · aceptada'), findsOneWidget);
    expect(find.text('5 de 5 · 2026-02-01 · "Excelente"'), findsOneWidget);
    expect(find.text('3 de 5 · 2026-02-02'), findsOneWidget);
    expect(find.text('4 de 5 · 2026-02-03'), findsOneWidget);
    expect(find.text('Libro · reservo · 2026-02-04'), findsOneWidget);
  });

  testWidgets('sin datos muestra los textos de vacio', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson([1, 2]),
    });

    await montarMisDatos(tester, controlador);

    expect(find.text('Teléfono: sin teléfono'), findsOneWidget);
    expect(find.text('Todavía no publicaste nada.'), findsOneWidget);
    expect(find.text('No hiciste ofertas.'), findsOneWidget);
    expect(find.text('No recibiste ofertas.'), findsOneWidget);
    expect(find.text('No calificaste a nadie.'), findsOneWidget);
    expect(find.text('Aún no te calificaron.'), findsOneWidget);
    expect(find.text('Sin movimientos.'), findsOneWidget);
    expect(find.text('Quitar mi teléfono'), findsNothing);
  });

  testWidgets('una lista que no es lista cuenta como vacia', (tester) async {
    final datos = datosCompletos(telefono: '');
    datos['publicaciones'] = 'no es lista';
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datos),
    });

    await montarMisDatos(tester, controlador);

    expect(find.text('Todavía no publicaste nada.'), findsOneWidget);
    expect(find.text('Teléfono: sin teléfono'), findsOneWidget);
  });

  testWidgets('descargar en la VM avisa que solo funciona en el navegador', (tester) async {
    final registro = <http.Request>[];
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (peticion) {
        if (peticion.url.queryParameters['formato'] == null) return respuestaJson(datosCompletos());
        return http.Response('{"ok":true}', 200);
      },
    }, registro: registro);
    await montarMisDatos(tester, controlador);

    await tocar(tester, find.text('Descargar JSON'));
    expect(find.text('La descarga solo está disponible desde el navegador'), findsOneWidget);
    await tocar(tester, find.text('Descargar CSV'));

    final formatos = registro
        .where((p) => p.url.queryParameters['formato'] != null)
        .map((p) => p.url.queryParameters['formato'])
        .toList();
    expect(formatos, ['json', 'csv']);
  });

  testWidgets('un error al descargar se muestra en un aviso', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (peticion) {
        if (peticion.url.queryParameters['formato'] == null) return respuestaJson(datosCompletos());
        return respuestaJson({'error': 'No se pudo exportar'}, 500);
      },
    });
    await montarMisDatos(tester, controlador);

    await tocar(tester, find.text('Descargar JSON'));

    expect(find.text('El servidor tuvo un problema interno. Intenta más tarde.'), findsOneWidget);
  });

  testWidgets('quitar el telefono avisa y recarga los datos', (tester) async {
    var quitado = false;
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datosCompletos(telefono: quitado ? null : '70000000')),
      'DELETE /api/usuarios/yo/telefono': (_) {
        quitado = true;
        return respuestaJson({});
      },
    });
    await montarMisDatos(tester, controlador);

    await tocar(tester, find.text('Quitar mi teléfono'));

    expect(find.text('Quitamos tu teléfono'), findsOneWidget);
    expect(find.text('Teléfono: sin teléfono'), findsOneWidget);
  });

  testWidgets('si no se puede quitar el telefono muestra el error', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datosCompletos()),
      'DELETE /api/usuarios/yo/telefono': (_) => respuestaJson({'error': 'No se pudo quitar'}, 500),
    });
    await montarMisDatos(tester, controlador);

    await tocar(tester, find.text('Quitar mi teléfono'));

    expect(find.text('No se pudo quitar'), findsOneWidget);
    expect(find.text('Teléfono: 70000000'), findsOneWidget);
  });

  testWidgets('un error del servidor se puede reintentar', (tester) async {
    var intentos = 0;
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) {
        intentos++;
        if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
        return respuestaJson(datosCompletos());
      },
    });
    await montarMisDatos(tester, controlador);
    expect(find.text('Sin servicio'), findsOneWidget);

    await tocar(tester, find.text('Reintentar'));

    expect(find.text('Nombre: Ana Perez'), findsOneWidget);
  });

  testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
    final controlador = await controladorConFallas({});
    controlador.fallan.add('datos');

    await montarMisDatos(tester, controlador);

    expect(find.text('No se pudieron cargar tus datos'), findsOneWidget);
  });

  testWidgets('el boton de texto vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datosCompletos()),
    });
    await montarMisDatos(tester, controlador);

    await tocar(tester, find.text('Volver al perfil'));

    expect(find.text('Destino /perfil'), findsOneWidget);
  });

  testWidgets('la flecha de la barra vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/usuarios/yo/datos': (_) => respuestaJson(datosCompletos()),
    });
    await montarMisDatos(tester, controlador);

    await tocarIcono(tester, Icons.arrow_back);

    expect(find.text('Destino /perfil'), findsOneWidget);
  });
}
