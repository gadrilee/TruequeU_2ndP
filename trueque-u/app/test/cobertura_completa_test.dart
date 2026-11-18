// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/configuracion.dart';
import 'package:trueque_u/estado/controlador_autenticacion.dart';
import 'package:trueque_u/main.dart';
import 'package:trueque_u/pantallas/Publicacion.dart';
import 'package:trueque_u/pantallas/pantalla_avisos.dart';
import 'package:trueque_u/pantallas/pantalla_cambiar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_feed_publicaciones.dart';
import 'package:trueque_u/pantallas/pantalla_historial.dart';
import 'package:trueque_u/pantallas/pantalla_iniciar_sesion.dart';
import 'package:trueque_u/pantallas/pantalla_inicio.dart';
import 'package:trueque_u/pantallas/pantalla_intercambios.dart';
import 'package:trueque_u/pantallas/pantalla_mis_datos.dart';
import 'package:trueque_u/pantallas/pantalla_mis_publicaciones.dart';
import 'package:trueque_u/pantallas/pantalla_ofertas.dart';
import 'package:trueque_u/pantallas/pantalla_perfil.dart';
import 'package:trueque_u/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_registro.dart';
import 'package:trueque_u/rutas.dart';
import 'package:trueque_u/servicios/analitica.dart';
import 'package:trueque_u/servicios/cliente_api.dart';
import 'package:trueque_u/servicios/descarga_archivo.dart';
import 'package:trueque_u/servicios/descarga_archivo_otro.dart';
import 'package:trueque_u/tema.dart';
import 'package:trueque_u/utilidades/etiquetas.dart';
import 'package:trueque_u/utilidades/formato_entrega.dart';
import 'package:trueque_u/utilidades/validadores.dart';
import 'package:trueque_u/utilidades/whatsapp.dart';
import 'package:trueque_u/widgets/banner_error.dart';
import 'package:trueque_u/widgets/bloque_calificacion.dart';
import 'package:trueque_u/widgets/bloque_entrega.dart';
import 'package:trueque_u/widgets/boton_carga.dart';
import 'package:trueque_u/widgets/campo_texto.dart';
import 'package:trueque_u/widgets/chip_estado.dart';
import 'package:trueque_u/widgets/dialogo_ayuda.dart';
import 'package:trueque_u/widgets/dialogo_calificacion.dart';
import 'package:trueque_u/widgets/dialogo_confirmacion.dart';
import 'package:trueque_u/widgets/dialogo_editar_publicacion.dart';
import 'package:trueque_u/widgets/dialogo_eliminar_cuenta.dart';
import 'package:trueque_u/widgets/dialogo_entrega.dart';
import 'package:trueque_u/widgets/dialogo_motivo.dart';
import 'package:trueque_u/widgets/dialogo_oferta.dart';
import 'package:trueque_u/widgets/encabezado_acceso.dart';
import 'package:trueque_u/widgets/error_con_reintento.dart';
import 'package:trueque_u/widgets/estrellas.dart';
import 'package:trueque_u/widgets/estructura_principal.dart';
import 'package:trueque_u/widgets/etiqueta.dart';
import 'package:trueque_u/widgets/filtros_feed.dart';
import 'package:trueque_u/widgets/foto_publicacion.dart';
import 'package:trueque_u/widgets/mensaje_vacio.dart';
import 'package:trueque_u/widgets/pagina_acceso.dart';
import 'package:trueque_u/widgets/resumen_calificaciones.dart';
import 'package:trueque_u/widgets/tarjeta_feed.dart';
import 'package:trueque_u/widgets/tarjeta_intercambio.dart';
import 'package:trueque_u/widgets/tarjeta_mi_publicacion.dart';

void main() {
  test('todos los archivos de lib se cargan para que cuenten en la cobertura', () {
    expect(true, isTrue);
  });
}
