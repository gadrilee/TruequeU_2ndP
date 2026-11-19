# Reporte de accesibilidad · Trueque U

Fecha: 2026-11-18 · Herramienta: Lighthouse 13.6.0 (HeadlessChromium 153), categoría Accesibilidad, escritorio y móvil.

## 1. Resumen

| Ruta | Escritorio antes → después | Móvil antes → después | Auditorías aprobadas antes → después | Nodos accesibles (`flt-semantics`) antes → después |
| --- | --- | --- | --- | --- |
| `/` | 100 → 100 | 100 → 100 | 18/17 → 20 | 0 → 8 |
| `/iniciar-sesion` | 100 → 100 | 100 → 100 | 18/17 → 22 | 0 → 14 |
| `/registro` | 100 → 100 | 100 → 100 | 18/17 → 22 | 0 → 17 |
| `/recuperar-contrasena` | 100 → 100 | 100 → 100 | 18/17 → 22 | 0 → 10 |

- **Antes:** producción, `https://trueque-u-ihc.web.app/#/<ruta>`.
- **Después:** build local del código corregido (`http://localhost:8080/#/<ruta>`), con la misma API de producción. Producción quedará igual tras el despliegue.

## 2. Interpretación: el 100 del "antes" no era real

Trueque U es una app Flutter web y dibuja la interfaz en un `<canvas>`. Sin la semántica activada, el DOM no tiene ningún nodo accesible: había 0 nodos `flt-semantics` en todas las rutas.

Lighthouse auditó un documento vacío. Marcó 45-46 auditorías como "no aplicables" y por eso dio 100. Para un lector de pantalla la página estaba en blanco: no había botones, campos ni textos que anunciar. Es un **falso negativo**, no evidencia de accesibilidad.

Después de la corrección, el mismo puntaje de 100 sí significa algo:
- Lighthouse audita 20-22 reglas sobre un árbol accesible real, de 8 a 17 nodos por pantalla.
- Ninguna regla falla.

Lighthouse no puede medir el contraste del texto dibujado en canvas, así que el contraste se comprobó aparte (sección 4).

## 3. Hallazgos y correcciones

| # | Hallazgo | Criterio WCAG | Impacto en usuarios | Corrección (evidencia) |
| --- | --- | --- | --- | --- |
| 1 | Sin árbol accesible: la app no expone ningún elemento a tecnologías de asistencia | 1.3.1, 4.1.2 | Grave: un lector de pantalla no puede usar la app | `SemanticsBinding.instance.ensureSemantics()` al arrancar (`trueque-u/app/lib/main.dart:15`, `:20`) |
| 2 | Idioma del documento: Flutter sobrescribía `lang` con `en-US` | 3.1.1 | El lector pronuncia el español con reglas del inglés | `<html lang="es">` (`web/index.html:2`) y `locale: Locale('es')` con `flutter_localizations` (`lib/main.dart:60-66`) |
| 3 | Botón "Volver" solo con ícono, sin nombre accesible | 4.1.2, 2.4.6 | Se anunciaba como "botón" sin propósito | `tooltip: 'Volver'` (`lib/widgets/pagina_acceso.dart:47`) |
| 4 | Logo, fotos y títulos sin descripción ni rol de encabezado | 1.1.1, 1.3.1 | Imágenes sin texto alternativo; no se podía navegar por títulos | Etiquetas y `header: true` (`logo_trueque_u.dart:11`, `foto_publicacion.dart:48-49`, `mensaje_vacio.dart:33,36`, `encabezado_acceso.dart:57`, `pantalla_feed_publicaciones.dart:519`) |
| 5 | Estrellas de calificación con zona táctil de 40 px | 2.5.8 | Difícil de tocar con precisión | Se quitó `VisualDensity.compact`: ahora 48 px (`lib/widgets/estrellas.dart`) |
| 6 | Bordes de campos y botones con borde a 1.26:1 | 1.4.11 | Personas con baja visión no ven dónde está el campo | `borde` → `contorno` (4.80:1) (`lib/tema.dart:75`, `:144`; `lib/widgets/filtros_feed.dart:52,59`) |

Las correcciones están protegidas por tests:
- `test/accesibilidad_test.dart` aplica las guías de Flutter `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline` y `textContrastGuideline` sobre las pantallas públicas y los widgets clave.
- `test/contraste_aa_test.dart` comprueba el contraste de los pares de color.

## 4. Contraste WCAG AA

Detalle completo en [contraste.md](contraste.md). Se evaluaron 31 pares texto/fondo y control/fondo tal como la app los usa, y 13 pares del esquema de color. El umbral es 4.5:1 para texto normal y 3:1 para texto grande y componentes de interfaz.

- **Falló un solo uso:** el borde de los controles (`borde` `#E7E5E4` sobre blanco, 1.26:1). Ahora usa `contorno` `#78716C`, a 4.80:1, y cumple.
- **Todos los pares de texto cumplen AA.** Ningún color de la paleta `TemaTruequeU` cambió de valor.
- **Bordes de tarjetas:** siguen en `borde` porque son decorativos y no identifican un control.
- **Cuidado a futuro:** `contorno` sobre `fondo` mide 4.49:1, así que no debe usarse como texto sobre `fondo`.

## 5. Capturas de Lighthouse (antes / después)

