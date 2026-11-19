import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trueque_u/tema.dart';

enum TipoContraste { texto, textoGrande, interfaz }

class ParContraste {
  const ParContraste(
    this.nombre,
    this.donde,
    this.primerPlano,
    this.fondo,
    this.tipo, {
    this.primerPlanoAntes,
  });

  final String nombre;
  final String donde;
  final Color primerPlano;
  final Color fondo;
  final TipoContraste tipo;
  final Color? primerPlanoAntes;

  double get minimo => tipo == TipoContraste.texto ? 4.5 : 3.0;
  double get razon => razonContraste(primerPlano, fondo);
  double? get razonAntes =>
      primerPlanoAntes == null ? null : razonContraste(primerPlanoAntes!, fondo);
}

double _canal(double valor) {
  return valor <= 0.03928 ? valor / 12.92 : pow((valor + 0.055) / 1.055, 2.4).toDouble();
}

double luminancia(Color color) {
  return 0.2126 * _canal(color.r) + 0.7152 * _canal(color.g) + 0.0722 * _canal(color.b);
}

double razonContraste(Color a, Color b) {
  final x = luminancia(a);
  final y = luminancia(b);
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

const _texto = TipoContraste.texto;
const _interfaz = TipoContraste.interfaz;

const paresContraste = <ParContraste>[
  ParContraste('texto / fondo', 'Cuerpo de las pantallas', TemaTruequeU.texto, TemaTruequeU.fondo, _texto),
  ParContraste('texto / blanco', 'Texto en tarjetas y campos', TemaTruequeU.texto, TemaTruequeU.blanco, _texto),
  ParContraste('textoSuave / fondo', 'Textos secundarios y etiquetas de campo', TemaTruequeU.textoSuave, TemaTruequeU.fondo, _texto),
  ParContraste('textoSuave / blanco', 'Descripciones en tarjetas y ayuda de campos', TemaTruequeU.textoSuave, TemaTruequeU.blanco, _texto),
  ParContraste('textoSuave / superficieAlta', 'Chip "No disponible" y oferta cancelada', TemaTruequeU.textoSuave, TemaTruequeU.superficieAlta, _texto),
  ParContraste('textoSuave / azulClaro', 'Texto secundario sobre azul claro', TemaTruequeU.textoSuave, TemaTruequeU.azulClaro, _texto),
  ParContraste('contorno / blanco', 'Autor y pie de la tarjeta del feed', TemaTruequeU.contorno, TemaTruequeU.blanco, _texto),
  ParContraste('blanco / azul', 'Botón principal y chip "Intercambio acordado"', TemaTruequeU.blanco, TemaTruequeU.azul, _texto),
  ParContraste('blanco / rojo', 'Botón "Crear cuenta", botón flotante y rechazar', TemaTruequeU.blanco, TemaTruequeU.rojo, _texto),
  ParContraste('blanco / azulOscuro', 'Título del encabezado y texto del aviso emergente', TemaTruequeU.blanco, TemaTruequeU.azulOscuro, _texto),
  ParContraste('azulClaro / azulOscuro', 'Acción del aviso emergente y parte alta del encabezado', TemaTruequeU.azulClaro, TemaTruequeU.azulOscuro, _texto),
  ParContraste('azulClaro / azul', 'Subtítulo en la parte baja del encabezado', TemaTruequeU.azulClaro, TemaTruequeU.azul, _texto),
  ParContraste('azul / fondo', 'Botones de texto, enlaces y barra superior', TemaTruequeU.azul, TemaTruequeU.fondo, _texto),
  ParContraste('azul / blanco', 'Botones con borde y texto resaltado en tarjetas', TemaTruequeU.azul, TemaTruequeU.blanco, _texto),
  ParContraste('azulOscuro / azulClaro', 'Chip "Disponible" e indicador de navegación', TemaTruequeU.azulOscuro, TemaTruequeU.azulClaro, _texto),
  ParContraste('azulOscuro / fondo', 'Título de la barra superior', TemaTruequeU.azulOscuro, TemaTruequeU.fondo, _texto),
  ParContraste('rojoOscuro / rojoClaro', 'Chip "Reservado" y banner de error', TemaTruequeU.rojoOscuro, TemaTruequeU.rojoClaro, _texto),
  ParContraste('verdeOscuro / verdeClaro', 'Chip "Intercambiado" y confirmaciones', TemaTruequeU.verdeOscuro, TemaTruequeU.verdeClaro, _texto),
  ParContraste('rojo / fondo', 'Mensaje de error de campos y "Eliminar cuenta"', TemaTruequeU.rojo, TemaTruequeU.fondo, _texto),
  ParContraste('rojo / blanco', 'Error en campos blancos y acciones destructivas', TemaTruequeU.rojo, TemaTruequeU.blanco, _texto),
  ParContraste('rojo / rojoClaro', 'Texto de oferta rechazada', TemaTruequeU.rojo, TemaTruequeU.rojoClaro, _texto),
  ParContraste('verdeOscuro / fondo', 'Estados confirmados sobre el fondo', TemaTruequeU.verdeOscuro, TemaTruequeU.fondo, _texto),
  ParContraste('contorno / blanco', 'Borde de campos de texto y del buscador', TemaTruequeU.contorno, TemaTruequeU.blanco, _interfaz, primerPlanoAntes: TemaTruequeU.borde),
  ParContraste('contorno / blanco', 'Borde de botones con borde y de los filtros', TemaTruequeU.contorno, TemaTruequeU.blanco, _interfaz, primerPlanoAntes: TemaTruequeU.borde),
  ParContraste('contorno / fondo', 'Ícono del mensaje vacío', TemaTruequeU.contorno, TemaTruequeU.fondo, _interfaz),
  ParContraste('contorno / superficieAlta', 'Ícono de foto vacía', TemaTruequeU.contorno, TemaTruequeU.superficieAlta, _interfaz),
  ParContraste('azul / blanco', 'Borde del campo enfocado', TemaTruequeU.azul, TemaTruequeU.blanco, _interfaz),
  ParContraste('rojo / blanco', 'Estrellas de calificación', TemaTruequeU.rojo, TemaTruequeU.blanco, _interfaz),
  ParContraste('textoSuave / fondo', 'Íconos secundarios y flechas de listas', TemaTruequeU.textoSuave, TemaTruequeU.fondo, _interfaz),
  ParContraste('azul / azulClaro', 'Íconos sobre azul claro', TemaTruequeU.azul, TemaTruequeU.azulClaro, _interfaz),
  ParContraste('blanco / azulOscuro', 'Flecha "Volver" del encabezado', TemaTruequeU.blanco, TemaTruequeU.azulOscuro, _interfaz),
];

List<ParContraste> paresDelEsquema(ColorScheme e) {
  return [
    ParContraste('primary / onPrimary', 'Esquema', e.onPrimary, e.primary, _texto),
    ParContraste('secondary / onSecondary', 'Esquema', e.onSecondary, e.secondary, _texto),
    ParContraste('tertiary / onTertiary', 'Esquema', e.onTertiary, e.tertiary, _texto),
    ParContraste('error / onError', 'Esquema', e.onError, e.error, _texto),
    ParContraste('primaryContainer / onPrimaryContainer', 'Esquema', e.onPrimaryContainer, e.primaryContainer, _texto),
    ParContraste('secondaryContainer / onSecondaryContainer', 'Esquema', e.onSecondaryContainer, e.secondaryContainer, _texto),
    ParContraste('tertiaryContainer / onTertiaryContainer', 'Esquema', e.onTertiaryContainer, e.tertiaryContainer, _texto),
    ParContraste('errorContainer / onErrorContainer', 'Esquema', e.onErrorContainer, e.errorContainer, _texto),
    ParContraste('surface / onSurface', 'Esquema', e.onSurface, e.surface, _texto),
    ParContraste('surface / onSurfaceVariant', 'Esquema', e.onSurfaceVariant, e.surface, _texto),
    ParContraste('surfaceContainer / onSurfaceVariant', 'Esquema', e.onSurfaceVariant, e.surfaceContainer, _texto),
    ParContraste('inverseSurface / onInverseSurface', 'Esquema', e.onInverseSurface, e.inverseSurface, _texto),
    ParContraste('inverseSurface / inversePrimary', 'Esquema', e.inversePrimary, e.inverseSurface, _texto),
  ];
}
