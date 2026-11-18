import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Datos de configuración que salen del archivo .env
class ConfiguracionEntorno {
  /// Dirección del servidor (sin /api). Si el .env no la trae, usa la local.
  static String get _servidor {
    // Se acepta API_URL y también api_url, por si se escribe en minúsculas
    final url = dotenv.env['API_URL'] ?? dotenv.env['api_url'];
    if (url == null || url.isEmpty) return 'http://localhost:3000';
    // Se quitan las barras del final para no generar "//api"
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  /// Dirección base de las peticiones, por ejemplo https://ihc-2.onrender.com/api
  static String get urlBase => '$_servidor/api';

  /// True si el .env no trae la dirección y se está usando la local.
  static bool get usaServidorLocal =>
      (dotenv.env['API_URL'] ?? dotenv.env['api_url'] ?? '').isEmpty;
}
