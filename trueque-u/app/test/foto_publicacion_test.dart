import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:trueque_u/widgets/foto_publicacion.dart';

const pngMinimo =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class SelectorFalso extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  SelectorFalso(this.archivo);

  final XFile? archivo;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return archivo;
  }
}

void usarArchivo(Uint8List bytes, String nombre) {
  ImagePickerPlatform.instance = SelectorFalso(XFile.fromData(bytes, name: nombre, path: nombre));
}

Future<void> montar(WidgetTester tester, Widget hijo) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: hijo))));
}

void main() {
  group('elegirFoto', () {
    test('si no se elige nada devuelve null', () async {
      ImagePickerPlatform.instance = SelectorFalso(null);

      expect(await elegirFoto(), isNull);
    });

    test('devuelve la foto png como data URL', () async {
      final bytes = base64Decode(pngMinimo);
      usarArchivo(bytes, 'foto.PNG');

      expect(await elegirFoto(), 'data:image/png;base64,$pngMinimo');
    });

    test('una foto jpg se marca como jpeg', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      usarArchivo(bytes, 'foto.jpg');

      expect(await elegirFoto(), 'data:image/jpeg;base64,${base64Encode(bytes)}');
    });

    test('una foto jpeg tambien se acepta', () async {
      usarArchivo(Uint8List.fromList([1]), 'foto.jpeg');

      expect(await elegirFoto(), startsWith('data:image/jpeg;base64,'));
    });

    test('rechaza fotos de mas de 2 MB', () async {
      usarArchivo(Uint8List(2 * 1024 * 1024 + 1), 'foto.png');

      expect(
        elegirFoto(),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', 'La foto puede pesar hasta 2 MB')),
      );
    });

    test('rechaza extensiones que no son jpg ni png', () async {
      usarArchivo(Uint8List.fromList([1]), 'foto.gif');

      expect(
        elegirFoto(),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', 'La foto tiene que ser jpg o png')),
      );
    });
  });

  group('FotoPublicacion', () {
    testWidgets('sin url muestra el icono de imagen vacia', (tester) async {
      await montar(tester, FotoPublicacion());

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).last).height, 140);
    });

    testWidgets('una url en blanco cuenta como vacia', (tester) async {
      await montar(tester, FotoPublicacion(url: '   ', alto: 80));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('la version cuadrada usa AspectRatio', (tester) async {
      await montar(tester, FotoPublicacion(cuadrada: true));

      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('una data URL se dibuja con Image.memory', (tester) async {
      await montar(tester, FotoPublicacion(url: 'data:image/png;base64,$pngMinimo'));

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<MemoryImage>());
    });

    testWidgets('una url normal se dibuja con Image.network y muestra el error si falla', (tester) async {
      await montar(tester, FotoPublicacion(url: 'http://imagenes.test/no-existe.png'));

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<NetworkImage>());

      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });
  });
}
