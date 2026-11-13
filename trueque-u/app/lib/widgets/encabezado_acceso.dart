import 'package:flutter/material.dart';

import '../tema.dart';

class EncabezadoAcceso extends StatelessWidget {
  const EncabezadoAcceso({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.conLogo = false,
    this.alVolver,
  });

  final String titulo;
  final String subtitulo;
  final bool conLogo;
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final alineacion =
        conLogo ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TemaTruequeU.azulOscuro, TemaTruequeU.azul],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: alineacion,
            children: [
              if (alVolver != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: alVolver,
                ),
              if (conLogo) ...[
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 36,
                    color: TemaTruequeU.rojo,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                titulo,
                style: textos.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                textAlign: conLogo ? TextAlign.center : TextAlign.start,
                style: textos.bodyLarge?.copyWith(color: TemaTruequeU.azulClaro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
