import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'configuracion.dart';
import 'estado/controlador_autenticacion.dart';
import 'rutas.dart';
import 'servicios/cliente_api.dart';
import 'tema.dart';

// coverage:ignore-start
Future<void> main() async {
  debugPrint('[inicio] Arrancando Trueque U...');
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[inicio] Leyendo el archivo .env');
  await dotenv.load(fileName: '.env');
  debugPrint('[inicio] El backend está en: ${ConfiguracionEntorno.urlBase}');
  if (ConfiguracionEntorno.usaServidorLocal) {
    debugPrint('[inicio] OJO: el .env no trae API_URL, se usará localhost (en el celular no sirve)');
  }

  final preferencias = await SharedPreferences.getInstance();
  final autenticacion = ControladorAutenticacion(ClienteApi(), preferencias);

  // Se restaura la sesión ANTES de mostrar la primera pantalla, para que al
  // recargar la app las rutas privadas ya sepan si hay persona o no.
  await autenticacion.restaurarSesion();

  debugPrint('[inicio] Todo listo, se muestra la primera pantalla');
  runApp(AplicacionTruequeU(autenticacion: autenticacion));
}
// coverage:ignore-end

class AplicacionTruequeU extends StatefulWidget {
  const AplicacionTruequeU({super.key, required this.autenticacion});

  final ControladorAutenticacion autenticacion;

  @override
  State<AplicacionTruequeU> createState() => _AplicacionTruequeUState();
}

class _AplicacionTruequeUState extends State<AplicacionTruequeU> {
  late final GoRouter _rutas = construirRutas(widget.autenticacion);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ControladorAutenticacion>.value(
      value: widget.autenticacion,
      child: MaterialApp.router(
        title: 'Trueque U',
        debugShowCheckedModeBanner: false,
        theme: TemaTruequeU.claro(),
        routerConfig: _rutas,
      ),
    );
  }
}
