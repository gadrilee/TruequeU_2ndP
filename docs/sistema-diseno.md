# Sistema de diseño TruequeU

Los valores de diseño (colores, espacios, radios, tamaños y estilos de texto) viven en un solo archivo, `design/figma-plugin/tokens.json`, y los íconos en `design/figma-plugin/iconos.json`. Un plugin local de Figma lee esos archivos y construye el sistema de diseño en el archivo abierto: variables, estilos de texto, íconos, logo, componentes y pantallas.

## Cómo ejecutarlo

1. Solo si cambian los `Icons.*` que usa la app, descargar los SVG oficiales (necesita red; el plugin no la tiene):

   ```
   node design/figma-plugin/iconos.mjs
   ```

   Lee los `Icons.*` de `trueque-u/app/lib`, descarga cada SVG y escribe `iconos.json` e `iconos-marco.json`. Falla con la lista completa si alguno no existe.
2. Generar el código del plugin:

   ```
   node design/figma-plugin/generar.mjs
   ```

   Esto escribe `design/figma-plugin/code.js` (tokens e íconos van incrustados al inicio) y actualiza las tablas generadas de este documento.
3. En Figma Desktop, abrir el archivo de destino y elegir Plugins, Development, Import plugin from manifest, y seleccionar `design/figma-plugin/manifest.json`.
4. Ejecutar Plugins, Development, TruequeU Sistema de diseño.

El plugin es idempotente: al volver a ejecutarlo actualiza por nombre las colecciones, variables y estilos existentes, y recrea todo el contenido de las cuatro páginas (Fundamentos, Componentes, Pantallas, Diálogos). No debe editarse a mano el contenido de esas páginas, porque se reemplaza.

Para comprobar el código del plugin sin Figma, `node design/figma-plugin/prueba.mjs` lo ejecuta contra una simulación mínima de la API. Verifica variables, estilos de texto, conjuntos de componentes, pantallas, diálogos, que cada clase `Pantalla*` de `lib/pantallas` tenga su marco, que los `Icons.*` de `lib` sean exactamente los íconos de `iconos.json` y las variantes de `Icono`, que ningún texto use glifos de símbolo y que ningún relleno quede sin variable, pero no demuestra cómo se ve en Figma real.

## Regla de nombres

- Dart `Clase.campo` se llama en Figma `Clase/campo`. La barra reemplaza el punto porque Figma no admite puntos en los nombres de variables.
- Las colecciones de variables son `TemaTruequeU`, `ColorScheme`, `Espacios`, `Radios` y `Tipos`. El nombre de cada variable es el nombre del campo Dart; su descripción guarda el identificador Dart (por ejemplo `TemaTruequeU.azul`).
- `ColorScheme` contiene los roles del tema; cada uno es un alias a una variable de `TemaTruequeU`.
- Los estilos de texto se llaman `TextTheme/<rol>` (los 15 roles de Material 3 resueltos del tema), `TextosTruequeU/<campo>` (el estilo efectivo en Flutter, ver la sección de tipografía) y `TextoDerivado/<nombre>` (estilos que Flutter produce al combinar un rol con un cambio de peso o tamaño). El tamaño se enlaza a la variable de `Tipos` cuando existe una con ese valor; los tamaños que solo existen en Material (57, 45, 36, 32, 28, 24, 22) son constantes del framework y quedan como valor.
- El ícono `Icons.foo` es la variante `nombre=foo` del componente `Icono`.
- Cada componente de Figma se llama igual que la clase del widget Flutter, y cada pantalla igual que la clase de la pantalla.
- Las propiedades de variante usan el vocabulario del código (`Estado`, `Variante`, `Tipo`, `Tono`, etc.) y los valores de estado coinciden con los del widget cuando existen (`disponible`, `reservado`, `intercambiado`...).

## Token Dart, variable Figma y valor

Tabla generada desde `tokens.json` por `generar.mjs`; no se edita a mano.

