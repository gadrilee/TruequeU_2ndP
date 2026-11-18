import 'package:flutter/material.dart';

import '../utilidades/etiquetas.dart';
import 'etiqueta.dart';
import 'foto_publicacion.dart';
import '../tema.dart';

/// =========================================================================
/// TARJETA DE PUBLICACIÓN PROPIA
/// =========================================================================
/// Muestra los detalles de la publicación del usuario, el estado actual,
/// quién la reservó (si aplica) y las acciones que sí se pueden hacer.
///
/// Ley de Hick (Clase 16): si la publicación está reservada, el servidor
/// rechaza editar, cambiar el estado y eliminar. Por eso en ese caso esos
/// controles no se muestran y solo quedan "Completar" y WhatsApp.
class TarjetaMiPublicacion extends StatelessWidget {
  const TarjetaMiPublicacion({
    super.key,
    required this.id,
    required this.titulo,
    this.descripcion,
    this.imagenUrl,
    required this.estado,
    required this.categoria,
    required this.estadoPublicacion,
    this.nombreReserva,
    this.telefonoReserva,
    required this.enProgreso,
    required this.alCompletar,
    required this.alAbrirWhatsapp,
    required this.alEditar,
    required this.alEliminar,
    required this.alDescartarReserva,
    required this.alCambiarEstado,
  });

