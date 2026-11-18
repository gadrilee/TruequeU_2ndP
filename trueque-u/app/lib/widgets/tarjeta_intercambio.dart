import 'package:flutter/material.dart';

import '../utilidades/etiquetas.dart';
import '../tema.dart';

/// Una tarjeta por intercambio completado: el objeto y con quién se hizo.
class TarjetaIntercambio extends StatelessWidget {
  const TarjetaIntercambio({
    super.key,
    required this.pub,
    required this.idYo,
  });

  final Map<String, dynamic> pub; // la publicación intercambiada
  final int? idYo; // id de la persona con sesión

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final autor = pub['autor'] as Map<String, dynamic>?;
    final reserva = pub['usuario_reserva'] as Map<String, dynamic>?;
    final fueDueno = (pub['id_usuario'] as num?)?.toInt() == idYo;

    // La otra persona del intercambio
    final otra = fueDueno ? reserva : autor;
    final nombreOtra = otra?['nombre'] as String? ?? 'otra persona';
    final categoria = etiquetasCategoria[pub['categoria']] ?? 'Otros';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(Espacios.e16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (pub['titulo'] as String?) ?? 'Sin título',
              style: TextosTruequeU.tituloTarjeta,
            ),
            const SizedBox(height: Espacios.e6),
            Text(
              fueDueno
                  ? 'Lo entregaste a: $nombreOtra'
                  : 'Lo recibiste de: $nombreOtra',
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
            const SizedBox(height: Espacios.e8),
            Wrap(
              spacing: Espacios.e8,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Categoría: $categoria'),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Intercambiado'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
