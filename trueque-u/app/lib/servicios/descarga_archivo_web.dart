import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool descargarArchivo(String nombre, String contenido, String tipo) {
  final archivo = web.Blob(
    [contenido.toJS].toJS,
    web.BlobPropertyBag(type: '$tipo;charset=utf-8'),
  );
  final enlace = web.document.createElement('a') as web.HTMLAnchorElement;
  enlace.href = web.URL.createObjectURL(archivo);
  enlace.download = nombre;
  enlace.click();
  web.URL.revokeObjectURL(enlace.href);
  return true;
}
