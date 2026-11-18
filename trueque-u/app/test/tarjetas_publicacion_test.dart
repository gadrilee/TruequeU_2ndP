import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/widgets/filtros_feed.dart';
import 'package:trueque_u/widgets/tarjeta_feed.dart';
import 'package:trueque_u/widgets/tarjeta_mi_publicacion.dart';

import 'ayudantes/publicaciones.dart';

Future<void> montarTarjeta(WidgetTester tester, Widget tarjeta) async {
  usarAncho(tester, 600);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: tarjeta is TarjetaFeed
            ? SizedBox(height: 720, child: tarjeta)
            : SingleChildScrollView(child: tarjeta),
      ),
    ),
  );
}

TarjetaFeed tarjetaFeed({
  String? descripcion,
  String? imagenUrl,
  String estadoFisico = 'nuevo',
  String categoria = 'libros',
  String estadoPublicacion = 'disponible',
  String? nombreReserva,
  String? telefonoDueno,
  bool estaReservado = false,
  bool loReserveYo = false,
  bool esMiPublicacion = false,
  bool ofertaEnviada = false,
  bool enProgreso = false,
  List<String>? llamadas,
}) {
  void anotar(String nombre) => llamadas?.add(nombre);
  return TarjetaFeed(
    id: 1,
    titulo: 'Lampara',
    descripcion: descripcion,
    imagenUrl: imagenUrl,
    estadoFisico: estadoFisico,
    categoria: categoria,
    estadoPublicacion: estadoPublicacion,
    nombreAutor: 'Beto',
    nombreReserva: nombreReserva,
    telefonoDueno: telefonoDueno,
    estaReservado: estaReservado,
    loReserveYo: loReserveYo,
    esMiPublicacion: esMiPublicacion,
    ofertaEnviada: ofertaEnviada,
    enProgreso: enProgreso,
    alContactar: () => anotar('contactar'),
    alReservar: () => anotar('reservar'),
    alOfertar: () => anotar('ofertar'),
    alDescartar: () => anotar('descartar'),
    alCompletar: () => anotar('completar'),
  );
}

TarjetaMiPublicacion tarjetaPropia({
  String? descripcion,
  String estado = 'nuevo',
  String categoria = 'libros',
  String estadoPublicacion = 'disponible',
  String? nombreReserva,
  String? telefonoReserva,
  bool enProgreso = false,
  List<String>? llamadas,
}) {
  void anotar(String nombre) => llamadas?.add(nombre);
  return TarjetaMiPublicacion(
    id: 1,
    titulo: 'Lampara',
    descripcion: descripcion,
    estado: estado,
    categoria: categoria,
    estadoPublicacion: estadoPublicacion,
    nombreReserva: nombreReserva,
    telefonoReserva: telefonoReserva,
    enProgreso: enProgreso,
    alCompletar: () => anotar('completar'),
    alAbrirWhatsapp: () => anotar('whatsapp'),
    alEditar: () => anotar('editar'),
    alEliminar: () => anotar('eliminar'),
    alDescartarReserva: () => anotar('descartar'),
    alCambiarEstado: anotar,
  );
}

