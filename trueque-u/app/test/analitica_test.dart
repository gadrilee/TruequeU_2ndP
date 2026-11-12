import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trueque_u/servicios/analitica.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  test('track registra el evento una vez con las props esperadas', () async {
    final enviados = <http.Request>[];
    final cliente = MockClient((peticion) async {
      enviados.add(peticion);
      return http.Response('{}', 201);
    });

    await track(
      'oferta_enviada',
      {'id_publicacion': 5, 'id_publicacion_ofrecida': 9, 'categoria': 'libros'},
      ClienteApi(cliente: cliente),
    );

    expect(enviados.length, 1);
    expect(enviados.first.url.path, '/api/eventos');
    final cuerpo = jsonDecode(enviados.first.body);
    expect(cuerpo['evento'], 'oferta_enviada');
    expect(cuerpo['props'], {
      'id_publicacion': 5,
      'id_publicacion_ofrecida': 9,
      'categoria': 'libros',
    });
    expect(cuerpo['fecha'], isNotEmpty);
  });

  test('si el servidor falla, track no lanza error', () async {
    final cliente = MockClient((peticion) async => http.Response('{}', 500));

    await track('oferta_iniciada', {'id_publicacion': 5}, ClienteApi(cliente: cliente));
  });

  test('feed_filtrado envia filtros y conteo sin el texto de busqueda', () async {
    final enviados = <http.Request>[];
    final cliente = MockClient((peticion) async {
      enviados.add(peticion);
      return http.Response('{}', 201);
    });

    await track(
      'feed_filtrado',
      {
        'categoria': 'libros',
        'condicion': null,
        'disponibilidad': 'disponible',
        'tiene_busqueda': true,
        'num_resultados': 3,
      },
      ClienteApi(cliente: cliente),
    );

    final cuerpo = jsonDecode(enviados.first.body);
    expect(cuerpo['evento'], 'feed_filtrado');
    expect(cuerpo['props']['tiene_busqueda'], true);
    expect(cuerpo['props']['num_resultados'], 3);
    expect(cuerpo['props'].containsKey('buscar'), false);
  });

  test('reserva_cancelada envia el origen', () async {
    final enviados = <http.Request>[];
    final cliente = MockClient((peticion) async {
      enviados.add(peticion);
      return http.Response('{}', 201);
    });

    await track(
      'reserva_cancelada',
      {'id_publicacion': 4, 'origen': 'feed'},
      ClienteApi(cliente: cliente),
    );

    final cuerpo = jsonDecode(enviados.first.body);
    expect(cuerpo['evento'], 'reserva_cancelada');
    expect(cuerpo['props'], {'id_publicacion': 4, 'origen': 'feed'});
  });
}
