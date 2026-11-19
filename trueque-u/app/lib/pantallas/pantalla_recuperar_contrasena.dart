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
              color: TemaTruequeU.azulClaro,
              borderRadius: BorderRadius.circular(Radios.r16),
            ),
            child: const Icon(Icons.vpn_key, color: TemaTruequeU.azul),
          ),
        ),
        const SizedBox(height: Espacios.e16),
        const Text(
          'Escribe el correo de tu cuenta y te enviaremos una contraseña nueva.',
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
                accionTeclado: TextInputAction.done,
                alEnviar: _enviar,
                validador: validarCorreo,
              ),
              const SizedBox(height: Espacios.e16),
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
          const SizedBox(height: Espacios.e16),
          Container(
            padding: const EdgeInsets.all(Espacios.e16),
            decoration: BoxDecoration(
              color: TemaTruequeU.verdeClaro,
              borderRadius: BorderRadius.circular(Radios.r14),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: TemaTruequeU.verdeOscuro),
                SizedBox(width: Espacios.e12),
                Expanded(
                  child: Text(
                    'Listo. Revisa tu correo: ahí está tu contraseña nueva.',
                    style: TextStyle(color: TemaTruequeU.verdeOscuro),
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
