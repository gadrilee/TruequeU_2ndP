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
      titulo: 'Ofrecer un objeto',
      pregunta: '¿Qué objeto tuyo ofreces por «$tituloDeseado»?',
      textoEnviar: 'Enviar oferta',
      mensajeVacio: 'No tienes publicaciones disponibles para ofrecer. '
          'Crea una y déjala en estado disponible.',
      conBotonCrear: true,
      opciones: misDisponibles,
      alCrear: () {
        Navigator.of(ctx).pop();
        context.go('/publicacion');
      },
    ),
  );
}

Future<int?> mostrarDialogoContraoferta(
  BuildContext context, {
  required String tituloPedido,
  required List<Map<String, dynamic>> opciones,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _DialogoOferta(
      titulo: 'Contraofertar',
      pregunta: '¿Qué otro objeto propones por «$tituloPedido»?',
      textoEnviar: 'Enviar contraoferta',
      mensajeVacio: 'No hay otro objeto disponible para proponer en esta negociación.',
      conBotonCrear: false,
      opciones: opciones,
      alCrear: () {},
    ),
  );
}

class _DialogoOferta extends StatefulWidget {
  const _DialogoOferta({
    required this.titulo,
    required this.pregunta,
    required this.textoEnviar,
    required this.mensajeVacio,
    required this.conBotonCrear,
    required this.opciones,
    required this.alCrear,
  });

  final String titulo;
  final String pregunta;
  final String textoEnviar;
  final String mensajeVacio;
  final bool conBotonCrear;
  final List<Map<String, dynamic>> opciones;
  final VoidCallback alCrear;

  @override
  State<_DialogoOferta> createState() => _DialogoOfertaState();
}

class _DialogoOfertaState extends State<_DialogoOferta> {
  int? _elegida;

  @override
  Widget build(BuildContext context) {
    final vacio = widget.opciones.isEmpty;

    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: vacio
            ? Text(widget.mensajeVacio)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pregunta),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: RadioGroup<int>(
                        groupValue: _elegida,
                        onChanged: (valor) => setState(() => _elegida = valor),
                        child: Column(
                          children: [
                            for (final pub in widget.opciones)
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
        if (vacio && widget.conBotonCrear)
          FilledButton(
            onPressed: widget.alCrear,
            child: const Text('Crear publicación'),
          )
        else if (!vacio)
          FilledButton(
            onPressed: _elegida == null
                ? null
                : () => Navigator.of(context).pop(_elegida),
            child: Text(widget.textoEnviar),
          ),
      ],
    );
  }
}
