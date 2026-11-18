import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/analitica.dart';
import '../servicios/cliente_api.dart';
import '../servicios/descarga_archivo.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/pagina_acceso.dart';

class PantallaMisDatos extends StatefulWidget {
  const PantallaMisDatos({super.key, this.descargar = descargarArchivo});

  final bool Function(String nombre, String contenido, String tipo) descargar;

  @override
  State<PantallaMisDatos> createState() => _PantallaMisDatosState();
}

class _PantallaMisDatosState extends State<PantallaMisDatos> {
  bool _cargando = true;
  bool _descargando = false;
  String? _error;
  Map<String, dynamic> _datos = {};

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
      final datos = await context.read<ControladorAutenticacion>().obtenerMisDatos();
      if (!mounted) return;
      setState(() {
        _datos = datos;
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
        _error = 'No se pudieron cargar tus datos';
        _cargando = false;
      });
    }
  }

  Future<void> _descargar(String formato) async {
    final auth = context.read<ControladorAutenticacion>();
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _descargando = true);
    try {
      final contenido = await auth.descargarMisDatos(formato);
      final tipo = formato == 'csv' ? 'text/csv' : 'application/json';
      final listo = widget.descargar('mis-datos.$formato', contenido, tipo);
      if (listo) {
        track('datos_descargados', {'formato': formato}, auth.api);      }
      mensajes.showSnackBar(SnackBar(
        content: Text(listo
            ? 'Tus datos se descargaron'
            : 'La descarga solo está disponible desde el navegador'),
      ));
    } on ExcepcionApi catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  Future<void> _quitarTelefono() async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      await context.read<ControladorAutenticacion>().quitarTelefono();
      mensajes.showSnackBar(const SnackBar(content: Text('Quitamos tu teléfono')));
      await _cargar();
    } on ExcepcionApi catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  String _fecha(dynamic iso) {
    final texto = iso as String? ?? '';
    return texto.length >= 10 ? texto.substring(0, 10) : texto;
  }

  List<Map<String, dynamic>> _lista(String clave) {
    final valores = _datos[clave];
    if (valores is! List) return [];
    return valores.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _tarjeta(String titulo, List<String> lineas, String vacio, {Widget? accion}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lineas.isEmpty) Text(vacio),
            for (final linea in lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(linea),
              ),
            if (accion != null) accion,
          ],
        ),
      ),
    );
  }

  List<Widget> _tarjetas() {
    final perfil = Map<String, dynamic>.from(_datos['perfil'] as Map? ?? {});
    final telefono = perfil['telefono'] as String?;

    final ofertasHechas = _lista('ofertas_hechas').map((o) =>
        'Ofreciste "${o['objeto_ofrecido']}" por "${o['objeto_pedido']}" · ${o['estado']}');
    final ofertasRecibidas = _lista('ofertas_recibidas').map((o) =>
        'Te ofrecieron "${o['objeto_ofrecido']}" por "${o['objeto_pedido']}" · ${o['estado']}');
    String estrellas(Map<String, dynamic> c) {
      final comentario = c['comentario'] as String?;
      final texto = '${c['puntaje']} de 5 · ${_fecha(c['creado_en'])}';
      return comentario == null || comentario.isEmpty ? texto : '$texto · "$comentario"';
    }

    return [
      _tarjeta(
        'Tu perfil',
        [
          'Nombre: ${perfil['nombre'] ?? ''}',
          'Correo: ${perfil['correo'] ?? ''}',
          'Teléfono: ${telefono == null || telefono.isEmpty ? 'sin teléfono' : telefono}',
          'Cuenta creada: ${_fecha(perfil['creado_en'])}',
        ],
        '',
        accion: telefono == null || telefono.isEmpty
            ? null
            : TextButton(
                onPressed: _quitarTelefono,
                child: const Text('Quitar mi teléfono'),
              ),
      ),
      _tarjeta(
        'Tus publicaciones',
        _lista('publicaciones')
            .map((p) => '${p['titulo']} · ${p['estado_publicacion']}')
            .toList(),
        'Todavía no publicaste nada.',
      ),
      _tarjeta(
        'Ofertas que hiciste',
        ofertasHechas.toList(),
        'No hiciste ofertas.',
      ),
      _tarjeta(
        'Ofertas que recibiste',
        ofertasRecibidas.toList(),
        'No recibiste ofertas.',
      ),
      _tarjeta(
        'Calificaciones que diste',
        _lista('calificaciones_dadas').map(estrellas).toList(),
        'No calificaste a nadie.',
      ),
      _tarjeta(
        'Calificaciones que recibiste',
        _lista('calificaciones_recibidas').map(estrellas).toList(),
        'Aún no te calificaron.',
      ),
      _tarjeta(
        'Tu historial',
        _lista('historial')
            .map((h) => '${h['titulo']} · ${h['tipo']} · ${_fecha(h['creado_en'])}')
            .toList(),
        'Sin movimientos.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    if (_cargando) {
      contenido = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      contenido = ErrorConReintento(mensaje: _error, alReintentar: _cargar);
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Esto es lo que la app guarda de ti. Puedes descargarlo cuando quieras.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _descargando ? null : () => _descargar('json'),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar JSON'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _descargando ? null : () => _descargar('csv'),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final tarjeta in _tarjetas()) ...[
            tarjeta,
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return PaginaAcceso(
      titulo: 'Mis datos',
      anchoMaximo: 560,
      alVolver: () => context.go('/perfil'),
      hijos: [
        contenido,
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/perfil'),
          child: const Text('Volver al perfil'),
        ),
      ],
    );
  }
}
