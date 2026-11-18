import 'package:flutter/material.dart';

import 'banner_error.dart';
import '../tema.dart';

/// Mensaje de error con un botón "Reintentar" debajo.
class ErrorConReintento extends StatelessWidget {
  const ErrorConReintento({
    super.key,
    required this.mensaje,
    required this.alReintentar,
  });

  final String? mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Espacios.e24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BannerError(mensaje),
              FilledButton.tonal(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
