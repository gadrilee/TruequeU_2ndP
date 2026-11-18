import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/pagina_acceso.dart';
import '../tema.dart';

/// RUTA PÚBLICA ("/"): se abre sin iniciar sesión.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return PaginaAcceso(
      titulo: 'Trueque U',
      subtitulo: 'Intercambia objetos y materiales con otros estudiantes.',
      conLogo: true,
      hijos: [
        const SizedBox(height: Espacios.e16),
        FilledButton(
          onPressed: () => context.go('/iniciar-sesion'),
          child: const Text('Iniciar sesión'),
        ),
        const SizedBox(height: Espacios.e12),
        OutlinedButton(
          onPressed: () => context.go('/registro'),
          child: const Text('Crear cuenta'),
        ),
      ],
    );
  }
}
