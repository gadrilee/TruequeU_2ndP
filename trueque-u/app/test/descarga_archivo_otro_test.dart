import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/servicios/descarga_archivo.dart';

void main() {
  test('fuera de la web descargarArchivo no descarga nada', () {
    expect(descargarArchivo('datos.csv', 'a,b', 'text/csv'), false);
  });
}
