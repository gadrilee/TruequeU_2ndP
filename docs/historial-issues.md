# Historial — ¿Qué ocurrió con el intercambio? (análisis e issues)

**Proyecto:** Trueque U · **Tarea de la Clase 16 (para la casa):** nueva feature *Historial*
**Orden de trabajo:** primero backend, después front, al final la evidencia.

Los números de issue los asigna GitHub; aquí se usan `H-1`…`H-8` para referirse a ellos. Al crearlos, reemplazar por el número real y vincularlos al padre con *Add sub-issue*.

---

## 1. Decisión de alcance

**El historial guarda y muestra tres tipos de evento** de un intercambio:

| Tipo (`tipo`) | Qué pasó | Cómo se lee |
|---|---|---|
| `reservo` | Una persona reservó la publicación | «Reservaste…» / «Ana reservó tu…» |
| `cancelo_reserva` | Quien reservó canceló su reserva | «Cancelaste la reserva de…» / «Ana canceló su reserva de tu…» |
| `completo` | Se completó el intercambio | «Completaste el intercambio de…» / «Ana completó el intercambio de tu…» |

**Por qué no solo los intercambios completados:** hoy, al cancelar una reserva se borra `id_usuario_reserva`, y `publicaciones` no guarda fechas. Con solo los completados el historial diría siempre lo mismo («Intercambiado») y no respondería «¿qué ocurrió?». Con tres tipos sí cuenta la trayectoria (reservó → canceló → reservó → completó) y sigue siendo pequeño.

**Lo que NO se hace (para no cargar la tarea):** sin paginación, sin buscador, sin editar ni borrar eventos, sin notificaciones, sin tocar el estado de las publicaciones. Los intercambios completados *antes* de existir esta tabla no aparecen (son datos de prueba).

**Datos reales y del usuario correcto:** cada evento se guarda en la base de datos en el mismo momento en que ocurre la acción, y `GET /api/historial` solo devuelve los eventos en los que la persona con sesión participó (como quien hizo la acción o como la otra parte).

### Tabla propuesta (Neon / PostgreSQL)

```sql
CREATE TABLE historial (
  id              SERIAL PRIMARY KEY,
  tipo            VARCHAR(20) NOT NULL
                  CHECK (tipo IN ('reservo', 'cancelo_reserva', 'completo')),
  id_publicacion  INTEGER REFERENCES publicaciones(id) ON DELETE SET NULL,
  titulo          VARCHAR(150) NOT NULL,   -- copia: el evento sobrevive si se elimina la publicación
  categoria       VARCHAR(20)  NOT NULL,   -- copia, por la misma razón
  id_usuario      INTEGER NOT NULL REFERENCES usuarios(id),  -- quien hizo la acción
  id_otro_usuario INTEGER NOT NULL REFERENCES usuarios(id),  -- la otra persona del intercambio
  creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX historial_usuario_idx ON historial (id_usuario, creado_en DESC);
CREATE INDEX historial_otro_idx    ON historial (id_otro_usuario, creado_en DESC);
```

### Consulta y respuesta

`GET /api/historial?tipo=…` (con sesión). `tipo` es opcional: `reservas` (reservó + canceló) o `completados`; otro valor da 400.

```json
[
  {
    "id": 12,
    "tipo": "completo",
    "creado_en": "2026-10-20T18:30:00.000Z",
    "lo_hice_yo": true,
    "publicacion": { "id": 5, "titulo": "Calculadora científica", "categoria": "electronica" },
    "otra_persona": { "id": 3, "nombre": "Ana" }
  }
]
```

Orden: `creado_en` descendente (lo más reciente primero), con `id` descendente como desempate. No se envía el teléfono de nadie.

### Decisiones de diseño previstas (Tarea 4)

| Principio | Decisión para el Historial |
|---|---|
| **Fitts** | La entrada es un botón de 52 px en el Perfil (mismo tamaño que los demás, dentro del bloque «Publicaciones»), en lugar de «Intercambios completados». Cada evento es una tarjeta completa tocable (toda el área abre el detalle). |
| **Hick** | Solo tres opciones de filtro en una fila: **Todo · Reservas · Completados**. Los tres tipos de evento se agrupan en dos filtros, no se muestran como tres. |
| **Carga cognitiva** | Cada tarjeta empieza por el resultado en palabras (con ícono y texto, no solo color), luego el objeto y la otra persona, y al final la fecha. Se entiende sin recordar otras pantallas. El detalle agrega categoría y fecha completa. |

---

## 2. Orden de los issues

