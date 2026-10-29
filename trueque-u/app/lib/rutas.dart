import 'package:go_router/go_router.dart';

import 'estado/controlador_autenticacion.dart';
import 'pantallas/Publicacion.dart';
import 'pantallas/pantalla_cambiar_contrasena.dart';
import 'pantallas/pantalla_feed_publicaciones.dart';
import 'pantallas/pantalla_historial.dart';
import 'pantallas/pantalla_iniciar_sesion.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_intercambios.dart';
import 'pantallas/pantalla_mis_publicaciones.dart';
import 'pantallas/pantalla_ofertas.dart';
import 'pantallas/pantalla_perfil.dart';
import 'pantallas/pantalla_recuperar_contrasena.dart';
import 'pantallas/pantalla_registro.dart';

/// Rutas que exigen sesión iniciada (protegidas).
const _rutasPrivadas = {
  '/perfil',
  '/cambiar-contrasena',
  '/publicacion',
  '/mis-publicaciones',
  '/feed', // Feed general de publicaciones en cuadrícula
  '/intercambios', // Intercambios completados de la persona
  '/ofertas',
  '/historial', // Qué ocurrió con los intercambios de la persona
};

/// Rutas que no tienen sentido si ya hay sesión.
const _rutasSoloInvitados = {'/iniciar-sesion', '/registro'};

GoRouter construirRutas(ControladorAutenticacion autenticacion) {
  return GoRouter(
    initialLocation: '/',
    // Cada vez que la sesión cambia (inicio o cierre) se vuelve a evaluar redirect.
    refreshListenable: autenticacion,
    redirect: (context, estado) {
      final ruta = estado.uri.path;

      // Ruta privada sin sesión -> inicio de sesión.
      if (_rutasPrivadas.contains(ruta) && !autenticacion.autenticado) {
        return '/iniciar-sesion';
      }
      // Inicio de sesión o registro con sesión activa -> directo al perfil.
      if (_rutasSoloInvitados.contains(ruta) && autenticacion.autenticado) {
        return '/perfil';
      }
      return null;
    },
    routes: [
      // PÚBLICAS: se abren sin iniciar sesión.
      GoRoute(path: '/', builder: (context, estado) => const PantallaInicio()),
      GoRoute(
        path: '/iniciar-sesion',
        builder: (context, estado) => const PantallaIniciarSesion(),
      ),
      GoRoute(
        path: '/registro',
        builder: (context, estado) => const PantallaRegistro(),
      ),
      GoRoute(
        path: '/recuperar-contrasena',
        builder: (context, estado) => const PantallaRecuperarContrasena(),
      ),
      // PRIVADAS: exigen sesión (ver redirect).
      GoRoute(
        path: '/perfil',
        builder: (context, estado) => const PantallaPerfil(),
      ),
      GoRoute(
        path: '/cambiar-contrasena',
        builder: (context, estado) => const PantallaCambiarContrasena(),
      ),
      GoRoute(
        path: '/publicacion',
        builder: (context, estado) => const PantallaPublicacion(),
      ),
      GoRoute(
        path: '/mis-publicaciones',
        builder: (context, estado) => const PantallaMisPublicaciones(),
      ),
      // Intercambios completados de la persona con sesión
      GoRoute(
        path: '/intercambios',
        builder: (context, estado) => const PantallaIntercambios(),
      ),
      GoRoute(
        path: '/ofertas',
        builder: (context, estado) => const PantallaOfertas(),
      ),
      // Historial de reservas e intercambios de la persona con sesión
      GoRoute(
        path: '/historial',
        builder: (context, estado) => const PantallaHistorial(),
      ),
      // Feed general: vista pública en cuadrícula de todas las ofertas de trueque
      GoRoute(
        path: '/feed',
        builder: (context, estado) => const PantallaFeedPublicaciones(),
      ),
    ],
  );
}
