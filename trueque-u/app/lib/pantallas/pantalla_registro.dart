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

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _contrasena.dispose();
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
          .registrar(_nombre.text, _correo.text, _contrasena.text,
              telefono: _telefono.text);
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
      titulo: 'Crear cuenta',
      subtitulo: 'Únete a la comunidad de tu campus',
      alVolver: () => context.go('/iniciar-sesion'),
      pie: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('¿Ya tienes cuenta?'),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => context.go('/iniciar-sesion'),
            child: const Text('Inicia sesión'),
          ),
        ],
      ),
      hijos: [
        Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                controlador: _nombre,
                etiqueta: 'Nombre completo',
                icono: Icons.person_outline,
                accionTeclado: TextInputAction.next,
                validador: (v) =>
                    (v ?? '').trim().length < 2 ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: Espacios.e16),
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
                controlador: _telefono,
                etiqueta: 'Teléfono (opcional, 8 dígitos)',
                ayuda:
                    'Solo lo verá la persona con la que acuerdes un trueque. Puedes dejarlo vacío.',
                icono: Icons.phone_outlined,
                tipoTeclado: TextInputType.phone,
                accionTeclado: TextInputAction.next,
                validador: validarTelefonoOpcional,
              ),
              const SizedBox(height: Espacios.e16),
              CampoTexto(
                controlador: _contrasena,
                etiqueta: 'Contraseña',
                icono: Icons.lock_outline,
                ocultar: true,
                accionTeclado: TextInputAction.next,
                validador: validarContrasenaNueva,
              ),
              const SizedBox(height: Espacios.e16),
              CampoTexto(
                controlador: _confirmacion,
                etiqueta: 'Repite la contraseña',
                icono: Icons.lock_outline,
                ocultar: true,
                accionTeclado: TextInputAction.done,
                alEnviar: _enviar,
                validador: (v) =>
                    v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: Espacios.e16),
              BannerError(_error),
              BotonCarga(
                texto: 'Crear cuenta',
                cargando: _cargando,
                alPresionar: _enviar,
                rojo: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