<!-- tokens:inicio -->
| Token Dart | Variable Figma | Valor |
| --- | --- | --- |
| `TemaTruequeU.azul` | `TemaTruequeU/azul` | #2A3964 |
| `TemaTruequeU.azulOscuro` | `TemaTruequeU/azulOscuro` | #1B2645 |
| `TemaTruequeU.azulClaro` | `TemaTruequeU/azulClaro` | #DDE3F2 |
| `TemaTruequeU.rojo` | `TemaTruequeU/rojo` | #CC100C |
| `TemaTruequeU.rojoClaro` | `TemaTruequeU/rojoClaro` | #FBE3E2 |
| `TemaTruequeU.rojoOscuro` | `TemaTruequeU/rojoOscuro` | #8F0B08 |
| `TemaTruequeU.fondo` | `TemaTruequeU/fondo` | #FAF7F2 |
| `TemaTruequeU.borde` | `TemaTruequeU/borde` | #E7E5E4 |
| `TemaTruequeU.verdeClaro` | `TemaTruequeU/verdeClaro` | #DCF2E3 |
| `TemaTruequeU.verdeOscuro` | `TemaTruequeU/verdeOscuro` | #14532D |
| `TemaTruequeU.blanco` | `TemaTruequeU/blanco` | #FFFFFF |
| `TemaTruequeU.texto` | `TemaTruequeU/texto` | #1C1917 |
| `TemaTruequeU.textoSuave` | `TemaTruequeU/textoSuave` | #57534E |
| `TemaTruequeU.contorno` | `TemaTruequeU/contorno` | #78716C |
| `TemaTruequeU.superficieAlta` | `TemaTruequeU/superficieAlta` | #F1ECE5 |
| `ColorScheme.primary` | `ColorScheme/primary` | TemaTruequeU/azul (#2A3964) |
| `ColorScheme.onPrimary` | `ColorScheme/onPrimary` | TemaTruequeU/blanco (#FFFFFF) |
| `ColorScheme.primaryContainer` | `ColorScheme/primaryContainer` | TemaTruequeU/azulClaro (#DDE3F2) |
| `ColorScheme.onPrimaryContainer` | `ColorScheme/onPrimaryContainer` | TemaTruequeU/azulOscuro (#1B2645) |
| `ColorScheme.secondary` | `ColorScheme/secondary` | TemaTruequeU/rojo (#CC100C) |
| `ColorScheme.onSecondary` | `ColorScheme/onSecondary` | TemaTruequeU/blanco (#FFFFFF) |
| `ColorScheme.secondaryContainer` | `ColorScheme/secondaryContainer` | TemaTruequeU/rojoClaro (#FBE3E2) |
| `ColorScheme.onSecondaryContainer` | `ColorScheme/onSecondaryContainer` | TemaTruequeU/rojoOscuro (#8F0B08) |
| `ColorScheme.tertiary` | `ColorScheme/tertiary` | TemaTruequeU/verdeOscuro (#14532D) |
| `ColorScheme.onTertiary` | `ColorScheme/onTertiary` | TemaTruequeU/blanco (#FFFFFF) |
| `ColorScheme.tertiaryContainer` | `ColorScheme/tertiaryContainer` | TemaTruequeU/verdeClaro (#DCF2E3) |
| `ColorScheme.onTertiaryContainer` | `ColorScheme/onTertiaryContainer` | TemaTruequeU/verdeOscuro (#14532D) |
| `ColorScheme.error` | `ColorScheme/error` | TemaTruequeU/rojo (#CC100C) |
| `ColorScheme.onError` | `ColorScheme/onError` | TemaTruequeU/blanco (#FFFFFF) |
| `ColorScheme.errorContainer` | `ColorScheme/errorContainer` | TemaTruequeU/rojoClaro (#FBE3E2) |
| `ColorScheme.onErrorContainer` | `ColorScheme/onErrorContainer` | TemaTruequeU/rojoOscuro (#8F0B08) |
| `ColorScheme.surface` | `ColorScheme/surface` | TemaTruequeU/fondo (#FAF7F2) |
| `ColorScheme.onSurface` | `ColorScheme/onSurface` | TemaTruequeU/texto (#1C1917) |
| `ColorScheme.onSurfaceVariant` | `ColorScheme/onSurfaceVariant` | TemaTruequeU/textoSuave (#57534E) |
| `ColorScheme.outline` | `ColorScheme/outline` | TemaTruequeU/contorno (#78716C) |
| `ColorScheme.outlineVariant` | `ColorScheme/outlineVariant` | TemaTruequeU/borde (#E7E5E4) |
| `ColorScheme.surfaceContainerHighest` | `ColorScheme/surfaceContainerHighest` | TemaTruequeU/superficieAlta (#F1ECE5) |
| `Espacios.e2` | `Espacios/e2` | 2 |
| `Espacios.e4` | `Espacios/e4` | 4 |
| `Espacios.e6` | `Espacios/e6` | 6 |
| `Espacios.e8` | `Espacios/e8` | 8 |
| `Espacios.e10` | `Espacios/e10` | 10 |
| `Espacios.e12` | `Espacios/e12` | 12 |
| `Espacios.e16` | `Espacios/e16` | 16 |
| `Espacios.e20` | `Espacios/e20` | 20 |
| `Espacios.e24` | `Espacios/e24` | 24 |
| `Espacios.e32` | `Espacios/e32` | 32 |
| `Espacios.e40` | `Espacios/e40` | 40 |
| `Radios.r8` | `Radios/r8` | 8 |
| `Radios.r12` | `Radios/r12` | 12 |
| `Radios.r14` | `Radios/r14` | 14 |
| `Radios.r16` | `Radios/r16` | 16 |
| `Radios.r20` | `Radios/r20` | 20 |
| `Radios.r28` | `Radios/r28` | 28 |
| `Radios.r36` | `Radios/r36` | 36 |
| `Tipos.t11` | `Tipos/t11` | 11 |
| `Tipos.t12` | `Tipos/t12` | 12 |
| `Tipos.t13` | `Tipos/t13` | 13 |
| `Tipos.t14` | `Tipos/t14` | 14 |
| `Tipos.t16` | `Tipos/t16` | 16 |
| `Tipos.t17` | `Tipos/t17` | 17 |
| `Tipos.t18` | `Tipos/t18` | 18 |
| `Tipos.t26` | `Tipos/t26` | 26 |
| `TextosTruequeU.titulo` | Estilo de texto `TextosTruequeU/titulo` | 26 px, altura 1.43 (37.18 px), espaciado 0.25, peso 700 |
| `TextosTruequeU.subtitulo` | Estilo de texto `TextosTruequeU/subtitulo` | 18 px, altura 1.43 (25.74 px), espaciado 0.25, peso 700 |
| `TextosTruequeU.tituloTarjeta` | Estilo de texto `TextosTruequeU/tituloTarjeta` | 17 px, altura 1.43 (24.31 px), espaciado 0.25, peso 700 |
| `TextosTruequeU.tituloItem` | Estilo de texto `TextosTruequeU/tituloItem` | 16 px, altura 1.43 (22.88 px), espaciado 0.25, peso 700 |
| `TextosTruequeU.cuerpo` | Estilo de texto `TextosTruequeU/cuerpo` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `TextosTruequeU.detalle` | Estilo de texto `TextosTruequeU/detalle` | 13 px, altura 1.43 (18.59 px), espaciado 0.25, peso 400 |
| `TextosTruequeU.etiqueta` | Estilo de texto `TextosTruequeU/etiqueta` | 12 px, altura 1.43 (17.16 px), espaciado 0.25, peso 500 |
| `TextosTruequeU.ayuda` | Estilo de texto `TextosTruequeU/ayuda` | 12 px, altura 1.43 (17.16 px), espaciado 0.25, peso 400 |
| `TextosTruequeU.chip` | Estilo de texto `TextosTruequeU/chip` | 11 px, altura 1.43 (15.73 px), espaciado 0.25, peso 500 |
| `TextosTruequeU.chipDestacado` | Estilo de texto `TextosTruequeU/chipDestacado` | 11 px, altura 1.43 (15.73 px), espaciado 0.25, peso 700 |
| `TextosTruequeU.pie` | Estilo de texto `TextosTruequeU/pie` | 11 px, altura 1.43 (15.73 px), espaciado 0.25, peso 400 |
| `TextTheme.displayLarge` | Estilo de texto `TextTheme/displayLarge` | 57 px, altura 1.12 (63.84 px), espaciado -0.25, peso 400 |
| `TextTheme.displayMedium` | Estilo de texto `TextTheme/displayMedium` | 45 px, altura 1.16 (52.2 px), espaciado 0, peso 400 |
| `TextTheme.displaySmall` | Estilo de texto `TextTheme/displaySmall` | 36 px, altura 1.22 (43.92 px), espaciado 0, peso 400 |
| `TextTheme.headlineLarge` | Estilo de texto `TextTheme/headlineLarge` | 32 px, altura 1.25 (40 px), espaciado 0, peso 400 |
| `TextTheme.headlineMedium` | Estilo de texto `TextTheme/headlineMedium` | 28 px, altura 1.29 (36.12 px), espaciado 0, peso 400 |
| `TextTheme.headlineSmall` | Estilo de texto `TextTheme/headlineSmall` | 24 px, altura 1.33 (31.92 px), espaciado 0, peso 400 |
| `TextTheme.titleLarge` | Estilo de texto `TextTheme/titleLarge` | 22 px, altura 1.27 (27.94 px), espaciado 0, peso 400 |
| `TextTheme.titleMedium` | Estilo de texto `TextTheme/titleMedium` | 16 px, altura 1.5 (24 px), espaciado 0.15, peso 500 |
| `TextTheme.titleSmall` | Estilo de texto `TextTheme/titleSmall` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `TextTheme.bodyLarge` | Estilo de texto `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `TextTheme.bodyMedium` | Estilo de texto `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `TextTheme.bodySmall` | Estilo de texto `TextTheme/bodySmall` | 12 px, altura 1.33 (15.96 px), espaciado 0.4, peso 400 |
| `TextTheme.labelLarge` | Estilo de texto `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `TextTheme.labelMedium` | Estilo de texto `TextTheme/labelMedium` | 12 px, altura 1.33 (15.96 px), espaciado 0.5, peso 500 |
| `TextTheme.labelSmall` | Estilo de texto `TextTheme/labelSmall` | 11 px, altura 1.45 (15.95 px), espaciado 0.5, peso 500 |
<!-- tokens:fin -->

## Tipografía: contexto Flutter a estilo Figma

La app no define familia: Material 3 usa Roboto. Las alturas y el espaciado de letras no están en `tema.dart`; los pone Flutter.

- `ThemeData.textTheme` sin localizar tiene los tamaños en `null`; los valores reales salen de `Theme.of(context).textTheme` dentro de un `MaterialApp`. Por eso el test los lee de ahí.
- El cuerpo de cualquier `Scaffold`, `Card` o diálogo hereda `DefaultTextStyle` igual a `bodyMedium` (14 px, altura 1.43, espaciado 0.25). Un `Text(style: TextosTruequeU.x)` se mezcla encima, así que el estilo efectivo de `TextosTruequeU.x` es su tamaño y peso con la altura 1.43 y el espaciado 0.25 de `bodyMedium`.
- Los widgets de Material no usan el estilo del cuerpo: cada uno aplica el suyo (botones `labelLarge`, campos `bodyLarge`, `AppBar` `titleLarge`, diálogos `headlineSmall`...).
- La altura de línea en Figma es `tamaño x altura` en píxeles con dos decimales (Flutter multiplica sin redondear a entero). `TextoDerivado/botonTextoNegrita` no tiene altura (`AUTO`) ni espaciado: `TextButton.styleFrom(textStyle: ...)` reemplaza por completo el estilo del botón.
- El peso 600 de Flutter (`FontWeight.w600`) usa `Roboto SemiBold` en Figma; si la fuente no lo tiene, el plugin cae a `Bold` y lo informa el test.
- La etiqueta flotante de un campo es la etiqueta de 16 px reducida a 0.75 (`_kFinalLabelScale` de Flutter): 12 px, altura 1, espaciado 0.375.

Estilos derivados (tabla generada desde `tokens.json`):

<!-- derivados:inicio -->
| Estilo Figma | Valor |
| --- | --- |
| `TextoDerivado/campoEtiqueta` | 16 px, altura 1 (16 px), espaciado 0.5, peso 400 |
| `TextoDerivado/campoEtiquetaFlotante` | 12 px, altura 1 (12 px), espaciado 0.375, peso 400 |
| `TextoDerivado/headlineMediumNegrita` | 28 px, altura 1.29 (36.12 px), espaciado 0, peso 700 |
| `TextoDerivado/headlineSmallNegrita` | 24 px, altura 1.33 (31.92 px), espaciado 0, peso 700 |
| `TextoDerivado/titleLargeNegrita` | 22 px, altura 1.27 (27.94 px), espaciado 0, peso 700 |
| `TextoDerivado/titleMediumNegrita` | 16 px, altura 1.5 (24 px), espaciado 0.15, peso 700 |
| `TextoDerivado/bodyMediumNegrita` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 700 |
| `TextoDerivado/bodyMediumSemibold` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 600 |
| `TextoDerivado/chipSemibold` | 11 px, altura 1.43 (15.73 px), espaciado 0.25, peso 600 |
| `TextoDerivado/autorPropio` | 12 px, altura 1.43 (17.16 px), espaciado 0.25, peso 700 |
| `TextoDerivado/botonTextoNegrita` | 14 px, altura auto, espaciado 0, peso 700 |
| `TextoDerivado/avatarGrande` | 26 px, altura 1.5 (39 px), espaciado 0.15, peso 700 |
| `TextoDerivado/avatarChico` | 12 px, altura 1.5 (18 px), espaciado 0.15, peso 500 |
<!-- derivados:fin -->

Contexto Flutter a estilo Figma (tabla generada; cada fila la verifica `tipografia_figma_test.dart` montando el widget real de Material o de la app):

<!-- contextos:inicio -->
| Contexto Flutter | Estilo Figma | Valor |
| --- | --- | --- |
| `Scaffold.texto` | `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `FilledButton` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `FilledButton.tonal` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `OutlinedButton` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `TextButton` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `TextButton.negrita` | `TextoDerivado/botonTextoNegrita` | 14 px, altura auto, espaciado 0, peso 700 |
| `FloatingActionButton.extended` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `AppBar.titulo` | `TextTheme/titleLarge` | 22 px, altura 1.27 (27.94 px), espaciado 0, peso 400 |
| `TextField.entrada` | `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `TextField.hint` | `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `TextField.etiqueta` | `TextoDerivado/campoEtiqueta` | 16 px, altura 1 (16 px), espaciado 0.5, peso 400 |
| `TextField.etiquetaFlotante` | `TextoDerivado/campoEtiquetaFlotante` | 12 px, altura 1 (12 px), espaciado 0.375, peso 400 |
| `TextField.ayuda` | `TextTheme/bodySmall` | 12 px, altura 1.33 (15.96 px), espaciado 0.4, peso 400 |
| `TextField.error` | `TextTheme/bodySmall` | 12 px, altura 1.33 (15.96 px), espaciado 0.4, peso 400 |
| `TextField.contador` | `TextTheme/bodySmall` | 12 px, altura 1.33 (15.96 px), espaciado 0.4, peso 400 |
| `DropdownButtonFormField.valor` | `TextTheme/titleMedium` | 16 px, altura 1.5 (24 px), espaciado 0.15, peso 500 |
| `ListTile.titulo` | `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `ListTile.subtitulo` | `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `RadioListTile.titulo` | `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `RadioListTile.subtitulo` | `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `AlertDialog.titulo` | `TextTheme/headlineSmall` | 24 px, altura 1.33 (31.92 px), espaciado 0, peso 400 |
| `AlertDialog.contenido` | `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `NavigationBar.etiqueta` | `TextTheme/labelMedium` | 12 px, altura 1.33 (15.96 px), espaciado 0.5, peso 500 |
| `SnackBar` | `TextTheme/bodyMedium` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 400 |
| `Chip` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `InputChip` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `SegmentedButton` | `TextTheme/labelLarge` | 14 px, altura 1.43 (20.02 px), espaciado 0.1, peso 500 |
| `CircleAvatar.grande` | `TextoDerivado/avatarGrande` | 26 px, altura 1.5 (39 px), espaciado 0.15, peso 700 |
| `CircleAvatar.chico` | `TextoDerivado/avatarChico` | 12 px, altura 1.5 (18 px), espaciado 0.15, peso 500 |
| `EncabezadoAcceso.titulo` | `TextoDerivado/headlineMediumNegrita` | 28 px, altura 1.29 (36.12 px), espaciado 0, peso 700 |
| `EncabezadoAcceso.subtitulo` | `TextTheme/bodyLarge` | 16 px, altura 1.5 (24 px), espaciado 0.5, peso 400 |
| `Text.negrita` | `TextoDerivado/bodyMediumNegrita` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 700 |
| `Text.semibold` | `TextoDerivado/bodyMediumSemibold` | 14 px, altura 1.43 (20.02 px), espaciado 0.25, peso 600 |
| `Text.chipSemibold` | `TextoDerivado/chipSemibold` | 11 px, altura 1.43 (15.73 px), espaciado 0.25, peso 600 |
| `Text.autorPropio` | `TextoDerivado/autorPropio` | 12 px, altura 1.43 (17.16 px), espaciado 0.25, peso 700 |
| `Text.headlineSmallNegrita` | `TextoDerivado/headlineSmallNegrita` | 24 px, altura 1.33 (31.92 px), espaciado 0, peso 700 |
| `Text.titleLargeNegrita` | `TextoDerivado/titleLargeNegrita` | 22 px, altura 1.27 (27.94 px), espaciado 0, peso 700 |
| `Text.titleMediumNegrita` | `TextoDerivado/titleMediumNegrita` | 16 px, altura 1.5 (24 px), espaciado 0.15, peso 700 |
<!-- contextos:fin -->

Cómo se aplicó en los componentes: texto de botón (`BotonCarga`, `FloatingActionButton`, `SegmentedButton`, chips) usa `TextTheme/labelLarge`; texto de `CampoTexto` usa `TextTheme/bodyLarge` (valor), `TextoDerivado/campoEtiqueta` (etiqueta sin valor) y `TextTheme/bodySmall` (ayuda y error); `AppBar` usa `TextTheme/titleLarge`; los diálogos usan `TextTheme/headlineSmall` para el título; las etiquetas de `EstructuraPrincipal` usan `TextTheme/labelMedium`; las filas de lista usan `TextTheme/bodyLarge` y `TextTheme/bodyMedium`; el texto suelto de las pantallas usa `TextTheme/bodyMedium` o el derivado correspondiente (`TextoPantalla`: subtitulo es `headlineSmallNegrita`, negrita es `bodyMediumNegrita`, ayuda es `bodySmall`, enlace es `labelLarge`); y los widgets de la app con `TextosTruequeU.x` (tarjetas, chips, etiquetas) usan `TextosTruequeU/x`.

## Íconos

Todos los íconos son los de Material Icons, no glifos de texto. Fuente: paquete npm `@material-design-icons/svg` versión 0.14.15 (Google, licencia Apache 2.0), descargado de jsDelivr por `iconos.mjs`. La regla de nombres es: `foo_outlined` es el estilo Outlined de `foo`; un nombre sin sufijo es el estilo Filled (el de la fuente `MaterialIcons` de Flutter). Cuatro nombres antiguos de Flutter (`info_outline`, `lock_outline`, `label_outline`, `bookmark_outline`) no existen en el paquete y se toman del Outlined del mismo ícono.

Se comparó el recuadro de cada SVG con el glifo de la fuente `MaterialIcons-Regular.otf` que trae Flutter 3.47.1: 51 de 52 coinciden dentro de 0.1 unidades; `handshake_outlined` difiere 0.39 unidades de 24 porque la fuente de Flutter tiene un rediseño más nuevo que el paquete.

El componente `Icono` tiene una variante por ícono (`nombre=<identificador Flutter>`), de 24 x 24, con un solo vector aplanado de `figma.createNodeFromSvg` cuyo relleno es `ColorScheme/onSurfaceVariant` por defecto. Cada instancia se escala al tamaño que usa el código Flutter (14, 16, 18, 20, 24, 28, 36 o 64) y cambia el relleno a la variable que usa Flutter. Los íconos que Material dibuja por dentro de un widget (`Icons.arrow_drop_down` del selector, `Icons.check` del `SegmentedButton`) no aparecen en `lib`; viven en `IconoMarco` y en `iconos-marco.json`.

Íconos que usa la app (tabla generada desde `iconos.json`):

<!-- iconos:inicio -->
| Identificador Flutter | Material Icons |
| --- | --- |
| `Icons.add` | Filled `add` |
| `Icons.arrow_back` | Filled `arrow_back` |
| `Icons.arrow_forward` | Filled `arrow_forward` |
| `Icons.block_outlined` | Outlined `block` |
| `Icons.bookmark_add_outlined` | Outlined `bookmark_add` |
| `Icons.bookmark_outline` | Outlined `bookmark` (nombre antiguo de Flutter, mismo dibujo) |
| `Icons.broken_image_outlined` | Outlined `broken_image` |
| `Icons.cancel_outlined` | Outlined `cancel` |
| `Icons.category_outlined` | Outlined `category` |
| `Icons.chat_outlined` | Outlined `chat` |
| `Icons.check_circle_outline` | Filled `check_circle_outline` |
| `Icons.chevron_right` | Filled `chevron_right` |
| `Icons.close` | Filled `close` |
| `Icons.delete_outline` | Filled `delete_outline` |
| `Icons.download` | Filled `download` |
| `Icons.edit_outlined` | Outlined `edit` |
| `Icons.explore` | Filled `explore` |
| `Icons.explore_outlined` | Outlined `explore` |
| `Icons.feed_outlined` | Outlined `feed` |
| `Icons.folder_shared_outlined` | Outlined `folder_shared` |
| `Icons.handshake_outlined` | Outlined `handshake` |
| `Icons.help_outline` | Filled `help_outline` |
| `Icons.history` | Filled `history` |
| `Icons.image_outlined` | Outlined `image` |
| `Icons.inbox_outlined` | Outlined `inbox` |
| `Icons.info_outline` | Outlined `info` (nombre antiguo de Flutter, mismo dibujo) |
| `Icons.inventory_2` | Filled `inventory_2` |
| `Icons.inventory_2_outlined` | Outlined `inventory_2` |
| `Icons.key_outlined` | Outlined `key` |
| `Icons.label_outline` | Outlined `label` (nombre antiguo de Flutter, mismo dibujo) |
| `Icons.lock_outline` | Outlined `lock` (nombre antiguo de Flutter, mismo dibujo) |
| `Icons.logout` | Filled `logout` |
| `Icons.mail_outline` | Filled `mail_outline` |
| `Icons.more_vert` | Filled `more_vert` |
| `Icons.notifications_active` | Filled `notifications_active` |
| `Icons.notifications_none` | Filled `notifications_none` |
| `Icons.outbox_outlined` | Outlined `outbox` |
| `Icons.person` | Filled `person` |
| `Icons.person_outline` | Filled `person_outline` |
| `Icons.person_pin_outlined` | Outlined `person_pin` |
| `Icons.phone_outlined` | Outlined `phone` |
| `Icons.refresh` | Filled `refresh` |
| `Icons.search` | Filled `search` |
| `Icons.search_off` | Filled `search_off` |
| `Icons.star` | Filled `star` |
| `Icons.star_border` | Filled `star_border` |
| `Icons.swap_horiz` | Filled `swap_horiz` |
| `Icons.tune` | Filled `tune` |
| `Icons.undo` | Filled `undo` |
| `Icons.visibility_off_outlined` | Outlined `visibility_off` |
| `Icons.visibility_outlined` | Outlined `visibility` |
| `Icons.vpn_key` | Filled `vpn_key` |
<!-- iconos:fin -->

Íconos internos de Material:

<!-- iconos-marco:inicio -->
| Ícono interno de Material | Material Icons |
| --- | --- |
| `Icons.arrow_drop_down` | Filled `arrow_drop_down` |
| `Icons.check` | Filled `check` |
<!-- iconos-marco:fin -->

Color y tamaño por contexto, tomados del código de Flutter y de los valores por defecto de Material 3:

| Contexto | Color | Tamaño |
| --- | --- | --- |
| `NavigationBar` seleccionado / no seleccionado | `onSecondaryContainer` / `onSurfaceVariant` | 24 |
| `IconButton` (`help_outline`, `refresh`, `arrow_forward`, `more_vert`) | `onSurfaceVariant` | 24 (20 en `TarjetaMiPublicacion`) |
| Ícono de `AppBar` (volver, actualizar) | `TemaTruequeU/azulOscuro` (`foregroundColor`) | 24 |
| `prefixIcon` y `suffixIcon` de `CampoTexto` | `onSurfaceVariant` (`error` en el sufijo con error; `onSurface` con opacidad 0.38 si está deshabilitado) | 24 |
| Ícono dentro de botón (`FilledButton.icon`, `OutlinedButton.icon`) | color del texto del botón | 18 (16 donde el código lo indica) |
| Avatar de `Chip` (`tune`, `check_circle_outline`) | `primary` | 16 |
| Borrar de `InputChip` (`close`) | `onSurfaceVariant` | 18 |
| `Estrellas`, `ResumenCalificaciones` | `secondary` | 24 |
| Logo (`swap_horiz`) | `TemaTruequeU/rojo` | 36 |
| `Etiqueta` | color del texto de la etiqueta | 14 |
| `MensajeVacio` | `outline` | 64 |

Diferencias con Flutter que no se pueden enlazar a un token: el ícono sin color explícito (`history`, `chevron_right` fuera de un `ListTile`, `broken_image_outlined`, el ícono de `TarjetaHistorial`) usa `IconTheme` negro al 87 % (`Color(0xDD000000)`) y la flecha del selector usa `Colors.grey.shade700`; ninguno es token, así que en Figma se enlazan a `ColorScheme/onSurface` y `ColorScheme/onSurfaceVariant`, que son los más cercanos.

## Componente Figma, archivo Flutter y variantes

Los archivos están en `trueque-u/app/lib/widgets/` salvo los marcados como Material, patrón inline o clase privada de una pantalla (no existen como widget propio). Todos usan auto layout; padding y separación están enlazados a `Espacios`, radios a `Radios`, y rellenos y bordes a variables de `ColorScheme` (o `TemaTruequeU/blanco` y `TemaTruequeU/rojo` donde el código usa esos colores directamente).

| Componente Figma | Archivo Flutter | Variantes y estados |
| --- | --- | --- |
| `Icono` | `Icons.*` de Material (ver la sección de íconos) | nombre: los 52 identificadores de `Icons.*` que usa `lib` |
| `IconoMarco` | íconos que Material dibuja por dentro de un widget | nombre: `arrow_drop_down`, `check` |
| `LogoTruequeU` | `logo_trueque_u.dart` | Variante: icono, conNombre |
| `BotonCarga` | `boton_carga.dart` | Estado: default, hover, presionado, cargando, deshabilitado. Variante: primario, rojo, tonal, contorno, contornoRojo (contorno con color de error), texto (TextButton). Icono: no, si (ícono de 18 px antes del texto, como `FilledButton.icon`) |
| `CampoTexto` | `campo_texto.dart` | Estado: vacio, enfocado, relleno, error, deshabilitado. Tipo: texto, contrasena, multilinea. Icono: no, si |
| `BannerError` | `banner_error.dart` | Estado: default |
| `ChipEstado` | `chip_estado.dart` | Estado: disponible, reservado, reservadoPorTi, intercambiado, acordado, noDisponible |
| `Etiqueta` | `etiqueta.dart` | Tono: primario, secundario, terciario |
| `Estrellas` | `estrellas.dart` | Puntaje: 0 a 5. Modo: lectura, interactivo |
| `FotoPublicacion` | `foto_publicacion.dart` | Estado: vacia, imagen, error. Forma: ancha, cuadrada |
| `MensajeVacio` | `mensaje_vacio.dart` | ConBoton: si, no |
| `ErrorConReintento` | `error_con_reintento.dart` | Estado: default |
| `FiltrosFeed` | `filtros_feed.dart` | Estado: sinFiltros, conFiltros |
| `TarjetaFeed` | `tarjeta_feed.dart` | Estado: disponible, reservadoPorMi, reservadoPorOtro, propia, ofertaEnviada, intercambiado |
| `TarjetaMiPublicacion` | `tarjeta_mi_publicacion.dart` | Reservada: si, no |
| `EncabezadoAcceso` | `encabezado_acceso.dart` | ConLogo: si, no |
| `EstructuraPrincipal` | `estructura_principal.dart` | Activo: explorar, misPublicaciones, ofertas, perfil |
| `ResumenCalificaciones` | `resumen_calificaciones.dart` | Estado: cargando, vacio, conDatos |
| `BloqueCalificacion` | `bloque_calificacion.dart` | Estado: sinCalificar, calificado |
| `BloqueEntrega` | `bloque_entrega.dart` | Estado: sinAcuerdo, acuerdoVigente, propuestaPendiente, reprogramando |
| `TarjetaIntercambio` | `tarjeta_intercambio.dart` | Rol: entregue, recibi |
| `SegmentedButton` | Material, usado en `pantalla_ofertas.dart` | Seleccionado: recibidas, enviadas |
| `ChipEstadoOferta` | `_ChipEstado` en `pantalla_ofertas.dart` | Estado: pendiente, contraofertada, aceptada, completada, anulada, rechazada, cancelada |
| `TarjetaOferta` | `_TarjetaOferta` en `pantalla_ofertas.dart` | Estado: los 7 de `ChipEstadoOferta`. Lado: recibida, enviada |
| `FilaLista` | patrón inline: `ListTile` en `pantalla_perfil.dart` | Icono: con, sin. Subtitulo: con, sin. Final: ninguno, chevron. Tono: normal, error |
| `TarjetaAviso` | patrón inline: `Card` + `ListTile` en `pantalla_avisos.dart` | Estado: noLeida, leida |
| `TarjetaHistorial` | patrón inline: `Card` en `pantalla_historial.dart` | Tipo: reservo, canceloReserva, completo |
| `FiltrosHistorial` | patrón inline: `ChoiceChip` en `pantalla_historial.dart` | Seleccionado: todo, reservas, completados |
| `TarjetaDatos` | patrón inline: `_tarjeta` en `pantalla_mis_datos.dart` | Variante: normal, conAccion |
| `CabeceraFeed` | patrón inline: saludo y botones de `pantalla_feed_publicaciones.dart` | Estado: default |
| `PieEnlace` | patrón inline: `pie` de `pantalla_iniciar_sesion.dart` y `pantalla_registro.dart` | Variante: crearCuenta, iniciarSesion |
| `IconoCaja` | patrón inline: cuadro de ícono de `pantalla_recuperar_contrasena.dart` | Icono: llave |
| `BannerExito` | patrón inline: aviso verde de `pantalla_recuperar_contrasena.dart` | Estado: default |
| `TextoPantalla` | patrón inline: `Text` suelto de las pantallas | Estilo: titulo, subtitulo, cuerpo, negrita, suave, ayuda, error, enlace. Alineacion: izquierda, centro, derecha |
| `AppBar` | Material, configurado en `pagina_acceso.dart` | Volver: no, si. Accion: ninguna, refrescar |
| `FloatingActionButton` | Material, rojo del tema (`FloatingActionButton.extended`) | Variante: extendido |
| `SnackBar` | Material, fondo `onSurface` | Estado: default |
| `DropdownButtonFormField` | Material, usado en `Publicacion.dart` | Estado: default, enfocado |
| `CircleAvatar` | Material, usado en `pantalla_perfil.dart` y `dialogo_ayuda.dart` | Tamano: grande, chico |
| `Divider` | Material, usado en `pantalla_perfil.dart` | Estado: default |
| `CircularProgressIndicator` | Material | Tamano: grande, pequeno |
| `confirmarAccion` | `dialogo_confirmacion.dart` | Variante: normal, destructivo |
| `mostrarAyudaTrueque` | `dialogo_ayuda.dart` | Estado: default |
| `pedirCalificacion` | `dialogo_calificacion.dart` | Estado: sinPuntaje, conPuntaje, error |
| `pedirMotivoCancelacion` | `dialogo_motivo.dart` | Estado: vacio, conMotivo |
| `pedirDatosEntrega` | `dialogo_entrega.dart` | Variante: proponer, reprogramar, contraproponer, conErrores |
| `mostrarDialogoOferta` | `dialogo_oferta.dart` (incluye `mostrarDialogoContraoferta`) | Tipo: ofrecer, contraofertar. Estado: conOpciones, vacio |
| `DialogoEditarPublicacion` | `dialogo_editar_publicacion.dart` | Estado: normal, guardando, error |
| `DialogoEliminarCuenta` | `dialogo_eliminar_cuenta.dart` | Estado: normal, error |
| `DialogoHistorial` | patrón inline: `AlertDialog` de `pantalla_ofertas.dart`, `bloque_entrega.dart` y `pantalla_historial.dart` | Tipo: negociacion, entrega, movimiento |

Los componentes con texto editable exponen una propiedad de texto (`texto`, `mensaje`, `titulo`, `subtitulo`, etc.). Las tarjetas, los bloques, los diálogos, `MensajeVacio` y `ErrorConReintento` están armados con instancias de los componentes anteriores. Las variantes cuyo texto cambia según el estado (por ejemplo `PieEnlace` o `TarjetaHistorial`) no tienen propiedad de texto: el texto se cambia en la instancia.

Limitaciones conocidas:

- Las dos tablas de colores por contexto de íconos y las diferencias con tokens están en la sección de íconos; los botones de las tarjetas y las pantallas llevan ícono donde el código Flutter lo lleva (`FilledButton.icon`, `OutlinedButton.icon`, `TextButton.icon`).
- `EncabezadoAcceso` intenta un degradado de `azulOscuro` a `azul` con las paradas enlazadas a variables. Si la API de Figma no conserva ese enlace, el plugin usa un relleno sólido `ColorScheme/onPrimaryContainer` para no dejar colores fijos.
- Estados como hover y presionado no existen en Flutter como widgets; se modelan con opacidad sobre el color del token.
- La estructura de `CampoTexto` muestra la etiqueta o el valor, no la etiqueta flotante encima del valor que dibuja Flutter; los estilos de cada texto sí son los de Flutter. El campo `DropdownButtonFormField` sí muestra la etiqueta flotante.
- Los estados `BannerError` y `ErrorConReintento` tienen una sola variante porque no tienen estados propios en el código.

## Pantalla Figma y archivo Flutter

Los archivos están en `trueque-u/app/lib/pantallas/`. Cada pantalla es un marco de 390 x 844 con auto layout vertical, armado solo con instancias de los componentes y marcos de disposición enlazados a variables (ningún texto ni figura suelta). Los textos, el orden de las secciones, las barras de aplicación, el botón flotante y la barra de navegación reflejan lo que dibuja el código Flutter.

Están en la página `📱 Pantallas`, ordenadas por flujo: acceso, pestañas de la barra de navegación y pantallas secundarias. El nombre de cada marco es exactamente el nombre de la clase Flutter.

| Pantalla Figma | Archivo Flutter | Ruta | Contenido |
| --- | --- | --- | --- |
| `PantallaInicio` | `pantalla_inicio.dart` | `/` | Encabezado con logo, botones Iniciar sesión y Crear cuenta |
| `PantallaIniciarSesion` | `pantalla_iniciar_sesion.dart` | `/iniciar-sesion` | Encabezado con logo, campos Correo y Contraseña, enlace de contraseña olvidada, pie Crear cuenta |
| `PantallaRegistro` | `pantalla_registro.dart` | `/registro` | Cinco campos (con ayuda del teléfono), botón rojo, pie Inicia sesión |
| `PantallaRecuperarContrasena` | `pantalla_recuperar_contrasena.dart` | `/recuperar-contrasena` | Ícono de llave, texto, campo Correo, botón, pie para volver |
| `PantallaFeedPublicaciones` | `pantalla_feed_publicaciones.dart` | `/feed` | Cabecera con saludo, filtros, tarjetas, botón flotante Publicar, navegación (Explorar) |
| `PantallaMisPublicaciones` | `pantalla_mis_publicaciones.dart` | `/mis-publicaciones` | AppBar con actualizar, total, tarjetas, botón flotante, navegación |
| `PantallaOfertas` | `pantalla_ofertas.dart` | `/ofertas` | AppBar, `SegmentedButton`, tarjetas de oferta, navegación |
| `PantallaPerfil` | `pantalla_perfil.dart` | `/perfil` | Avatar, nombre, correo, calificaciones, lista de opciones, Cerrar sesión, navegación |
| `PantallaPublicacion` | `Publicacion.dart` | `/publicacion` | AppBar con volver, campos, dos selectores, foto, Guardar y Cancelar |
| `PantallaIntercambios` | `pantalla_intercambios.dart` | `/intercambios` | AppBar con volver y actualizar, tarjetas de intercambio |
| `PantallaHistorial` | `pantalla_historial.dart` | `/historial` | AppBar, filtros Todo, Reservas y Completados, tarjetas de movimiento |
| `PantallaAvisos` | `pantalla_avisos.dart` | `/avisos` | AppBar con volver, avisos leídos y no leídos |
| `PantallaMisDatos` | `pantalla_mis_datos.dart` | `/mis-datos` | Botones de descarga y siete tarjetas de datos |
| `PantallaCambiarContrasena` | `pantalla_cambiar_contrasena.dart` | `/cambiar-contrasena` | AppBar, tres campos, Guardar y Cancelar |

Marcos de estado, con el nombre `<Clase> · <estado>`, en la misma página:

| Marco | Qué muestra |
| --- | --- |
| `PantallaIniciarSesion · error` | Banner de error de credenciales |
| `PantallaRecuperarContrasena · enviado` | Aviso verde de envío |
| `PantallaFeedPublicaciones · vacío` | No hay publicaciones disponibles |
| `PantallaFeedPublicaciones · sin resultados` | Filtros activos sin coincidencias |
| `PantallaFeedPublicaciones · error` | Error con reintento |
| `PantallaFeedPublicaciones · cargando` | Indicador de carga |
| `PantallaMisPublicaciones · vacío` | Aún no tienes publicaciones |
| `PantallaMisPublicaciones · publicación guardada` | `SnackBar` de confirmación |
| `PantallaOfertas · enviadas` | Segmento Enviadas con oferta pendiente y rechazada |
| `PantallaOfertas · entrega y calificación` | Oferta aceptada (entrega) y completada (calificación) |
| `PantallaOfertas · vacío` | Nadie te ha ofrecido un trueque |
| `PantallaPublicacion · con foto` | Foto elegida, Cambiar foto y Quitar foto |
| `PantallaIntercambios · vacío` | Aún no tienes intercambios completados |
| `PantallaHistorial · vacío` | Aún no tienes movimientos |
| `PantallaHistorial · filtro sin resultados` | Filtro Reservas sin elementos |
| `PantallaAvisos · vacío` | No tienes avisos |
| `PantallaMisDatos · cargando` | Indicador de carga |
| `PantallaMisDatos · descarga` | `SnackBar` de descarga |
| `PantallaCambiarContrasena · error` | Campo de confirmación con error |

### Diálogos

La página `💬 Diálogos` muestra cada diálogo sobre la pantalla desde la que se abre. Cada marco es de 390 x 844 e incluye la pantalla, un velo (`ColorScheme/onSurface` con opacidad 0.32, posición absoluta) y la instancia del diálogo centrada.

| Marco | Pantalla de fondo |
| --- | --- |
| `confirmarAccion · normal`, `confirmarAccion · destructivo` | `PantallaOfertas` |
| `confirmarAccion · cancelar oferta` | `PantallaOfertas · enviadas` |
| `mostrarAyudaTrueque` | `PantallaFeedPublicaciones` |
| `pedirCalificacion · sinPuntaje`, `· conPuntaje`, `· error` | `PantallaOfertas · entrega y calificación` |
| `pedirMotivoCancelacion · vacío`, `· con motivo` | `PantallaOfertas · entrega y calificación` |
| `pedirDatosEntrega · proponer`, `· reprogramar`, `· contraproponer`, `· con errores` | `PantallaOfertas · entrega y calificación` |
| `mostrarDialogoOferta · ofrecer`, `· ofrecer sin opciones` | `PantallaFeedPublicaciones` |
| `mostrarDialogoOferta · contraofertar`, `· contraofertar sin opciones` | `PantallaOfertas` |
| `DialogoEditarPublicacion · normal`, `· guardando`, `· error` | `PantallaMisPublicaciones` |
| `DialogoEliminarCuenta · normal`, `· contraseña incorrecta` | `PantallaPerfil` |
| `DialogoHistorial · negociación` | `PantallaOfertas` |
| `DialogoHistorial · entrega` | `PantallaOfertas · entrega y calificación` |
| `DialogoHistorial · movimiento` | `PantallaHistorial` |

Las pantallas de Figma son composiciones representativas con datos de ejemplo (Ana Pérez, Luis Gómez, Calculadora científica), no una copia exacta de cada estado posible de la pantalla en Flutter. La referencia visual para espacios y jerarquía fue `docs/propuesta-visual-campus-fresco.op`; no se copió ningún color de ella, todo está enlazado a variables.

Cómo se verifica que no falte ninguna pantalla: `prueba.mjs` lee `trueque-u/app/lib/pantallas/*.dart`, busca las clases `class Pantalla... extends StatelessWidget/StatefulWidget` (incluida `PantallaPublicacion` de `Publicacion.dart`) y falla si alguna no tiene un marco con ese nombre exacto, o si la lista de pantallas de Figma no coincide con la del código.

Limitaciones de las pantallas:

- Los textos de los widgets de Material usan el estilo que Flutter aplica en ese contexto (ver la sección de tipografía), no una aproximación.
- Las sombras y la elevación de `Card`, `SnackBar`, diálogos y botón flotante no se dibujan (no son variables de color).
- El teclado, el desplazamiento y las animaciones no existen en Figma: el contenido largo se recorta al alto de la pantalla.
- Los diálogos se muestran con ancho fijo de 310 y sus botones de acción se reparten el ancho, mientras que Flutter los alinea a la derecha.

## Cómo el test de paridad protege los nombres

`trueque-u/app/test/tokens_figma_test.dart` lee `design/figma-plugin/tokens.json` y lo compara con el código Dart:

- Las secciones del JSON son exactamente `TemaTruequeU`, `ColorScheme`, `Espacios`, `Radios`, `Tipos`, `TextosTruequeU`, `TextTheme`, `TextoDerivado` y `Contextos`.
- Cada color de `TemaTruequeU` existe en el código con el mismo nombre y el mismo hex, y no sobran ni faltan claves.
- Cada rol de `ColorScheme` apunta a un color del tema y el rol del tema Flutter resuelve a ese mismo color.
- Espacios, radios y tamaños de texto coinciden en nombre y valor.
- Cada estilo de `TextosTruequeU` coincide en tamaño (vía su alias a `Tipos`) y peso.

`trueque-u/app/test/tipografia_figma_test.dart` compara la tipografía con lo que resuelve Flutter, sin números escritos de memoria:

- `TextTheme`: los 15 roles de `Theme.of(context).textTheme` (tamaño, altura, espaciado, peso y familia Roboto) coinciden con el JSON, sin claves de más ni de menos.
- `TextosTruequeU`: el `DefaultTextStyle` del cuerpo de un `Scaffold` mezclado con cada estilo da tamaño, altura, espaciado y peso del JSON.
- `Contextos` y `TextoDerivado`: para cada contexto monta el widget real (botones, campos, `AppBar`, `ListTile`, `AlertDialog`, `NavigationBar`, `SnackBar`, chips, `SegmentedButton`, `CircleAvatar`, `EncabezadoAcceso`...), lee el estilo del `Text` o del `EditableText` y lo compara con el estilo al que apunta el JSON. Falla si falta o sobra un contexto, si una referencia no existe o si un estilo derivado no lo usa ningún contexto.

`prueba.mjs` además exige que cada estilo derivado se use en algún nodo de texto, que ningún texto tenga glifos de símbolo y que `Icons.*` de `lib`, `iconos.json` y las variantes de `Icono` sean el mismo conjunto.

Como el plugin construye las variables solo desde `tokens.json`, renombrar o cambiar un token en Dart sin actualizar el JSON rompe el test, y cambiarlo en el JSON sin tocar el código también. Flujo para cambiar un token: editar `tema.dart` y `tokens.json`, correr `flutter test test/tokens_figma_test.dart test/tipografia_figma_test.dart`, ejecutar `node design/figma-plugin/generar.mjs` y volver a correr el plugin en Figma.
