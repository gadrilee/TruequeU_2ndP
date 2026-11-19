import 'package:flutter/material.dart';
import '../tema.dart';

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

    Color fondo;
    Color texto;
    String etiqueta;

    switch (estado) {
      case 'disponible':
        fondo = TemaTruequeU.azulClaro;
        texto = TemaTruequeU.azulOscuro;
        etiqueta = 'Disponible';
        break;
      case 'reservado':
        fondo = TemaTruequeU.rojoClaro;
        texto = TemaTruequeU.rojoOscuro;
        etiqueta = loReserveYo ? 'Reservado por ti' : 'Reservado';
        break;
      case 'intercambiado':
        fondo = TemaTruequeU.verdeClaro;
        texto = TemaTruequeU.verdeOscuro;
        etiqueta = 'Intercambiado';
        break;
      case 'acordado':
        fondo = TemaTruequeU.azul;
        texto = TemaTruequeU.blanco;
        etiqueta = 'Intercambio acordado';
        break;
      case 'no disponible':
        fondo = TemaTruequeU.superficieAlta;
        texto = TemaTruequeU.textoSuave;
        etiqueta = 'No disponible';
        break;
      default:
        fondo = TemaTruequeU.superficieAlta;
        texto = TemaTruequeU.textoSuave;
        etiqueta = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espacios.e10, vertical: Espacios.e4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Radios.r20),
      ),
      child: Text(
        etiqueta,
        style: TextosTruequeU.chipDestacado.copyWith(color: texto),
      ),
    );
  }
}
