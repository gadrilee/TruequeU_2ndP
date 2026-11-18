import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trueque_u/widgets/dialogo_oferta.dart';
import 'package:trueque_u/widgets/resumen_calificaciones.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

class ResultadoDialogo {
  int? valor;
  bool cerrado = false;
}

Future<ResultadoDialogo> abrirDialogo(
  WidgetTester tester,
  Future<int?> Function(BuildContext context) abrir,
) async {
  usarPantallaGrande(tester);
  final resultado = ResultadoDialogo();
  await montarConRuteador(
    tester,
    rutas: [
      GoRoute(
        path: '/',
        builder: (context, estado) => Scaffold(
          body: Builder(
            builder: (contexto) => TextButton(
              onPressed: () async {
                resultado.valor = await abrir(contexto);
                resultado.cerrado = true;
              },
              child: Text('Abrir'),
            ),
          ),
        ),
      ),
      rutaMarcada('/publicacion'),
    ],
  );
  await tocar(tester, find.text('Abrir'));
  return resultado;
}

final opciones = [
  {'id': 4, 'titulo': 'Mouse', 'categoria': 'electronica'},
  {'id': 5, 'titulo': null, 'categoria': 'rara'},
];

void main() {
  setUp(cargarEntornoDePrueba);

  group('ResumenCalificaciones', () {
    Future<void> montarResumen(WidgetTester tester, Map<String, dynamic> respuesta, {int estado = 200}) async {
      final controlador = await controladorConSesion({
        'GET /api/calificaciones/resumen': (_) => respuestaJson(respuesta, estado),
      });
      await montarWidget(tester, Scaffold(body: ResumenCalificaciones(idUsuario: 7)), controlador: controlador);
    }

    testWidgets('con una calificacion usa el singular', (tester) async {
      await montarResumen(tester, {'cantidad': 1, 'promedio': 4});
      await tester.pumpAndSettle();

      expect(find.text('4.0 de 5 · 1 calificación'), findsOneWidget);
    });

    testWidgets('con varias usa el plural', (tester) async {
      await montarResumen(tester, {'cantidad': 3, 'promedio': 4.25});
      await tester.pumpAndSettle();

      expect(find.text('4.3 de 5 · 3 calificaciones'), findsOneWidget);
    });

    testWidgets('sin calificaciones lo avisa', (tester) async {
      await montarResumen(tester, {});
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes calificaciones'), findsOneWidget);
    });

    testWidgets('si el servidor falla deja de cargar y no muestra calificaciones', (tester) async {
      await montarResumen(tester, {'error': 'Falla'}, estado: 500);
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes calificaciones'), findsOneWidget);
    });

    testWidgets('mientras carga reserva el espacio', (tester) async {
      await montarResumen(tester, {'cantidad': 1, 'promedio': 5});

      expect(find.text('Aún no tienes calificaciones'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('mostrarDialogoOferta', () {
    testWidgets('elegir un objeto habilita el envio y devuelve su id', (tester) async {
      final resultado = await abrirDialogo(
        tester,
        (context) => mostrarDialogoOferta(context, tituloDeseado: 'Libro', misDisponibles: opciones),
      );

      expect(find.text('¿Qué objeto tuyo ofreces por «Libro»?'), findsOneWidget);
      expect(find.text('Electrónica'), findsOneWidget);
      expect(find.text('Sin título'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enviar oferta')).onPressed, isNull);

      await tocar(tester, find.text('Mouse'));
      await confirmar(tester, 'Enviar oferta');

      expect(resultado.valor, 4);
    });

    testWidgets('cancelar devuelve nulo', (tester) async {
      final resultado = await abrirDialogo(
        tester,
        (context) => mostrarDialogoOferta(context, tituloDeseado: 'Libro', misDisponibles: opciones),
      );

      await tocar(tester, find.text('Cancelar'));

      expect(resultado.cerrado, isTrue);
      expect(resultado.valor, isNull);
    });

    testWidgets('sin objetos disponibles ofrece crear una publicacion', (tester) async {
      await abrirDialogo(
        tester,
        (context) => mostrarDialogoOferta(context, tituloDeseado: 'Libro', misDisponibles: []),
      );
      expect(find.textContaining('No tienes publicaciones disponibles'), findsOneWidget);

      await tocar(tester, find.text('Crear publicación'));

      expect(find.text('Destino /publicacion'), findsOneWidget);
    });
  });

  group('mostrarDialogoContraoferta', () {
    testWidgets('elegir un objeto devuelve su id', (tester) async {
      final resultado = await abrirDialogo(
        tester,
        (context) => mostrarDialogoContraoferta(context, tituloPedido: 'Libro', opciones: opciones),
      );
      expect(find.text('¿Qué otro objeto propones por «Libro»?'), findsOneWidget);

      await tocar(tester, find.text('Mouse'));
      await confirmar(tester, 'Enviar contraoferta');

      expect(resultado.valor, 4);
    });

    testWidgets('sin objetos solo explica y deja cancelar', (tester) async {
      final resultado = await abrirDialogo(
        tester,
        (context) => mostrarDialogoContraoferta(context, tituloPedido: 'Libro', opciones: []),
      );

      expect(find.text('No hay otro objeto disponible para proponer en esta negociación.'), findsOneWidget);
      expect(find.text('Crear publicación'), findsNothing);
      expect(find.text('Enviar contraoferta'), findsNothing);

      await tocar(tester, find.text('Cancelar'));

      expect(resultado.cerrado, isTrue);
    });
  });
}
