import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import 'banner_error.dart';
import 'campo_texto.dart';
import 'foto_publicacion.dart';
import '../tema.dart';

/// =========================================================================
/// DIÁLOGO PARA EDITAR INFORMACIÓN (SOLO NOMBRE Y DESCRIPCIÓN)
/// =========================================================================
/// Permite modificar únicamente el nombre y la descripción del objeto publicado.
/// Muestra errores de validación y respuestas de error del servidor como BannerError.
class DialogoEditarPublicacion extends StatefulWidget {
  const DialogoEditarPublicacion({
    super.key,
    required this.id,
    required this.tituloInicial,
    this.descripcionInicial,
    this.imagenInicial,
  });

  final int id;
  final String tituloInicial;
  final String? descripcionInicial;
  final String? imagenInicial;

  @override
  State<DialogoEditarPublicacion> createState() =>
      _DialogoEditarPublicacionState();
}

class _DialogoEditarPublicacionState extends State<DialogoEditarPublicacion> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  bool _guardando = false;
  String? _error;
  String? _fotoNueva;
  bool _quitarFoto = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.tituloInicial);
    _descripcionCtrl =
        TextEditingController(text: widget.descripcionInicial ?? '');
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await context.read<ControladorAutenticacion>().editarPublicacion(
            widget.id,
            titulo: _tituloCtrl.text,
            descripcion: _descripcionCtrl.text,
            imagen: _fotoNueva,
            quitarImagen: _quitarFoto && _fotoNueva == null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error al actualizar la publicación';
        _guardando = false;
      });
    }
  }

  Future<void> _elegir() async {
    try {
      final foto = await elegirFoto();
      if (foto == null || !mounted) return;
      setState(() {
        _fotoNueva = foto;
        _quitarFoto = false;
        _error = null;
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  String? get _fotoVisible {
    if (_fotoNueva != null) return _fotoNueva;
    if (_quitarFoto) return null;
    return widget.imagenInicial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar información'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoTexto(
                  controlador: _tituloCtrl,
                  etiqueta: 'Nombre del objeto',
                  accionTeclado: TextInputAction.next,
                  validador: (v) {
                    final texto = (v ?? '').trim();
                    if (texto.isEmpty) return 'Escribe el nombre del objeto';
                    if (texto.length < 2) return 'Mínimo 2 letras';
                    if (texto.length > 150) return 'Máximo 150 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: Espacios.e16),
                CampoTexto(
                  controlador: _descripcionCtrl,
                  etiqueta: 'Descripción (opcional)',
                  lineas: 3,
                  tipoTeclado: TextInputType.multiline,
                ),
                const SizedBox(height: Espacios.e16),
                FotoPublicacion(url: _fotoVisible, alto: 140),
                const SizedBox(height: Espacios.e8),
                OutlinedButton(
                  onPressed: _guardando ? null : _elegir,
                  child: const Text('Cambiar foto'),
                ),
                if (_fotoVisible != null)
                  TextButton(
                    onPressed: _guardando
                        ? null
                        : () => setState(() {
                              _fotoNueva = null;
                              _quitarFoto = true;
                            }),
                    child: const Text('Quitar foto'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: Espacios.e16),
                  BannerError(_error),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
