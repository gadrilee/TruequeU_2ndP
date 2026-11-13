import 'package:flutter/material.dart';

/// Botón principal que muestra un indicador mientras carga.
class BotonCarga extends StatelessWidget {
  const BotonCarga({
    super.key,
    required this.texto,
    required this.cargando,
    required this.alPresionar,
    this.rojo = false,
  });

  final String texto;
  final bool cargando;
  final VoidCallback alPresionar;
  final bool rojo;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: rojo
          ? FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            )
          : null,
      onPressed: cargando ? null : alPresionar,
      child: cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(texto),
    );
  }
}
