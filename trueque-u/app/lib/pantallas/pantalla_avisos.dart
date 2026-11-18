import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/mensaje_vacio.dart';
import '../widgets/pagina_acceso.dart';
import '../tema.dart';

class PantallaAvisos extends StatefulWidget {
  const PantallaAvisos({super.key});

  @override
  State<PantallaAvisos> createState() => _PantallaAvisosState();
}

class _PantallaAvisosState extends State<PantallaAvisos> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _avisos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final auth = context.read<ControladorAutenticacion>();
      final avisos = await auth.obtenerAvisos();
      if (!mounted) return;
      setState(() {
        _avisos = avisos;
        _cargando = false;
      });
      for (final aviso in avisos.where((a) => a['leida'] != true)) {
        try {
          await auth.marcarAvisoLeido((aviso['id'] as num).toInt());
        } catch (_) {}
      }
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus avisos';
        _cargando = false;
      });
    }
  }

  String _fecha(String? iso) {
    final fecha = DateTime.tryParse(iso ?? '')?.toLocal();
    if (fecha == null) return '';
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    Widget contenido;
    if (_cargando) {
      contenido = const Padding(
        padding: EdgeInsets.all(Espacios.e40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      contenido = ErrorConReintento(mensaje: _error, alReintentar: _cargar);
    } else if (_avisos.isEmpty) {
      contenido = const MensajeVacio(
        icono: Icons.notifications_none,
        titulo: 'No tienes avisos',
        mensaje: 'Aquí aparecerán los cambios importantes en tus trueques.',
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final aviso in _avisos)
            Card(
              child: ListTile(
                leading: Icon(
                  aviso['leida'] == true
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: colores.primary,
                ),
                title: Text(aviso['mensaje'] as String? ?? ''),
                subtitle: Text(_fecha(aviso['creado_en'] as String?)),
              ),
            ),
        ],
      );
    }

    return PaginaAcceso(
      titulo: 'Avisos',
      anchoMaximo: 560,
      alVolver: () => context.go('/perfil'),
      hijos: [
        contenido,
        const SizedBox(height: Espacios.e16),
        TextButton(
          onPressed: () => context.go('/perfil'),
          child: const Text('Volver al perfil'),
        ),
      ],
    );
  }
}
