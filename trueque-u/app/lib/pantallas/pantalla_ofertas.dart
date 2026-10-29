import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../widgets/dialogo_confirmacion.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/mensaje_vacio.dart';
import '../widgets/pagina_acceso.dart';

class PantallaOfertas extends StatefulWidget {
  const PantallaOfertas({super.key});

  @override
  State<PantallaOfertas> createState() => _PantallaOfertasState();
}

class _PantallaOfertasState extends State<PantallaOfertas> {
  bool _cargando = true;
  String? _error;
  bool _viendoEnviadas = false;
  List<Map<String, dynamic>> _recibidas = [];
  List<Map<String, dynamic>> _enviadas = [];
  final Set<int> _enProgreso = {};

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
      final resultados = await Future.wait([
        auth.obtenerOfertasRecibidas(),
        auth.obtenerOfertasEnviadas(),
      ]);
      if (!mounted) return;
      setState(() {
        _recibidas = resultados[0];
        _enviadas = resultados[1];
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
        _error = 'No se pudieron cargar las ofertas';
        _cargando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _lista =>
      _viendoEnviadas ? _enviadas : _recibidas;

  Future<void> _responder(
    int id,
    String accion,
    String titulo,
    String mensaje,
    String boton,
  ) async {
    final acepta = await confirmarAccion(
      context,
      titulo: titulo,
      mensaje: mensaje,
      textoBoton: boton,
    );
    if (!acepta || !mounted) return;

    setState(() => _enProgreso.add(id));
    try {
      final auth = context.read<ControladorAutenticacion>();
      final texto = switch (accion) {
        'aceptar' => await auth.aceptarOferta(id),
        'rechazar' => await auth.rechazarOferta(id),
        _ => await auth.cancelarOferta(id),
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
      await _cargar();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la oferta')),
      );
    } finally {
      if (mounted) setState(() => _enProgreso.remove(id));
    }
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
    } else if (_lista.isEmpty) {
      contenido = MensajeVacio(
        icono: Icons.swap_horiz,
        titulo: _viendoEnviadas
            ? 'Todavía no envías ofertas'
            : 'Nadie te ha ofrecido un trueque',
        mensaje: _viendoEnviadas
            ? 'En Explorar publicaciones elige un objeto ajeno y ofrece uno de los tuyos.'
            : 'Cuando alguien ofrezca un objeto por una publicación tuya, aparecerá aquí.',
        textoBoton: 'Explorar publicaciones',
        alBoton: () => context.go('/feed'),
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final oferta in _lista) ...[
            _TarjetaOferta(
              oferta: oferta,
              recibida: !_viendoEnviadas,
              enProgreso: _enProgreso.contains((oferta['id'] as num).toInt()),
              alAceptar: () {
                final pedida = oferta['pedida'] as Map<String, dynamic>;
                final ofrecida = oferta['ofrecida'] as Map<String, dynamic>;
                _responder(
                  (oferta['id'] as num).toInt(),
                  'aceptar',
                  'Aceptar trueque',
                  '¿Aceptas cambiar «${ofrecida['titulo']}» por «${pedida['titulo']}»? '
                      'Las dos quedarán intercambiadas y las otras ofertas pendientes de esos objetos se cancelarán.',
                  'Aceptar',
                );
              },
              alRechazar: () => _responder(
                (oferta['id'] as num).toInt(),
                'rechazar',
                'Rechazar oferta',
                '¿Rechazas esta oferta? Quien la envió verá que fue rechazada.',
                'Rechazar',
              ),
              alCancelar: () => _responder(
                (oferta['id'] as num).toInt(),
                'cancelar',
                'Cancelar oferta',
                '¿Cancelas esta oferta? El dueño ya no podrá aceptarla.',
                'Cancelar oferta',
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return PaginaAcceso(
      titulo: 'Ofertas de trueque',
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
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Recibidas'), icon: Icon(Icons.inbox_outlined)),
            ButtonSegment(value: 1, label: Text('Enviadas'), icon: Icon(Icons.outbox_outlined)),
          ],
          selected: {_viendoEnviadas ? 1 : 0},
          onSelectionChanged: (valor) =>
              setState(() => _viendoEnviadas = valor.first == 1),
        ),
        const SizedBox(height: 16),
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

class _TarjetaOferta extends StatelessWidget {
  const _TarjetaOferta({
    required this.oferta,
    required this.recibida,
    required this.enProgreso,
    required this.alAceptar,
    required this.alRechazar,
    required this.alCancelar,
  });

  final Map<String, dynamic> oferta;
  final bool recibida;
  final bool enProgreso;
  final VoidCallback alAceptar;
  final VoidCallback alRechazar;
  final VoidCallback alCancelar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final pedida = oferta['pedida'] as Map<String, dynamic>? ?? {};
    final ofrecida = oferta['ofrecida'] as Map<String, dynamic>? ?? {};
    final oferente = oferta['oferente'] as Map<String, dynamic>? ?? {};
    final autorPedida = pedida['autor'] as Map<String, dynamic>? ?? {};
    final estado = (oferta['estado'] as String?) ?? 'pendiente';
    final pendiente = estado == 'pendiente';

    final quien = recibida
        ? 'De: ${oferente['nombre'] ?? 'Alguien'}'
        : 'Para: ${autorPedida['nombre'] ?? 'el dueño'}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChipEstado(estado: estado),
                const Spacer(),
                Text(quien, style: TextStyle(color: colores.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Quiere: ${pedida['titulo'] ?? 'un objeto'}'),
            const SizedBox(height: 4),
            Text(
              'Ofrece: ${ofrecida['titulo'] ?? 'un objeto'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (pendiente) ...[
              const SizedBox(height: 12),
              if (enProgreso)
                const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (recibida)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: alAceptar,
                        child: const Text('Aceptar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: alRechazar,
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: alCancelar,
                  child: const Text('Cancelar oferta'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final (texto, fondo, tinta) = switch (estado) {
      'aceptada' => ('Aceptada', colores.primaryContainer, colores.onPrimaryContainer),
      'rechazada' => ('Rechazada', colores.errorContainer, colores.onErrorContainer),
      'cancelada' => ('Cancelada', colores.surfaceContainerHighest, colores.onSurfaceVariant),
      _ => ('Pendiente', colores.secondaryContainer, colores.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: TextStyle(color: tinta, fontWeight: FontWeight.w600)),
    );
  }
}
