import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utilidades/etiquetas.dart';

Future<int?> mostrarDialogoOferta(
  BuildContext context, {
  required String tituloDeseado,
  required List<Map<String, dynamic>> misDisponibles,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _DialogoOferta(
      tituloDeseado: tituloDeseado,
      misDisponibles: misDisponibles,
      alCrear: () {
        Navigator.of(ctx).pop();
        context.go('/publicacion');
      },
    ),
  );
}

class _DialogoOferta extends StatefulWidget {
  const _DialogoOferta({
    required this.tituloDeseado,
    required this.misDisponibles,
    required this.alCrear,
  });

  final String tituloDeseado;
  final List<Map<String, dynamic>> misDisponibles;
  final VoidCallback alCrear;

  @override
  State<_DialogoOferta> createState() => _DialogoOfertaState();
}

class _DialogoOfertaState extends State<_DialogoOferta> {
  int? _elegida;

  @override
  Widget build(BuildContext context) {
    final vacio = widget.misDisponibles.isEmpty;

    return AlertDialog(
      title: const Text('Ofrecer un objeto'),
      content: SizedBox(
        width: 420,
        child: vacio
            ? const Text(
                'No tienes publicaciones disponibles para ofrecer. '
                'Crea una y déjala en estado disponible.',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Qué objeto tuyo ofreces por «${widget.tituloDeseado}»?'),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: RadioGroup<int>(
                        groupValue: _elegida,
                        onChanged: (valor) => setState(() => _elegida = valor),
                        child: Column(
                          children: [
                            for (final pub in widget.misDisponibles)
                              RadioListTile<int>(
                                value: (pub['id'] as num).toInt(),
                                contentPadding: EdgeInsets.zero,
                                title: Text((pub['titulo'] as String?) ?? 'Sin título'),
                                subtitle: Text(
                                  etiquetasCategoria[pub['categoria']] ?? 'Otros',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (vacio)
          FilledButton(
            onPressed: widget.alCrear,
            child: const Text('Crear publicación'),
          )
        else
          FilledButton(
            onPressed: _elegida == null
                ? null
                : () => Navigator.of(context).pop(_elegida),
            child: const Text('Enviar oferta'),
          ),
      ],
    );
  }
}
