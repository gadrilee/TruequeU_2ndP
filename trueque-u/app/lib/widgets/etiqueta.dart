import 'package:flutter/material.dart';
import '../tema.dart';

class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.icono,
    required this.texto,
    required this.fondo,
    required this.colorTexto,
  });

  final IconData icono;
  final String texto;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espacios.e10, vertical: Espacios.e4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Radios.r16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: colorTexto),
          const SizedBox(width: Espacios.e4),
          Text(
            texto,
            style: TextosTruequeU.etiqueta.copyWith(color: colorTexto),
          ),
        ],
      ),
    );
  }
}
