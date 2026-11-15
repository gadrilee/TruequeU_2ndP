import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/analitica.dart';
import '../servicios/cliente_api.dart';

class DialogoEliminarCuenta extends StatefulWidget {
  const DialogoEliminarCuenta({super.key});

  @override
  State<DialogoEliminarCuenta> createState() => _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState extends State<DialogoEliminarCuenta> {
  final _contrasena = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    if (_contrasena.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña');
      return;
    }
    final auth = context.read<ControladorAutenticacion>();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final cancelados = await auth.eliminarCuenta(_contrasena.text);
      if (!mounted) return;
      Navigator.of(context).pop(cancelados);
    } on ExcepcionApi catch (e) {
      if (e.codigoEstado == 401) {
        track('eliminacion_cuenta_bloqueada', {'motivo': 'contrasena_incorrecta'}, auth.api);
      }
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Eliminar cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esto es lo que va a pasar:'),
            const SizedBox(height: 8),
            const Text('• Tus trueques en curso se cancelan y se avisa a la otra persona.'),
            const Text('• Tus publicaciones dejan de mostrarse.'),
            const Text('• Tus calificaciones quedan sin tu nombre.'),
            const Text('• No se puede deshacer.'),
            const SizedBox(height: 16),
            TextField(
              controller: _contrasena,
              obscureText: true,
              enabled: !_enviando,
              decoration: InputDecoration(
                labelText: 'Tu contraseña',
                errorText: _error,
              ),
              onSubmitted: (_) => _eliminar(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('boton-cancelar-eliminar'),
                    onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('boton-confirmar-eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colores.error,
                      side: BorderSide(color: colores.error),
                    ),
                    onPressed: _enviando ? null : _eliminar,
                    child: const Text('Eliminar cuenta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
