import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/cliente_api.dart';

/// Representa al usuario que tiene la sesión iniciada en la aplicación.
class UsuarioAutenticado {
  const UsuarioAutenticado({
    required this.id,
    required this.nombre,
    this.correo,
  });

  final int id;
  final String nombre;
  final String? correo;

  factory UsuarioAutenticado.desdeJson(Map<String, dynamic> json) =>
      UsuarioAutenticado(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nombre: json['nombre'] as String? ?? '',
        correo: json['correo'] as String?,
      );
}

/// Maneja la sesión: registro, inicio y cierre de sesión, recuperación y cambio
/// de contraseña. El token se guarda en SharedPreferences (localStorage en web),
/// así la sesión sobrevive a recargar la aplicación.
class ControladorAutenticacion extends ChangeNotifier {
  ControladorAutenticacion(this._api, this._preferencias);

  static const _claveToken = 'trueque_token';

  final ClienteApi _api;
  final SharedPreferences _preferencias;

  UsuarioAutenticado? _usuario;
  UsuarioAutenticado? get usuario => _usuario;
  bool get autenticado => _usuario != null;

  /// Se llama una vez al iniciar la app: si hay un token guardado, lo valida
  /// con el servidor y recupera a la persona.
  Future<void> restaurarSesion() async {
    final guardado = _preferencias.getString(_claveToken);
    if (guardado == null) {
      debugPrint('[sesion] No hay sesión guardada, se va al login');
      return;
    }

    debugPrint('[sesion] Hay una sesión guardada, la valido con el servidor...');
    _api.token = guardado;
    try {
      final datos = await _api.get('/sesiones/actual');
      _usuario = UsuarioAutenticado.desdeJson(datos['usuario'] as Map<String, dynamic>);
      debugPrint('[sesion] Sesión recuperada: ${_usuario?.nombre}');
    } on ExcepcionApi catch (e) {
      // Sesión cerrada o vencida: se descarta. Si solo falló la red, el token
      // se conserva para un próximo intento.
      if (e.codigoEstado == 401) {
        debugPrint('[sesion] La sesión venció, se borra');
        await _borrarSesion();
      } else {
        debugPrint('[sesion] No se pudo validar (${e.mensaje}), guardo el token para después');
      }
    }
    notifyListeners();
  }

  Future<void> registrar(
    String nombre,
    String correo,
    String contrasena, {
    String? telefono,
  }) async {
    debugPrint('[registro] Creando cuenta para $correo');
    final datos = await _api.post('/usuarios', {
      'nombre': nombre.trim(),
      'correo': correo.trim(),
      'contrasena': contrasena,
      if (telefono != null && telefono.trim().isNotEmpty)
        'telefono': telefono.trim(),
    });
    await _guardarSesion(datos);
  }

  Future<void> iniciarSesion(String correo, String contrasena) async {
    debugPrint('[login] Iniciando sesión de $correo');
    final datos = await _api.post('/sesiones', {
      'correo': correo.trim(),
      'contrasena': contrasena,
    });
    await _guardarSesion(datos);
  }

  Future<void> cerrarSesion() async {
    debugPrint('[login] Cerrando sesión');
    try {
      await _api.delete('/sesiones/actual');
    } on ExcepcionApi {
      // Aunque el servidor no responda, la sesión local se cierra igual.
    }
    await _borrarSesion();
    debugPrint('[login] Sesión cerrada');
    notifyListeners();
  }

  /// Pide una contraseña nueva: el servidor la envía al correo de la persona.
  Future<void> recuperarContrasena(String correo) async {
    debugPrint('[recuperar] Pidiendo contraseña nueva para $correo');
    await _api.post('/recuperaciones', {'correo': correo.trim()});
    debugPrint('[recuperar] Listo, debería llegar al correo');
  }

  ClienteApi get api => _api;

  Future<void> cambiarContrasena(String contrasenaActual, String contrasenaNueva) async {
    debugPrint('[usuario] Cambiando la contraseña');
    await _api.put('/usuarios/contrasena', {
      'contrasenaActual': contrasenaActual,
      'contrasenaNueva': contrasenaNueva,
    });
    debugPrint('[usuario] Contraseña cambiada');
  }

