// Prueba E2E en Chrome: publicar un objeto y verlo en Mis publicaciones.
//
// Requisitos: backend en http://localhost:3000 y base de datos con usuarios de prueba.
//
// Cómo correrlo (con backend arriba):
//   ./integration_test/correr_e2e.sh
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trueque_u/main.dart' as app;

import 'ayudantes/acciones.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Usuario de prueba (ver base_de_datos/datos.sql)
  const correo = 'carlosmamani@ejemplo.com';
  const contrasena = 'carlos1234';

  testWidgets(
    'Publicar un objeto y aparece en Mis publicaciones',
    (tester) async {
      await app.main();
      await esperarPantalla(tester);

      // 1) Entrar a la app
      await iniciarSesion(
        tester,
        correo: correo,
        contrasena: contrasena,
      );

      // 2) Abrir el formulario de nueva publicación
      await tocar(tester, 'Crear nueva publicación');
      expect(find.text('Nueva publicación'), findsOneWidget);

      // 3) Completar datos del objeto (título único para no chocar con datos viejos)
      final titulo =
          'Objeto E2E ${DateTime.now().millisecondsSinceEpoch}';
      await escribir(
        tester,
        etiqueta: 'Nombre del objeto',
        valor: titulo,
      );
      await escribir(
        tester,
        etiqueta: 'Descripción (opcional)',
        valor: 'Publicado por la prueba E2E en el navegador',
      );
      await elegirEnDesplegable(
        tester,
        etiquetaActual: 'Nuevo',
        opcion: 'Usado',
      );
      await elegirEnDesplegable(
        tester,
        etiquetaActual: 'Otros',
        opcion: 'Libros',
      );

      // 4) Guardar → vuelve al perfil
      await tocar(tester, 'Guardar');
      expect(find.text('Mi perfil'), findsOneWidget);

      // 5) Abrir Mis publicaciones y comprobar que el objeto está listado
      await tocar(tester, 'Mis publicaciones');
      expect(find.text('Mis publicaciones'), findsWidgets);
      expect(
        find.text(titulo),
        findsOneWidget,
        reason: 'El objeto publicado debe verse en Mis publicaciones',
      );
    },
  );
}
