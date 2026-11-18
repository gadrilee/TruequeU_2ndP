import 'package:flutter/material.dart';

import '../tema.dart';

/// Pregunta "¿seguro?" antes de una acción. Devuelve true si la persona acepta.
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String textoBoton,
  String textoCancelar = 'Cancelar',
  bool destructivo = false,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(textoCancelar),
        ),
        FilledButton(
          style: destructivo
              ? FilledButton.styleFrom(
                  backgroundColor: TemaTruequeU.rojo,
                  foregroundColor: TemaTruequeU.blanco,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(textoBoton),
        ),
      ],
    ),
  );
  return respuesta == true;
}
