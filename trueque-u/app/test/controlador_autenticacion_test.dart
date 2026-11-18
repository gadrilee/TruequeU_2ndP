import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/servicios/cliente_api.dart';

import 'ayudantes/montar.dart';

Map<String, dynamic> sesionDe(String token, {String nombre = 'Ana Perez'}) => {
  'token': token,
  'usuario': {'id': 7, 'nombre': nombre, 'correo': 'ana@correo.com'},
};

Map<String, dynamic> cuerpoDe(http.Request peticion) =>
    jsonDecode(peticion.body) as Map<String, dynamic>;

void main() {
  late List<http.Request> peticiones;

  setUp(() {
    peticiones = [];
  });

  group('UsuarioAutenticado', () {
    test('desdeJson lee los campos', () {
      final usuario = UsuarioAutenticado.desdeJson({
        'id': 3,
        'nombre': 'Luis',
        'correo': 'luis@correo.com',
      });

      expect(usuario.id, 3);
      expect(usuario.nombre, 'Luis');
      expect(usuario.correo, 'luis@correo.com');
    });

    test('desdeJson usa valores por defecto si faltan datos', () {
      final usuario = UsuarioAutenticado.desdeJson({});

      expect(usuario.id, 0);
      expect(usuario.nombre, '');
      expect(usuario.correo, isNull);
    });
  });

  group('restaurarSesion', () {
    test('no hace nada si no hay token guardado', () async {
      final controlador = await controladorSinRed();

      await controlador.restaurarSesion();

      expect(controlador.autenticado, isFalse);
      expect(controlador.usuario, isNull);
    });

    test('recupera al usuario cuando el token es valido', () async {
      final cliente = clienteRuteado({
        'GET /api/sesiones/actual': (_) => respuestaJson({
          'usuario': {'id': 7, 'nombre': 'Ana Perez'},
        }),
      }, registro: peticiones);
      final controlador = await crearControlador(
        cliente,
        preferencias: {'trueque_token': 'tok-guardado'},
      );
      var avisos = 0;
      controlador.addListener(() => avisos++);

      await controlador.restaurarSesion();

      expect(controlador.autenticado, isTrue);
      expect(controlador.usuario!.nombre, 'Ana Perez');
      expect(controlador.api.token, 'tok-guardado');
      expect(peticiones.single.headers['Authorization'], 'Bearer tok-guardado');
      expect(avisos, 1);
    });

    test('borra el token cuando el servidor responde 401', () async {
      final cliente = clienteRuteado({
        'GET /api/sesiones/actual': (_) => respuestaJson({'error': 'vencida'}, 401),
      });
      final controlador = await crearControlador(
        cliente,
        preferencias: {'trueque_token': 'tok-viejo'},
      );

      await controlador.restaurarSesion();

      final prefs = await SharedPreferences.getInstance();
      expect(controlador.autenticado, isFalse);
      expect(controlador.api.token, isNull);
      expect(prefs.getString('trueque_token'), isNull);
    });

    test('conserva el token cuando el servidor falla con otro error', () async {
      final cliente = clienteRuteado({
        'GET /api/sesiones/actual': (_) => respuestaJson({'error': 'caido'}, 500),
      });
      final controlador = await crearControlador(
        cliente,
        preferencias: {'trueque_token': 'tok-guardado'},
      );

      await controlador.restaurarSesion();

      final prefs = await SharedPreferences.getInstance();
      expect(controlador.autenticado, isFalse);
      expect(prefs.getString('trueque_token'), 'tok-guardado');
    });
  });

  group('registrar', () {
    test('envia los datos limpios, guarda la sesion y avisa', () async {
      final cliente = clienteRuteado({
        'POST /api/usuarios': (_) => respuestaJson(sesionDe('tok-nuevo'), 201),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);
      var avisos = 0;
      controlador.addListener(() => avisos++);

      await controlador.registrar(
        '  Ana Perez ',
        ' ana@correo.com ',
        'secreto1',
        telefono: ' 12345678 ',
      );

      final cuerpo = cuerpoDe(peticiones.single);
      expect(cuerpo['nombre'], 'Ana Perez');
      expect(cuerpo['correo'], 'ana@correo.com');
      expect(cuerpo['contrasena'], 'secreto1');
      expect(cuerpo['telefono'], '12345678');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('trueque_token'), 'tok-nuevo');
      expect(controlador.usuario!.id, 7);
      expect(avisos, 1);
    });

    test('no manda el telefono si viene vacio o nulo', () async {
      final cliente = clienteRuteado({
        'POST /api/usuarios': (_) => respuestaJson(sesionDe('t'), 201),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.registrar('Ana', 'ana@correo.com', 'secreto1', telefono: '   ');
      await controlador.registrar('Ana', 'ana@correo.com', 'secreto1');

      expect(cuerpoDe(peticiones[0]).containsKey('telefono'), isFalse);
      expect(cuerpoDe(peticiones[1]).containsKey('telefono'), isFalse);
    });

    test('propaga el error del servidor y no guarda sesion', () async {
      final cliente = clienteRuteado({
        'POST /api/usuarios': (_) => respuestaJson({'error': 'Correo repetido'}, 409),
      });
      final controlador = await crearControlador(cliente);

      expect(
        controlador.registrar('Ana', 'ana@correo.com', 'secreto1'),
        throwsA(isA<ExcepcionApi>().having((e) => e.mensaje, 'mensaje', 'Correo repetido')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controlador.autenticado, isFalse);
    });
  });

  group('iniciarSesion', () {
    test('guarda la sesion con las credenciales limpias', () async {
      final cliente = clienteRuteado({
        'POST /api/sesiones': (_) => respuestaJson(sesionDe('tok-login')),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.iniciarSesion(' ana@correo.com ', 'secreto1');

      final cuerpo = cuerpoDe(peticiones.single);
      expect(cuerpo['correo'], 'ana@correo.com');
      expect(cuerpo['contrasena'], 'secreto1');
      expect(controlador.autenticado, isTrue);
      expect(controlador.api.token, 'tok-login');
    });

    test('lanza la excepcion si las credenciales fallan', () async {
      final cliente = clienteRuteado({
        'POST /api/sesiones': (_) => respuestaJson({'error': 'Datos incorrectos'}, 401),
      });
      final controlador = await crearControlador(cliente);

      await expectLater(
        controlador.iniciarSesion('ana@correo.com', 'mala'),
        throwsA(isA<ExcepcionApi>()),
      );
      expect(controlador.autenticado, isFalse);
    });
  });

  group('cerrarSesion', () {
    test('avisa al servidor y limpia la sesion local', () async {
      final cliente = clienteRuteado({
        'POST /api/sesiones': (_) => respuestaJson(sesionDe('tok-login')),
        'DELETE /api/sesiones/actual': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');
      var avisos = 0;
      controlador.addListener(() => avisos++);

      await controlador.cerrarSesion();

      final prefs = await SharedPreferences.getInstance();
      expect(peticiones.last.method, 'DELETE');
      expect(controlador.autenticado, isFalse);
      expect(prefs.getString('trueque_token'), isNull);
      expect(avisos, 1);
    });

    test('cierra la sesion local aunque el servidor no responda', () async {
      final cliente = MockClient((peticion) async {
        if (peticion.method == 'POST') return respuestaJson(sesionDe('tok-login'));
        throw Exception('sin red');
      });
      final controlador = await crearControlador(cliente);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');

      await controlador.cerrarSesion();

      expect(controlador.autenticado, isFalse);
      expect(controlador.api.token, isNull);
    });
  });

  group('contrasenas y cuenta', () {
    test('recuperarContrasena manda el correo sin espacios', () async {
      final cliente = clienteRuteado({
        'POST /api/recuperaciones': (_) => respuestaJson({'mensaje': 'ok'}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.recuperarContrasena('  ana@correo.com ');

      expect(cuerpoDe(peticiones.single), {'correo': 'ana@correo.com'});
    });

    test('cambiarContrasena manda actual y nueva', () async {
      final cliente = clienteRuteado({
        'PUT /api/usuarios/contrasena': (_) => respuestaJson({'mensaje': 'ok'}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.cambiarContrasena('vieja12', 'nueva12');

      expect(cuerpoDe(peticiones.single), {
        'contrasenaActual': 'vieja12',
        'contrasenaNueva': 'nueva12',
      });
    });

    test('obtenerMisDatos devuelve el mapa o vacio si no es mapa', () async {
      Object cuerpo = {'nombre': 'Ana'};
      final cliente = clienteRuteado({
        'GET /api/usuarios/yo/datos': (_) => respuestaJson(cuerpo),
      });
      final controlador = await crearControlador(cliente);

      expect(await controlador.obtenerMisDatos(), {'nombre': 'Ana'});
      cuerpo = [1, 2];
      expect(await controlador.obtenerMisDatos(), isEmpty);
    });

    test('quitarTelefono llama a DELETE telefono', () async {
      final cliente = clienteRuteado({
        'DELETE /api/usuarios/yo/telefono': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.quitarTelefono();

      expect(peticiones.single.url.path, '/api/usuarios/yo/telefono');
    });

    test('descargarMisDatos pide el formato indicado como texto', () async {
      final cliente = MockClient((peticion) async {
        peticiones.add(peticion);
        return http.Response('a,b\n1,2', 200);
      });
      final controlador = await crearControlador(cliente);

      final texto = await controlador.descargarMisDatos('csv');

      expect(texto, 'a,b\n1,2');
      expect(peticiones.single.url.query, 'formato=csv');
    });

    test('eliminarCuenta devuelve los trueques cancelados', () async {
      final cliente = clienteRuteado({
        'DELETE /api/usuarios/yo': (_) => respuestaJson({'trueques_cancelados': 3}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      expect(await controlador.eliminarCuenta('secreto1'), 3);
      expect(cuerpoDe(peticiones.single), {'contrasena': 'secreto1'});
    });

    test('eliminarCuenta devuelve 0 si el servidor no informa cancelados', () async {
      Object cuerpo = {'mensaje': 'ok'};
      final cliente = clienteRuteado({
        'DELETE /api/usuarios/yo': (_) => respuestaJson(cuerpo),
      });
      final controlador = await crearControlador(cliente);

      expect(await controlador.eliminarCuenta('secreto1'), 0);
      cuerpo = [1];
      expect(await controlador.eliminarCuenta('secreto1'), 0);
    });

    test('olvidarSesion limpia todo y avisa', () async {
      final cliente = clienteRuteado({
        'POST /api/sesiones': (_) => respuestaJson(sesionDe('tok-login')),
      });
      final controlador = await crearControlador(cliente);
      await controlador.iniciarSesion('ana@correo.com', 'secreto1');
      var avisos = 0;
      controlador.addListener(() => avisos++);

      await controlador.olvidarSesion();

      final prefs = await SharedPreferences.getInstance();
      expect(controlador.autenticado, isFalse);
      expect(prefs.getString('trueque_token'), isNull);
      expect(avisos, 1);
    });
  });

  group('listas', () {
    final filas = [
      {'id': 1, 'titulo': 'Libro'},
      {'id': 2, 'titulo': 'Calculadora'},
    ];

    Future<ControladorAutenticacion> conRuta(String ruta, Object Function() cuerpo) {
      return crearControlador(
        clienteRuteado({
          'GET /api$ruta': (_) => respuestaJson(cuerpo()),
        }, registro: peticiones),
      );
    }

    test('obtenerAvisos convierte la lista y devuelve vacio si no es lista', () async {
      Object cuerpo = filas;
      final controlador = await conRuta('/notificaciones', () => cuerpo);

      expect(await controlador.obtenerAvisos(), filas);
      cuerpo = {'x': 1};
      expect(await controlador.obtenerAvisos(), isEmpty);
    });

    test('marcarAvisoLeido llama a PUT leida', () async {
      final controlador = await crearControlador(
        clienteRuteado({
          'PUT /api/notificaciones/5/leida': (_) => respuestaJson({}),
        }, registro: peticiones),
      );

      await controlador.marcarAvisoLeido(5);

      expect(peticiones.single.url.path, '/api/notificaciones/5/leida');
    });

    test('obtenerMisPublicaciones convierte la lista', () async {
      Object cuerpo = filas;
      final controlador = await conRuta('/publicaciones/mias', () => cuerpo);

      expect(await controlador.obtenerMisPublicaciones(), filas);
      cuerpo = {'x': 1};
      expect(await controlador.obtenerMisPublicaciones(), isEmpty);
    });

    test('obtenerIntercambios convierte la lista', () async {
      Object cuerpo = filas;
      final controlador = await conRuta('/publicaciones/intercambiadas', () => cuerpo);

      expect(await controlador.obtenerIntercambios(), filas);
      cuerpo = {'x': 1};
      expect(await controlador.obtenerIntercambios(), isEmpty);
    });

    test('obtenerOfertasRecibidas y enviadas usan su ruta', () async {
      final controlador = await crearControlador(
        clienteRuteado({
          'GET /api/ofertas/recibidas': (_) => respuestaJson(filas),
          'GET /api/ofertas/enviadas': (_) => respuestaJson({'x': 1}),
        }),
      );

      expect(await controlador.obtenerOfertasRecibidas(), filas);
      expect(await controlador.obtenerOfertasEnviadas(), isEmpty);
    });

    test('obtenerPublicacionesFeed sin filtros pide la ruta base', () async {
      final controlador = await conRuta('/publicaciones', () => filas);

      expect(await controlador.obtenerPublicacionesFeed(), filas);
      expect(peticiones.single.url.query, isEmpty);
    });

    test('obtenerPublicacionesFeed manda solo los filtros activos', () async {
      final controlador = await conRuta('/publicaciones', () => filas);

      await controlador.obtenerPublicacionesFeed(
        buscar: '  libro ',
        categoria: 'Libros',
        condicion: 'Nuevo',
        disponibilidad: 'disponible',
      );
      await controlador.obtenerPublicacionesFeed(buscar: '   ');

      expect(peticiones[0].url.queryParameters, {
        'buscar': 'libro',
        'categoria': 'Libros',
        'condicion': 'Nuevo',
        'disponibilidad': 'disponible',
      });
      expect(peticiones[1].url.query, isEmpty);
    });

    test('obtenerPublicacionesFeed devuelve vacio si no llega una lista', () async {
      final controlador = await conRuta('/publicaciones', () => {'x': 1});

      expect(await controlador.obtenerPublicacionesFeed(), isEmpty);
    });

    test('obtenerHistorial con y sin tipo', () async {
      Object cuerpo = filas;
      final controlador = await conRuta('/historial', () => cuerpo);

      expect(await controlador.obtenerHistorial(), filas);
      expect(await controlador.obtenerHistorial(tipo: 'reservas'), filas);
      cuerpo = {'x': 1};
      expect(await controlador.obtenerHistorial(), isEmpty);
      expect(peticiones[0].url.query, isEmpty);
      expect(peticiones[1].url.query, 'tipo=reservas');
    });

    test('obtenerHistorialOferta devuelve las propuestas', () async {
      Object cuerpo = {'propuestas': filas};
      final controlador = await conRuta('/ofertas/5/historial', () => cuerpo);

      expect(await controlador.obtenerHistorialOferta(5), filas);
      cuerpo = {'propuestas': 'nada'};
      expect(await controlador.obtenerHistorialOferta(5), isEmpty);
      cuerpo = [1];
      expect(await controlador.obtenerHistorialOferta(5), isEmpty);
    });
  });

  group('publicaciones', () {
    test('crearPublicacion manda los campos y omite los vacios', () async {
      final cliente = clienteRuteado({
        'POST /api/publicaciones': (_) => respuestaJson({}, 201),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.crearPublicacion(
        titulo: '  Libro ',
        descripcion: ' Casi nuevo ',
        estado: 'Nuevo',
        categoria: 'Libros',
        imagen: 'data:abc',
      );
      await controlador.crearPublicacion(
        titulo: 'Lapiz',
        descripcion: '  ',
        estado: 'Usado',
        categoria: 'Otros',
      );

      expect(cuerpoDe(peticiones[0]), {
        'titulo': 'Libro',
        'descripcion': 'Casi nuevo',
        'estado': 'Nuevo',
        'categoria': 'Libros',
        'imagen': 'data:abc',
      });
      expect(cuerpoDe(peticiones[1]), {
        'titulo': 'Lapiz',
        'estado': 'Usado',
        'categoria': 'Otros',
      });
    });

    test('reservar, completar y descartar usan su ruta PUT', () async {
      final cliente = clienteRuteado({
        'PUT /api/publicaciones/4/reservado': (_) => respuestaJson({}),
        'PUT /api/publicaciones/4/intercambiado': (_) => respuestaJson({}),
        'PUT /api/publicaciones/4/disponible': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.reservarPublicacion(4);
      await controlador.completarIntercambio(4);
      await controlador.descartarReservaPublicacion(4);

      expect(peticiones.map((p) => p.url.path), [
        '/api/publicaciones/4/reservado',
        '/api/publicaciones/4/intercambiado',
        '/api/publicaciones/4/disponible',
      ]);
    });

    test('cambiarEstadoPublicacion elige la ruta segun el estado', () async {
      final cliente = clienteRuteado({
        'PUT /api/publicaciones/4/disponible': (_) => respuestaJson({}),
        'PUT /api/publicaciones/4/oculto': (_) => respuestaJson({}),
        'PUT /api/publicaciones/4/no-disponible': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.cambiarEstadoPublicacion(4, 'disponible');
      await controlador.cambiarEstadoPublicacion(4, 'oculto');
      await controlador.cambiarEstadoPublicacion(4, 'no disponible');

      expect(peticiones.map((p) => p.url.path), [
        '/api/publicaciones/4/disponible',
        '/api/publicaciones/4/oculto',
        '/api/publicaciones/4/no-disponible',
      ]);
    });

    test('cambiarEstadoPublicacion rechaza un estado desconocido', () async {
      final controlador = await controladorSinRed();

      expect(
        controlador.cambiarEstadoPublicacion(4, 'volando'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('eliminarPublicacion llama a DELETE', () async {
      final cliente = clienteRuteado({
        'DELETE /api/publicaciones/9': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.eliminarPublicacion(9);

      expect(peticiones.single.method, 'DELETE');
    });

    test('editarPublicacion arma el cuerpo segun los datos', () async {
      final cliente = clienteRuteado({
        'PUT /api/publicaciones/9': (_) => respuestaJson({}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.editarPublicacion(
        9,
        titulo: ' Nuevo ',
        descripcion: ' texto ',
        imagen: 'data:img',
        quitarImagen: true,
      );
      await controlador.editarPublicacion(9, titulo: 'Solo titulo', descripcion: '  ');

      expect(cuerpoDe(peticiones[0]), {
        'titulo': 'Nuevo',
        'descripcion': 'texto',
        'quitar_imagen': true,
        'imagen': 'data:img',
      });
      expect(cuerpoDe(peticiones[1]), {'titulo': 'Solo titulo', 'descripcion': null});
    });
  });

  group('ofertas', () {
    test('crearOferta devuelve el mensaje o uno por defecto', () async {
      Object cuerpo = {'mensaje': 'Enviada!'};
      final cliente = clienteRuteado({
        'POST /api/ofertas': (_) => respuestaJson(cuerpo, 201),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      expect(
        await controlador.crearOferta(idPublicacionPedida: 1, idPublicacionOfrecida: 2),
        'Enviada!',
      );
      cuerpo = [1];
      expect(
        await controlador.crearOferta(idPublicacionPedida: 1, idPublicacionOfrecida: 2),
        'Oferta enviada',
      );
      expect(cuerpoDe(peticiones.first), {
        'id_publicacion_pedida': 1,
        'id_publicacion_ofrecida': 2,
      });
    });

    final acciones = <String, ({String ruta, String porDefecto, Future<String> Function(ControladorAutenticacion) llamar})>{
      'aceptarOferta': (
        ruta: 'PUT /api/ofertas/3/aceptada',
        porDefecto: 'Oferta aceptada',
        llamar: (c) => c.aceptarOferta(3),
      ),
      'rechazarOferta': (
        ruta: 'PUT /api/ofertas/3/rechazada',
        porDefecto: 'Oferta rechazada',
        llamar: (c) => c.rechazarOferta(3),
      ),
      'cancelarOferta': (
        ruta: 'PUT /api/ofertas/3/cancelada',
        porDefecto: 'Oferta cancelada',
        llamar: (c) => c.cancelarOferta(3),
      ),
      'confirmarEntrega': (
        ruta: 'PUT /api/ofertas/3/entrega',
        porDefecto: 'Entrega confirmada',
        llamar: (c) => c.confirmarEntrega(3),
      ),
      'cancelarIntercambio': (
        ruta: 'PUT /api/ofertas/3/anulada',
        porDefecto: 'Intercambio cancelado',
        llamar: (c) => c.cancelarIntercambio(3, 'ya no puedo'),
      ),
      'contraofertar': (
        ruta: 'POST /api/ofertas/3/contraoferta',
        porDefecto: 'Contraoferta enviada',
        llamar: (c) => c.contraofertar(3, 8),
      ),
      'proponerEntrega': (
        ruta: 'POST /api/propuestas-entrega',
        porDefecto: 'Propuesta enviada',
        llamar: (c) => c.proponerEntrega(3, {'lugar': 'Biblioteca'}),
      ),
      'contraproponerEntrega': (
        ruta: 'POST /api/propuestas-entrega/3/contrapropuesta',
        porDefecto: 'Contrapropuesta enviada',
        llamar: (c) => c.contraproponerEntrega(3, {'lugar': 'Cafeteria'}),
      ),
      'aceptarEntrega': (
        ruta: 'PUT /api/propuestas-entrega/3/aceptada',
        porDefecto: 'Propuesta aceptada',
        llamar: (c) => c.aceptarEntrega(3),
      ),
      'calificarIntercambio': (
        ruta: 'POST /api/calificaciones',
        porDefecto: 'Calificación enviada',
        llamar: (c) => c.calificarIntercambio(3, 5, 'Excelente'),
      ),
    };

    acciones.forEach((nombre, accion) {
      test('$nombre devuelve el mensaje del servidor o el de por defecto', () async {
        Object cuerpo = {'mensaje': 'Mensaje del servidor'};
        final controlador = await crearControlador(
          clienteRuteado({accion.ruta: (_) => respuestaJson(cuerpo)}),
        );

        expect(await accion.llamar(controlador), 'Mensaje del servidor');
        cuerpo = [1];
        expect(await accion.llamar(controlador), accion.porDefecto);
      });
    });

    test('cancelarIntercambio manda el motivo', () async {
      final cliente = clienteRuteado({
        'PUT /api/ofertas/3/anulada': (_) => respuestaJson({'mensaje': 'ok'}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.cancelarIntercambio(3, 'ya no puedo');

      expect(cuerpoDe(peticiones.single), {'motivo': 'ya no puedo'});
    });

    test('proponerEntrega incluye el id de la oferta y la propuesta', () async {
      final cliente = clienteRuteado({
        'POST /api/propuestas-entrega': (_) => respuestaJson({'mensaje': 'ok'}),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      await controlador.proponerEntrega(3, {'lugar': 'Biblioteca'});

      expect(cuerpoDe(peticiones.single), {'id_oferta': 3, 'lugar': 'Biblioteca'});
    });

    test('obtenerEntrega devuelve el mapa o vacio', () async {
      Object cuerpo = {'estado': 'pendiente'};
      final cliente = clienteRuteado({
        'GET /api/propuestas-entrega': (_) => respuestaJson(cuerpo),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      expect(await controlador.obtenerEntrega(3), {'estado': 'pendiente'});
      cuerpo = [1];
      expect(await controlador.obtenerEntrega(3), isEmpty);
      expect(peticiones.first.url.query, 'id_oferta=3');
    });

    test('obtenerMiCalificacion devuelve la calificacion o null', () async {
      Object cuerpo = {
        'mia': {'puntaje': 4},
      };
      final cliente = clienteRuteado({
        'GET /api/calificaciones': (_) => respuestaJson(cuerpo),
      });
      final controlador = await crearControlador(cliente);

      expect(await controlador.obtenerMiCalificacion(3), {'puntaje': 4});
      cuerpo = {'mia': null};
      expect(await controlador.obtenerMiCalificacion(3), isNull);
      cuerpo = [1];
      expect(await controlador.obtenerMiCalificacion(3), isNull);
    });

    test('obtenerResumenCalificaciones devuelve el mapa o vacio', () async {
      Object cuerpo = {'cantidad': 2, 'promedio': 4.5};
      final cliente = clienteRuteado({
        'GET /api/calificaciones/resumen': (_) => respuestaJson(cuerpo),
      }, registro: peticiones);
      final controlador = await crearControlador(cliente);

      expect(await controlador.obtenerResumenCalificaciones(7), {'cantidad': 2, 'promedio': 4.5});
      cuerpo = [1];
      expect(await controlador.obtenerResumenCalificaciones(7), isEmpty);
      expect(peticiones.first.url.query, 'id_usuario=7');
    });
  });
}
