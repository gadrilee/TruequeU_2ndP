import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utilidades/etiquetas.dart';
import 'chip_estado.dart';
import 'foto_publicacion.dart';
import '../tema.dart';

/// =========================================================================
/// COMPONENTE CARD DEL FEED
/// =========================================================================
/// Renderiza cada tarjeta con sus datos esenciales, badges informativos y botón
/// interactivo de Reservar / Descartar.
class TarjetaFeed extends StatelessWidget {
  const TarjetaFeed({
    super.key,
    required this.id,
    required this.titulo,
    this.descripcion,
    this.imagenUrl,
    required this.estadoFisico,
    required this.categoria,
    required this.estadoPublicacion,
    required this.nombreAutor,
    this.nombreReserva,
    this.telefonoDueno,
    required this.estaReservado,
    required this.loReserveYo,
    required this.esMiPublicacion,
    this.ofertaEnviada = false,
    required this.enProgreso,
    required this.alContactar,
    required this.alReservar,
    required this.alOfertar,
    required this.alDescartar,
    required this.alCompletar,
  });

  final int id;
  final String titulo;
  final String? descripcion;
  final String? imagenUrl;
  final String estadoFisico; // 'nuevo' o 'usado'
  final String categoria; // 'libros', 'electronica',....
  final String estadoPublicacion; // 'disponible', 'reservado', etc.
  final String nombreAutor;
  final String? nombreReserva;
  final String? telefonoDueno; // solo llega si yo reservé
  final bool estaReservado;
  final bool loReserveYo;
  final bool esMiPublicacion;
  final bool ofertaEnviada;
  final bool enProgreso;
  final VoidCallback alContactar;
  final VoidCallback alReservar;
  final VoidCallback alOfertar;
  final VoidCallback alDescartar;
  final VoidCallback alCompletar;