| # | Issue | Parte |
|:-:|---|---|
| Padre | `[Historial] ¿Qué ocurrió con el intercambio?` | — |
| H-1 | Tabla `historial` y modelo | Backend |
| H-2 | Registrar el evento al reservar, cancelar y completar | Backend |
| H-3 | `GET /api/historial`: consulta del usuario, orden y filtro | Backend |
| H-4 | Pruebas del historial | Backend |
| H-5 | Pantalla Historial: lista, orden, estado vacío y error | Front |
| H-6 | Filtro (Todo · Reservas · Completados) y detalle del evento | Front |
| H-7 | Entrada desde el Perfil | Front |
| H-8 | Evidencia: `docs/decisiones-interaccion.md` | Docs |

---

## Issue padre

**Título:** `[Historial] ¿Qué ocurrió con el intercambio?`

**Cuerpo:**

> **Historia:** Como persona que reserva o publica objetos, quiero ver un historial de lo que ocurrió con mis intercambios, para saber qué pasó, cuándo, con quién y cuál fue el resultado sin tener que recordarlo.
>
> ### Alcance
> Una funcionalidad nueva conectada a datos reales: se guarda un evento cada vez que alguien **reserva**, **cancela una reserva** o **completa un intercambio**, y una pantalla *Historial* lo muestra a las personas involucradas. No es un texto agregado a una pantalla.
>
> ### Criterios de aceptación
> - [ ] Reservar, cancelar una reserva y completar un intercambio crean un evento guardado en la base de datos.
> - [ ] El historial solo muestra eventos de la persona con sesión (como autora de la acción o como la otra parte).
> - [ ] Lo más reciente aparece primero y cada evento dice qué ocurrió, cuándo, con quién y sobre qué objeto.
> - [ ] Sin eventos, el estado vacío dice qué hacer después.
> - [ ] Hay una prueba que comprueba la consulta y otra la regla de a quién se muestra cada evento.
> - [ ] Las tres decisiones de diseño (Fitts, Hick, carga cognitiva) tienen antes, después y código en `docs/decisiones-interaccion.md`.
>
> ### Sub-issues
> H-1 a H-8 (ver lista).

---

## H-1 · Tabla `historial` y modelo

**Título:** `[Historial][Backend] Tabla historial y modelo`

> **Padre:** Historial
>
> ### Qué
> Crear la tabla `historial` en Neon con el SQL del documento y agregar su modelo Sequelize (`src/models/historial.js`) y las relaciones en `init-models.js` (`usuarios`, `publicaciones`).
>
> ### Criterios
> - [ ] La tabla existe en Neon con las restricciones (`CHECK` de `tipo`, claves foráneas, índices).
> - [ ] `models.historial` está disponible y el servidor arranca sin errores.
> - [ ] Eliminar una publicación no borra sus eventos (`ON DELETE SET NULL`).

## H-2 · Registrar el evento al reservar, cancelar y completar

**Título:** `[Historial][Backend] Registrar eventos al reservar, cancelar y completar`

> **Padre:** Historial · **Depende de:** H-1
>
> ### Qué
> En `putReserva` y `putReservaDescartada` (`reservas.controlador.js`) y en `putIntercambio` (`intercambios.controlador.js`) se guarda el evento con `models.historial.create(...)` dentro del mismo controlador (sin función compartida). El cambio de estado y el evento van juntos en una transacción: si falla uno, no se guarda ninguno. Solo se guarda `cancelo_reserva` si de verdad había una reserva (reactivar una publicación oculta no cuenta).
>
> ### Criterios
> - [ ] Reservar crea `reservo` (actor: quien reserva; otra persona: el dueño).
> - [ ] Descartar una reserva crea `cancelo_reserva` solo cuando había una reserva (no cuando el dueño reactiva una publicación oculta).
> - [ ] Completar crea `completo` (actor: quien completa; otra persona: la otra parte).
> - [ ] Una acción rechazada por las reglas (403/409) no crea ningún evento.
> - [ ] Se imprime en consola un log corto al registrar cada evento.

## H-3 · `GET /api/historial`

**Título:** `[Historial][Backend] Consulta del historial de la persona con sesión`

