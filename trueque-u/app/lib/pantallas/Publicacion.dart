import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/analitica.dart';
import '../servicios/cliente_api.dart';
import '../utilidades/etiquetas.dart';
import '../widgets/banner_error.dart';
import '../widgets/boton_carga.dart';
import '../widgets/campo_texto.dart';
import '../widgets/pagina_acceso.dart';

/// Formulario para crear una nueva publicación de trueque.
class PantallaPublicacion extends StatefulWidget {
  const PantallaPublicacion({super.key});

  @override
  State<PantallaPublicacion> createState() => _PantallaPublicacionState();
}

class _PantallaPublicacionState extends State<PantallaPublicacion> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  String _estado = 'nuevo'; // 'nuevo' o 'usado'
  String _categoria = 'otros'; // libros, electronica, ropa u otros
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final auth = context.read<ControladorAutenticacion>();
      await auth.crearPublicacion(
            titulo: _nombre.text,
            descripcion: _descripcion.text,
            estado: _estado,
            categoria: _categoria,
          );
      track('publicacion_creada', {
        'categoria': _categoria,
        'estado': _estado,
        'tiene_descripcion': _descripcion.text.trim().isNotEmpty,
      }, auth.api);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación guardada exitosamente')),
      );
      // Cierra la pantalla y vuelve a pantalla_perfil.dart
      context.go('/perfil');
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error al guardar la publicación';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaAcceso(
      titulo: 'Nueva publicación',
      alVolver: () => context.go('/perfil'),
      hijos: [
        Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                controlador: _nombre,
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
              const SizedBox(height: 16),
              CampoTexto(
                controlador: _descripcion,
                etiqueta: 'Descripción (opcional)',
                lineas: 3,
                tipoTeclado: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado del objeto',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'nuevo', child: Text('Nuevo')),
                  DropdownMenuItem(value: 'usado', child: Text('Usado')),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _estado = valor);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in etiquetasCategoria.entries)
                    DropdownMenuItem(value: c.key, child: Text(c.value)),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _categoria = valor);
                  }
                },
              ),
              const SizedBox(height: 20),
              BannerError(_error),
              BotonCarga(
                texto: 'Guardar',
                cargando: _cargando,
                alPresionar: _guardar,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/perfil'),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
