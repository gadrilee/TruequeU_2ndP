import 'package:flutter/material.dart';

Future<String?> pedirMotivoCancelacion(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _DialogoMotivo(),
  );
}

class _DialogoMotivo extends StatefulWidget {
  const _DialogoMotivo();

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar intercambio'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Las dos publicaciones volverán a estar disponibles. '
              'El motivo queda guardado en el historial.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivo,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Motivo'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _motivo.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_motivo.text.trim()),
          child: const Text('Sí, cancelar'),
        ),
      ],
    );
  }
}
