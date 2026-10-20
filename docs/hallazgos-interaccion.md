# Hallazgos de interacción — Clase 16 (Fitts, Hick y carga cognitiva)

**Proyecto:** Trueque U · **Funcionalidad analizada:** Completar · acciones del objeto · datos del intercambio
**Integrantes:** Job Natanael Contreras Garzon · Eudenia Gandira Flores Veizaga

Se documentan tres hallazgos, uno por principio, sobre el flujo de completar un intercambio. Se priorizó **Hick**: se corrigió y se comprobó en la aplicación.

| Hallazgo | Captura | Justificación breve | Estado |
|---|---|---|---|
| Fitts | `evidencias/clase-16/antes-fitts.png` | Distancia y área: tres acciones a 6–8 px | Documentado |
| **Hick** | `evidencias/clase-16/antes-hick.png` → `despues-hick.png` | Cantidad: 5 de 7 acciones no sirven | **Corregido** |
| Carga cognitiva | `evidencias/clase-16/antes-carga-cognitiva.png` | Qué debe recordar: con quién fue el intercambio | Documentado |

> Las capturas son una representación de la pantalla hecha a partir del código. Se pueden reemplazar por capturas reales de la aplicación con el mismo nombre.

---

## 1. Fitts — acción difícil de alcanzar (documentado)

**Dónde:** feed de publicaciones → tarjeta de una publicación que reservé yo.
**Captura:** `docs/evidencias/clase-16/antes-fitts.png`

**Qué se observa:** «Cancelar reserva» (en rojo) queda a **8 px** de «WhatsApp» y a **6 px** de «Completar intercambio». Son tres acciones con consecuencias distintas casi pegadas. Además, en *Mis publicaciones* «Completar intercambio» es un botón compacto, abajo a la derecha, lejos de los datos de quien reservó.

**Justificación (tamaño, distancia o área activa):** con objetivos tan cercanos, un toque impreciso activa la acción equivocada. Cancelar la reserva pide confirmación, pero igual obliga a corregir un error evitable.

**Código:** `trueque-u/app/lib/widgets/tarjeta_feed.dart` L237-L268 (botones y separaciones de 6 y 8 px) · `trueque-u/app/lib/widgets/tarjeta_mi_publicacion.dart` L256-L270 (botón compacto).

**Posible corrección (pendiente):** separar «Cancelar reserva» de las acciones principales y dar a «Completar» el tamaño estándar.

---

## 2. Hick — demasiadas opciones (corregido)

**Dónde:** Mis publicaciones → tarjeta de una publicación **reservada**.
**Capturas:** `docs/evidencias/clase-16/antes-hick.png` y `docs/evidencias/clase-16/despues-hick.png`

**Qué se observaba (antes):** la tarjeta mostraba 5 controles y 7 acciones: editar, menú de estado (3 opciones), eliminar, WhatsApp y «Completar intercambio». Con la publicación reservada, el servidor **rechaza** editar, ocultar, marcar como no disponible, eliminar y descartar la reserva desde el dueño. Solo funcionaban WhatsApp y Completar: **5 de las 7 acciones estaban a la vista pero no se podían usar**.

**Justificación (cantidad, agrupación o prioridad):** cada opción de más hace que decidir cueste más, y aquí las opciones inútiles competían con las dos que sí importan en ese momento.

**Reglas del backend que lo confirman:**
- Editar: `trueque-u/backend/src/controllers/publicaciones.controlador.js` L270-L277
- Eliminar: mismo archivo, L359-L366
- Ocultar: mismo archivo, L411-L418
- Marcar como no disponible: mismo archivo, L470-L478
- Descartar la reserva siendo dueño: `trueque-u/backend/src/controllers/reservas.controlador.js` L110-L116

**Corrección aplicada (después):** si la publicación está reservada, la tarjeta no muestra editar, el menú de estado ni eliminar. Quedan solo WhatsApp y «Completar intercambio», más una línea que explica el motivo: «Está reservada: solo puedes completar el intercambio o escribir a quien la reservó». Si está disponible, se ve todo como antes.

**Código (después):** `trueque-u/app/lib/widgets/tarjeta_mi_publicacion.dart` L89-L150 (bloque `if (!estaReservada)`) y L229-L237 (la línea explicativa).

**Cómo se comprueba en la app:**
1. Con la cuenta del dueño, abrir *Mis publicaciones* con una publicación disponible: se ven lápiz, menú y papelera.
2. Con otra cuenta, reservarla desde el feed.
3. Volver a *Mis publicaciones* con la cuenta del dueño: solo se ven WhatsApp y «Completar intercambio», y la línea explicativa.

---

## 3. Carga cognitiva — información que exige esfuerzo (documentado)

**Dónde:** Mis publicaciones o feed → «Completar intercambio» → diálogo de confirmación.
**Captura:** `docs/evidencias/clase-16/antes-carga-cognitiva.png`

**Qué se observa:** el diálogo dice «¿Confirmas que el intercambio de "Calculadora científica" ya se realizó?» pero **no dice con quién**. Además, cuando «Completar» está deshabilitado, el motivo solo aparece en un tooltip, que en el celular exige mantener presionado.

**Justificación (qué debe recordar, interpretar o comparar):** la persona tiene que recordar quién reservó, un dato que está en otra pantalla, para confirmar que es el intercambio correcto. Y debe descubrir por su cuenta por qué el botón no responde.

**Código:** `trueque-u/app/lib/pantallas/pantalla_mis_publicaciones.dart` L179-L186 · `trueque-u/app/lib/pantallas/pantalla_feed_publicaciones.dart` L240-L247 · `trueque-u/app/lib/widgets/tarjeta_mi_publicacion.dart` L258-L262 (tooltip).

**Posible corrección (pendiente):** incluir el nombre de la otra persona en el diálogo.

---

## Mejora anterior ya aplicada (pantalla Perfil)

En el commit `46e9b01` se corrigió el menú del Perfil: botones más altos, «Cerrar sesión» separada, acciones agrupadas en dos bloques y una sola acción principal. Las capturas del antes están en `docs/antes-fitts.png`, `docs/antes-hick.png` y `docs/antes-carga-cognitiva.png`.
