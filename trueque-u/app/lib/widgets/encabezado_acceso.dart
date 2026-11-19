import 'package:flutter/material.dart';

import '../tema.dart';
import 'logo_trueque_u.dart';

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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Radios.r36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Espacios.e24, Espacios.e16, Espacios.e24, Espacios.e32),
          child: Column(
            crossAxisAlignment: alineacion,
            children: [
              if (alVolver != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back, color: TemaTruequeU.blanco),
                  onPressed: alVolver,
                ),
              if (conLogo) ...[
                const SizedBox(height: Espacios.e16),
                const LogoTruequeU(),
                const SizedBox(height: Espacios.e16),
              ],
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: textos.headlineMedium?.copyWith(
                    color: TemaTruequeU.blanco,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: Espacios.e4),
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
