import 'package:flutter/material.dart';

/// Ayuda corta y contextual: cómo se reserva y se entrega un objeto en Trueque U.
Future<void> mostrarAyudaTrueque(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cómo funciona?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Paso(
              numero: '1',
              texto: 'Reservar: toca "Reservar" en un objeto disponible. Quedará apartado para ti.',
            ),
            _Paso(
              numero: '2',
              texto: 'Coordinar: escribe al dueño con el botón "WhatsApp" para acordar lugar y hora.',
            ),
            _Paso(
              numero: '3',
              texto: 'Entregar: encuéntrense y hagan el intercambio.',
            ),
            _Paso(
              numero: '4',
              texto: 'Completar: toca "Completar intercambio" cuando ya se realizó.',
            ),
            SizedBox(height: 8),
            Text('¿Te equivocaste? Usa "Cancelar reserva" y el objeto vuelve a estar disponible.'),
            SizedBox(height: 12),
            Text(
              'También puedes ofrecer uno de tus objetos: en una publicación disponible toca '
              '"Ofrecer un objeto". El dueño la acepta o la rechaza en Ofertas de trueque.',
            ),
            SizedBox(height: 12),
            Text('Estados', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              '• Disponible: se puede reservar.\n'
              '• Reservado: alguien lo apartó.\n'
              '• No disponible: se ve, pero nadie puede reservarlo.\n'
              '• Oculta: solo la ve su dueño.\n'
              '• Intercambiado: el trueque ya se completó.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});

  final String numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            child: Text(numero, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
