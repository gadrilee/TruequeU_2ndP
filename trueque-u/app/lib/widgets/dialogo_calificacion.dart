import 'package:flutter/material.dart';

import 'estrellas.dart';

Future<Map<String, dynamic>?> pedirCalificacion(BuildContext context, {required String nombre}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _DialogoCalificacion(nombre: nombre),
  );
}

class _DialogoCalificacion extends StatefulWidget {
  const _DialogoCalificacion({required this.nombre});

  final String nombre;

  @override
  State<_DialogoCalificacion> createState() => _DialogoCalificacionState();
}

class _DialogoCalificacionState extends State<_DialogoCalificacion> {
  final _comentario = TextEditingController();
  int _puntaje = 0;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _elegir(int puntaje) {
    setState(() {
      _puntaje = puntaje;
      _error = null;
    });
  }

  void _enviar() {
    if (_puntaje == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas');
      return;
    }
    Navigator.of(context).pop({'puntaje': _puntaje, 'comentario': _comentario.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calificar a ${widget.nombre}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Estrellas(puntaje: _puntaje, alElegir: _elegir),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comentario,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _enviar, child: const Text('Enviar calificación')),
      ],
    );
  }
}
