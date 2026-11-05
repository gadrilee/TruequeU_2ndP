import 'package:flutter/material.dart';

/// Etiqueta visual pequeña que indica el estado actual de la publicación
class ChipEstado extends StatelessWidget {
  const ChipEstado({
    super.key,
    required this.estado,
    required this.loReserveYo,
  });

  final String estado;
  final bool loReserveYo;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    Color fondo;
    Color texto;
    String etiqueta;

    switch (estado) {
      case 'disponible':
        fondo = Colors.green.shade100;
        texto = Colors.green.shade900;
        etiqueta = 'Disponible';
        break;
      case 'reservado':
        fondo = loReserveYo ? colores.primaryContainer : Colors.amber.shade100;
        texto = loReserveYo ? colores.onPrimaryContainer : Colors.amber.shade900;
        etiqueta = loReserveYo ? 'Reservado por ti' : 'Reservado';
        break;
      case 'intercambiado':
        fondo = Colors.blue.shade100;
        texto = Colors.blue.shade900;
        etiqueta = 'Intercambiado';
        break;
      case 'acordado':
        fondo = Colors.purple.shade100;
        texto = Colors.purple.shade900;
        etiqueta = 'Intercambio acordado';
        break;
      case 'no disponible':
        fondo = Colors.grey.shade200;
        texto = Colors.grey.shade700;
        etiqueta = 'No disponible';
        break;
      default:
        fondo = colores.surfaceContainerHighest;
        texto = colores.onSurfaceVariant;
        etiqueta = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: texto,
        ),
      ),
    );
  }
}
