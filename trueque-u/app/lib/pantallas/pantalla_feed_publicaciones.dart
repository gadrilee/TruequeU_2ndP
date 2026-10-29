import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../utilidades/whatsapp.dart';
import '../widgets/dialogo_ayuda.dart';
import '../widgets/dialogo_confirmacion.dart';
import '../widgets/dialogo_oferta.dart';
import '../widgets/error_con_reintento.dart';
import '../widgets/filtros_feed.dart';
import '../widgets/mensaje_vacio.dart';
import '../widgets/tarjeta_feed.dart';

/// =========================================================================
/// PANTALLA FEED DE PUBLICACIONES (VISTA EN CUADRÍCULA / GRID)
/// =========================================================================
/// Muestra todas las publicaciones del sistema en una cuadrícula responsiva.
/// Permite a cualquier usuario explorar ofertas de trueque, ver el estado
/// de cada artículo, buscar por título, filtrar, reservar, descartar reservas
/// y completar intercambios.
class PantallaFeedPublicaciones extends StatefulWidget {
  const PantallaFeedPublicaciones({super.key});

  @override
  State<PantallaFeedPublicaciones> createState() =>
      _PantallaFeedPublicacionesState();
}

class _PantallaFeedPublicacionesState extends State<PantallaFeedPublicaciones> {
  // Estados para control de carga y errores
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _publicaciones = [];

  // Búsqueda y filtros (null = sin filtro)
  final _buscarCtrl = TextEditingController();
  String _busqueda = ''; // texto de búsqueda que ya se aplicó
  String? _categoria;
  String? _condicion;
  String? _disponibilidad;

  bool get _hayFiltros =>
      _busqueda.isNotEmpty ||
      _categoria != null ||
      _condicion != null ||
      _disponibilidad != null;

  // Almacena los IDs de publicaciones que tienen una acción en proceso (para mostrar spinner en el botón)
  final Set<int> _accionesEnProgreso = {};

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  /// Cambia un filtro y vuelve a pedir las publicaciones
  void _aplicarFiltro(VoidCallback cambio) {
    setState(cambio);
    _cargarPublicaciones();
  }

  /// Aplica el texto escrito en el buscador
  void _buscar() => _aplicarFiltro(() => _busqueda = _buscarCtrl.text.trim());

  /// Elige un valor para un filtro ('categoria', 'condicion' o 'disponibilidad')
  void _elegirFiltro(String filtro, String valor) {
    _aplicarFiltro(() {
      if (filtro == 'categoria') _categoria = valor;
      if (filtro == 'condicion') _condicion = valor;
      if (filtro == 'disponibilidad') _disponibilidad = valor;
    });
  }

  /// Quita un solo filtro (o la búsqueda)
  void _quitarFiltro(String filtro) {
    if (filtro == 'busqueda') _buscarCtrl.clear();
    _aplicarFiltro(() {
      if (filtro == 'busqueda') _busqueda = '';
      if (filtro == 'categoria') _categoria = null;
      if (filtro == 'condicion') _condicion = null;
      if (filtro == 'disponibilidad') _disponibilidad = null;
    });
  }

  /// Quita todos los filtros y la búsqueda
  void _quitarFiltros() {
    _buscarCtrl.clear();
    _aplicarFiltro(() {
      _busqueda = '';
      _categoria = null;
      _condicion = null;
      _disponibilidad = null;
    });
  }

