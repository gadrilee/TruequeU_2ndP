import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../tema.dart';

Future<String?> elegirFoto() async {
  final archivo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 80,
  );
  if (archivo == null) return null;
  final bytes = await archivo.readAsBytes();
  if (bytes.length > 2 * 1024 * 1024) {
    throw const FormatException('La foto puede pesar hasta 2 MB');
  }
  final nombre = archivo.name.toLowerCase();
  if (!nombre.endsWith('.jpg') && !nombre.endsWith('.jpeg') && !nombre.endsWith('.png')) {
    throw const FormatException('La foto tiene que ser jpg o png');
  }
  final tipo = nombre.endsWith('.png') ? 'png' : 'jpeg';
  return 'data:image/$tipo;base64,${base64Encode(bytes)}';
}

class FotoPublicacion extends StatelessWidget {
  const FotoPublicacion({super.key, this.url, this.alto = 140, this.cuadrada = false});

  final String? url;
  final double alto;
  final bool cuadrada;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final vacia = url == null || url!.trim().isEmpty;
    final hijo = vacia
        ? ColoredBox(
            color: colores.surfaceContainerHighest,
            child: Icon(Icons.image_outlined, color: colores.outline),
          )
        : _imagen();
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radios.r12),
      child: cuadrada
          ? AspectRatio(aspectRatio: 1, child: hijo)
          : SizedBox(height: alto, width: double.infinity, child: hijo),
    );
  }

  Widget _imagen() {
    if (url!.startsWith('data:image')) {
      final coma = url!.indexOf(',');
      return Image.memory(
        base64Decode(url!.substring(coma + 1)),
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
