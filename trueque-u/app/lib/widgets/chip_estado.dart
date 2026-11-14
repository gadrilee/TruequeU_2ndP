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
        fondo = colores.primaryContainer;
        texto = colores.onPrimaryContainer;
        etiqueta = 'Disponible';
        break;
      case 'reservado':
        fondo = colores.secondaryContainer;
        texto = colores.onSecondaryContainer;
        etiqueta = loReserveYo ? 'Reservado por ti' : 'Reservado';
        break;
      case 'intercambiado':
        fondo = colores.tertiaryContainer;
        texto = colores.onTertiaryContainer;
        etiqueta = 'Intercambiado';
        break;
      case 'acordado':
        fondo = colores.primary;
        texto = colores.onPrimary;
        etiqueta = 'Intercambio acordado';
        break;
      case 'no disponible':
        fondo = colores.surfaceContainerHighest;
        texto = colores.onSurfaceVariant;
        etiqueta = 'No disponible';
        break;
      default:
        fondo = colores.surfaceContainerHighest;
        texto = colores.onSurfaceVariant;
        etiqueta = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
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
