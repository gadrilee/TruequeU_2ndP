import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/controlador_autenticacion.dart';
import '../servicios/cliente_api.dart';
import '../utilidades/validadores.dart';
import '../widgets/banner_error.dart';
import '../widgets/boton_carga.dart';
import '../widgets/campo_texto.dart';
import '../widgets/pagina_acceso.dart';
import '../tema.dart';

/// RUTA PRIVADA ("/cambiar-contrasena"): cambio de contraseña con la sesión iniciada.
class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key});

  @override
  State<PantallaCambiarContrasena> createState() => _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final _formulario = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context
          .read<ControladorAutenticacion>()
          .cambiarContrasena(_actual.text, _nueva.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
      );
      context.go('/perfil');
    } on ExcepcionApi catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaAcceso(
      titulo: 'Cambiar contraseña',
      hijos: [
        Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                controlador: _actual,
                etiqueta: 'Contraseña actual',
                ocultar: true,
                accionTeclado: TextInputAction.next,
                validador: (v) =>
                    (v ?? '').isEmpty ? 'Escribe tu contraseña actual' : null,
              ),
              const SizedBox(height: Espacios.e16),
              CampoTexto(
                controlador: _nueva,
                etiqueta: 'Contraseña nueva',
                ocultar: true,
                accionTeclado: TextInputAction.next,
                validador: validarContrasenaNueva,
              ),
              const SizedBox(height: Espacios.e16),
              CampoTexto(
                controlador: _confirmacion,
                etiqueta: 'Repite la contraseña nueva',
                ocultar: true,
                accionTeclado: TextInputAction.done,
                alEnviar: _enviar,
                validador: (v) =>
                    v != _nueva.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: Espacios.e16),
              BannerError(_error),
              BotonCarga(texto: 'Guardar', cargando: _cargando, alPresionar: _enviar),
            ],
          ),
        ),
        const SizedBox(height: Espacios.e8),
        TextButton(
          onPressed: () => context.go('/perfil'),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
