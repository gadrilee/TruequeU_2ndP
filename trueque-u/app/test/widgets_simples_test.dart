// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';
import 'package:trueque_u/widgets/banner_error.dart';
import 'package:trueque_u/widgets/boton_carga.dart';
import 'package:trueque_u/widgets/campo_texto.dart';
import 'package:trueque_u/widgets/chip_estado.dart';
import 'package:trueque_u/widgets/encabezado_acceso.dart';
import 'package:trueque_u/widgets/error_con_reintento.dart';
import 'package:trueque_u/widgets/estrellas.dart';
import 'package:trueque_u/widgets/etiqueta.dart';
import 'package:trueque_u/widgets/mensaje_vacio.dart';
import 'package:trueque_u/widgets/pagina_acceso.dart';
import 'package:trueque_u/widgets/tarjeta_intercambio.dart';

Future<void> montar(WidgetTester tester, Widget hijo) {
  return tester.pumpWidget(
    MaterialApp(theme: TemaTruequeU.claro(), home: Scaffold(body: hijo)),
  );
}

void main() {
  group('BannerError', () {
    testWidgets('sin mensaje no dibuja nada', (tester) async {
      await montar(tester, const BannerError(null));

      expect(find.byType(Container), findsNothing);
    });

    testWidgets('con mensaje lo muestra', (tester) async {
      await montar(tester, const BannerError('Algo fallo'));

      expect(find.text('Algo fallo'), findsOneWidget);
    });
  });

  group('BotonCarga', () {
    testWidgets('muestra el texto y llama a alPresionar', (tester) async {
      var toques = 0;
      await montar(tester, BotonCarga(texto: 'Entrar', cargando: false, alPresionar: () => toques++));

      await tester.tap(find.text('Entrar'));

      expect(toques, 1);
    });

    testWidgets('mientras carga muestra el indicador y no responde', (tester) async {
      var toques = 0;
      await montar(tester, BotonCarga(texto: 'Entrar', cargando: true, alPresionar: () => toques++));

      await tester.tap(find.byType(FilledButton));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
      expect(toques, 0);
    });

    testWidgets('la version roja usa el color secundario', (tester) async {
      await montar(tester, BotonCarga(texto: 'Borrar', cargando: false, rojo: true, alPresionar: () {}));

      final boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.style?.backgroundColor?.resolve({}), TemaTruequeU.rojo);
    });
  });

  group('CampoTexto', () {
    testWidgets('muestra etiqueta, ayuda e icono', (tester) async {
      await montar(
        tester,
        CampoTexto(
          controlador: TextEditingController(),
          etiqueta: 'Correo',
          ayuda: 'Tu correo de la universidad',
          icono: Icons.mail,
        ),
      );

      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Tu correo de la universidad'), findsOneWidget);
      expect(find.byIcon(Icons.mail), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('el campo de contrasena se puede mostrar y ocultar', (tester) async {
      final controlador = TextEditingController(text: 'secreto');
      await montar(tester, CampoTexto(controlador: controlador, etiqueta: 'Clave', ocultar: true));

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('al enviar llama a alEnviar', (tester) async {
      var enviado = false;
      await montar(
        tester,
        CampoTexto(
          controlador: TextEditingController(),
          etiqueta: 'Buscar',
          accionTeclado: TextInputAction.done,
          alEnviar: () => enviado = true,
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(enviado, true);
    });

    testWidgets('sin alEnviar enviar no hace nada', (tester) async {
      await montar(tester, CampoTexto(controlador: TextEditingController(), etiqueta: 'Buscar'));

      await tester.tap(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(tester.takeException(), isNull);
    });
  });

  group('ChipEstado', () {
    const casos = {
      'disponible': 'Disponible',
      'intercambiado': 'Intercambiado',
      'acordado': 'Intercambio acordado',
      'no disponible': 'No disponible',
      'oculta': 'oculta',
    };

    for (final caso in casos.entries) {
      testWidgets('el estado ${caso.key} muestra ${caso.value}', (tester) async {
        await montar(tester, ChipEstado(estado: caso.key, loReserveYo: false));

        expect(find.text(caso.value), findsOneWidget);
      });
    }

    testWidgets('reservado por otra persona', (tester) async {
      await montar(tester, const ChipEstado(estado: 'reservado', loReserveYo: false));

      expect(find.text('Reservado'), findsOneWidget);
    });

    testWidgets('reservado por mi', (tester) async {
      await montar(tester, const ChipEstado(estado: 'reservado', loReserveYo: true));

      expect(find.text('Reservado por ti'), findsOneWidget);
    });
  });

  group('EncabezadoAcceso', () {
    testWidgets('muestra titulo y subtitulo sin logo ni boton volver', (tester) async {
      await montar(tester, const EncabezadoAcceso(titulo: 'Hola', subtitulo: 'Bienvenido'));

      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
      expect(find.byTooltip('Volver'), findsNothing);
    });

    testWidgets('con logo y boton volver', (tester) async {
      var volvio = false;
      await montar(
        tester,
        EncabezadoAcceso(
          titulo: 'Hola',
          subtitulo: 'Bienvenido',
          conLogo: true,
          alVolver: () => volvio = true,
        ),
      );

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));

      expect(volvio, true);
    });
  });

  group('ErrorConReintento', () {
    testWidgets('muestra el error y reintenta al tocar el boton', (tester) async {
      var intentos = 0;
      await montar(tester, ErrorConReintento(mensaje: 'Sin red', alReintentar: () => intentos++));

      expect(find.text('Sin red'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));

      expect(intentos, 1);
    });
  });

  group('Estrellas', () {
    testWidgets('pinta las estrellas segun el puntaje', (tester) async {
      await montar(tester, const Estrellas(puntaje: 3));

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('sin alElegir los botones estan desactivados', (tester) async {
      await montar(tester, const Estrellas(puntaje: 0));

      final boton = tester.widget<IconButton>(find.byKey(const ValueKey('estrella-1')));
      expect(boton.onPressed, isNull);
    });

    testWidgets('con alElegir devuelve la estrella tocada', (tester) async {
      int? elegida;
      await montar(tester, Estrellas(puntaje: 0, alElegir: (valor) => elegida = valor));

      await tester.tap(find.byKey(const ValueKey('estrella-4')));

      expect(elegida, 4);
    });
  });

  group('Etiqueta', () {
    testWidgets('muestra icono y texto', (tester) async {
      await montar(
        tester,
        Etiqueta(icono: Icons.star, texto: 'Nuevo', fondo: Colors.red, colorTexto: Colors.white),
      );

      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('MensajeVacio', () {
    testWidgets('solo con icono y titulo', (tester) async {
      await montar(tester, const MensajeVacio(icono: Icons.inbox, titulo: 'Nada por aqui'));

      expect(find.text('Nada por aqui'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('con mensaje y boton', (tester) async {
      var toques = 0;
      await montar(
        tester,
        MensajeVacio(
          icono: Icons.inbox,
          titulo: 'Nada por aqui',
          mensaje: 'Publica algo',
          textoBoton: 'Publicar',
          alBoton: () => toques++,
        ),
      );

      expect(find.text('Publica algo'), findsOneWidget);

      await tester.tap(find.text('Publicar'));

      expect(toques, 1);
    });

    testWidgets('un texto de boton sin accion no dibuja el boton', (tester) async {
      await montar(tester, const MensajeVacio(icono: Icons.inbox, titulo: 'Nada', textoBoton: 'Publicar'));

      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('PaginaAcceso', () {
    testWidgets('sin subtitulo usa AppBar con acciones y boton flotante', (tester) async {
      var volvio = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaAcceso(
            titulo: 'Perfil',
            hijos: const [Text('Contenido')],
            alVolver: () => volvio = true,
            acciones: const [Icon(Icons.help)],
            botonFlotante: const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
          ),
        ),
      );

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Contenido'), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));

      expect(volvio, true);
    });

    testWidgets('sin subtitulo ni alVolver no hay flecha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PaginaAcceso(titulo: 'Perfil', hijos: [Text('Contenido')])),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('con subtitulo usa el encabezado y muestra el pie', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaginaAcceso(
            titulo: 'Entrar',
            subtitulo: 'Con tu cuenta',
            conLogo: true,
            hijos: [Text('Formulario')],
            pie: Text('Pie de pagina'),
          ),
        ),
      );

      expect(find.byType(EncabezadoAcceso), findsOneWidget);
      expect(find.text('Formulario'), findsOneWidget);
      expect(find.text('Pie de pagina'), findsOneWidget);
    });

    testWidgets('con subtitulo y sin pie no dibuja el pie', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaginaAcceso(titulo: 'Entrar', subtitulo: 'Con tu cuenta', hijos: [Text('Formulario')]),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('TarjetaIntercambio', () {
    final publicacion = {
      'titulo': 'Libro de calculo',
      'categoria': 'libros',
      'id_usuario': 1,
      'autor': {'nombre': 'Ana'},
      'usuario_reserva': {'nombre': 'Beto'},
    };

    testWidgets('si fui el dueno muestra a quien lo entregue', (tester) async {
      await montar(tester, TarjetaIntercambio(pub: publicacion, idYo: 1));

      expect(find.text('Libro de calculo'), findsOneWidget);
      expect(find.text('Lo entregaste a: Beto'), findsOneWidget);
      expect(find.text('Categoría: Libros'), findsOneWidget);
      expect(find.text('Intercambiado'), findsOneWidget);
    });

    testWidgets('si no fui el dueno muestra de quien lo recibi', (tester) async {
      await montar(tester, TarjetaIntercambio(pub: publicacion, idYo: 2));

      expect(find.text('Lo recibiste de: Ana'), findsOneWidget);
    });

    testWidgets('sin datos usa valores por defecto', (tester) async {
      await montar(tester, const TarjetaIntercambio(pub: {'categoria': 'raro'}, idYo: null));

      expect(find.text('Sin título'), findsOneWidget);
      expect(find.text('Lo entregaste a: otra persona'), findsOneWidget);
      expect(find.text('Categoría: Otros'), findsOneWidget);
    });
  });
}
