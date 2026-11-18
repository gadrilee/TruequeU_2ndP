import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/widgets/dialogo_ayuda.dart';
import 'package:trueque_u/widgets/dialogo_calificacion.dart';
import 'package:trueque_u/widgets/dialogo_confirmacion.dart';
import 'package:trueque_u/widgets/dialogo_motivo.dart';

Future<void> montarBoton(WidgetTester tester, void Function(BuildContext) alTocar) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => alTocar(context),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

Future<void> abrir(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('mostrarAyudaTrueque', () {
    testWidgets('muestra la ayuda y se cierra con Entendido', (tester) async {
      await montarBoton(tester, (contexto) => mostrarAyudaTrueque(contexto));
      await abrir(tester);

      expect(find.text('¿Cómo funciona?'), findsOneWidget);
      expect(find.textContaining('Reservar: toca'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo funciona?'), findsNothing);
    });
  });

  group('confirmarAccion', () {
    Future<void> montarConfirmacion(
      WidgetTester tester,
      List<bool> resultados, {
      bool destructivo = false,
      String textoCancelar = 'Cancelar',
    }) {
      return montarBoton(tester, (contexto) async {
        resultados.add(
          await confirmarAccion(
            contexto,
            titulo: 'Eliminar',
            mensaje: 'Seguro?',
            textoBoton: 'Si, eliminar',
            textoCancelar: textoCancelar,
            destructivo: destructivo,
          ),
        );
      });
    }

    testWidgets('devuelve true al aceptar', (tester) async {
      final resultados = <bool>[];
      await montarConfirmacion(tester, resultados);
      await abrir(tester);

      expect(find.text('Seguro?'), findsOneWidget);

      await tester.tap(find.text('Si, eliminar'));
      await tester.pumpAndSettle();

      expect(resultados, [true]);
    });

    testWidgets('devuelve false al cancelar con el texto personalizado', (tester) async {
      final resultados = <bool>[];
      await montarConfirmacion(tester, resultados, textoCancelar: 'Mejor no');
      await abrir(tester);

      await tester.tap(find.text('Mejor no'));
      await tester.pumpAndSettle();

      expect(resultados, [false]);
    });

    testWidgets('devuelve false si se cierra tocando fuera', (tester) async {
      final resultados = <bool>[];
      await montarConfirmacion(tester, resultados);
      await abrir(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(resultados, [false]);
    });

    testWidgets('la version destructiva usa el color de error', (tester) async {
      await montarConfirmacion(tester, <bool>[], destructivo: true);
      await abrir(tester);

      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Si, eliminar'));
      expect(boton.style?.backgroundColor?.resolve({}), isNotNull);
    });
  });

  group('pedirMotivoCancelacion', () {
    testWidgets('el boton esta desactivado hasta escribir un motivo', (tester) async {
      await montarBoton(tester, (contexto) => pedirMotivoCancelacion(contexto));
      await abrir(tester);

      final boton = find.widgetWithText(FilledButton, 'Sí, cancelar');
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump();

      expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    });

    testWidgets('devuelve el motivo sin espacios', (tester) async {
      String? motivo;
      await montarBoton(tester, (contexto) async => motivo = await pedirMotivoCancelacion(contexto));
      await abrir(tester);

      await tester.enterText(find.byType(TextFormField), '  No puedo ir  ');
      await tester.pump();
      await tester.tap(find.text('Sí, cancelar'));
      await tester.pumpAndSettle();

      expect(motivo, 'No puedo ir');
    });

    testWidgets('Volver cierra sin motivo', (tester) async {
      String? motivo = 'pendiente';
      await montarBoton(tester, (contexto) async => motivo = await pedirMotivoCancelacion(contexto));
      await abrir(tester);

      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(motivo, isNull);
    });
  });

  group('pedirCalificacion', () {
    testWidgets('sin estrellas muestra un error y no cierra', (tester) async {
      await montarBoton(tester, (contexto) => pedirCalificacion(contexto, nombre: 'Ana'));
      await abrir(tester);

      expect(find.text('Calificar a Ana'), findsOneWidget);

      await tester.tap(find.text('Enviar calificación'));
      await tester.pump();

      expect(find.text('Elige de 1 a 5 estrellas'), findsOneWidget);
      expect(find.text('Calificar a Ana'), findsOneWidget);
    });

    testWidgets('elegir estrellas quita el error y devuelve puntaje y comentario', (tester) async {
      Map<String, dynamic>? resultado;
      await montarBoton(
        tester,
        (contexto) async => resultado = await pedirCalificacion(contexto, nombre: 'Ana'),
      );
      await abrir(tester);

      await tester.tap(find.text('Enviar calificación'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('estrella-5')));
      await tester.pump();

      expect(find.text('Elige de 1 a 5 estrellas'), findsNothing);

      await tester.enterText(find.byType(TextFormField), '  Muy amable  ');
      await tester.tap(find.text('Enviar calificación'));
      await tester.pumpAndSettle();

      expect(resultado, {'puntaje': 5, 'comentario': 'Muy amable'});
    });

    testWidgets('Volver cierra sin calificar', (tester) async {
      Map<String, dynamic>? resultado = {'x': 1};
      await montarBoton(
        tester,
        (contexto) async => resultado = await pedirCalificacion(contexto, nombre: 'Ana'),
      );
      await abrir(tester);

      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
    });
  });
}
