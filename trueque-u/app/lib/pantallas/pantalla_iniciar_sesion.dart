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

class PantallaIniciarSesion extends StatefulWidget {
  const PantallaIniciarSesion({super.key});

  @override
  State<PantallaIniciarSesion> createState() => _PantallaIniciarSesionState();
}

class _PantallaIniciarSesionState extends State<PantallaIniciarSesion> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
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
          .iniciarSesion(_correo.text, _contrasena.text);
      if (!mounted) return;
      context.go('/feed');
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
      titulo: 'Trueque U',
      subtitulo: 'Qué bueno verte de nuevo',
      conLogo: true,
      pie: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('¿No tienes cuenta?'),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => context.go('/registro'),
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
      hijos: [
        Text(
          'Inicia sesión',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Espacios.e16),
        Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                controlador: _correo,
                etiqueta: 'Correo',
                icono: Icons.mail_outline,
                tipoTeclado: TextInputType.emailAddress,
                accionTeclado: TextInputAction.next,
                validador: validarCorreo,
              ),
              const SizedBox(height: Espacios.e16),
              CampoTexto(
                controlador: _contrasena,
                etiqueta: 'Contraseña',
                icono: Icons.lock_outline,
                ocultar: true,
                accionTeclado: TextInputAction.done,
                alEnviar: _enviar,
                validador: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/recuperar-contrasena'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: Espacios.e8),
              BannerError(_error),
              BotonCarga(
                texto: 'Iniciar sesión',
                cargando: _cargando,
                alPresionar: _enviar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
