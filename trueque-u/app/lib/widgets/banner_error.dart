import 'package:flutter/material.dart';
import '../tema.dart';

/// Mensaje de error del servidor, mostrado encima del botón.
class BannerError extends StatelessWidget {
  const BannerError(this.mensaje, {super.key});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    if (mensaje == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: Espacios.e16),
      padding: const EdgeInsets.all(Espacios.e12),
      decoration: BoxDecoration(
        color: TemaTruequeU.rojoClaro,
        borderRadius: BorderRadius.circular(Radios.r8),
      ),
      child: Text(mensaje!, style: const TextStyle(color: TemaTruequeU.rojoOscuro)),
    );
  }
}