### `/` (Escritorio)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/inicio-escritorio-1-puntaje.png" width="420"> | <img src="despues/inicio-escritorio-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/inicio-escritorio-3-secciones.png" width="420"> | <img src="despues/inicio-escritorio-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/inicio-escritorio-4-pie.png" width="420"> | <img src="despues/inicio-escritorio-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/inicio-escritorio-5-aprobadas.png" width="420"> | <img src="despues/inicio-escritorio-5-aprobadas.png" width="420"> |

### `/` (Móvil)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/inicio-movil-1-puntaje.png" width="420"> | <img src="despues/inicio-movil-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/inicio-movil-3-secciones.png" width="420"> | <img src="despues/inicio-movil-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/inicio-movil-4-pie.png" width="420"> | <img src="despues/inicio-movil-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/inicio-movil-5-aprobadas.png" width="420"> | <img src="despues/inicio-movil-5-aprobadas.png" width="420"> |

### `/iniciar-sesion` (Escritorio)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/iniciar-sesion-escritorio-1-puntaje.png" width="420"> | <img src="despues/iniciar-sesion-escritorio-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/iniciar-sesion-escritorio-3-secciones.png" width="420"> | <img src="despues/iniciar-sesion-escritorio-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/iniciar-sesion-escritorio-4-pie.png" width="420"> | <img src="despues/iniciar-sesion-escritorio-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/iniciar-sesion-escritorio-5-aprobadas.png" width="420"> | <img src="despues/iniciar-sesion-escritorio-5-aprobadas.png" width="420"> |

### `/iniciar-sesion` (Móvil)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/iniciar-sesion-movil-1-puntaje.png" width="420"> | <img src="despues/iniciar-sesion-movil-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/iniciar-sesion-movil-3-secciones.png" width="420"> | <img src="despues/iniciar-sesion-movil-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/iniciar-sesion-movil-4-pie.png" width="420"> | <img src="despues/iniciar-sesion-movil-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/iniciar-sesion-movil-5-aprobadas.png" width="420"> | <img src="despues/iniciar-sesion-movil-5-aprobadas.png" width="420"> |

### `/registro` (Escritorio)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/registro-escritorio-1-puntaje.png" width="420"> | <img src="despues/registro-escritorio-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/registro-escritorio-3-secciones.png" width="420"> | <img src="despues/registro-escritorio-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/registro-escritorio-4-pie.png" width="420"> | <img src="despues/registro-escritorio-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/registro-escritorio-5-aprobadas.png" width="420"> | <img src="despues/registro-escritorio-5-aprobadas.png" width="420"> |

### `/registro` (Móvil)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/registro-movil-1-puntaje.png" width="420"> | <img src="despues/registro-movil-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/registro-movil-3-secciones.png" width="420"> | <img src="despues/registro-movil-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/registro-movil-4-pie.png" width="420"> | <img src="despues/registro-movil-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/registro-movil-5-aprobadas.png" width="420"> | <img src="despues/registro-movil-5-aprobadas.png" width="420"> |

### `/recuperar-contrasena` (Escritorio)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/recuperar-contrasena-escritorio-1-puntaje.png" width="420"> | <img src="despues/recuperar-contrasena-escritorio-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/recuperar-contrasena-escritorio-3-secciones.png" width="420"> | <img src="despues/recuperar-contrasena-escritorio-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/recuperar-contrasena-escritorio-4-pie.png" width="420"> | <img src="despues/recuperar-contrasena-escritorio-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/recuperar-contrasena-escritorio-5-aprobadas.png" width="420"> | <img src="despues/recuperar-contrasena-escritorio-5-aprobadas.png" width="420"> |

### `/recuperar-contrasena` (Móvil)

| Captura | Antes (producción) | Después (build local) |
| --- | --- | --- |
| Puntaje | <img src="antes/recuperar-contrasena-movil-1-puntaje.png" width="420"> | <img src="despues/recuperar-contrasena-movil-1-puntaje.png" width="420"> |
| Secciones de auditorías | <img src="antes/recuperar-contrasena-movil-3-secciones.png" width="420"> | <img src="despues/recuperar-contrasena-movil-3-secciones.png" width="420"> |
| Pie con versión y entorno | <img src="antes/recuperar-contrasena-movil-4-pie.png" width="420"> | <img src="despues/recuperar-contrasena-movil-4-pie.png" width="420"> |
| Aprobadas y no aplicables expandidas | <img src="antes/recuperar-contrasena-movil-5-aprobadas.png" width="420"> | <img src="despues/recuperar-contrasena-movil-5-aprobadas.png" width="420"> |


## 6. Revisiones manuales y limitaciones

- **Revisiones manuales que Lighthouse lista** (teclado, orden de foco, lector de pantalla, zoom 200 %): no se hicieron de forma completa en esta entrega.
- **Rutas con sesión** (feed, ofertas, perfil, etc.): no se midieron en esta entrega. La cuenta de prueba existe, pero la medición se recortó por tiempo.
- **Encabezados:** `header: true` está aplicado, pero en el DOM de Flutter web no aparece como `role="heading"`. Falta comprobar cómo lo anuncia un lector de pantalla.
- **Rendimiento:** la corrida completa en `/` (escritorio) dio rendimiento 44 → 43, buenas prácticas 81 → 81 y SEO 91 → 91. Rendimiento no es parte de este trabajo.

## 7. Cómo reproducir

```
node docs/accesibilidad/herramientas/medir.mjs        # corre Lighthouse y toma las capturas
node docs/accesibilidad/herramientas/comparacion.mjs docs/accesibilidad   # tablas antes/después
cd trueque-u/app && flutter test test/accesibilidad_test.dart test/contraste_aa_test.dart
```
