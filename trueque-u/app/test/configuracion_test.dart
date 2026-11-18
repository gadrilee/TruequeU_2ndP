import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/configuracion.dart';

void main() {
  group('ConfiguracionEntorno', () {
    test('usa API_URL y agrega /api', () {
      dotenv.testLoad(fileInput: 'API_URL=https://servidor.test');

      expect(ConfiguracionEntorno.urlBase, 'https://servidor.test/api');
      expect(ConfiguracionEntorno.usaServidorLocal, false);
    });

    test('acepta api_url en minusculas', () {
      dotenv.testLoad(fileInput: 'api_url=https://minusculas.test');

      expect(ConfiguracionEntorno.urlBase, 'https://minusculas.test/api');
      expect(ConfiguracionEntorno.usaServidorLocal, false);
    });

    test('quita las barras del final', () {
      dotenv.testLoad(fileInput: 'API_URL=https://servidor.test///');

      expect(ConfiguracionEntorno.urlBase, 'https://servidor.test/api');
    });

    test('sin API_URL usa el servidor local', () {
      dotenv.testLoad(fileInput: '');

      expect(ConfiguracionEntorno.urlBase, 'http://localhost:3000/api');
      expect(ConfiguracionEntorno.usaServidorLocal, true);
    });

    test('con API_URL vacia usa el servidor local', () {
      dotenv.testLoad(fileInput: 'API_URL=');

      expect(ConfiguracionEntorno.urlBase, 'http://localhost:3000/api');
      expect(ConfiguracionEntorno.usaServidorLocal, true);
    });
  });
}
