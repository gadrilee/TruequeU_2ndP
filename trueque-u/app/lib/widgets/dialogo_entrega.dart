import 'package:flutter/material.dart';

import '../utilidades/formato_entrega.dart';

Future<Map<String, String>?> pedirDatosEntrega(
  BuildContext context, {
  required String titulo,
  required String textoBoton,
  Map<String, dynamic>? actual,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => _DialogoEntrega(titulo: titulo, textoBoton: textoBoton, actual: actual),
  );
}

class _DialogoEntrega extends StatefulWidget {
  const _DialogoEntrega({required this.titulo, required this.textoBoton, this.actual});

  final String titulo;
  final String textoBoton;
  final Map<String, dynamic>? actual;

  @override
  State<_DialogoEntrega> createState() => _DialogoEntregaState();
}

class _DialogoEntregaState extends State<_DialogoEntrega> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _fecha;
  late final TextEditingController _hora;
  late final TextEditingController _lugar;

  @override
  void initState() {
    super.initState();
    final actual = widget.actual;
    _fecha = TextEditingController(
      text: actual == null ? '' : fechaLegible(actual['fecha'] as String),
    );
    _hora = TextEditingController(text: actual == null ? '' : '${actual['hora']}');
    _lugar = TextEditingController(text: actual == null ? '' : '${actual['lugar']}');
  }

  @override
  void dispose() {
    _fecha.dispose();
    _hora.dispose();
    _lugar.dispose();
    super.dispose();
  }

  String? _validarFecha(String? texto) {
    final iso = fechaAIso(texto ?? '');
    if (iso == null) return 'Escribe una fecha válida, por ejemplo 15/06/2030';
    if (fechaYaPaso(iso)) return 'La fecha ya pasó, elige otra';
    return null;
  }

  String? _validarHora(String? texto) {
    return horaAIso(texto ?? '') == null ? 'Escribe una hora válida, por ejemplo 15:30' : null;
  }

  String? _validarLugar(String? texto) {
    return (texto ?? '').trim().isEmpty ? 'Escribe el lugar de la entrega' : null;
  }

  void _enviar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.of(context).pop({
      'fecha': fechaAIso(_fecha.text)!,
      'hora': horaAIso(_hora.text)!,
      'lugar': _lugar.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fecha,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(labelText: 'Fecha (dd/mm/aaaa)'),
                  validator: _validarFecha,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hora,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(labelText: 'Hora (hh:mm)'),
                  validator: _validarHora,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lugar,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Lugar'),
                  validator: _validarLugar,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _enviar, child: Text(widget.textoBoton)),
      ],
    );
  }
}
