import 'package:flutter/material.dart';

import 'encabezado_acceso.dart';
import '../tema.dart';

class PaginaAcceso extends StatelessWidget {
  const PaginaAcceso({
    super.key,
    required this.titulo,
    required this.hijos,
    this.subtitulo,
    this.conLogo = false,
    this.pie,
    this.alVolver,
    this.acciones,
    this.anchoMaximo = 420,
    this.botonFlotante,
  });

  final String titulo;
  final List<Widget> hijos;
  final String? subtitulo;
  final bool conLogo;
  final Widget? pie;
  final VoidCallback? alVolver;
  final List<Widget>? acciones;
  final double anchoMaximo;
  final Widget? botonFlotante;

  @override
  Widget build(BuildContext context) {
    final contenido = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: hijos,
      ),
    );

    if (subtitulo == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          automaticallyImplyLeading: false,
          leading: alVolver != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: alVolver,
                )
              : null,
          actions: acciones,
        ),
        floatingActionButton: botonFlotante,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacios.e24),
            child: contenido,
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          EncabezadoAcceso(
            titulo: titulo,
            subtitulo: subtitulo!,
            conLogo: conLogo,
            alVolver: alVolver,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Espacios.e24),
                child: contenido,
              ),
            ),
          ),
          if (pie != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Espacios.e16),
                child: pie,
              ),
            ),
        ],
      ),
    );
  }
}
