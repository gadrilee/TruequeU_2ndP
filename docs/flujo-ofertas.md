# Flujo de la oferta de trueque

Antes, reservar una publicación solo guardaba quién la apartó. El dueño no elegía nada y no había un objeto a cambio.

Ahora quien quiere un objeto ofrece **una publicación propia**. El dueño de la otra la acepta o la rechaza. Eso se guarda en PostgreSQL, así que sigue ahí al recargar o volver a entrar.

## Archivos nuevos

### `trueque-u/base_de_datos/migracion_ofertas.sql`

La base de Docker ya estaba creada. `estructura.sql` solo corre la primera vez, cuando el volumen está vacío. Este archivo crea la tabla `ofertas` en esa base que ya existe, y deja una oferta de ejemplo: Carlos ofrece su mouse por el libro de cálculo de Eudenia. Se puede ejecutar más de una vez.

### `trueque-u/backend/src/models/ofertas.js`

Sequelize necesita un modelo para leer y escribir la tabla. Sin este archivo el backend no conoce `ofertas`.

### `trueque-u/backend/src/utils/ofertasPendientes.js`

Varios controladores preguntan lo mismo: si una publicación está en una oferta que todavía no se respondió. Se dejó en un solo lugar para no repetir la consulta en reservas, eliminar, ocultar y marcar no disponible.

### `trueque-u/backend/src/controllers/ofertas.controlador.js`

Aquí está la lógica:

- Crear la oferta. Tiene que ser un objeto mío y disponible, a cambio de uno ajeno y disponible. El mismo objeto no puede estar prometido en dos ofertas pendientes.
- Listar las recibidas (soy el dueño de lo que piden) y las enviadas (yo las mandé).
- Aceptar. Solo el dueño. Las dos publicaciones pasan a `intercambiado`. Las otras ofertas pendientes de esos objetos quedan `cancelada`. Se guarda el evento `completo` en el historial.
- Rechazar. Solo el dueño. Los objetos siguen disponibles.
- Cancelar. Solo quien la envió, y solo si sigue pendiente.

### `trueque-u/backend/src/routes/ofertas.rutas.js`

Conecta esas funciones con las URL y exige sesión:

- `POST /api/ofertas`
- `GET /api/ofertas/recibidas`
- `GET /api/ofertas/enviadas`
- `PUT /api/ofertas/:id/aceptada`
- `PUT /api/ofertas/:id/rechazada`
- `PUT /api/ofertas/:id/cancelada`

### `trueque-u/app/lib/widgets/dialogo_oferta.dart`

Al tocar "Ofrecer un objeto" hay que elegir cuál publicación propia se da a cambio. El diálogo lista solo las que están disponibles. Si no hay ninguna, manda a crear una.

### `trueque-u/app/lib/pantallas/pantalla_ofertas.dart`

Pantalla con dos pestañas: Recibidas y Enviadas. En las pendientes, el dueño acepta o rechaza y quien ofreció puede cancelar. Al volver a entrar se vuelven a pedir al servidor, por eso el resultado no se pierde.

## Archivos que ya existían

### `trueque-u/base_de_datos/estructura.sql`

Se agregó la tabla `ofertas` para una instalación nueva: qué publicación se quiere, cuál se ofrece, quién ofrece y el estado (`pendiente`, `aceptada`, `rechazada`, `cancelada`). El índice único impide prometer el mismo objeto en dos ofertas pendientes.

### `trueque-u/base_de_datos/datos.sql`

Se inserta la oferta de ejemplo (publicación 1, el libro de Eudenia, a cambio de la 8, el mouse de Carlos) para que al cargar los datos de prueba ya haya algo que aceptar o rechazar.

### `trueque-u/backend/src/models/init-models.js`

Registra el modelo `ofertas` junto con los demás, para que `models.ofertas` exista al arrancar.

### `trueque-u/backend/src/database/sequelize.js`

Relaciona cada oferta con la publicación pedida, la ofrecida y el usuario que ofrece. Así la respuesta trae los títulos y los nombres, no solo los ids.

### `trueque-u/backend/src/routes/index.js`

Monta las rutas nuevas en `/api/ofertas`.

### `trueque-u/backend/src/utils/reglasObjeto.js`

Se agregó `puedeCrearOferta`. Revisa que no ofrezcas por lo tuyo, que el objeto ofrecido sea tuyo y que los dos estén disponibles.

### `trueque-u/backend/src/utils/reglaObjeto.test.js`

Pruebas de esa regla: caso válido, ofertar por lo propio, ofrecer algo ajeno y ofrecer un objeto que ya está en otra oferta pendiente.

### `trueque-u/backend/src/controllers/reservas.controlador.js`

No se puede reservar una publicación que ya tiene una oferta pendiente. Si se reserva, el dueño ya no podría aceptar el trueque porque el objeto dejó de estar disponible.

### `trueque-u/backend/src/controllers/publicaciones.controlador.js`

No se puede eliminar, ocultar ni marcar como no disponible una publicación con una oferta pendiente. Primero hay que aceptarla, rechazarla o cancelarla. Si no, la oferta quedaría apuntando a un objeto que ya no se puede intercambiar.

