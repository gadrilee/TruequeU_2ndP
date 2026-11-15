import 'package:flutter/material.dart';

class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.icono,
    this.validador,
    this.tipoTeclado,
    this.accionTeclado,
    this.alEnviar,
    this.ocultar = false,
    this.lineas = 1,
    this.ayuda,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData? icono;
  final String? Function(String?)? validador;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final VoidCallback? alEnviar;
  final bool ocultar;
  final int lineas;
  final String? ayuda;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  bool _verTexto = false;

  @override
  Widget build(BuildContext context) {
    final oculto = widget.ocultar && !_verTexto;

    return TextFormField(
      controller: widget.controlador,
      obscureText: oculto,
      keyboardType: widget.tipoTeclado,
      textInputAction: widget.accionTeclado,
      maxLines: widget.ocultar ? 1 : widget.lineas,
      validator: widget.validador,
      onFieldSubmitted: (_) => widget.alEnviar?.call(),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        helperMaxLines: 3,
        prefixIcon: widget.icono != null ? Icon(widget.icono) : null,
        suffixIcon: widget.ocultar
            ? IconButton(
                tooltip: _verTexto ? 'Ocultar contraseña' : 'Mostrar contraseña',
                icon: Icon(
                  _verTexto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _verTexto = !_verTexto),
              )
            : null,
      ),
    );
  }
}
