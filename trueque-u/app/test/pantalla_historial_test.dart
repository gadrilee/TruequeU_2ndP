// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trueque_u/pantallas/pantalla_historial.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';
import 'ayudantes/trueques.dart';

const instante = '2026-03-15T12:00:00Z';
const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String diaCorto() {
  final fecha = DateTime.parse(instante).toLocal();
  return '${fecha.day} ${meses[fecha.month - 1]}';
}

String fechaCompleta() {
  final fecha = DateTime.parse(instante).toLocal();
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${diaCorto()} ${fecha.year}, $hora:$minuto';
}

Map<String, dynamic> evento(
  String tipo, {
  bool yo = true,
  String? titulo = 'Libro',
  int? idPublicacion = 1,
  String? otra = 'Beto',
  String? categoria = 'libros',
  String? creado = instante,
}) {
  return {
    'tipo': tipo,
    'lo_hice_yo': yo,
    'creado_en': creado,
    'publicacion': {'id': idPublicacion, 'titulo': titulo, 'categoria': categoria},
    'otra_persona': {'nombre': otra},
  };
}

void main() {
  setUp(cargarEntornoDePrueba);

  final todos = [
    evento('reservo'),
    evento('reservo', yo: false),
    evento('cancelo_reserva'),
    evento('cancelo_reserva', yo: false),
    evento('completo'),
    evento('completo', yo: false),
  ];

  testWidgets('cuenta cada movimiento con su frase', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson(todos),
    });

    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    expect(find.text('Reservaste «Libro» de Beto'), findsOneWidget);
    expect(find.text('Beto reservó tu «Libro»'), findsOneWidget);
    expect(find.text('Cancelaste tu reserva de «Libro»'), findsOneWidget);
    expect(find.text('Beto canceló su reserva de «Libro»'), findsOneWidget);
    expect(find.text('Completaste el intercambio de «Libro» con Beto'), findsOneWidget);
    expect(find.text('Beto completó el intercambio de «Libro»'), findsOneWidget);
    expect(find.text('Reservado · ${diaCorto()}'), findsNWidgets(2));
  });

  testWidgets('el detalle muestra estado, categoria, persona y fecha', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson([evento('cancelo_reserva')]),
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocar(tester, find.text('Cancelaste tu reserva de «Libro»'));

    expect(find.text('Estado: Reserva cancelada'), findsOneWidget);
    expect(find.text('Categoría: Libros'), findsOneWidget);
    expect(find.text('Con: Beto'), findsOneWidget);
    expect(find.text('Fecha: ${fechaCompleta()}'), findsOneWidget);
    expect(find.text('Esta publicación ya no existe.'), findsNothing);

    await tocar(tester, find.text('Cerrar'));
    expect(find.text('Estado: Reserva cancelada'), findsNothing);
  });

  testWidgets('el detalle usa valores por defecto cuando faltan datos', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson([
        evento('reservo', titulo: null, idPublicacion: null, otra: null, categoria: null, creado: null),
        evento('completo', yo: false, titulo: null, otra: null),
      ]),
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocar(tester, find.text('Reservaste «un objeto» de otra persona'));

    expect(find.text('Sin título'), findsOneWidget);
    expect(find.text('Categoría: Otros'), findsOneWidget);
    expect(find.text('Con: otra persona'), findsOneWidget);
    expect(find.text('Fecha: '), findsOneWidget);
    expect(find.text('Estado: Reservado'), findsOneWidget);
    expect(find.text('Esta publicación ya no existe.'), findsOneWidget);
    await tocar(tester, find.text('Cerrar'));

    await tocar(tester, find.text('otra persona completó el intercambio de «un objeto»'));
    expect(find.text('Estado: Completado'), findsOneWidget);
  });

  testWidgets('los filtros piden al servidor solo ese tipo', (tester) async {
    final registro = <http.Request>[];
    final controlador = await controladorConSesion({
      'GET /api/historial': (peticion) {
        final tipo = peticion.url.queryParameters['tipo'];
        return respuestaJson(tipo == null ? todos : [evento('reservo')]);
      },
    }, registro: registro);
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocar(tester, find.text('Reservas'));
    await tocar(tester, find.text('Reservas'));

    final pedidos = registro.where((p) => p.url.path == '/api/historial').toList();
    expect(pedidos.length, 2);
    expect(pedidos.last.url.queryParameters['tipo'], 'reservas');
    expect(find.text('Reservaste «Libro» de Beto'), findsOneWidget);
  });

  testWidgets('sin movimientos invita a explorar', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson({'otro': 1}),
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);
    expect(find.text('Aún no tienes movimientos'), findsOneWidget);

    await tocar(tester, find.text('Explorar publicaciones'));

    expect(find.text('Destino /feed'), findsOneWidget);
  });

  testWidgets('un filtro vacio permite volver a ver todo', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (peticion) {
        final tipo = peticion.url.queryParameters['tipo'];
        return respuestaJson(tipo == null ? [evento('reservo')] : []);
      },
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocar(tester, find.text('Completados'));
    expect(find.text('No hay completados'), findsOneWidget);
    await tocar(tester, find.text('Ver todo'));

    expect(find.text('Reservaste «Libro» de Beto'), findsOneWidget);
  });

  testWidgets('un error del servidor se puede reintentar', (tester) async {
    var intentos = 0;
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) {
        intentos++;
        if (intentos == 1) return respuestaJson({'error': 'Sin servicio'}, 503);
        return respuestaJson([]);
      },
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);
    expect(find.text('Sin servicio'), findsOneWidget);

    await tocarIcono(tester, Icons.refresh);

    expect(find.text('Aún no tienes movimientos'), findsOneWidget);
  });

  testWidgets('un fallo inesperado muestra un mensaje general', (tester) async {
    final controlador = await controladorConFallas({});
    controlador.fallan.add('historial');

    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    expect(find.text('No se pudo cargar tu historial'), findsOneWidget);
  });

  testWidgets('el boton de texto vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocar(tester, find.text('Volver al perfil'));

    expect(find.text('Destino /perfil'), findsOneWidget);
  });

  testWidgets('la flecha de la barra vuelve al perfil', (tester) async {
    final controlador = await controladorConSesion({
      'GET /api/historial': (_) => respuestaJson([]),
    });
    await montarPerfilYDestinos(tester, PantallaHistorial(), controlador);

    await tocarIcono(tester, Icons.arrow_back);

    expect(find.text('Destino /perfil'), findsOneWidget);
  });
}
