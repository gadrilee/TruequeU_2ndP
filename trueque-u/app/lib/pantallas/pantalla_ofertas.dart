import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/analitica.dart';
import '../servicios/cliente_api.dart';
import '../widgets/bloque_calificacion.dart';
import '../widgets/bloque_entrega.dart';
import '../widgets/dialogo_confirmacion.dart';
import '../widgets/dialogo_motivo.dart';
import '../widgets/dialogo_oferta.dart';
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
        'entrega' => await auth.confirmarEntrega(id),
        _ => await auth.cancelarOferta(id),
      };
      final evento = switch (accion) {
        'aceptar' => 'oferta_aceptada',
        'rechazar' => 'oferta_rechazada',
        'entrega' => 'entrega_confirmada',
        _ => 'oferta_cancelada',
      };
      track(evento, {'id_oferta': id}, auth.api);
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

  Future<void> _cancelarIntercambio(int id) async {
    final motivo = await pedirMotivoCancelacion(context);
    if (motivo == null || !mounted) return;

    setState(() => _enProgreso.add(id));
    try {
      final auth = context.read<ControladorAutenticacion>();
      final texto = await auth.cancelarIntercambio(id, motivo);
      track('intercambio_cancelado', {'id_oferta': id}, auth.api);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
      await _cargar();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _enProgreso.remove(id));
    }
  }

  Future<void> _contraofertar(Map<String, dynamic> oferta) async {
    final auth = context.read<ControladorAutenticacion>();
    final pedida = oferta['pedida'] as Map<String, dynamic>;
    final ofrecida = oferta['ofrecida'] as Map<String, dynamic>;
    final idOferente = (ofrecida['id_usuario'] as num).toInt();
    final idActual = (ofrecida['id'] as num).toInt();

    List<Map<String, dynamic>> disponibles;
    try {
      disponibles = await auth.obtenerPublicacionesFeed(disponibilidad: 'disponible');
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      return;
    }
    if (!mounted) return;

    final opciones = disponibles
        .where((pub) =>
            (pub['id_usuario'] as num).toInt() == idOferente &&
            (pub['id'] as num).toInt() != idActual)
        .toList();
    track('contraoferta_iniciada', {
      'id_oferta': (oferta['id'] as num).toInt(),
      'num_opciones': opciones.length,
    }, auth.api);
    final idNueva = await mostrarDialogoContraoferta(
      context,
      tituloPedido: pedida['titulo'] as String? ?? 'un objeto',
      opciones: opciones,
    );
    if (idNueva == null || !mounted) return;

    final id = (oferta['id'] as num).toInt();
    setState(() => _enProgreso.add(id));
    try {
      final texto = await auth.contraofertar(id, idNueva);
      track('contraoferta_enviada', {
        'id_oferta': id,
        'id_publicacion_nueva': idNueva,
        'id_publicacion_anterior': idActual,
      }, auth.api);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
      await _cargar();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _enProgreso.remove(id));
    }
  }

  String _fecha(String? texto) {
    if (texto == null) return '';
    final fecha = DateTime.parse(texto).toLocal();
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$minuto';
  }

  Future<void> _verHistorial(Map<String, dynamic> oferta) async {
    final auth = context.read<ControladorAutenticacion>();
    List<Map<String, dynamic>> propuestas;
    try {
      propuestas = await auth.obtenerHistorialOferta((oferta['id'] as num).toInt());
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      return;
    }
    if (!mounted) return;

    final pedida = oferta['pedida'] as Map<String, dynamic>;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Historial de la negociación'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Se negocia: ${pedida['titulo']}'),
                const SizedBox(height: 12),
                for (final propuesta in propuestas) ...[
                  Text(
                    'Ronda ${propuesta['ronda']}: ${propuesta['oferente']['nombre']} propone ${propuesta['ofrecida']['titulo']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_nombreEstado(propuesta['estado'] as String)} · ${_fecha(propuesta['creado_en'] as String?)}',
                  ),
                  if (propuesta['motivo_cancelacion'] != null)
                    Text('Motivo: ${propuesta['motivo_cancelacion']}'),
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
                      'Las dos publicaciones quedarán acordadas, cada uno confirmará la entrega y las otras ofertas pendientes de esos objetos se cancelarán.',
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
              idYo: context.read<ControladorAutenticacion>().usuario?.id,
              alConfirmarEntrega: () => _responder(
                (oferta['id'] as num).toInt(),
                'entrega',
                'Confirmar entrega',
                '¿Confirmas que ya entregaste tu objeto y recibiste el otro? Cuando las dos partes confirmen, el intercambio queda completado.',
                'Confirmar',
              ),
              alCancelarIntercambio: () => _cancelarIntercambio((oferta['id'] as num).toInt()),
              alContraofertar: () => _contraofertar(oferta),
              alVerHistorial: () => _verHistorial(oferta),
              alCancelar: () => _responder(
                (oferta['id'] as num).toInt(),
                'cancelar',
                'Cancelar oferta',
                '¿Cancelas esta oferta? La otra persona ya no podrá aceptarla.',
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
    required this.alContraofertar,
    required this.alVerHistorial,
    required this.idYo,
    required this.alConfirmarEntrega,
    required this.alCancelarIntercambio,
  });

  final Map<String, dynamic> oferta;
  final bool recibida;
  final int? idYo;
  final VoidCallback alConfirmarEntrega;
  final VoidCallback alCancelarIntercambio;
  final bool enProgreso;
  final VoidCallback alAceptar;
  final VoidCallback alRechazar;
  final VoidCallback alCancelar;
  final VoidCallback alContraofertar;
  final VoidCallback alVerHistorial;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final pedida = oferta['pedida'] as Map<String, dynamic>? ?? {};
    final ofrecida = oferta['ofrecida'] as Map<String, dynamic>? ?? {};
    final oferente = oferta['oferente'] as Map<String, dynamic>? ?? {};
    final autorPedida = pedida['autor'] as Map<String, dynamic>? ?? {};
    final estado = (oferta['estado'] as String?) ?? 'pendiente';
    final pendiente = estado == 'pendiente';
    final soyPedida = pedida['id_usuario'] == idYo;
    final miaConfirmada =
        (soyPedida ? oferta['confirma_pedida'] : oferta['confirma_ofrecida']) == true;
    final otraConfirmada =
        (soyPedida ? oferta['confirma_ofrecida'] : oferta['confirma_pedida']) == true;

    final autorOfrecida = ofrecida['autor'] as Map<String, dynamic>? ?? {};
    final receptor =
        oferta['id_usuario'] == pedida['id_usuario'] ? autorOfrecida : autorPedida;
    final quien = recibida
        ? 'De: ${oferente['nombre'] ?? 'Alguien'}'
        : 'Para: ${receptor['nombre'] ?? 'la otra persona'}';
    final nombreOtra =
        ((recibida ? oferente['nombre'] : receptor['nombre']) as String?) ?? 'la otra persona';

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
            const SizedBox(height: 4),
            Text('Ronda ${oferta['ronda'] ?? 1}', style: TextStyle(color: colores.onSurfaceVariant)),
            const SizedBox(height: 8),
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
              if (!enProgreso && recibida) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: alContraofertar,
                  child: const Text('Contraofertar'),
                ),
              ],
            ],
            if (estado == 'aceptada') ...[
              const SizedBox(height: 12),
              BloqueEntrega(
                key: ValueKey('entrega-${oferta['id']}'),
                idOferta: (oferta['id'] as num).toInt(),
                idYo: idYo,
              ),
              const SizedBox(height: 12),
              Text(miaConfirmada ? 'Tu entrega: confirmada' : 'Tu entrega: pendiente'),
              Text(
                otraConfirmada
                    ? 'La otra persona: confirmada'
                    : 'La otra persona: pendiente',
              ),
              const SizedBox(height: 8),
              if (enProgreso)
                const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                FilledButton(
                  onPressed: miaConfirmada ? null : alConfirmarEntrega,
                  child: const Text('Confirmar entrega'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: alCancelarIntercambio,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colores.error,
                    side: BorderSide(color: colores.error),
                  ),
                  child: const Text('Cancelar intercambio'),
                ),
              ],
            ],
            if (estado == 'completada') ...[
              const SizedBox(height: 12),
              BloqueCalificacion(
                key: ValueKey('calificacion-${oferta['id']}'),
                idOferta: (oferta['id'] as num).toInt(),
                nombreOtra: nombreOtra,
              ),
            ],
            if (estado == 'anulada' && oferta['motivo_cancelacion'] != null) ...[
              const SizedBox(height: 8),
              Text('Motivo: ${oferta['motivo_cancelacion']}'),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: alVerHistorial,
                child: const Text('Ver historial'),
              ),
            ),
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
      'contraofertada' => ('Contraofertada', colores.tertiaryContainer, colores.onTertiaryContainer),
      'aceptada' => ('Aceptada', colores.primaryContainer, colores.onPrimaryContainer),
      'completada' => ('Intercambio completado', colores.primaryContainer, colores.onPrimaryContainer),
      'anulada' => ('Intercambio cancelado', colores.errorContainer, colores.onErrorContainer),
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

String _nombreEstado(String estado) {
  return switch (estado) {
    'aceptada' => 'Aceptada',
    'completada' => 'Intercambio completado',
    'anulada' => 'Intercambio cancelado',
    'rechazada' => 'Rechazada',
    'cancelada' => 'Cancelada',
    'contraofertada' => 'Contraofertada',
    _ => 'Pendiente',
  };
}