> **Padre:** Historial · **Depende de:** H-1
>
> ### Qué
> Nueva ruta `GET /api/historial` (con `exigirSesion`) en `historial.controlador.js` y `historial.rutas.js`. Devuelve los eventos donde `id_usuario` o `id_otro_usuario` es la persona con sesión, con el formato del documento, del más reciente al más antiguo. Filtro opcional `?tipo=reservas|completados`.
>
> ### Criterios
> - [ ] Solo devuelve eventos en los que la persona participó.
> - [ ] Orden: `creado_en` descendente, `id` descendente como desempate.
> - [ ] `tipo` inválido responde 400 con mensaje claro.
> - [ ] La respuesta incluye `lo_hice_yo`, la publicación (id, título, categoría) y la otra persona (id, nombre), sin teléfonos.
> - [ ] Sin eventos devuelve una lista vacía (no un error).

## H-4 · Pruebas del historial

**Título:** `[Historial][Backend] Pruebas de la consulta y del registro de eventos`

> **Padre:** Historial · **Depende de:** H-2, H-3
>
> ### Criterios
> - [ ] Prueba: la consulta devuelve solo los eventos de la persona y los ordena del más reciente al más antiguo.
> - [ ] Prueba: un tercero que no participó no ve el evento.
> - [ ] Prueba: el filtro `reservas` y `completados` y el 400 por tipo inválido.
> - [ ] Prueba: completar un intercambio registra un evento `completo`; una acción rechazada no registra nada.
> - [ ] `npm test` pasa completo.

## H-5 · Pantalla Historial: lista, orden, estado vacío y error

**Título:** `[Historial][Front] Pantalla Historial con lista, estado vacío y error`

> **Padre:** Historial · **Depende de:** H-3
>
> ### Qué
> Nueva ruta privada `/historial` y `pantalla_historial.dart`, con `obtenerHistorial()` en el controlador. Una tarjeta por evento con el resultado en palabras, el objeto, la otra persona y la fecha; carga, error con reintento y estado vacío.
>
> ### Criterios
> - [ ] Los datos vienen del backend (no son ejemplos fijos).
> - [ ] Lo más reciente se ve primero.
> - [ ] El texto de cada evento cambia según `lo_hice_yo` («Reservaste…» / «Ana reservó tu…»).
> - [ ] El estado vacío explica qué hacer («Cuando reserves o completes un intercambio, aparecerá aquí») y lleva al feed.
> - [ ] Los errores se muestran en lenguaje simple, con botón para reintentar.

## H-6 · Filtro y detalle del evento

**Título:** `[Historial][Front] Filtro Todo · Reservas · Completados y detalle del evento`

> **Padre:** Historial · **Depende de:** H-5
>
> ### Criterios
> - [ ] Tres opciones de filtro en una fila: Todo, Reservas, Completados (la elegida se ve marcada).
> - [ ] Con un filtro sin resultados, el mensaje vacío lo dice y ofrece quitar el filtro.
> - [ ] Toda la tarjeta es tocable y abre el detalle (categoría, fecha y hora completas, otra persona).
> - [ ] El estado se indica con ícono y texto, no solo con color.

## H-7 · Entrada desde el Perfil

**Título:** `[Historial][Front] Botón Historial en el Perfil`

> **Padre:** Historial · **Depende de:** H-5
>
> ### Criterios
> - [ ] El Perfil tiene un botón «Historial» de 52 px, dentro del bloque «Publicaciones».
> - [ ] Reemplaza a «Intercambios completados» (la pantalla antigua deja de usarse; el endpoint antiguo puede quedarse sin romper nada).
> - [ ] La ruta `/historial` exige sesión.

## H-8 · Evidencia de las tres decisiones

**Título:** `[Historial][Docs] docs/decisiones-interaccion.md con antes, después y código`

> **Padre:** Historial · **Depende de:** H-5, H-6, H-7
>
> ### Criterios
> - [ ] El archivo documenta Fitts, Hick y carga cognitiva, cada una con **antes**, **después** y **referencia al código** (archivo y líneas).
> - [ ] Las capturas están en `docs/evidencias/` con nombres claros.
> - [ ] El «antes» usa la pantalla actual «Intercambios completados» (sin fecha, sin filtro, tarjeta no tocable) y el menú del Perfil.
> - [ ] Los commits siguen el estilo del proyecto (`feat(historial): …`, `docs: …`).

---

## 3. Checklist de la docente → dónde se cumple

| Criterio de terminado | Issue |
|---|---|
| El issue y sus sub-issues explican el alcance | Padre + H-1…H-8 |
| El historial usa datos reales y pertenece al usuario correcto | H-1, H-2, H-3 |
| El orden y los estados se entienden | H-3, H-5, H-6 |
| El estado vacío orienta qué hacer después | H-5, H-6 |
| Una prueba comprueba la consulta o regla principal | H-4 |
| Las tres decisiones tienen antes, después y código | H-7, H-8 |
