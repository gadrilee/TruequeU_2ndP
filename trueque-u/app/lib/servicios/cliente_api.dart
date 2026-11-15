import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../configuracion.dart';

class ExcepcionApi implements Exception {
  ExcepcionApi(this.mensaje, [this.codigoEstado]);

  final String mensaje;
  final int? codigoEstado;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP mínimo hacia la API de Node.js.
class ClienteApi {
  ClienteApi({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// Token de la sesión actual (null si no hay sesión).
  String? token;

  Future<dynamic> get(String ruta) => _enviar('GET', ruta);

  Future<dynamic> post(String ruta, [Map<String, dynamic>? cuerpo]) =>
      _enviar('POST', ruta, cuerpo);

  Future<dynamic> put(String ruta, Map<String, dynamic> cuerpo) =>
      _enviar('PUT', ruta, cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Future<String> getTexto(String ruta) async {
    final uri = Uri.parse('${ConfiguracionEntorno.urlBase}$ruta');
    final cabeceras = <String, String>{};
    if (token != null) cabeceras['Authorization'] = 'Bearer $token';

    debugPrint('[api] Mandando GET $uri');
    http.Response respuesta;
    try {
      respuesta = await _cliente
          .get(uri, headers: cabeceras)
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw ExcepcionApi(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet e inténtalo de nuevo en unos segundos.',
      );
    }
    debugPrint('[api] Respondió ${respuesta.statusCode}');

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return utf8.decode(respuesta.bodyBytes);
    }
    throw ExcepcionApi(_explicarCodigo(respuesta.statusCode), respuesta.statusCode);
  }

  Future<dynamic> _enviar(
    String metodo,
    String ruta, [
    Map<String, dynamic>? cuerpo,
  ]) async {
    final uri = Uri.parse('${ConfiguracionEntorno.urlBase}$ruta');
    final cabeceras = <String, String>{'Content-Type': 'application/json'};
    if (token != null) cabeceras['Authorization'] = 'Bearer $token';

    // Solo se imprime el método y la dirección (nunca el token ni las contraseñas)
    debugPrint('[api] Mandando $metodo $uri');
    final reloj = Stopwatch()..start();

    http.Response respuesta;
    try {
      final peticion = switch (metodo) {
        'GET' => _cliente.get(uri, headers: cabeceras),
        'DELETE' => _cliente.delete(uri, headers: cabeceras),
        'PUT' => _cliente.put(uri, headers: cabeceras, body: jsonEncode(cuerpo ?? {})),
        _ => _cliente.post(uri, headers: cabeceras, body: jsonEncode(cuerpo ?? {})),
      };
      respuesta = await peticion.timeout(const Duration(seconds: 60));
    } catch (e) {
      final seg = (reloj.elapsedMilliseconds / 1000).toStringAsFixed(1);
      if (e is TimeoutException) {
        debugPrint('[api] No contestó en $seg s. Si Render estaba dormido, tarda en despertar.');
      } else {
        debugPrint('[api] No se pudo conectar ($seg s). Error real: ${e.runtimeType} -> $e');
      }
      throw ExcepcionApi(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet e inténtalo de nuevo en unos segundos.',
      );
    }
    debugPrint('[api] Respondió ${respuesta.statusCode} en ${reloj.elapsedMilliseconds} ms');

    dynamic datos;
    if (respuesta.body.isNotEmpty) {
      try {
        datos = jsonDecode(respuesta.body);
      } catch (_) {
        debugPrint('[api] La respuesta no venía en JSON (¿será otra página?)');
      }
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return datos ?? <String, dynamic>{};
    }
    // Si el backend mandó su propio mensaje se usa ese; si no, se explica el código.
    final errorMensaje = (datos is Map ? datos['error'] as String? : null) ??
        _explicarCodigo(respuesta.statusCode);
    debugPrint('[api] Error ${respuesta.statusCode}: $errorMensaje');
    throw ExcepcionApi(errorMensaje, respuesta.statusCode);
  }

  /// Explica en palabras simples qué significa cada código de error HTTP.
  String _explicarCodigo(int codigo) {
    final explicacion = switch (codigo) {
      400 => 'La solicitud no es válida. Revisa los datos enviados.',
      401 => 'Tu sesión no es válida o venció. Inicia sesión de nuevo.',
      403 => 'No tienes permiso para hacer esta acción.',
      404 => 'No se encontró lo que buscas.',
      405 => 'Esta acción no está permitida en el servidor.',
      408 => 'La solicitud tardó demasiado en enviarse. Intenta de nuevo.',
      409 => 'Esta publicación cambió mientras la mirabas. Actualiza la lista e inténtalo de nuevo.',
      500 => 'El servidor tuvo un problema interno. Intenta más tarde.',
      502 => 'El servidor no respondió bien. Intenta de nuevo en unos segundos.',
      503 => 'El servidor no está disponible ahora. Intenta más tarde.',
      504 => 'El servidor tardó demasiado en responder. Intenta de nuevo en unos segundos.',
      _ => 'Ocurrió un error inesperado. Inténtalo de nuevo.',
    };
    // El código HTTP queda solo en el registro de depuración, no en pantalla
    return explicacion;
  }
}
