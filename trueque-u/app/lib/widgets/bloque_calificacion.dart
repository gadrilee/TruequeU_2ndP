import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/analitica.dart';
import '../servicios/cliente_api.dart';
import 'dialogo_calificacion.dart';
import 'estrellas.dart';

class BloqueCalificacion extends StatefulWidget {
  const BloqueCalificacion({super.key, required this.idOferta, required this.nombreOtra});

  final int idOferta;
  final String nombreOtra;

  @override
  State<BloqueCalificacion> createState() => _BloqueCalificacionState();
}

class _BloqueCalificacionState extends State<BloqueCalificacion> {
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  Map<String, dynamic>? _mia;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final mia = await context.read<ControladorAutenticacion>().obtenerMiCalificacion(widget.idOferta);
      if (!mounted) return;
      setState(() {
        _mia = mia;
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

  Future<void> _calificar() async {
    final auth = context.read<ControladorAutenticacion>();
    track('calificacion_iniciada', {'id_oferta': widget.idOferta}, auth.api);
    final datos = await pedirCalificacion(context, nombre: widget.nombreOtra);
    if (datos == null || !mounted) return;
    setState(() => _enviando = true);
    try {
      final texto = await auth.calificarIntercambio(
        widget.idOferta,
        datos['puntaje'] as int,
        datos['comentario'] as String,
      );
      track('calificacion_enviada', {
        'id_oferta': widget.idOferta,
        'puntaje': datos['puntaje'],
        'con_comentario': (datos['comentario'] as String).isNotEmpty,
      }, auth.api);
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

  List<Widget> _contenido() {
    if (_cargando || _enviando) {
      return const [Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))];
    }
    if (_error != null) return [Text(_error!)];

    final mia = _mia;
    if (mia == null) {
      return [
        Text('Todavía no calificas a ${widget.nombreOtra}'),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _calificar, child: const Text('Calificar')),
      ];
    }
    final comentario = (mia['comentario'] as String?) ?? '';
    return [
      Text(
        'Calificaste a ${widget.nombreOtra}: ${mia['puntaje']} de 5',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Estrellas(puntaje: (mia['puntaje'] as num).toInt()),
      if (comentario.isNotEmpty) Text('"$comentario"'),
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
          const Text('Calificación', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ..._contenido(),
        ],
      ),
    );
  }
}
