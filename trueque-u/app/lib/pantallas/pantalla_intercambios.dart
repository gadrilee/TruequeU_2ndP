import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/mensaje_vacio.dart';
import '../widgets/pagina_acceso.dart';
import '../widgets/tarjeta_intercambio.dart';
import '../tema.dart';

/// RUTA PRIVADA ("/intercambios"): los intercambios completados de la persona,
/// ya sea como dueña del objeto o como quien lo reservó.
class PantallaIntercambios extends StatefulWidget {
  const PantallaIntercambios({super.key});

  @override
  State<PantallaIntercambios> createState() => _PantallaIntercambiosState();
}

class _PantallaIntercambiosState extends State<PantallaIntercambios> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _intercambios = [];

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
      final lista =
          await context.read<ControladorAutenticacion>().obtenerIntercambios();
      if (!mounted) return;
      setState(() {
        _intercambios = lista;
        _cargando = false;
      });
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus intercambios';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final yo = context.watch<ControladorAutenticacion>().usuario;

    Widget contenido;
    if (_cargando) {
      contenido = const Padding(
        padding: EdgeInsets.all(Espacios.e40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      contenido = ErrorConReintento(mensaje: _error, alReintentar: _cargar);
    } else if (_intercambios.isEmpty) {
      contenido = const MensajeVacio(
        icono: Icons.handshake_outlined,
        titulo: 'Aún no tienes intercambios completados',
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pub in _intercambios) ...[
            TarjetaIntercambio(pub: pub, idYo: yo?.id),
            const SizedBox(height: Espacios.e12),
          ],
        ],
      );
    }

    return PaginaAcceso(
      titulo: 'Intercambios completados',
      anchoMaximo: 560,
      alVolver: () => context.go('/perfil'),
      acciones: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          onPressed: _cargar,
        ),
      ],
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
