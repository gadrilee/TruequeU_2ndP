import 'package:flutter/material.dart';
import '../tema.dart';

/// Mensaje de error del servidor, mostrado encima del botón.
class BannerError extends StatelessWidget {
  const BannerError(this.mensaje, {super.key});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    if (mensaje == null) return const SizedBox.shrink();
    final colores = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Espacios.e16),
      padding: const EdgeInsets.all(Espacios.e12),
      decoration: BoxDecoration(
        color: colores.errorContainer,
        borderRadius: BorderRadius.circular(Radios.r8),
      ),
      child: Text(mensaje!, style: TextStyle(color: colores.onErrorContainer)),
    );
  }
}
