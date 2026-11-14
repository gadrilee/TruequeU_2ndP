import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../widgets/pagina_acceso.dart';
import '../widgets/resumen_calificaciones.dart';

/// RUTA PRIVADA ("/perfil"): sin sesión, el router redirige a "/iniciar-sesion".
class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  String _iniciales(String nombre) {
    final palabras = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return '?';
    if (palabras.length == 1) return palabras.first[0].toUpperCase();
    return (palabras[0][0] + palabras[1][0]).toUpperCase();
  }

  Widget _opcion(BuildContext context, IconData icono, String texto, String ruta) {
    return ListTile(
      leading: Icon(icono, color: Theme.of(context).colorScheme.primary),
      title: Text(texto),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(ruta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<ControladorAutenticacion>().usuario;
    // Al cerrar sesión, el router tarda un instante en redirigir.
    if (usuario == null) return const SizedBox.shrink();

    final colores = Theme.of(context).colorScheme;

    return PaginaAcceso(
      titulo: 'Mi perfil',
      hijos: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: colores.primary,
            child: Text(
              _iniciales(usuario.nombre),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colores.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          usuario.nombre,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (usuario.correo != null) ...[
          const SizedBox(height: 4),
          Text(
            usuario.correo!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 8),
        ResumenCalificaciones(
          key: ValueKey('calificaciones-${usuario.id}'),
          idUsuario: usuario.id,
        ),
        const SizedBox(height: 24),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _opcion(context, Icons.handshake_outlined, 'Intercambios completados', '/intercambios'),
              const Divider(height: 1),
              _opcion(context, Icons.history, 'Historial', '/historial'),
              const Divider(height: 1),
              _opcion(context, Icons.key_outlined, 'Cambiar contraseña', '/cambiar-contrasena'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colores.error,
            side: BorderSide(color: colores.error),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          onPressed: () => context.read<ControladorAutenticacion>().cerrarSesion(),
        ),
      ],
    );
  }
}
