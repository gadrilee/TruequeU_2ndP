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

/// Recuperar contraseña: la persona escribe su correo y recibe una contraseña nueva por correo.
class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() =>
      _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState extends State<PantallaRecuperarContrasena> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  bool _cargando = false;
  String? _error;
  bool _enviado = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _enviado = false;
    });
    try {
      await context.read<ControladorAutenticacion>().recuperarContrasena(_correo.text);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _cargando = false;
      });
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
    final colores = Theme.of(context).colorScheme;

    return PaginaAcceso(
      titulo: 'Recuperar contraseña',
      subtitulo: 'Te ayudamos a volver a entrar',
      alVolver: () => context.go('/iniciar-sesion'),
      pie: TextButton.icon(
        onPressed: () => context.go('/iniciar-sesion'),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver a iniciar sesión'),
      ),
      hijos: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.vpn_key, color: colores.primary),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Escribe el correo de tu cuenta y te enviaremos una contraseña nueva.',
        ),
        const SizedBox(height: 16),
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
                accionTeclado: TextInputAction.done,
                alEnviar: _enviar,
                validador: validarCorreo,
              ),
              const SizedBox(height: 16),
              BannerError(_error),
              BotonCarga(
                texto: 'Enviar contraseña nueva',
                cargando: _cargando,
                alPresionar: _enviar,
              ),
            ],
          ),
        ),
        if (_enviado) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colores.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colores.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Listo. Revisa tu correo: ahí está tu contraseña nueva.',
                    style: TextStyle(color: colores.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
