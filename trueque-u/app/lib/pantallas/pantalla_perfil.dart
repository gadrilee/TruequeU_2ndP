import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../widgets/pagina_acceso.dart';

/// RUTA PRIVADA ("/perfil"): sin sesión, el router redirige a "/iniciar-sesion".
///
/// Mejora de interacción (Clase 16):
/// - Fitts: botones más altos y "Cerrar sesión" separada del resto.
/// - Hick: acciones agrupadas en dos bloques y una sola acción principal.
/// - Carga cognitiva: etiquetas distintas entre sí y relleno solo en la principal.
class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  // Alto mínimo de los botones. Se usa la densidad estándar porque en escritorio
  // la densidad por defecto es compacta y deja los botones más bajos.
  static const _alto = Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<ControladorAutenticacion>().usuario;
    // Al cerrar sesión, el router tarda un instante en redirigir.
    if (usuario == null) return const SizedBox.shrink();

    final colores = Theme.of(context).colorScheme;
    final estiloTitulo = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: colores.onSurfaceVariant);

    final estiloPrincipal = FilledButton.styleFrom(
      minimumSize: _alto,
      visualDensity: VisualDensity.standard,
    );
    final estiloContorno = OutlinedButton.styleFrom(
      minimumSize: _alto,
      visualDensity: VisualDensity.standard,
    );
    // Cerrar sesión: sin relleno y en rojo, para que no se confunda con las demás.
    final estiloSalir = TextButton.styleFrom(
      minimumSize: _alto,
      visualDensity: VisualDensity.standard,
      foregroundColor: colores.error,
    );

    return PaginaAcceso(
      titulo: 'Mi perfil',
      hijos: [
        Text(
          'Hola, ${usuario.nombre}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),

        // ---- Bloque 1: publicaciones (la acción principal va primero) ----
        Text('PUBLICACIONES', style: estiloTitulo),
        const SizedBox(height: 8),
        FilledButton(
          style: estiloPrincipal,
          // Feed de todas las publicaciones (cards en cuadrícula)
          onPressed: () => context.go('/feed'),
          child: const Text('Explorar publicaciones'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: estiloContorno,
          onPressed: () => context.go('/publicacion'),
          child: const Text('Crear nueva publicación'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: estiloContorno,
          onPressed: () => context.go('/mis-publicaciones'),
          child: const Text('Mis publicaciones'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: estiloContorno,
          onPressed: () => context.go('/ofertas'),
          child: const Text('Ofertas de trueque'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: estiloContorno,
          onPressed: () => context.go('/historial'),
          child: const Text('Historial'),
        ),
        const SizedBox(height: 24),

        // ---- Bloque 2: cuenta ----
        Text('CUENTA', style: estiloTitulo),
        const SizedBox(height: 8),
        OutlinedButton(
          style: estiloContorno,
          onPressed: () => context.go('/cambiar-contrasena'),
          child: const Text('Cambiar contraseña'),
        ),

        // Espacio grande para que "Cerrar sesión" no se toque por error.
        const SizedBox(height: 40),
        TextButton(
          style: estiloSalir,
          // Al cerrar la sesión, el router redirige solo al inicio de sesión.
          onPressed: () => context.read<ControladorAutenticacion>().cerrarSesion(),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
