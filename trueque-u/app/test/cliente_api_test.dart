import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

import 'ayudantes/montar.dart';

MockClient clienteQueGuarda(List<http.Request> enviados, http.Response respuesta) {
  return MockClient((peticion) async {
    enviados.add(peticion);
    return respuesta;
  });
}

void main() {
  setUpAll(cargarEntornoDePrueba);

  group('ClienteApi con respuestas correctas', () {
    test('GET devuelve el JSON y manda el token', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('{"ok": true}', 200)))
        ..token = 'abc';

      final datos = await api.get('/cosas');

      expect(datos, {'ok': true});
      expect(enviados.single.url.toString(), 'http://servidor.test/api/cosas');
      expect(enviados.single.headers['Authorization'], 'Bearer abc');
    });

    test('sin token no manda la cabecera Authorization', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('[]', 200)));

      await api.get('/cosas');

      expect(enviados.single.headers.containsKey('Authorization'), false);
    });

    test('POST manda el cuerpo en JSON', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('{}', 201)));

      await api.post('/cosas', {'a': 1});

      expect(enviados.single.method, 'POST');
      expect(jsonDecode(enviados.single.body), {'a': 1});
    });

    test('POST sin cuerpo manda un objeto vacio', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('{}', 200)));

      await api.post('/cosas');

      expect(enviados.single.body, '{}');
    });

    test('PUT manda el cuerpo en JSON', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('{}', 200)));

      await api.put('/cosas/1', {'b': 2});

      expect(enviados.single.method, 'PUT');
      expect(jsonDecode(enviados.single.body), {'b': 2});
    });

    test('DELETE con cuerpo lo manda en JSON', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('{}', 200)));

      await api.delete('/cosas/1', {'c': 3});

      expect(enviados.single.method, 'DELETE');
      expect(jsonDecode(enviados.single.body), {'c': 3});
    });

    test('DELETE sin cuerpo no manda nada', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('', 204)));

      await api.delete('/cosas/1');

      expect(enviados.single.body, '');
    });

    test('una respuesta 2xx vacia devuelve un mapa vacio', () async {
      final api = ClienteApi(cliente: MockClient((_) async => http.Response('', 204)));

      expect(await api.get('/cosas'), <String, dynamic>{});
    });

    test('una respuesta 2xx que no es JSON devuelve un mapa vacio', () async {
      final api = ClienteApi(cliente: MockClient((_) async => http.Response('<html>', 200)));

      expect(await api.get('/cosas'), <String, dynamic>{});
    });

    test('el constructor sin cliente crea uno propio', () {
      expect(ClienteApi().token, isNull);
    });
  });

  group('ClienteApi con errores del servidor', () {
    Future<ExcepcionApi> fallo(http.Response respuesta) async {
      final api = ClienteApi(cliente: MockClient((_) async => respuesta));
      try {
        await api.get('/cosas');
      } on ExcepcionApi catch (e) {
        return e;
      }
      fail('Debia lanzar ExcepcionApi');
    }

    test('usa el mensaje de error que manda el backend', () async {
      final e = await fallo(http.Response('{"error": "Dato repetido"}', 400));

      expect(e.mensaje, 'Dato repetido');
      expect(e.codigoEstado, 400);
      expect(e.toString(), 'Dato repetido');
    });

    test('si el cuerpo no es JSON explica el codigo', () async {
      final e = await fallo(http.Response('<html>', 502));

      expect(e.mensaje, contains('no respondió bien'));
    });

    test('si el JSON no es un mapa explica el codigo', () async {
      final e = await fallo(http.Response('[1, 2]', 404));

      expect(e.mensaje, 'No se encontró lo que buscas.');
    });

    test('si el cuerpo viene vacio explica el codigo', () async {
      final e = await fallo(http.Response('', 401));

      expect(e.mensaje, contains('sesión'));
    });

    test('cada codigo conocido tiene su explicacion', () async {
      const esperados = {
        400: 'no es válida',
        401: 'sesión',
        403: 'permiso',
        404: 'No se encontró',
        405: 'no está permitida',
        408: 'tardó demasiado en enviarse',
        409: 'cambió mientras la mirabas',
        500: 'problema interno',
        502: 'no respondió bien',
        503: 'no está disponible',
        504: 'tardó demasiado en responder',
        418: 'error inesperado',
      };
      for (final entrada in esperados.entries) {
        final e = await fallo(http.Response('', entrada.key));
        expect(e.mensaje, contains(entrada.value), reason: 'codigo ${entrada.key}');
        expect(e.codigoEstado, entrada.key);
      }
    });
  });

  group('ClienteApi sin conexion', () {
    test('un error de red se convierte en ExcepcionApi', () async {
      final api = ClienteApi(cliente: MockClient((_) async => throw http.ClientException('sin red')));

      expect(
        () => api.post('/cosas', {'a': 1}),
        throwsA(isA<ExcepcionApi>().having((e) => e.codigoEstado, 'codigo', isNull)),
      );
    });

    test('un TimeoutException tambien se convierte en ExcepcionApi', () async {
      final api = ClienteApi(cliente: MockClient((_) async => throw TimeoutException('lento')));

      expect(
        () => api.get('/cosas'),
        throwsA(isA<ExcepcionApi>().having((e) => e.mensaje, 'mensaje', contains('No se pudo conectar'))),
      );
    });

    testWidgets('si el servidor no contesta en 60 segundos falla', (tester) async {
      final api = ClienteApi(cliente: MockClient((_) => Completer<http.Response>().future));
      Object? error;
      api.get('/cosas').catchError((Object e) {
        error = e;
        return null;
      });

      await tester.pump(const Duration(seconds: 61));

      expect(error, isA<ExcepcionApi>());
    });
  });

  group('ClienteApi.getTexto', () {
    test('devuelve el texto decodificado en utf8', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response.bytes(utf8.encode('á,b'), 200)))
        ..token = 'tok';

      expect(await api.getTexto('/csv'), 'á,b');
      expect(enviados.single.headers['Authorization'], 'Bearer tok');
    });

    test('sin token no manda Authorization', () async {
      final enviados = <http.Request>[];
      final api = ClienteApi(cliente: clienteQueGuarda(enviados, http.Response('x', 200)));

      await api.getTexto('/csv');

      expect(enviados.single.headers.containsKey('Authorization'), false);
    });

    test('un codigo de error lanza ExcepcionApi con su estado', () async {
      final api = ClienteApi(cliente: MockClient((_) async => http.Response('', 403)));

      expect(
        () => api.getTexto('/csv'),
        throwsA(isA<ExcepcionApi>().having((e) => e.codigoEstado, 'codigo', 403)),
      );
    });

    test('un error de red lanza ExcepcionApi', () async {
      final api = ClienteApi(cliente: MockClient((_) async => throw http.ClientException('sin red')));

      expect(() => api.getTexto('/csv'), throwsA(isA<ExcepcionApi>()));
    });
  });
}