  @override
  Widget build(BuildContext context) {

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.r20),
        side: BorderSide(
          color: loReserveYo ? TemaTruequeU.azul : TemaTruequeU.borde,
          width: loReserveYo ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Espacios.e16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: FotoPublicacion(url: imagenUrl)),
            const SizedBox(height: Espacios.e10),
            // Fila superior: Título del objeto y Chip de estado de publicación
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextosTruequeU.tituloTarjeta,
                  ),
                ),
                const SizedBox(width: Espacios.e8),
                ChipEstado(
                  estado: estadoPublicacion,
                  loReserveYo: loReserveYo,
                ),
              ],
            ),
            const SizedBox(height: Espacios.e6),

            // Autor de la publicación
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: TemaTruequeU.contorno),
                const SizedBox(width: Espacios.e4),
                Text(
                  esMiPublicacion ? 'Publicado por ti' : 'Por: $nombreAutor',
                  style: TextStyle(
                    fontSize: Tipos.t12,
                    fontWeight:
                        esMiPublicacion ? FontWeight.bold : FontWeight.normal,
                    color: esMiPublicacion ? TemaTruequeU.azul : TemaTruequeU.contorno,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espacios.e8),

            Text(
              (descripcion != null && descripcion!.trim().isNotEmpty)
                  ? descripcion!
                  : 'Sin descripción detallada',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextosTruequeU.detalle.copyWith(color: (descripcion != null && descripcion!.trim().isNotEmpty)
                    ? TemaTruequeU.textoSuave
                    : TemaTruequeU.contorno),
            ),
            const SizedBox(height: Espacios.e8),

            // Chips de estado del objeto e información de reserva si aplica
            Wrap(
              spacing: Espacios.e6,
              runSpacing: Espacios.e4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Espacios.e8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TemaTruequeU.azulClaro,
                    borderRadius: BorderRadius.circular(Radios.r8),
                  ),
                  child: Text(
                    estadoFisico == 'nuevo'
                        ? 'Condición: Nuevo'
                        : 'Condición: Usado',
                    style: TextosTruequeU.chip.copyWith(color: TemaTruequeU.azulOscuro),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Espacios.e8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TemaTruequeU.azulClaro,
                    borderRadius: BorderRadius.circular(Radios.r8),
                  ),
                  child: Text(
                    'Categoría: ${etiquetasCategoria[categoria] ?? 'Otros'}',
                    style: TextosTruequeU.chip.copyWith(color: TemaTruequeU.azulOscuro),
                  ),
                ),
                // Quién reservó: solo si fue otra persona (si fui yo, ya lo dice el chip superior)
                if (estaReservado && !loReserveYo && nombreReserva != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Espacios.e8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TemaTruequeU.rojoClaro,
                      borderRadius: BorderRadius.circular(Radios.r8),
                    ),
                    child: Text(
                      'Reservado por: $nombreReserva',
                      style: const TextStyle(
                        fontSize: Tipos.t11,
                        fontWeight: FontWeight.w600,
                        color: TemaTruequeU.rojoOscuro,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Espacios.e12),

            // BOTÓN DE ACCIÓN: Reservar / Descartar
            SizedBox(
              width: double.infinity,
              child: _construirBotonAccion(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el botón interactivo según el estado de la reserva y el usuario
  Widget _construirBotonAccion(BuildContext context) {

    // Si hay una operación asíncrona en curso en esta card
    if (enProgreso) {
      return const Center(
        child: SizedBox(
          height: 36,
          width: 36,
          child: Padding(
            padding: EdgeInsets.all(Espacios.e8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Intercambio ya completado: no se puede hacer nada más
    if (estadoPublicacion == 'intercambiado') {
      return const FilledButton.tonal(
        onPressed: null,
        child: Text('Intercambio completado'),
      );
    }

    if (estadoPublicacion == 'acordado') {
      return const FilledButton.tonal(
        onPressed: null,
        child: Text('Intercambio acordado'),
      );
    }

    // Caso 1: Reservada por el usuario actual -> puede completar o cancelar la reserva
    if (estaReservado && loReserveYo) {
      final tieneTelefono = telefonoDueno != null && telefonoDueno!.isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.handshake_outlined, size: 18),
            label: const Text('Completar intercambio'),
            onPressed: alCompletar,
          ),
          const SizedBox(height: Espacios.e6),
          Row(
            children: [
              // H7: quien reservó escribe al dueño con un toque para coordinar la entrega
              if (tieneTelefono) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                    onPressed: alContactar,
                  ),
                ),
                const SizedBox(width: Espacios.e8),
              ],
              // H3: salida de emergencia para quien reservó por error
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar reserva'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaTruequeU.rojo,
                    side: const BorderSide(color: TemaTruequeU.rojo),
                  ),
                  onPressed: alDescartar,
                ),
              ),
            ],
          ),
          if (!tieneTelefono) ...[
            const SizedBox(height: Espacios.e4),
            Text(
              'El contacto se ve cuando los dos aceptan',
              textAlign: TextAlign.center,
              style: TextosTruequeU.pie.copyWith(color: TemaTruequeU.contorno),
            ),
          ],
        ],
      );
    }

    // Caso 2: Reservada y es mi publicación -> el dueño puede completar el intercambio
    if (estaReservado && esMiPublicacion) {
      return FilledButton.icon(
        icon: const Icon(Icons.handshake_outlined, size: 18),
        label: const Text('Completar intercambio'),
        onPressed: alCompletar,
      );
    }

    // Caso 2b: Reservada por otra persona -> Botón deshabilitado
    if (estaReservado) {
      return const FilledButton.tonal(
        onPressed: null,
        child: Text('Reservado'),
      );
    }

    // Caso 3: Es la propia publicación del usuario y está disponible
    if (esMiPublicacion) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Ver en mis publicaciones'),
        onPressed: () => context.go('/mis-publicaciones'),
      );
    }

    if (ofertaEnviada) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FilledButton.tonal(
            onPressed: null,
            child: Text('Oferta enviada'),
          ),
          const SizedBox(height: Espacios.e6),
          OutlinedButton(
            onPressed: () => context.go('/ofertas'),
            child: const Text('Ver mis ofertas'),
          ),
        ],
      );
    }

    // Caso 4: Publicación disponible de otro usuario -> Botón "Reservar"
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Ofrecer un objeto'),
          onPressed: alOfertar,
        ),
        const SizedBox(height: Espacios.e2),
        TextButton.icon(
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Reservar'),
          onPressed: alReservar,
        ),
        Text(
          'Ofrecer: cambias un objeto tuyo. Reservar: solo lo apartas.',
          textAlign: TextAlign.center,
          style: TextosTruequeU.pie.copyWith(color: TemaTruequeU.contorno),
        ),
      ],
    );
  }
}