void main() {
  group('TarjetaFeed', () {
    testWidgets('con foto cabe en la celda de tres columnas sin desbordarse', (tester) async {
      usarAncho(tester, 1280);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 342,
                height: 540,
                child: tarjetaFeed(
                  imagenUrl: 'https://ejemplo.com/foto.png',
                  descripcion: 'Una descripcion larga que ocupa dos lineas en la tarjeta del feed',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Reservar'), findsOneWidget);
    });

    testWidgets('una publicacion disponible ofrece ofrecer y reservar', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(tester, tarjetaFeed(llamadas: llamadas));

      await tester.tap(find.text('Ofrecer un objeto'));
      await tester.tap(find.text('Reservar'));

      expect(llamadas, ['ofertar', 'reservar']);
      expect(find.text('Por: Beto'), findsOneWidget);
      expect(find.text('Condición: Nuevo'), findsOneWidget);
      expect(find.text('Categoría: Libros'), findsOneWidget);
      expect(find.text('Sin descripción detallada'), findsOneWidget);
    });

    testWidgets('muestra la descripcion y la condicion usado', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(descripcion: 'Funciona bien', estadoFisico: 'usado'));

      expect(find.text('Funciona bien'), findsOneWidget);
      expect(find.text('Condición: Usado'), findsOneWidget);
    });

    testWidgets('una descripcion en blanco cuenta como vacia', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(descripcion: '   '));

      expect(find.text('Sin descripción detallada'), findsOneWidget);
    });

    testWidgets('una categoria desconocida se muestra como otros', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(categoria: 'juguetes'));

      expect(find.text('Categoría: Otros'), findsOneWidget);
    });

    testWidgets('una foto que no carga muestra el icono de error', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(imagenUrl: 'http://imagenes.test/no-existe.png'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('mientras hay una accion muestra solo el progreso', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(enProgreso: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Reservar'), findsNothing);
    });

    testWidgets('intercambiado deja un boton deshabilitado', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(estadoPublicacion: 'intercambiado'));

      expect(find.text('Intercambio completado'), findsOneWidget);
    });

    testWidgets('acordado deja un boton deshabilitado', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(estadoPublicacion: 'acordado'));

      expect(find.widgetWithText(FilledButton, 'Intercambio acordado'), findsOneWidget);
    });

    testWidgets('si yo reserve con telefono puedo completar, escribir y cancelar', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(
        tester,
        tarjetaFeed(
          estadoPublicacion: 'reservado',
          estaReservado: true,
          loReserveYo: true,
          telefonoDueno: '71234567',
          llamadas: llamadas,
        ),
      );

      await tester.tap(find.text('Completar intercambio'));
      await tester.tap(find.text('WhatsApp'));
      await tester.tap(find.text('Cancelar reserva'));

      expect(llamadas, ['completar', 'contactar', 'descartar']);
      expect(find.text('El contacto se ve cuando los dos aceptan'), findsNothing);
    });

    testWidgets('si yo reserve sin telefono explica cuando se ve el contacto', (tester) async {
      await montarTarjeta(
        tester,
        tarjetaFeed(estadoPublicacion: 'reservado', estaReservado: true, loReserveYo: true),
      );

      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('El contacto se ve cuando los dos aceptan'), findsOneWidget);
    });

    testWidgets('un telefono vacio cuenta como sin telefono', (tester) async {
      await montarTarjeta(
        tester,
        tarjetaFeed(
          estadoPublicacion: 'reservado',
          estaReservado: true,
          loReserveYo: true,
          telefonoDueno: '',
        ),
      );

      expect(find.text('WhatsApp'), findsNothing);
    });

    testWidgets('el dueno de una reservada puede completar', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(
        tester,
        tarjetaFeed(
          estadoPublicacion: 'reservado',
          estaReservado: true,
          esMiPublicacion: true,
          nombreReserva: 'Carla',
          llamadas: llamadas,
        ),
      );

      await tester.tap(find.text('Completar intercambio'));

      expect(llamadas, ['completar']);
      expect(find.text('Publicado por ti'), findsOneWidget);
      expect(find.text('Reservado por: Carla'), findsOneWidget);
    });

    testWidgets('reservada por otra persona queda deshabilitada', (tester) async {
      await montarTarjeta(
        tester,
        tarjetaFeed(estadoPublicacion: 'reservado', estaReservado: true, nombreReserva: 'Carla'),
      );

      expect(find.text('Reservado'), findsWidgets);
      expect(find.text('Reservado por: Carla'), findsOneWidget);
    });

    testWidgets('reservada sin nombre no muestra quien reservo', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(estadoPublicacion: 'reservado', estaReservado: true));

      expect(find.textContaining('Reservado por:'), findsNothing);
    });

    testWidgets('con oferta enviada muestra el estado y el acceso a ofertas', (tester) async {
      await montarTarjeta(tester, tarjetaFeed(ofertaEnviada: true));

      expect(find.text('Oferta enviada'), findsOneWidget);
      expect(find.text('Ver mis ofertas'), findsOneWidget);
    });
  });

  group('TarjetaMiPublicacion', () {
    testWidgets('disponible muestra editar, estado y eliminar', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(tester, tarjetaPropia(descripcion: 'Con pantalla', llamadas: llamadas));

      await tester.tap(find.byTooltip('Editar información'));
      await tester.tap(find.byTooltip('Eliminar definitivamente'));

      expect(llamadas, ['editar', 'eliminar']);
      expect(find.text('Con pantalla'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.text('Libros'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('sin descripcion o en blanco no la muestra', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(descripcion: '  '));

      expect(find.text('  '), findsNothing);
    });

    testWidgets('el menu de estado avisa la opcion elegida', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(tester, tarjetaPropia(llamadas: llamadas));

      for (final opcion in ['Marcar como Disponible', 'Ocultar publicación', 'Marcar como No disponible']) {
        await tester.tap(find.byTooltip('Cambiar estado de la publicación'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(opcion));
        await tester.pumpAndSettle();
      }

      expect(llamadas, ['disponible', 'oculto', 'no disponible']);
    });

    testWidgets('en progreso bloquea los controles', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(estadoPublicacion: 'reservado', enProgreso: true));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Completar intercambio')).onPressed,
        isNull,
      );
    });

    testWidgets('en progreso y disponible deshabilita editar y eliminar', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(enProgreso: true, estado: 'usado', categoria: 'otra'));

      final editar = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      final eliminar = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline));
      expect(editar.onPressed, isNull);
      expect(eliminar.onPressed, isNull);
      expect(find.text('Usado'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
    });

    testWidgets('reservada oculta los controles y deja completar', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(
        tester,
        tarjetaPropia(estadoPublicacion: 'reservado', nombreReserva: 'Carla', llamadas: llamadas),
      );

      await tester.tap(find.text('Completar intercambio'));

      expect(llamadas, ['completar']);
      expect(find.byTooltip('Editar información'), findsNothing);
      expect(find.text('Reservado por: Carla'), findsOneWidget);
      expect(find.text('Está reservada: solo puedes completar el intercambio.'), findsOneWidget);
    });

    testWidgets('reservada sin nombre habla de un usuario', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(estadoPublicacion: 'reservado'));

      expect(find.text('Reservado por un usuario'), findsOneWidget);
    });

    testWidgets('acordada con telefono permite escribir por WhatsApp', (tester) async {
      final llamadas = <String>[];
      await montarTarjeta(
        tester,
        tarjetaPropia(estadoPublicacion: 'acordado', telefonoReserva: '70011223', llamadas: llamadas),
      );

      await tester.tap(find.text('Escribir por WhatsApp'));

      expect(llamadas, ['whatsapp']);
      expect(find.text('Intercambio acordado'), findsOneWidget);
      expect(find.textContaining('Tiene un intercambio acordado'), findsOneWidget);
    });

    testWidgets('acordada sin telefono no ofrece WhatsApp', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(estadoPublicacion: 'acordado', telefonoReserva: ''));

      expect(find.text('Escribir por WhatsApp'), findsNothing);
    });

    testWidgets('acordada sin dato de telefono no ofrece WhatsApp', (tester) async {
      await montarTarjeta(tester, tarjetaPropia(estadoPublicacion: 'acordado'));

      expect(find.text('Escribir por WhatsApp'), findsNothing);
    });

    testWidgets('cada estado de publicacion tiene su texto', (tester) async {
      final esperados = {
        'intercambiado': 'Intercambiado',
        'oculto': 'Oculto',
        'no disponible': 'No disponible',
        'raro': 'raro',
      };
      for (final entrada in esperados.entries) {
        await montarTarjeta(tester, tarjetaPropia(estadoPublicacion: entrada.key));

        expect(find.text(entrada.value), findsOneWidget);
      }
    });
  });

  group('FiltrosFeed', () {
    Future<void> montarFiltros(
      WidgetTester tester, {
      String busqueda = '',
      String? categoria,
      String? condicion,
      String? disponibilidad,
      List<String>? llamadas,
    }) async {
      usarAncho(tester, 900);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FiltrosFeed(
              buscarCtrl: TextEditingController(),
              busqueda: busqueda,
              categoria: categoria,
              condicion: condicion,
              disponibilidad: disponibilidad,
              alBuscar: () => llamadas?.add('buscar'),
              alElegir: (filtro, valor) => llamadas?.add('elegir $filtro $valor'),
              alQuitar: (filtro) => llamadas?.add('quitar $filtro'),
              alQuitarTodos: () => llamadas?.add('quitar todos'),
            ),
          ),
        ),
      );
    }

    testWidgets('sin filtros solo muestra el buscador y los menus', (tester) async {
      await montarFiltros(tester);

      expect(find.text('Buscar objetos'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
      expect(find.text('Quitar todos'), findsNothing);
    });

    testWidgets('cada menu avisa el valor elegido', (tester) async {
      final llamadas = <String>[];
      await montarFiltros(tester, llamadas: llamadas);

      await tester.tap(find.byTooltip('Filtrar por categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electrónica'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filtrar por condición'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filtrar por disponibilidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intercambiado'));
      await tester.pumpAndSettle();

      expect(llamadas, [
        'elegir categoria electronica',
        'elegir condicion nuevo',
        'elegir disponibilidad intercambiado',
      ]);
    });

    testWidgets('el boton y el teclado avisan que se busca', (tester) async {
      final llamadas = <String>[];
      await montarFiltros(tester, llamadas: llamadas);

      await tester.tap(find.byTooltip('Buscar'));
      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.search);

      expect(llamadas, ['buscar', 'buscar']);
    });

    testWidgets('los filtros activos se pueden quitar uno por uno o todos', (tester) async {
      final llamadas = <String>[];
      await montarFiltros(
        tester,
        busqueda: 'lampara',
        categoria: 'ropa',
        condicion: 'usado',
        disponibilidad: 'reservado',
        llamadas: llamadas,
      );

      for (final chip in [
        'Título: lampara',
        'Categoría: Ropa',
        'Condición: Usado',
        'Disponibilidad: Reservado',
      ]) {
        await tester.tap(
          find.descendant(
            of: find.widgetWithText(InputChip, chip),
            matching: find.byTooltip('Delete'),
          ),
        );
      }
      await tester.tap(find.text('Quitar todos'));

      expect(llamadas, [
        'quitar busqueda',
        'quitar categoria',
        'quitar condicion',
        'quitar disponibilidad',
        'quitar todos',
      ]);
    });
  });
}