  final int id;
  final String titulo;
  final String? descripcion;
  final String? imagenUrl;
  final String estado;
  final String categoria;
  final String estadoPublicacion;
  final String? nombreReserva;
  final String? telefonoReserva;
  final bool enProgreso; // hay una acción en curso con esta publicación
  final VoidCallback alCompletar;
  final VoidCallback alAbrirWhatsapp;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;
  final VoidCallback alDescartarReserva;
  final ValueChanged<String> alCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final estaReservada = estadoPublicacion == 'reservado';
    final estaAcordada = estadoPublicacion == 'acordado';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.r20),
        side: BorderSide(
          color: estaReservada ? colores.primary : colores.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Espacios.e16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de progreso mientras el servidor responde
            if (enProgreso) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: Espacios.e8),
            ],
            FotoPublicacion(url: imagenUrl, cuadrada: true),
            const SizedBox(height: Espacios.e12),
            // Encabezado: Título y menú de opciones (editar / cambiar estado / eliminar)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextosTruequeU.tituloTarjeta,
                  ),
                ),
                // Con la publicación reservada estos tres controles no se
                // muestran: el servidor los rechazaría (Ley de Hick).
                if (!estaReservada && !estaAcordada) ...[
                  // Botón lápiz para editar nombre y descripción
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colores.primary,
                    ),
                    tooltip: 'Editar información',
                    onPressed: enProgreso ? null : alEditar,
                  ),
                  const SizedBox(width: Espacios.e8),
                  // Selector de modo / estado_publicacion
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Cambiar estado de la publicación',
                    enabled: !enProgreso,
                    onSelected: alCambiarEstado,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'disponible',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: colores.tertiary),
                            const SizedBox(width: Espacios.e8),
                            const Text('Marcar como Disponible'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'oculto',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off_outlined, size: 18, color: colores.onSurfaceVariant),
                            const SizedBox(width: Espacios.e8),
                            const Text('Ocultar publicación'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'no disponible',
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined, size: 18, color: colores.error),
                            const SizedBox(width: Espacios.e8),
                            const Text('Marcar como No disponible'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Acción destructiva separada de las demás, con área táctil estándar (Ley de Fitts)
                  const SizedBox(width: Espacios.e8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: colores.error,
                    tooltip: 'Eliminar definitivamente',
                    onPressed: enProgreso ? null : alEliminar,
                  ),
                ],
              ],
            ),
            if (descripcion != null && descripcion!.trim().isNotEmpty) ...[
              const SizedBox(height: Espacios.e6),
              Text(
                descripcion!,
                style: TextosTruequeU.cuerpo.copyWith(color: colores.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: Espacios.e12),

            // Chips con la condición del objeto y el estado de la publicación
            Wrap(
              spacing: Espacios.e8,
              runSpacing: Espacios.e4,
              children: [
                Etiqueta(
                  icono: Icons.label_outline,
                  texto: estado == 'nuevo' ? 'Nuevo' : 'Usado',
                  fondo: colores.primaryContainer,
                  colorTexto: colores.onPrimaryContainer,
                ),
                Etiqueta(
                  icono: Icons.category_outlined,
                  texto: etiquetasCategoria[categoria] ?? 'Otros',
                  fondo: colores.primaryContainer,
                  colorTexto: colores.onPrimaryContainer,
                ),
                Etiqueta(
                  icono: Icons.info_outline,
                  texto: _formatearEstadoPublicacion(estadoPublicacion),
                  fondo: estaReservada
                      ? colores.secondaryContainer
                      : colores.primaryContainer,
                  colorTexto: estaReservada
                      ? colores.onSecondaryContainer
                      : colores.onPrimaryContainer,
                ),
                // Indicador explícito de quién reservó la publicación
                if (estaReservada)
                  Etiqueta(
                    icono: Icons.person_pin_outlined,
                    texto: nombreReserva != null
                        ? 'Reservado por: $nombreReserva'
                        : 'Reservado por un usuario',
                    fondo: colores.secondaryContainer,
                    colorTexto: colores.onSecondaryContainer,
                  ),
                if (estaReservada)
                  Etiqueta(
                    icono: Icons.phone_outlined,
                    texto: 'El contacto se ve cuando los dos aceptan',
                    fondo: colores.primaryContainer,
                    colorTexto: colores.onPrimaryContainer,
                  ),
                if (estaAcordada &&
                    telefonoReserva != null &&
                    telefonoReserva!.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(Radios.r16),
                    onTap: alAbrirWhatsapp,
                    child: Tooltip(
                      message: 'Abrir WhatsApp',
                      child: Etiqueta(
                        icono: Icons.chat_outlined,
                        texto: 'Escribir por WhatsApp',
                        fondo: colores.tertiaryContainer,
                        colorTexto: colores.onTertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),

            // Como ya no se ven editar ni eliminar, se explica el porqué
            if (estaReservada) ...[
              const SizedBox(height: Espacios.e8),
              Text(
                'Está reservada: solo puedes completar el intercambio.',
                style: TextosTruequeU.ayuda.copyWith(color: colores.onSurfaceVariant),
              ),
            ],

            if (estaAcordada) ...[
              const SizedBox(height: Espacios.e8),
              Text(
                'Tiene un intercambio acordado: confirma la entrega o cancélalo en Ofertas de trueque.',
                style: TextosTruequeU.ayuda.copyWith(color: colores.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: Espacios.e12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: Espacios.e8,
              runSpacing: Espacios.e8,
              children: [
                // Descartar la reserva (volver a disponible): comentado por ahora
                // if (estaReservada)
                //   OutlinedButton.icon(
                //     icon: const Icon(Icons.undo, size: 16),
                //     label: const Text('Descartar reserva'),
                //     style: OutlinedButton.styleFrom(
                //       visualDensity: VisualDensity.compact,
                //     ),
                //     onPressed: alDescartarReserva,
                //   ),
                // Completar el intercambio: solo funciona si está reservada
                // (si no, al tocarlo se explica el motivo)
                Tooltip(
                  message: estaReservada
                      ? 'Completar el intercambio'
                      : 'Disponible cuando alguien reserve la publicación',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.handshake_outlined, size: 16),
                    label: const Text('Completar intercambio'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    // Sin reserva se deshabilita de verdad (igual que en el feed)
                    onPressed: (estaReservada && !enProgreso) ? alCompletar : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearEstadoPublicacion(String valor) {
    switch (valor) {
      case 'disponible':
        return 'Disponible';
      case 'reservado':
        return 'Reservado';
      case 'intercambiado':
        return 'Intercambiado';
      case 'acordado':
        return 'Intercambio acordado';
      case 'oculto':
        return 'Oculto';
      case 'no disponible':
        return 'No disponible';
      default:
        return valor;
    }
  }
}
