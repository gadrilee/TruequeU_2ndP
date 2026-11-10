import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../utilidades/formato_entrega.dart';
import 'dialogo_entrega.dart';

class BloqueEntrega extends StatefulWidget {
  const BloqueEntrega({super.key, required this.idOferta, required this.idYo});

  final int idOferta;
  final int? idYo;

  @override
  State<BloqueEntrega> createState() => _BloqueEntregaState();
}

class _BloqueEntregaState extends State<BloqueEntrega> {
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  List<Map<String, dynamic>> _propuestas = [];
  Map<String, dynamic>? _vigente;
  Map<String, dynamic>? _pendiente;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Map<String, dynamic>? _mapaONulo(dynamic valor) {
    return valor is Map ? Map<String, dynamic>.from(valor) : null;
  }

  Future<void> _cargar() async {
    try {
      final datos = await context.read<ControladorAutenticacion>().obtenerEntrega(widget.idOferta);
      if (!mounted) return;
      setState(() {
        _propuestas = (datos['propuestas'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _vigente = _mapaONulo(datos['vigente']);
        _pendiente = _mapaONulo(datos['pendiente']);
        _error = null;
        _cargando = false;
      });
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    }
  }

  Future<void> _ejecutar(Future<String> Function() accion) async {
    setState(() => _enviando = true);
    try {
      final texto = await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
      await _cargar();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _proponer() async {
    final reprograma = _vigente != null;
    final datos = await pedirDatosEntrega(
      context,
      titulo: reprograma ? 'Reprogramar la entrega' : 'Proponer fecha y lugar',
      textoBoton: reprograma ? 'Enviar reprogramación' : 'Enviar propuesta',
      actual: _vigente,
    );
    if (datos == null || !mounted) return;
    await _ejecutar(
      () => context.read<ControladorAutenticacion>().proponerEntrega(widget.idOferta, datos),
    );
  }

  Future<void> _contraproponer() async {
    final datos = await pedirDatosEntrega(
      context,
      titulo: 'Contraproponer',
      textoBoton: 'Enviar contrapropuesta',
      actual: _pendiente,
    );
    if (datos == null || !mounted) return;
    final id = (_pendiente!['id'] as num).toInt();
    await _ejecutar(
      () => context.read<ControladorAutenticacion>().contraproponerEntrega(id, datos),
    );
  }

  Future<void> _aceptar() async {
    final id = (_pendiente!['id'] as num).toInt();
    await _ejecutar(() => context.read<ControladorAutenticacion>().aceptarEntrega(id));
  }

  String _nombreEstado(String estado) {
    return switch (estado) {
      'aceptada' => 'Acuerdo vigente',
      'contrapuesta' => 'Se respondió con otra propuesta',
      'reemplazada' => 'Reemplazada por una reprogramación',
      _ => 'Esperando respuesta',
    };
  }

  Future<void> _verHistorial() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Historial de entrega'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final propuesta in _propuestas) ...[
                  Text(
                    '${(propuesta['proponente'] as Map)['nombre']} propone: ${resumenEntrega(propuesta)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_nombreEstado(propuesta['estado'] as String)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenido() {
    if (_cargando) {
      return const [Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))];
    }
    if (_error != null) return [Text(_error!)];

    final pendiente = _pendiente;
    final reprograma = _vigente != null;
    final esMia = pendiente != null && pendiente['id_usuario'] == widget.idYo;

    return [
      if (_vigente != null)
        Text('Acordado: ${resumenEntrega(_vigente!)}', style: const TextStyle(fontWeight: FontWeight.bold))
      else
        const Text('Todavía no acordaron fecha ni lugar'),
      if (pendiente != null) ...[
        const SizedBox(height: 8),
        if (esMia) ...[
          Text(
            '${reprograma ? 'Tu cambio espera respuesta' : 'Tu propuesta espera respuesta'}: ${resumenEntrega(pendiente)}',
          ),
          if (reprograma) const Text('Mientras tanto sigue vigente el acuerdo anterior.'),
        ] else ...[
          Text(
            '${(pendiente['proponente'] as Map)['nombre']} ${reprograma ? 'propone cambiar a' : 'propone'}: ${resumenEntrega(pendiente)}',
          ),
          if (reprograma) const Text('Mientras tanto sigue vigente el acuerdo anterior.'),
          const SizedBox(height: 8),
          if (_enviando)
            const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: _aceptar, child: const Text('Aceptar propuesta')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: _contraproponer, child: const Text('Contraproponer')),
                ),
              ],
            ),
        ],
      ] else if (!_enviando) ...[
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _proponer,
          child: Text(reprograma ? 'Reprogramar' : 'Proponer fecha y lugar'),
        ),
      ],
      if (_propuestas.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _verHistorial, child: const Text('Historial de entrega')),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fecha y lugar de entrega', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ..._contenido(),
        ],
      ),
    );
  }
}
