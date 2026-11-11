import 'package:flutter/material.dart';

class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.puntaje, this.alElegir});

  final int puntaje;
  final ValueChanged<int>? alElegir;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: ValueKey('estrella-$i'),
            tooltip: '$i de 5',
            visualDensity: VisualDensity.compact,
            onPressed: alElegir == null ? null : () => alElegir!(i),
            icon: Icon(i <= puntaje ? Icons.star : Icons.star_border, color: Colors.amber),
          ),
      ],
    );
  }
}