  /// Crea una nueva publicación de objeto para intercambiar.
  Future<void> crearPublicacion({
    required String titulo,
    String? descripcion,
    required String estado,
    required String categoria,
  }) async {
    debugPrint('[publicaciones] Creando "$titulo"');
    await _api.post('/publicaciones', {
      'titulo': titulo.trim(),
      if (descripcion != null && descripcion.trim().isNotEmpty)
        'descripcion': descripcion.trim(),
      'estado': estado,
      'categoria': categoria,
    });
    debugPrint('[publicaciones] Publicación creada');
  }

  /// Obtiene las publicaciones creadas por la persona con sesión activa.
  Future<List<Map<String, dynamic>>> obtenerMisPublicaciones() async {
    debugPrint('[publicaciones] Pidiendo mis publicaciones');
    final respuesta = await _api.get('/publicaciones/mias');
    if (respuesta is List) {
      debugPrint('[publicaciones] Llegaron ${respuesta.length} mías');
      return respuesta.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Obtiene las publicaciones del feed general (cards en grid).
  /// Se puede buscar por título y filtrar; los filtros se combinan.
  Future<List<Map<String, dynamic>>> obtenerPublicacionesFeed({
    String? buscar,
    String? categoria,
    String? condicion,
    String? disponibilidad,
  }) async {
    // Solo se mandan los filtros que están activos
    final filtros = <String, String>{
      if (buscar != null && buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
      if (categoria != null) 'categoria': categoria,
      if (condicion != null) 'condicion': condicion,
      if (disponibilidad != null) 'disponibilidad': disponibilidad,
    };
    final consulta = Uri(queryParameters: filtros).query;
    final ruta = consulta.isEmpty ? '/publicaciones' : '/publicaciones?$consulta';

    debugPrint('[publicaciones] Pidiendo el feed ($ruta)');
    final respuesta = await _api.get(ruta);
    if (respuesta is List) {
      debugPrint('[publicaciones] Llegaron ${respuesta.length} en el feed');
      return respuesta.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Reserva una publicación. El servidor sabe quién reserva por la sesión.
  /// Llama a PUT /api/publicaciones/:id/reservado
  Future<void> reservarPublicacion(int id) async {
    debugPrint('[publicaciones] Reservando la publicación $id');
    await _api.put('/publicaciones/$id/reservado', {});
    debugPrint('[publicaciones] Publicación $id reservada');
  }

  /// Completa el intercambio (lo hace el dueño o quien reservó).
  /// Llama a PUT /api/publicaciones/:id/intercambiado
  Future<void> completarIntercambio(int id) async {
    debugPrint('[intercambios] Completando el intercambio de la $id');
    await _api.put('/publicaciones/$id/intercambiado', {});
    debugPrint('[intercambios] Intercambio de la $id completado');
  }

  /// Intercambios completados de la persona con sesión (para su perfil).
  Future<List<Map<String, dynamic>>> obtenerIntercambios() async {
    debugPrint('[intercambios] Pidiendo mis intercambios completados');
    final respuesta = await _api.get('/publicaciones/intercambiadas');
    if (respuesta is List) {
      debugPrint('[intercambios] Llegaron ${respuesta.length}');
      return respuesta.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<String> crearOferta({
    required int idPublicacionPedida,
    required int idPublicacionOfrecida,
  }) async {
    debugPrint(
      '[ofertas] Ofrezco $idPublicacionOfrecida por $idPublicacionPedida',
    );
    final datos = await _api.post('/ofertas', {
      'id_publicacion_pedida': idPublicacionPedida,
      'id_publicacion_ofrecida': idPublicacionOfrecida,
    });
    return (datos is Map ? datos['mensaje'] as String? : null) ?? 'Oferta enviada';
  }

  Future<List<Map<String, dynamic>>> obtenerOfertasRecibidas() async {
    return _listaOfertas('/ofertas/recibidas');
  }

  Future<List<Map<String, dynamic>>> obtenerOfertasEnviadas() async {
    return _listaOfertas('/ofertas/enviadas');
  }

  Future<String> aceptarOferta(int id) async {
    final datos = await _api.put('/ofertas/$id/aceptada', {});
    return (datos is Map ? datos['mensaje'] as String? : null) ?? 'Oferta aceptada';
  }

  Future<String> rechazarOferta(int id) async {
    final datos = await _api.put('/ofertas/$id/rechazada', {});
    return (datos is Map ? datos['mensaje'] as String? : null) ?? 'Oferta rechazada';
  }

  Future<String> cancelarOferta(int id) async {
    final datos = await _api.put('/ofertas/$id/cancelada', {});
    return (datos is Map ? datos['mensaje'] as String? : null) ?? 'Oferta cancelada';
  }

  Future<List<Map<String, dynamic>>> _listaOfertas(String ruta) async {
    final respuesta = await _api.get(ruta);
    if (respuesta is List) {
      return respuesta.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Historial de la persona con sesión: qué ocurrió con sus intercambios.
  /// [tipo] es opcional: 'reservas' o 'completados' (sin tipo trae todo).
  /// Llama a GET /api/historial
  Future<List<Map<String, dynamic>>> obtenerHistorial({String? tipo}) async {
    debugPrint('[historial] Pidiendo mi historial (${tipo ?? 'todo'})');
    final respuesta = await _api.get(
      tipo == null ? '/historial' : '/historial?tipo=$tipo',
    );
    if (respuesta is List) {
      debugPrint('[historial] Llegaron ${respuesta.length} movimientos');
      return respuesta.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Descarta o cancela una reserva activa, regresando el objeto a 'disponible'.
  /// Llama a PUT /api/publicaciones/:id/disponible
  Future<void> descartarReservaPublicacion(int id) async {
    debugPrint('[publicaciones] Descartando la reserva de la $id');
    await _api.put('/publicaciones/$id/disponible', {});
    debugPrint('[publicaciones] Publicación $id otra vez disponible');
  }

  /// Permite al creador cambiar el estado de su publicación:
  /// 'disponible', 'oculto', 'no disponible'. (Reservar lo hace otra persona.)
  Future<void> cambiarEstadoPublicacion(int id, String nuevoEstado) async {
    switch (nuevoEstado) {
      case 'disponible':
        await descartarReservaPublicacion(id);
        break;
      case 'oculto':
        debugPrint('[publicaciones] Ocultando la publicación $id');
        await _api.put('/publicaciones/$id/oculto', {});
        break;
      case 'no disponible':
        debugPrint('[publicaciones] Marcando la $id como no disponible');
        await _api.put('/publicaciones/$id/no-disponible', {});
        break;
      default:
        throw ArgumentError('Estado no válido: $nuevoEstado');
    }
  }

  /// Elimina una publicación propia por su ID.
  Future<void> eliminarPublicacion(int id) async {
    debugPrint('[publicaciones] Eliminando la publicación $id');
    await _api.delete('/publicaciones/$id');
    debugPrint('[publicaciones] Publicación $id eliminada');
  }

  /// Edita la información básica (título y descripción) de una publicación propia.
  /// Llama a PUT /api/publicaciones/:id
  Future<void> editarPublicacion(
    int id, {
    required String titulo,
    String? descripcion,
  }) async {
    debugPrint('[publicaciones] Editando la publicación $id');
    await _api.put('/publicaciones/$id', {
      'titulo': titulo.trim(),
      'descripcion': (descripcion != null && descripcion.trim().isNotEmpty)
          ? descripcion.trim()
          : null,
    });
    debugPrint('[publicaciones] Publicación $id editada');
  }

  Future<void> _guardarSesion(Map<String, dynamic> datos) async {
    final token = datos['token'] as String;
    _api.token = token;
    await _preferencias.setString(_claveToken, token);
    _usuario = UsuarioAutenticado.desdeJson(datos['usuario'] as Map<String, dynamic>);
    debugPrint('[sesion] Entró ${_usuario?.nombre}, token guardado');
    notifyListeners();
  }

  Future<void> _borrarSesion() async {
    _api.token = null;
    _usuario = null;
    await _preferencias.remove(_claveToken);
  }
}
