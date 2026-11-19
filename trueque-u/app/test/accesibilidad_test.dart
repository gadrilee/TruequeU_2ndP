import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trueque_u/pantallas/pantalla_iniciar_sesion.dart';
import 'package:trueque_u/pantallas/pantalla_inicio.dart';
import 'package:trueque_u/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:trueque_u/pantallas/pantalla_registro.dart';
import 'package:trueque_u/tema.dart';
import 'package:trueque_u/widgets/estrellas.dart';
import 'package:trueque_u/widgets/foto_publicacion.dart';
import 'package:trueque_u/widgets/logo_trueque_u.dart';
import 'package:trueque_u/widgets/mensaje_vacio.dart';
import 'package:trueque_u/widgets/tarjeta_feed.dart';
import 'package:trueque_u/widgets/tarjeta_mi_publicacion.dart';

import 'ayudantes/montar.dart';

Future<void> montarConTema(WidgetTester tester, Widget hijo) async {
  final controlador = await controladorSinRed();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controlador,
      child: MaterialApp(theme: TemaTruequeU.claro(), home: hijo),
    ),
  );
  await tester.pumpAndSettle();
}

void comprobarGuias(WidgetTester tester) {
  expect(tester, meetsGuideline(androidTapTargetGuideline));
  expect(tester, meetsGuideline(iOSTapTargetGuideline));
  expect(tester, meetsGuideline(labeledTapTargetGuideline));
  expect(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  final pantallas = <String, Widget Function()>{
    'inicio': () => const PantallaInicio(),
    'iniciar sesion': () => const PantallaIniciarSesion(),
    'registro': () => const PantallaRegistro(),
    'recuperar contrasena': () => const PantallaRecuperarContrasena(),
  };

  for (final entrada in pantallas.entries) {
    testWidgets('la pantalla ${entrada.key} cumple las guias de accesibilidad', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarConTema(tester, entrada.value());
      comprobarGuias(tester);
      semantica.dispose();
    });
  }

  testWidgets('las estrellas y el mensaje vacio cumplen las guias', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarConTema(
      tester,
      Scaffold(
        body: Column(
          children: [
            Estrellas(puntaje: 3, alElegir: (_) {}),
            const Expanded(
              child: MensajeVacio(
                icono: Icons.inbox_outlined,
                titulo: 'Sin publicaciones',
                mensaje: 'Todavía no hay nada para mostrar.',
              ),
            ),
          ],
        ),
      ),
    );
    comprobarGuias(tester);
    semantica.dispose();
  });

  testWidgets('las tarjetas de publicacion cumplen las guias', (tester) async {
    final semantica = tester.ensureSemantics();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    void nada() {}
    await montarConTema(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 720,
                child: TarjetaFeed(
                  id: 1,
                  titulo: 'Lampara',
                  descripcion: 'Una lampara de escritorio',
                  estadoFisico: 'nuevo',
                  categoria: 'libros',
                  estadoPublicacion: 'disponible',
                  nombreAutor: 'Beto',
                  estaReservado: false,
                  loReserveYo: false,
                  esMiPublicacion: false,
                  ofertaEnviada: false,
                  enProgreso: false,
                  alContactar: nada,
                  alReservar: nada,
                  alOfertar: nada,
                  alDescartar: nada,
                  alCompletar: nada,
                ),
              ),
              TarjetaMiPublicacion(
                id: 2,
                titulo: 'Libro',
                descripcion: 'Un libro de calculo',
                estado: 'nuevo',
                categoria: 'libros',
                estadoPublicacion: 'disponible',
                enProgreso: false,
                alCompletar: nada,
                alAbrirWhatsapp: nada,
                alEditar: nada,
                alEliminar: nada,
                alDescartarReserva: nada,
                alCambiarEstado: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    comprobarGuias(tester);
    semantica.dispose();
  });

  testWidgets('el logo y la foto tienen descripcion y la foto vacia se oculta', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarConTema(
      tester,
      const Scaffold(
        body: Column(
          children: [
            LogoTruequeU(),
            FotoPublicacion(url: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg=='),
            FotoPublicacion(),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Logo de Trueque U'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de la publicación'), findsOneWidget);
    semantica.dispose();
  });
}
