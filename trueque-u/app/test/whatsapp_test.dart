import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:trueque_u/utilidades/whatsapp.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class LanzadorFalso extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  LanzadorFalso({this.resultado = true, this.lanzaError = false});

  final bool resultado;
  final bool lanzaError;
  final enlaces = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    enlaces.add(url);
    if (lanzaError) throw Exception('sin navegador');
    return resultado;
  }
}

Future<void> montarBoton(WidgetTester tester, String telefono, {String? mensaje}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => abrirWhatsapp(context, telefono, mensaje: mensaje),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const textoError =
      'No se pudo abrir WhatsApp. Revisa que esté instalado o inténtalo desde el navegador.';

  testWidgets('abre el chat con el prefijo de Bolivia', (tester) async {
    final lanzador = LanzadorFalso();
    UrlLauncherPlatform.instance = lanzador;
    await montarBoton(tester, '71234567');

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(lanzador.enlaces, ['https://wa.me/59171234567']);
    expect(find.text(textoError), findsNothing);
  });

  testWidgets('codifica el mensaje en el enlace', (tester) async {
    final lanzador = LanzadorFalso();
    UrlLauncherPlatform.instance = lanzador;
    await montarBoton(tester, '71234567', mensaje: 'Hola, ¿qué tal?');

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(lanzador.enlaces.single, 'https://wa.me/59171234567?text=${Uri.encodeComponent('Hola, ¿qué tal?')}');
  });

  testWidgets('si no se puede abrir muestra un aviso', (tester) async {
    UrlLauncherPlatform.instance = LanzadorFalso(resultado: false);
    await montarBoton(tester, '71234567');

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(find.text(textoError), findsOneWidget);
  });

  testWidgets('si el lanzador falla muestra un aviso', (tester) async {
    UrlLauncherPlatform.instance = LanzadorFalso(lanzaError: true);
    await montarBoton(tester, '71234567');

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(find.text(textoError), findsOneWidget);
  });

  testWidgets('si la pantalla ya no esta montada no muestra el aviso', (tester) async {
    UrlLauncherPlatform.instance = LanzadorFalso(resultado: false);
    late BuildContext contexto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              contexto = context;
              return const Text('Pantalla');
            },
          ),
        ),
      ),
    );

    final pendiente = abrirWhatsapp(contexto, '71234567');
    await tester.pumpWidget(const SizedBox());
    await pendiente;

    expect(find.text(textoError), findsNothing);
  });
}
