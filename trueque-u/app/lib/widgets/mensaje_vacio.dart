import 'package:flutter/material.dart';
import '../tema.dart';

/// Mensaje centrado para cuando no hay nada que mostrar:
/// un ícono, un título, un texto opcional y un botón opcional.
class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoBoton,
    this.alBoton,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoBoton;
  final VoidCallback? alBoton;

  @override
  Widget build(BuildContext context) {

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(Espacios.e32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 64, color: TemaTruequeU.contorno),
              const SizedBox(height: Espacios.e16),
              Text(
                titulo,
                style: TextosTruequeU.subtitulo,
                textAlign: TextAlign.center,
              ),
              if (mensaje != null) ...[
                const SizedBox(height: Espacios.e8),
                Text(mensaje!, textAlign: TextAlign.center),
              ],
              if (textoBoton != null && alBoton != null) ...[
                const SizedBox(height: Espacios.e24),
                FilledButton(onPressed: alBoton, child: Text(textoBoton!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
