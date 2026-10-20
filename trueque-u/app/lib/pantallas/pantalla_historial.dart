import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../utilidades/etiquetas.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/mensaje_vacio.dart';
import '../widgets/pagina_acceso.dart';

/// RUTA PRIVADA ("/historial"): qué ocurrió con los intercambios de la persona.
///
/// Mejora de interacción (Clase 16):
/// - Fitts: toda la tarjeta se toca para ver el detalle y los filtros miden 48 px.
/// - Hick: solo tres filtros (Todo, Reservas, Completados).
/// - Carga cognitiva: cada tarjeta dice en una frase qué pasó, con ícono y texto
///   (no solo color), y el vacío explica qué hacer.
class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  // Filtros: lo que se muestra -> lo que entiende el backend (null = todo)
  static const _filtros = {
    'Todo': null,
    'Reservas': 'reservas',
    'Completados': 'completados',
  };

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  bool _cargando = true;
  String? _error;
  String _filtro = 'Todo';
  List<Map<String, dynamic>> _eventos = [];

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
      final lista = await context
          .read<ControladorAutenticacion>()
          .obtenerHistorial(tipo: _filtros[_filtro]);
      if (!mounted) return;
      setState(() {
        _eventos = lista;
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
        _error = 'No se pudo cargar tu historial';
        _cargando = false;
      });
    }
  }

  void _elegirFiltro(String filtro) {
    if (filtro == _filtro) return;
    _filtro = filtro;
    _cargar();
  }

  /// Qué pasó, en una frase, según quién hizo la acción
  String _frase(Map<String, dynamic> evento) {
    final loHiceYo = evento['lo_hice_yo'] == true;
    final titulo = (evento['publicacion']['titulo'] as String?) ?? 'un objeto';
    final otra = (evento['otra_persona']['nombre'] as String?) ?? 'otra persona';

    switch (evento['tipo']) {
      case 'reservo':
        return loHiceYo
            ? 'Reservaste «$titulo» de $otra'
            : '$otra reservó tu «$titulo»';
      case 'cancelo_reserva':
        return loHiceYo
            ? 'Cancelaste tu reserva de «$titulo»'
            : '$otra canceló su reserva de «$titulo»';
      default:
        return loHiceYo
            ? 'Completaste el intercambio de «$titulo» con $otra'
            : '$otra completó el intercambio de «$titulo»';
    }
  }

  /// Ícono y palabra del estado (así no depende solo del color)
  (IconData, String) _estado(String tipo) {
    switch (tipo) {
      case 'reservo':
        return (Icons.bookmark_outline, 'Reservado');
      case 'cancelo_reserva':
        return (Icons.cancel_outlined, 'Reserva cancelada');
      default:
        return (Icons.check_circle_outline, 'Completado');
    }
  }

  /// "20 oct" para la lista, o "20 oct 2026, 16:24" para el detalle
  String _fecha(String? iso, {bool completa = false}) {
    final fecha = DateTime.tryParse(iso ?? '')?.toLocal();
    if (fecha == null) return '';
    final dia = '${fecha.day} ${_meses[fecha.month - 1]}';
    if (!completa) return dia;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia ${fecha.year}, $hora:$minuto';
  }

  void _verDetalle(Map<String, dynamic> evento) {
    final publicacion = evento['publicacion'] as Map<String, dynamic>;
    final (icono, estado) = _estado(evento['tipo'] as String);
    final categoria = etiquetasCategoria[publicacion['categoria']] ?? 'Otros';
    final otra = (evento['otra_persona']['nombre'] as String?) ?? 'otra persona';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text((publicacion['titulo'] as String?) ?? 'Sin título'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_frase(evento)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(icono, size: 18),
                const SizedBox(width: 8),
                Text('Estado: $estado'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Categoría: $categoria'),
            const SizedBox(height: 8),
            Text('Con: $otra'),
            const SizedBox(height: 8),
            Text('Fecha: ${_fecha(evento['creado_en'] as String?, completa: true)}'),
            if (publicacion['id'] == null) ...[
              const SizedBox(height: 12),
              const Text('Esta publicación ya no existe.'),
            ],
          ],
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
    final colores = Theme.of(context).colorScheme;

    Widget contenido;
    if (_cargando) {
      contenido = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      contenido = ErrorConReintento(mensaje: _error, alReintentar: _cargar);
    } else if (_eventos.isEmpty && _filtro == 'Todo') {
      contenido = MensajeVacio(
        icono: Icons.history,
        titulo: 'Aún no tienes movimientos',
        mensaje: 'Cuando reserves o completes un intercambio, aparecerá aquí.',
        textoBoton: 'Explorar publicaciones',
        alBoton: () => context.go('/feed'),
      );
    } else if (_eventos.isEmpty) {
      contenido = MensajeVacio(
        icono: Icons.history,
        titulo: 'No hay ${_filtro.toLowerCase()}',
        mensaje: 'Todavía no tienes nada en esta lista.',
        textoBoton: 'Ver todo',
        alBoton: () => _elegirFiltro('Todo'),
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final evento in _eventos) ...[
            Card(
              elevation: 1,
              clipBehavior: Clip.antiAlias,
              // Toda la tarjeta es tocable
              child: InkWell(
                onTap: () => _verDetalle(evento),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_estado(evento['tipo'] as String).$1, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _frase(evento),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_estado(evento['tipo'] as String).$2} · ${_fecha(evento['creado_en'] as String?)}',
                              style: TextStyle(color: colores.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return PaginaAcceso(
      titulo: 'Historial',
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
        // Los tres filtros en una fila
        Wrap(
          spacing: 8,
          children: [
            for (final filtro in _filtros.keys)
              ChoiceChip(
                label: Text(filtro),
                selected: _filtro == filtro,
                visualDensity: VisualDensity.standard,
                onSelected: (_) => _elegirFiltro(filtro),
              ),
          ],
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