  /// Carga o recarga la lista de publicaciones desde el backend
  Future<void> _cargarPublicaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await context
          .read<ControladorAutenticacion>()
          .obtenerPublicacionesFeed(
            buscar: _busqueda,
            categoria: _categoria,
            condicion: _condicion,
            disponibilidad: _disponibilidad,
          );
      if (!mounted) return;
      setState(() {
        _publicaciones = lista;
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
        _error = 'No se pudieron cargar las publicaciones del feed';
        _cargando = false;
      });
    }
  }

  /// LÓGICA DE RESERVAR:
  /// Envía la petición PUT /api/publicaciones/:id/reservado (el servidor usa la sesión)
  Future<void> _reservar(int idPublicacion, String titulo) async {
    final auth = context.read<ControladorAutenticacion>();
    // Solo se reserva con la sesión iniciada
    if (auth.usuario == null) return;

    // H5 (prevención de errores): se pide confirmación antes de apartar el objeto
    final acepta = await confirmarAccion(
      context,
      titulo: 'Reservar publicación',
      mensaje:
          '¿Quieres reservar "$titulo"? Quedará apartada para ti y '
          'podrás cancelar la reserva si cambias de idea.',
      textoBoton: 'Reservar',
    );
    if (!acepta || !mounted) return;

    setState(() => _accionesEnProgreso.add(idPublicacion));

    try {
      await auth.reservarPublicacion(idPublicacion);
      if (!mounted) return;
      // H1/H7: se dice qué pasó y cuál es el siguiente paso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            'Reservaste "$titulo". Escríbele al dueño por WhatsApp para coordinar la entrega.',
          ),
        ),
      );
      // Recarga el feed para actualizar la información de la card
      await _cargarPublicaciones();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reservar la publicación')),
      );
    } finally {
      if (mounted) {
        setState(() => _accionesEnProgreso.remove(idPublicacion));
      }
    }
  }

  Future<void> _ofrecer(int idPublicacion, String titulo) async {
    final auth = context.read<ControladorAutenticacion>();
    if (auth.usuario == null) return;

    List<Map<String, dynamic>> mias;
    try {
      mias = await auth.obtenerMisPublicaciones();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
      return;
    }
    if (!mounted) return;

    final disponibles = mias
        .where((pub) => pub['estado_publicacion'] == 'disponible')
        .toList();
    final idOfrecida = await mostrarDialogoOferta(
      context,
      tituloDeseado: titulo,
      misDisponibles: disponibles,
    );
    if (idOfrecida == null || !mounted) return;

    setState(() => _accionesEnProgreso.add(idPublicacion));
    try {
      final mensaje = await auth.crearOferta(
        idPublicacionPedida: idPublicacion,
        idPublicacionOfrecida: idOfrecida,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text('$mensaje Revísala en Ofertas de trueque.'),
        ),
      );
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar la oferta')),
      );
    } finally {
      if (mounted) setState(() => _accionesEnProgreso.remove(idPublicacion));
    }
  }

  /// LÓGICA DE DESCARTAR RESERVA:
  /// Envía la petición PUT /api/publicaciones/:id/disponible para liberar la publicación
  Future<void> _descartarReserva(int idPublicacion, String titulo) async {
    final auth = context.read<ControladorAutenticacion>();

    // H3 (control y libertad): quien reservó puede cancelar, pero se le pide confirmar
    final acepta = await confirmarAccion(
      context,
      titulo: 'Cancelar reserva',
      mensaje:
          '¿Quieres cancelar tu reserva de "$titulo"? La publicación '
          'volverá a estar disponible para otras personas.',
      textoBoton: 'Sí, cancelar reserva',
      textoCancelar: 'Mantener reserva',
    );
    if (!acepta || !mounted) return;

    setState(() => _accionesEnProgreso.add(idPublicacion));

    try {
      await auth.descartarReservaPublicacion(idPublicacion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva descartada. Publicación nuevamente disponible.')),
      );
      // Recarga el feed para reflejar el estado disponible
      await _cargarPublicaciones();
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al descartar la reserva')),
      );
    } finally {
      if (mounted) {
        setState(() => _accionesEnProgreso.remove(idPublicacion));
      }
    }
  }

  /// LÓGICA DE COMPLETAR EL INTERCAMBIO:
  /// Pide confirmación y envía PUT /api/publicaciones/:id/intercambiado
  Future<void> _completar(int idPublicacion, String titulo) async {
    final auth = context.read<ControladorAutenticacion>();

    final acepta = await confirmarAccion(
      context,
      titulo: 'Completar intercambio',
      mensaje:
          '¿Confirmas que el intercambio de "$titulo" ya se realizó? '
          'Después no se podrá reservar, editar ni eliminar.',
      textoBoton: 'Completar',
    );
    if (!acepta || !mounted) return;

    setState(() => _accionesEnProgreso.add(idPublicacion));

    try {
      await auth.completarIntercambio(idPublicacion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Intercambio completado!')),
      );
      await _cargarPublicaciones();
    } on ExcepcionApi catch (e) {
      // Si no se puede, el servidor explica el motivo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al completar el intercambio')),
      );
    } finally {
      if (mounted) {
        setState(() => _accionesEnProgreso.remove(idPublicacion));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = context.watch<ControladorAutenticacion>().usuario;

    Widget cuerpo;

    if (_cargando) {
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      cuerpo = ErrorConReintento(
        mensaje: _error,
        alReintentar: _cargarPublicaciones,
      );
    } else if (_publicaciones.isEmpty && _hayFiltros) {
      // Hay filtros activos pero nada coincide
      cuerpo = MensajeVacio(
        icono: Icons.search_off,
        titulo: 'Ninguna publicación coincide con tu búsqueda',
        textoBoton: 'Quitar filtros',
        alBoton: _quitarFiltros,
      );
    } else if (_publicaciones.isEmpty) {
      cuerpo = MensajeVacio(
        icono: Icons.feed_outlined,
        titulo: 'No hay publicaciones disponibles',
        mensaje: 'Sé el primero en compartir un objeto para intercambiar con la comunidad.',
        textoBoton: 'Crear publicación',
        alBoton: () => context.go('/publicacion'),
      );
    } else {
      cuerpo = LayoutBuilder(
        builder: (context, constraints) {
          // Calcula el número de columnas para la cuadrícula en base al ancho disponible
          final anchoTotal = constraints.maxWidth;
          final int columnas = anchoTotal > 900
              ? 3
              : (anchoTotal > 600 ? 2 : 1);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  // Relación de aspecto adaptada para acomodar título, descripción y botones
                  mainAxisExtent: 420,
                ),
                itemCount: _publicaciones.length,
                itemBuilder: (context, index) {
                  final pub = _publicaciones[index];
                  final id = (pub['id'] as num).toInt();
                  final idAutor = (pub['id_usuario'] as num?)?.toInt();
                  final idReserva = (pub['id_usuario_reserva'] as num?)?.toInt();

                  // Extracción de datos del autor y de quién reservó
                  final autor = pub['autor'] as Map<String, dynamic>?;
                  final usuarioReserva = pub['usuario_reserva'] as Map<String, dynamic>?;

                  final nombreAutor = autor?['nombre'] as String? ?? 'Usuario';
                  final nombreReserva = usuarioReserva?['nombre'] as String?;
                  // El servidor manda el teléfono del dueño solo a quien reservó
                  final telefonoAutor = autor?['telefono'] as String?;

                  final estaReservado = pub['estado_publicacion'] == 'reservado';
                  final tituloPub = (pub['titulo'] as String?) ?? 'Sin título';
                  final loReserveYo =
                      usuarioActual != null && idReserva == usuarioActual.id;
                  final esMiPublicacion =
                      usuarioActual != null && idAutor == usuarioActual.id;
                  final enProgreso = _accionesEnProgreso.contains(id);

                  return TarjetaFeed(
                    id: id,
                    titulo: tituloPub,
                    descripcion: pub['descripcion'] as String?,
                    estadoFisico: (pub['estado'] as String?) ?? 'usado',
                    categoria: (pub['categoria'] as String?) ?? 'otros',
                    estadoPublicacion:
                        (pub['estado_publicacion'] as String?) ?? 'disponible',
                    nombreAutor: nombreAutor,
                    nombreReserva: nombreReserva,
                    estaReservado: estaReservado,
                    loReserveYo: loReserveYo,
                    esMiPublicacion: esMiPublicacion,
                    enProgreso: enProgreso,
                    telefonoDueno: telefonoAutor,
                    alContactar: () => abrirWhatsapp(
                      context,
                      telefonoAutor ?? '',
                      mensaje:
                          'Hola $nombreAutor, reservé "$tituloPub" en Trueque U. ¿Coordinamos la entrega?',
                    ),
                    alReservar: () => _reservar(id, tituloPub),
                    alOfertar: () => _ofrecer(id, tituloPub),
                    alDescartar: () => _descartarReserva(id, tituloPub),
                    alCompletar: () => _completar(id, tituloPub),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al perfil',
          onPressed: () => context.go('/perfil'),
        ),
        actions: [
          // H10: ayuda contextual, siempre a un toque
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ayuda: ¿cómo funciona?',
            onPressed: () => mostrarAyudaTrueque(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar feed',
            onPressed: _cargarPublicaciones,
          ),
        ],
      ),
      // Arriba el buscador y los filtros; abajo la lista
      body: Column(
        children: [
          FiltrosFeed(
            buscarCtrl: _buscarCtrl,
            busqueda: _busqueda,
            categoria: _categoria,
            condicion: _condicion,
            disponibilidad: _disponibilidad,
            alBuscar: _buscar,
            alElegir: _elegirFiltro,
            alQuitar: _quitarFiltro,
            alQuitarTodos: _quitarFiltros,
          ),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}
