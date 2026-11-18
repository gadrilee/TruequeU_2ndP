import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/widgets/dialogo_entrega.dart';

import 'ayudantes/montar.dart';
import 'ayudantes/publicaciones.dart';

class Resultado {
  Map<String, String>? valor;
  bool cerrado = false;
}

Future<Resultado> abrir(WidgetTester tester, {Map<String, dynamic>? actual}) async {
  usarPantallaGrande(tester);
  final resultado = Resultado();
  await montarWidget(
    tester,
    Scaffold(
      body: Builder(
        builder: (contexto) => TextButton(
          onPressed: () async {
            resultado.valor = await pedirDatosEntrega(
              contexto,
              titulo: 'Proponer',
              textoBoton: 'Enviar',
              actual: actual,
            );
            resultado.cerrado = true;
          },
          child: Text('Abrir'),
        ),
      ),
    ),
  );
  await tocar(tester, find.text('Abrir'));
  return resultado;
}

Future<void> llenar(WidgetTester tester, String fecha, String hora, String lugar) async {
  await tester.enterText(find.byType(TextFormField).at(0), fecha);
  await tester.enterText(find.byType(TextFormField).at(1), hora);
  await tester.enterText(find.byType(TextFormField).at(2), lugar);
}

String fechaFutura() {
  final fecha = DateTime.now().add(Duration(days: 30));
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String isoFuturo() {
  final partes = fechaFutura().split('/');
  return '${partes[2]}-${partes[1]}-${partes[0]}';
}

void main() {
  testWidgets('con datos validos devuelve fecha, hora y lugar en formato del servidor', (tester) async {
    final resultado = await abrir(tester);

    await llenar(tester, fechaFutura(), '9:05', '  Biblioteca  ');
    await confirmar(tester, 'Enviar');

    expect(resultado.valor, {'fecha': isoFuturo(), 'hora': '09:05', 'lugar': 'Biblioteca'});
  });

  testWidgets('con todo vacio muestra los tres errores y no cierra', (tester) async {
    final resultado = await abrir(tester);

    await confirmar(tester, 'Enviar');

    expect(find.text('Escribe una fecha válida, por ejemplo 15/06/2030'), findsOneWidget);
    expect(find.text('Escribe una hora válida, por ejemplo 15:30'), findsOneWidget);
    expect(find.text('Escribe el lugar de la entrega'), findsOneWidget);
    expect(resultado.cerrado, isFalse);
  });

  testWidgets('una fecha pasada se rechaza', (tester) async {
    await abrir(tester);

    await llenar(tester, '01/01/2020', '10:00', 'Cafeteria');
    await confirmar(tester, 'Enviar');

    expect(find.text('La fecha ya pasó, elige otra'), findsOneWidget);
  });

  testWidgets('con datos actuales los muestra ya escritos', (tester) async {
    final resultado = await abrir(
      tester,
      actual: {'fecha': isoFuturo(), 'hora': '15:30', 'lugar': 'Plaza'},
    );

    expect(find.text(fechaFutura()), findsOneWidget);
    expect(find.text('15:30'), findsOneWidget);
    expect(find.text('Plaza'), findsOneWidget);

    await confirmar(tester, 'Enviar');

    expect(resultado.valor, {'fecha': isoFuturo(), 'hora': '15:30', 'lugar': 'Plaza'});
  });

  testWidgets('volver cierra sin devolver nada', (tester) async {
    final resultado = await abrir(tester);

    await tocar(tester, find.text('Volver'));

    expect(resultado.cerrado, isTrue);
    expect(resultado.valor, isNull);
  });
}
