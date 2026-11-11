import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';

class ResumenCalificaciones extends StatefulWidget {
  const ResumenCalificaciones({super.key, required this.idUsuario});

  final int idUsuario;

  @override
  State<ResumenCalificaciones> createState() => _ResumenCalificacionesState();
}

class _ResumenCalificacionesState extends State<ResumenCalificaciones> {
  bool _cargando = true;
  int _cantidad = 0;
  double _promedio = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await context.read<ControladorAutenticacion>().obtenerResumenCalificaciones(widget.idUsuario);
      if (!mounted) return;
      setState(() {
        _cantidad = (datos['cantidad'] as num?)?.toInt() ?? 0;
        _promedio = (datos['promedio'] as num?)?.toDouble() ?? 0;
        _cargando = false;
      });
    } on ExcepcionApi {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const SizedBox(height: 24);
    if (_cantidad == 0) {
      return const Text('Aún no tienes calificaciones', textAlign: TextAlign.center);
    }
    final palabra = _cantidad == 1 ? 'calificación' : 'calificaciones';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.amber),
        const SizedBox(width: 6),
        Text('${_promedio.toStringAsFixed(1)} de 5 · $_cantidad $palabra'),
      ],
    );
  }
}