### `trueque-u/backend/src/controllers/historial.registro.test.js`

La prueba de reservar ahora pasa por la consulta de ofertas pendientes. El falso de la base incluye `ofertas.count` en 0 para que esa prueba siga reservando como antes.

### `trueque-u/app/lib/estado/controlador_autenticacion.dart`

Métodos que llama la pantalla: crear oferta, listar recibidas y enviadas, aceptar, rechazar y cancelar.

### `trueque-u/app/lib/rutas.dart`

La ruta privada `/ofertas`. Sin sesión redirige al inicio de sesión, igual que el perfil.

### `trueque-u/app/lib/pantallas/pantalla_perfil.dart`

Botón "Ofertas de trueque" para llegar a esa pantalla.

### `trueque-u/app/lib/widgets/tarjeta_feed.dart`

En una publicación disponible de otra persona se agregó el botón "Ofrecer un objeto". "Reservar" se dejó.

### `trueque-u/app/lib/pantallas/pantalla_feed_publicaciones.dart`

Al tocar el botón carga mis publicaciones disponibles, abre el diálogo y envía `POST /api/ofertas` con la publicación elegida. La tarjeta es un poco más alta para que quepan los dos botones.

### `trueque-u/app/lib/widgets/dialogo_ayuda.dart`

Se agregó un párrafo que explica que también se puede ofrecer un objeto propio y que el dueño responde en Ofertas de trueque.

## Preguntas que puede hacer el docente

El script mira cada commit. Si algo no cuadra con el mensaje o con el archivo anterior, pregunta. Estas son las que más pueden salir, y una respuesta corta.

**¿Por qué hay `migracion_ofertas.sql` si la tabla ya está en `estructura.sql`?**
`estructura.sql` solo se ejecuta cuando Docker crea la base por primera vez. Nuestra base ya existía, así que ese script no volvía a correr. La migración crea la tabla en la base que ya teníamos. En una instalación nueva basta con `estructura.sql`.

**¿Por qué la oferta de ejemplo usa los ids 1 y 8?**
En `datos.sql` las publicaciones se insertan en orden. La 1 es el libro de cálculo de Eudenia y la 8 es el mouse de Carlos. La migración no usa esos números: busca por título, por si los ids ya no coinciden.

**¿Por qué existe el estado `cancelada` si la tarea es aceptar o rechazar?**
Rechazar lo hace el dueño. Cancelar lo hace quien envió la oferta, si se arrepiente. También queda `cancelada` cuando se acepta otro trueque que usa el mismo objeto: ese objeto ya no se puede prometer.

**¿Por qué un objeto no puede estar en dos ofertas pendientes?**
Si ofrezco la misma calculadora a dos personas y las dos aceptan, no tengo dos calculadoras. Por eso el índice único solo aplica cuando el estado es `pendiente`. Si la oferta se rechaza o se cancela, ese objeto se puede volver a ofrecer.

**¿Por qué al aceptar se marcan las dos publicaciones como intercambiadas?**
El trueque es de los dos objetos. Si solo cambiara uno, el otro seguiría disponible y otra persona podría pedirlo. `id_usuario_reserva` queda con la otra persona para que los dos vean el intercambio en el historial y en los intercambios completados.

**¿Por qué se escriben dos filas `completo` en el historial?**
Una por cada objeto. El historial está armado por publicación. Si solo se guardara el libro, la calculadora no aparecería.

**¿Por qué no se puede reservar, borrar ni ocultar si hay una oferta pendiente?**
Aceptar exige que los dos objetos sigan disponibles. Si alguien reserva o el dueño oculta el objeto, la oferta pendiente ya no se podría cumplir. Primero se responde o se cancela.

**¿Por qué sigue el botón Reservar?**
La reserva ya estaba. La oferta es otra acción: ahí sí eliges qué objeto das y el dueño decide. No reemplazamos la reserva para no romper lo anterior.

**¿Por qué `historial.registro.test.js` cambió si el commit habla de reservas?**
Al reservar ahora se consulta si hay una oferta pendiente. La prueba usa una base falsa y no tenía `ofertas`. Se agregó `count` en 0 para que la reserva de prueba siga pasando.

**¿Por qué `id_usuario` en la oferta si el dueño del objeto ofrecido ya está en la publicación?**
Para saber rápido quién envió la oferta sin unir tablas, y para impedir que alguien ofrezca un objeto que no es suyo.

**¿Qué pasa si el dueño acepta y el objeto ya no está disponible?**
No se acepta. Responde 409 y le dice que rechace esa oferta. No se cambia una publicación y se deja la otra a medias: va todo en una transacción.

**¿Dónde se ve que persiste?**
En la tabla `ofertas`. La pantalla vuelve a pedir `/api/ofertas/recibidas` y `/api/ofertas/enviadas` al entrar. Recargar no borra la fila.

**¿Por qué el diálogo y la pantalla están en archivos nuevos?**
El feed ya tenía bastante. El diálogo solo elige el objeto propio. La pantalla solo lista y responde. Así no se mezcló con reservar.
