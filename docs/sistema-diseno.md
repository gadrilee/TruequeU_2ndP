# Sistema de diseño TruequeU

Los valores de diseño (colores, espacios, radios, tamaños y estilos de texto) viven en un solo archivo, `design/figma-plugin/tokens.json`. Un plugin local de Figma lee ese archivo y construye el sistema de diseño en el archivo abierto: variables, estilos de texto, logo, componentes y pantallas.

## Cómo ejecutarlo

1. Generar el código del plugin desde los tokens:

   ```
   node design/figma-plugin/generar.mjs
   ```

   Esto escribe `design/figma-plugin/code.js` (los tokens van incrustados al inicio) y actualiza la tabla de tokens de este documento.
2. En Figma Desktop, abrir el archivo de destino y elegir Plugins, Development, Import plugin from manifest, y seleccionar `design/figma-plugin/manifest.json`.
3. Ejecutar Plugins, Development, TruequeU Sistema de diseño.

El plugin es idempotente: al volver a ejecutarlo actualiza por nombre las colecciones, variables y estilos existentes, y recrea todo el contenido de las cuatro páginas (Fundamentos, Componentes, Pantallas, Diálogos). No debe editarse a mano el contenido de esas páginas, porque se reemplaza.

Para comprobar el código del plugin sin Figma, `node design/figma-plugin/prueba.mjs` lo ejecuta contra una simulación mínima de la API. Verifica variables, estilos, conjuntos de componentes, pantallas, diálogos, que cada clase `Pantalla*` de `lib/pantallas` tenga su marco y que ningún relleno quede sin variable, pero no demuestra cómo se ve en Figma real.

## Regla de nombres

- Dart `Clase.campo` se llama en Figma `Clase/campo`. La barra reemplaza el punto porque Figma no admite puntos en los nombres de variables.
- Las colecciones de variables son `TemaTruequeU`, `ColorScheme`, `Espacios`, `Radios` y `Tipos`. El nombre de cada variable es el nombre del campo Dart; su descripción guarda el identificador Dart (por ejemplo `TemaTruequeU.azul`).
- `ColorScheme` contiene los roles del tema; cada uno es un alias a una variable de `TemaTruequeU`.
- Los estilos de texto se llaman `TextosTruequeU/<campo>` y su tamaño está enlazado a la variable de `Tipos` correspondiente.
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
| `TextosTruequeU.titulo` | Estilo de texto `TextosTruequeU/titulo` | 26 px, peso 700 |
| `TextosTruequeU.subtitulo` | Estilo de texto `TextosTruequeU/subtitulo` | 18 px, peso 700 |
| `TextosTruequeU.tituloTarjeta` | Estilo de texto `TextosTruequeU/tituloTarjeta` | 17 px, peso 700 |
| `TextosTruequeU.tituloItem` | Estilo de texto `TextosTruequeU/tituloItem` | 16 px, peso 700 |
| `TextosTruequeU.cuerpo` | Estilo de texto `TextosTruequeU/cuerpo` | 14 px, peso 400 |
| `TextosTruequeU.detalle` | Estilo de texto `TextosTruequeU/detalle` | 13 px, peso 400 |
| `TextosTruequeU.etiqueta` | Estilo de texto `TextosTruequeU/etiqueta` | 12 px, peso 500 |
| `TextosTruequeU.ayuda` | Estilo de texto `TextosTruequeU/ayuda` | 12 px, peso 400 |
| `TextosTruequeU.chip` | Estilo de texto `TextosTruequeU/chip` | 11 px, peso 500 |
| `TextosTruequeU.chipDestacado` | Estilo de texto `TextosTruequeU/chipDestacado` | 11 px, peso 700 |
| `TextosTruequeU.pie` | Estilo de texto `TextosTruequeU/pie` | 11 px, peso 400 |
<!-- tokens:fin -->

## Componente Figma, archivo Flutter y variantes

Los archivos están en `trueque-u/app/lib/widgets/` salvo los marcados como Material, patrón inline o clase privada de una pantalla (no existen como widget propio). Todos usan auto layout; padding y separación están enlazados a `Espacios`, radios a `Radios`, y rellenos y bordes a variables de `ColorScheme` (o `TemaTruequeU/blanco` y `TemaTruequeU/rojo` donde el código usa esos colores directamente).

| Componente Figma | Archivo Flutter | Variantes y estados |
| --- | --- | --- |
| `LogoTruequeU` | `logo_trueque_u.dart` | Variante: icono, conNombre |
| `BotonCarga` | `boton_carga.dart` | Estado: default, hover, presionado, cargando, deshabilitado. Variante: primario, rojo, tonal, contorno, contornoRojo (contorno con color de error), texto (TextButton) |
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

- Los íconos son glifos de texto como marcador de posición (solo el logo dibuja un vector); usan colores del sistema pero no son los íconos de Material.
- `EncabezadoAcceso` intenta un degradado de `azulOscuro` a `azul` con las paradas enlazadas a variables. Si la API de Figma no conserva ese enlace, el plugin usa un relleno sólido `ColorScheme/onPrimaryContainer` para no dejar colores fijos.
- Estados como hover y presionado no existen en Flutter como widgets; se modelan con opacidad sobre el color del token.
- Los textos de botones usan el estilo `TextosTruequeU/cuerpo`; Flutter usa el estilo de botón por defecto de Material (14 px, peso 500).
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

- Los textos de varios estilos de Material sin token equivalente (por ejemplo el título de `ListTile` de 16 px regular, el título de `AppBar` de 22 px o `headlineSmall`) se aproximan con el estilo `TextosTruequeU` más cercano.
- Las sombras y la elevación de `Card`, `SnackBar`, diálogos y botón flotante no se dibujan (no son variables de color).
- El teclado, el desplazamiento y las animaciones no existen en Figma: el contenido largo se recorta al alto de la pantalla.
- Los diálogos se muestran con ancho fijo de 310 y sus botones de acción se reparten el ancho, mientras que Flutter los alinea a la derecha.

## Cómo el test de paridad protege los nombres

`trueque-u/app/test/tokens_figma_test.dart` lee `design/figma-plugin/tokens.json` y lo compara con el código Dart:

- Las secciones del JSON son exactamente `TemaTruequeU`, `ColorScheme`, `Espacios`, `Radios`, `Tipos` y `TextosTruequeU`.
- Cada color de `TemaTruequeU` existe en el código con el mismo nombre y el mismo hex, y no sobran ni faltan claves.
- Cada rol de `ColorScheme` apunta a un color del tema y el rol del tema Flutter resuelve a ese mismo color.
- Espacios, radios y tamaños de texto coinciden en nombre y valor.
- Cada estilo de `TextosTruequeU` coincide en tamaño (vía su alias a `Tipos`) y peso.

Como el plugin construye las variables solo desde `tokens.json`, renombrar o cambiar un token en Dart sin actualizar el JSON rompe el test, y cambiarlo en el JSON sin tocar el código también. Flujo para cambiar un token: editar `tema.dart` y `tokens.json`, correr `flutter test test/tokens_figma_test.dart`, ejecutar `node design/figma-plugin/generar.mjs` y volver a correr el plugin en Figma.
