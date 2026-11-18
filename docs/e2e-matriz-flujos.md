# Matriz de flujos E2E

Cada fila es un flujo de usuario o un error que la persona puede provocar. Una fila está `cubierto` cuando una prueba de `trueque-u/app/integration_test/` la ejecuta contra el backend y la base reales. Las filas `pendiente` llevan el número de brecha (1 a 14) del mapeo de la tarea `e2e-flow-coverage`.

Esta matriz es el criterio de aceptación: al cerrar la tarea, todas las filas deben estar en `cubierto`.

Columnas: **ID** (identificador estable), **Flujo o caso**, **Endpoint** (o pantalla), **Archivo** (en `integration_test/`), **Prueba** (nombre exacto), **Estado**.

## Acceso y cuenta

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| ACC-01 | Ver la pantalla de inicio con sus dos opciones | `UI /` | `acceso_test.dart` | Un visitante ve la pantalla de inicio con sus dos opciones | cubierto |
| ACC-02 | Ruta privada sin sesión redirige a iniciar sesión | `UI /perfil` | `acceso_test.dart` | Un visitante intenta abrir su perfil y lo mandan a iniciar sesión | cubierto |
| ACC-03 | Iniciar sesión | `POST /sesiones` | `acceso_test.dart` | Eudenia inicia sesión y ve su perfil | cubierto |
| ACC-04 | Iniciar sesión con contraseña incorrecta (401) | `POST /sesiones` | `acceso_test.dart` | Eudenia escribe mal su contraseña y ve el error | cubierto |
| ACC-05 | Iniciar sesión con campos vacíos (validación) | `POST /sesiones` | `acceso_test.dart` | Eudenia deja los campos vacíos y la app le pide los datos | cubierto |
| ACC-06 | Cerrar sesión | `DELETE /sesiones/actual` | `acceso_test.dart` | Eudenia cierra sesión desde su perfil | cubierto |
| ACC-07 | Crear cuenta | `POST /usuarios` | `acceso_test.dart` | Ana crea su cuenta y entra a su perfil | cubierto |
| ACC-08 | Crear cuenta con contraseñas distintas (validación) | `POST /usuarios` | `acceso_test.dart` | Ana escribe contraseñas distintas y la app se lo avisa | cubierto |
| ACC-09 | Crear cuenta con teléfono de menos de 8 dígitos (400) | `POST /usuarios` | `acceso_test.dart` | Ana usa un teléfono de menos de 8 dígitos y la app lo rechaza | cubierto |
| ACC-10 | Crear cuenta con un correo ya registrado (409) | `POST /usuarios` | `acceso_test.dart` | Ana intenta crear su cuenta con el correo de Eudenia y ve el error | cubierto |
| ACC-11 | Crear cuenta con correo inválido o nombre corto (400) | `POST /usuarios` | - | - | pendiente (brecha 3) |
| ACC-12 | Recuperar contraseña por correo | `POST /recuperaciones` | `acceso_test.dart` | Eudenia pide una contraseña nueva y la app le avisa que revise su correo | cubierto |
| ACC-13 | Recuperar contraseña con un correo que no existe (404) | `POST /recuperaciones` | `acceso_test.dart` | Ana pide recuperar un correo que no existe y ve el error | cubierto |
| ACC-14 | Volver a iniciar sesión desde recuperar contraseña | `UI /recuperar-contrasena` | `acceso_test.dart` | Eudenia vuelve a iniciar sesión desde la pantalla de recuperar | cubierto |
| ACC-15 | Iniciar sesión con la contraseña temporal recibida | `POST /sesiones` | - | - | pendiente (brecha 4) |
| ACC-16 | Cambiar contraseña y entrar con la nueva | `PUT /usuarios/contrasena` | `acceso_test.dart` | Eudenia cambia su contraseña y entra con la nueva | cubierto |
| ACC-17 | Cambiar contraseña con la actual incorrecta (400) | `PUT /usuarios/contrasena` | `acceso_test.dart` | Eudenia se equivoca con su contraseña actual y ve el error | cubierto |
| ACC-18 | Cambiar contraseña con una nueva muy corta (validación) | `PUT /usuarios/contrasena` | `acceso_test.dart` | Eudenia usa una contraseña nueva muy corta y la app se lo avisa | cubierto |
| ACC-19 | Cancelar el cambio de contraseña | `UI /cambiar-contrasena` | `acceso_test.dart` | Eudenia se arrepiente y cancela el cambio de contraseña | cubierto |
| ACC-20 | Con sesión iniciada, /iniciar-sesion y /registro redirigen a /feed | `UI /iniciar-sesion, /registro` | - | - | pendiente (brecha 9) |
| ACC-21 | Restaurar la sesión al recargar la app | `GET /sesiones/actual` | - | - | pendiente (brecha 10) |

## Publicaciones

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| PUB-01 | Publicar un objeto | `POST /publicaciones` | `publicaciones_test.dart` | Eudenia publica un libro usado y lo ve en sus publicaciones | cubierto |
| PUB-02 | Publicar con el nombre vacío (validación) | `POST /publicaciones` | `publicaciones_test.dart` | Eudenia deja el nombre vacío y la app se lo pide | cubierto |
| PUB-03 | Cancelar la publicación | `UI /publicacion` | `publicaciones_test.dart` | Eudenia cancela la publicación y vuelve a sus publicaciones | cubierto |
| PUB-04 | Publicar con foto | `POST /publicaciones` | - | - | pendiente (brecha 1) |
| PUB-05 | Editar con foto (cambiar o quitar la imagen) | `PUT /publicaciones/:id` | - | - | pendiente (brecha 1) |
| PUB-06 | Ver mis publicaciones | `GET /publicaciones/mias` | `publicaciones_test.dart` | Eudenia ve sus tres publicaciones | cubierto |
| PUB-07 | Lista vacía de mis publicaciones | `GET /publicaciones/mias` | `publicaciones_test.dart` | Ana todavía no publicó nada y ve el mensaje de lista vacía | cubierto |
| PUB-08 | Editar el título | `PUT /publicaciones/:id` | `publicaciones_test.dart` | Eudenia corrige el título de su chompa | cubierto |
| PUB-09 | Cancelar la edición | `UI /publicacion` | `publicaciones_test.dart` | Eudenia cancela la edición y su chompa queda igual | cubierto |
| PUB-10 | Editar bloqueado por reserva (409, la app oculta la acción) | `PUT /publicaciones/:id` | `publicaciones_test.dart` | Eudenia no puede editar la calculadora porque Job la reservó | cubierto |
| PUB-11 | Editar o reservar una publicación acordada (409) | `PUT /publicaciones/:id` | `intercambio_acordado_test.dart` | Una publicación acordada no se reserva ni se edita | cubierto |
| PUB-12 | Editar bloqueado por una oferta pendiente (409) | `PUT /publicaciones/:id` | - | - | pendiente (brecha 7) |
| PUB-13 | Ocultar una publicación | `PUT /publicaciones/:id/oculto` | `publicaciones_test.dart` | Eudenia oculta su chompa | cubierto |
| PUB-14 | Marcar como no disponible | `PUT /publicaciones/:id/no-disponible` | `publicaciones_test.dart` | Eudenia marca su chompa como no disponible | cubierto |
| PUB-15 | Ocultar y volver a dejar disponible | `PUT /publicaciones/:id/oculto` | `publicaciones_test.dart` | Eudenia oculta su chompa y después la vuelve a dejar disponible | cubierto |
| PUB-16 | Ocultar bloqueado por una oferta pendiente (409) | `PUT /publicaciones/:id/oculto` | `publicaciones_test.dart` | Eudenia no puede ocultar su libro de cálculo porque tiene una oferta pendiente | cubierto |
| PUB-17 | Marcar como no disponible bloqueado por una oferta pendiente (409) | `PUT /publicaciones/:id/no-disponible` | - | - | pendiente (brecha 7) |
| PUB-18 | Eliminar una publicación | `DELETE /publicaciones/:id` | `publicaciones_test.dart` | Eudenia elimina su chompa | cubierto |
| PUB-19 | Arrepentirse de eliminar | `UI /mis-publicaciones` | `publicaciones_test.dart` | Eudenia se arrepiente y no elimina su chompa | cubierto |
| PUB-20 | Eliminar bloqueado por una oferta pendiente (409) | `DELETE /publicaciones/:id` | `publicaciones_test.dart` | Eudenia no puede eliminar su libro de cálculo porque tiene una oferta pendiente | cubierto |
| PUB-21 | Eliminar bloqueado por reserva (la app oculta la acción) | `DELETE /publicaciones/:id` | `publicaciones_test.dart` | Eudenia no puede editar la calculadora porque Job la reservó | cubierto |
| PUB-22 | Completar el intercambio de una publicación reservada | `PUT /publicaciones/:id/intercambiado` | `publicaciones_test.dart` | Eudenia completa el intercambio de su calculadora reservada | cubierto |
| PUB-23 | Salir de mis publicaciones con la barra inferior | `UI /mis-publicaciones` | `publicaciones_test.dart` | Eudenia sale de sus publicaciones con la barra inferior | cubierto |
| PUB-24 | Consultar una publicación por id (solo API, sin pantalla) | `GET /publicaciones/:id` | - | - | pendiente (brecha 14) |

## Feed y reservas

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| FEE-01 | Abrir el feed y ver publicaciones recientes | `GET /publicaciones` | `feed_test.dart` | Eudenia abre el feed y ve las publicaciones recientes | cubierto |
| FEE-02 | Volver al perfil desde el feed | `UI /feed` | `feed_test.dart` | Eudenia vuelve al perfil desde el feed | cubierto |
| FEE-03 | Leer y cerrar la ayuda del feed | `UI /feed` | `feed_test.dart` | Eudenia lee la ayuda del feed y la cierra | cubierto |
| FEE-04 | Buscar por texto | `GET /publicaciones?buscar=` | `feed_test.dart` | Eudenia busca "Fisica" y solo ve el libro de Job | cubierto |
| FEE-05 | Búsqueda sin resultados y quitar filtros | `GET /publicaciones?buscar=` | `feed_test.dart` | Eudenia busca algo que no existe y quita el filtro | cubierto |
| FEE-06 | Filtrar por categoría | `GET /publicaciones?categoria=` | `feed_test.dart` | Eudenia filtra por la categoría Ropa | cubierto |
| FEE-07 | Filtrar por condición | `GET /publicaciones?condicion=` | `feed_test.dart` | Eudenia filtra por la condición Nuevo | cubierto |
| FEE-08 | Filtrar por disponibilidad | `GET /publicaciones?disponibilidad=` | `feed_test.dart` | Eudenia filtra por disponibilidad Intercambiado y ve los audífonos de Job | cubierto |
| FEE-09 | Combinar filtros y quitarlos todos | `GET /publicaciones` | `feed_test.dart` | Eudenia combina dos filtros y luego los quita todos | cubierto |
| FEE-10 | Reservar una publicación | `PUT /publicaciones/:id/reservado` | `feed_test.dart` | Eudenia reserva el libro de Física de Job | cubierto |
| FEE-11 | Cancelar la reserva propia | `PUT /publicaciones/:id/disponible` | `feed_test.dart` | Eudenia reserva el libro de Física y después cancela su reserva | cubierto |
| FEE-12 | Arrepentirse de cancelar la reserva | `UI /feed` | `feed_test.dart` | Eudenia piensa cancelar su reserva pero decide mantenerla | cubierto |
| FEE-13 | Completar el intercambio desde el feed | `PUT /publicaciones/:id/intercambiado` | `feed_test.dart` | Eudenia reserva el libro de Física y completa el intercambio desde el feed | cubierto |
| FEE-14 | Reservar con una oferta pendiente (409) | `PUT /publicaciones/:id/reservado` | `feed_test.dart` | Job intenta reservar el libro de Cálculo pero tiene una oferta pendiente | cubierto |
| FEE-15 | Ver la reserva propia | `GET /publicaciones` | `feed_test.dart` | Job ve que ya reservó la calculadora de Eudenia | cubierto |
| FEE-16 | Ver una publicación reservada por otra persona sin poder reservarla | `GET /publicaciones` | `feed_test.dart` | Carlos ve la calculadora reservada por otra persona sin poder reservarla | cubierto |
| FEE-17 | Ver la publicación propia y saltar a Mis publicaciones | `GET /publicaciones` | `feed_test.dart` | Eudenia ve su propia publicación y salta a Mis publicaciones | cubierto |
| FEE-18 | Cancelar la reserva de otra persona (403) | `PUT /publicaciones/:id/disponible` | - | - | pendiente (brecha 5) |
| FEE-19 | Reservar una publicación ya intercambiada o no disponible (409) | `PUT /publicaciones/:id/reservado` | - | - | pendiente (brecha 6) |
| FEE-20 | Botón de WhatsApp para contactar a la otra persona | `UI /feed` | - | - | pendiente (brecha 12) |

## Ofertas y contraofertas

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| OFE-01 | Enviar una oferta | `POST /ofertas` | `ofertas_test.dart` | Job envía una oferta por la chompa de Eudenia con su libro de Física | cubierto |
| OFE-02 | Ver la oferta en enviadas | `GET /ofertas/enviadas` | `ofertas_test.dart` | Job ve su oferta en la lista de enviadas | cubierto |
| OFE-03 | El receptor ve la oferta recibida | `GET /ofertas/recibidas` | `ofertas_test.dart` | Eudenia recibe la oferta que Job le envió por su chompa | cubierto |
| OFE-04 | Cerrar el cuadro de oferta sin enviar | `UI /feed` | `ofertas_test.dart` | Job se arrepiente y cierra el cuadro de oferta sin enviar nada | cubierto |
| OFE-05 | No enviar sin elegir uno de sus objetos (validación) | `POST /ofertas` | `ofertas_test.dart` | Job no puede enviar la oferta hasta elegir uno de sus objetos | cubierto |
| OFE-06 | Usar el mismo objeto en dos ofertas (409) | `POST /ofertas` | `ofertas_test.dart` | Job usa el mismo libro en dos ofertas y la app le avisa | cubierto |
| OFE-07 | Sin objetos para ofrecer, la app propone crear uno | `GET /publicaciones/mias` | `ofertas_test.dart` | Ana no tiene objetos para ofrecer y la app le propone crear uno | cubierto |
| OFE-08 | Ofertar por una publicación propia o con un objeto ajeno (403) | `POST /ofertas` | - | - | pendiente (brecha 8) |
| OFE-09 | Ver la oferta recibida | `GET /ofertas/recibidas` | `ofertas_test.dart` | Eudenia ve la oferta de Carlos por su libro de Cálculo | cubierto |
| OFE-10 | Aceptar una oferta | `PUT /ofertas/:id/aceptada` | `ofertas_test.dart` | Eudenia acepta la oferta de Carlos | cubierto |
| OFE-11 | Rechazar una oferta | `PUT /ofertas/:id/rechazada` | `ofertas_test.dart` | Eudenia rechaza la oferta de Carlos | cubierto |
| OFE-12 | Arrepentirse y no responder la oferta | `UI /ofertas` | `ofertas_test.dart` | Eudenia piensa en la oferta de Carlos y decide no responder todavía | cubierto |
| OFE-13 | Sin ofertas recibidas, la app sugiere explorar | `GET /ofertas/recibidas` | `ofertas_test.dart` | Job no recibió ofertas y la app le sugiere explorar publicaciones | cubierto |
| OFE-14 | Otras ofertas se cancelan al aceptar una | `PUT /ofertas/:id/aceptada` | `ofertas_test.dart` | Job ve cancelada su oferta cuando Eudenia acepta la de Carlos | cubierto |
| OFE-15 | Ver la oferta enviada | `GET /ofertas/enviadas` | `ofertas_test.dart` | Carlos ve la oferta que envió a Eudenia | cubierto |
| OFE-16 | Cancelar una oferta enviada | `PUT /ofertas/:id/cancelada` | `ofertas_test.dart` | Carlos cancela la oferta que envió | cubierto |
| OFE-17 | Una oferta cancelada ya no se puede aceptar | `PUT /ofertas/:id/aceptada` | `ofertas_test.dart` | Carlos cancela la oferta y Eudenia ya no puede aceptarla | cubierto |
| OFE-18 | Sin ofertas enviadas | `GET /ofertas/enviadas` | `ofertas_test.dart` | Job todavía no envió ofertas y la app se lo cuenta | cubierto |
| OFE-19 | Volver al perfil desde ofertas | `UI /ofertas` | `ofertas_test.dart` | Carlos vuelve al perfil desde las ofertas | cubierto |
| OFE-20 | Aceptar la oferta de otra persona (403, no se acepta la propia contraoferta) | `PUT /ofertas/:id/aceptada` | `contraofertas_test.dart` | Eudenia no puede aceptar su propia contraoferta | cubierto |
| OFE-21 | Contraofertar | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Eudenia responde la oferta de Carlos con una contraoferta | cubierto |
| OFE-22 | Contraofertar solo con objetos disponibles | `GET /publicaciones/mias` | `contraofertas_test.dart` | Eudenia solo ve los objetos disponibles de Carlos al contraofertar | cubierto |
| OFE-23 | Cerrar el cuadro de contraoferta sin enviar | `UI /ofertas` | `contraofertas_test.dart` | Eudenia cierra el cuadro de contraoferta sin enviar nada | cubierto |
| OFE-24 | El receptor recibe la contraoferta y puede responderla | `GET /ofertas/recibidas` | `contraofertas_test.dart` | Carlos recibe la contraoferta de Eudenia y puede responderla | cubierto |
| OFE-25 | Ver el historial de la negociación (receptor) | `GET /ofertas/:id/historial` | `contraofertas_test.dart` | Carlos ve el historial de la negociacion con Eudenia | cubierto |
| OFE-26 | Ver el historial de la negociación (emisor) | `GET /ofertas/:id/historial` | `contraofertas_test.dart` | Eudenia también ve el historial desde sus ofertas enviadas | cubierto |
| OFE-27 | Ver el historial de una negociación ajena (403) | `GET /ofertas/:id/historial` | `contraofertas_test.dart` | Job no puede ver la negociacion entre Eudenia y Carlos | cubierto |
| OFE-28 | Aceptar la contraoferta cierra la negociación | `PUT /ofertas/:id/aceptada` | `contraofertas_test.dart` | Carlos acepta la contraoferta y la negociacion se cierra | cubierto |
| OFE-29 | Rechazar la contraoferta | `PUT /ofertas/:id/rechazada` | `contraofertas_test.dart` | Carlos rechaza la contraoferta de Eudenia | cubierto |
| OFE-30 | Contraofertar una negociación cerrada (409) | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Nadie puede contraofertar una negociacion cerrada | cubierto |
| OFE-31 | Contraofertar una negociación ya aceptada (409) | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Nadie puede contraofertar una negociacion ya aceptada | cubierto |
| OFE-32 | Contraofertar una negociación ajena (403) | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Job no puede contraofertar la negociacion de Eudenia y Carlos | cubierto |
| OFE-33 | Negociar varias rondas | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Eudenia y Carlos negocian tres rondas | cubierto |
| OFE-34 | Cancelar la contraoferta propia | `PUT /ofertas/:id/cancelada` | `contraofertas_test.dart` | Carlos cancela su contraoferta | cubierto |
| OFE-35 | Reusar un objeto que ya está en otra oferta pendiente (409) | `POST /ofertas/:id/contraoferta` | `contraofertas_test.dart` | Carlos no puede reusar un objeto que ya está en otra oferta pendiente | cubierto |

## Intercambios y entrega

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| ENT-01 | Confirmar la entrega (primera parte) | `PUT /ofertas/:id/entrega` | `intercambio_acordado_test.dart` | Eudenia confirma primero y el intercambio todavía no se completa | cubierto |
| ENT-02 | Confirmar la entrega (segunda parte) y completar | `PUT /ofertas/:id/entrega` | `intercambio_acordado_test.dart` | Carlos confirma después y el intercambio queda completado | cubierto |
| ENT-03 | Cancelar el intercambio acordado con motivo | `PUT /ofertas/:id/anulada` | `intercambio_acordado_test.dart` | Eudenia cancela con motivo y su libro vuelve a estar disponible | cubierto |
| ENT-04 | Cancelar no reactiva ofertas anteriores y conserva el historial | `PUT /ofertas/:id/anulada` | `intercambio_acordado_test.dart` | Cancelar no reactiva las ofertas anteriores y conserva el historial | cubierto |
| ENT-05 | Cancelar sin motivo (validación) | `PUT /ofertas/:id/anulada` | `intercambio_acordado_test.dart` | Cancelar sin escribir el motivo no deja enviar | cubierto |
| ENT-06 | Confirmar la entrega siendo un tercero (403) o dos veces (409) | `PUT /ofertas/:id/entrega` | `intercambio_acordado_test.dart` | Solo participan las dos partes y cada una confirma una vez | cubierto |
| ENT-07 | Cancelar sin motivo (400), como tercero (403) y confirmar tras cancelar (409) | `PUT /ofertas/:id/anulada` | `intercambio_acordado_test.dart` | Cancelar exige motivo y después ya no se puede confirmar | cubierto |
| ENT-08 | Ver los intercambios completados (entregó) | `GET /publicaciones/intercambiadas` | `intercambios_historial_test.dart` | Job ve que entregó sus audífonos a Carlos | cubierto |
| ENT-09 | Ver los intercambios completados (recibió) | `GET /publicaciones/intercambiadas` | `intercambios_historial_test.dart` | Carlos ve que recibió los audífonos de Job | cubierto |
| ENT-10 | Sin intercambios completados | `GET /publicaciones/intercambiadas` | `intercambios_historial_test.dart` | Eudenia todavía no completó ningún intercambio | cubierto |
| ENT-11 | Aceptar, confirmar entre los dos y ver el intercambio completado | `PUT /ofertas/:id/aceptada` | `intercambios_historial_test.dart` | Eudenia acepta la oferta de Carlos, los dos confirman y ve el intercambio completado | cubierto |
| ENT-12 | Volver al perfil desde intercambios | `UI /intercambios` | `intercambios_historial_test.dart` | Job vuelve al perfil desde sus intercambios | cubierto |
| ENT-13 | Proponer, contraproponer, aceptar y reprogramar la entrega | `POST /propuestas-entrega, PUT /propuestas-entrega/:id/aceptada` | `coordinar_entrega_test.dart` | propuesta, contrapropuesta, aceptación y una reprogramación aceptada | cubierto |
| ENT-14 | Coordinar siendo un tercero (403) o aceptar la propia propuesta (403) | `GET/POST/PUT /propuestas-entrega` | `coordinar_entrega_test.dart` | Solo las dos partes participan y nadie responde su propia propuesta | cubierto |
| ENT-15 | Una sola propuesta pendiente (409); el acuerdo vigente no cambia hasta aceptar | `POST /propuestas-entrega` | `coordinar_entrega_test.dart` | Solo hay una propuesta pendiente y el acuerdo vigente no cambia hasta aceptar | cubierto |
| ENT-16 | Coordinar antes de aceptar la oferta o tras terminar el intercambio (409) | `POST /propuestas-entrega` | `coordinar_entrega_test.dart` | No se coordina antes de aceptar la oferta ni después de terminar el intercambio | cubierto |
| ENT-17 | Propuesta con datos incompletos o fecha pasada (validación y 400) | `POST /propuestas-entrega` | `coordinar_entrega_test.dart` | Datos incompletos o una fecha pasada no se envían | cubierto |

## Calificaciones

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| CAL-01 | Calificar a la otra parte y ver el promedio en el perfil | `POST /calificaciones, GET /calificaciones/resumen` | `calificar_intercambio_test.dart` | Ambas partes califican con estrellas y el perfil muestra el promedio y la cantidad | cubierto |
| CAL-02 | El perfil promedia todas las calificaciones recibidas | `GET /calificaciones/resumen` | `calificar_intercambio_test.dart` | El perfil promedia todas las calificaciones que recibe | cubierto |
| CAL-03 | Calificar dos veces el mismo intercambio (409) | `POST /calificaciones` | `calificar_intercambio_test.dart` | Cada parte califica una sola vez y la segunda calificación se rechaza | cubierto |
| CAL-04 | Calificar un intercambio cancelado o sin completar (409) | `POST /calificaciones` | `calificar_intercambio_test.dart` | Un intercambio cancelado o sin completar no se califica | cubierto |
| CAL-05 | Calificar como tercero (403) o con puntaje o comentario fuera de rango (400) | `POST /calificaciones` | `calificar_intercambio_test.dart` | Solo las dos partes califican y el puntaje es de 1 a 5 | cubierto |
| CAL-06 | Cerrar el diálogo de calificación sin enviar | `UI /ofertas` | `analitica_calificaciones_test.dart` | Cerrar el diálogo sin enviar solo registra calificacion_iniciada | cubierto |
| CAL-07 | Calificación de una cuenta eliminada se conserva como Usuario eliminado | `GET /calificaciones/resumen` | `salida_honesta_test.dart` | La calificación de una cuenta eliminada queda y Carlos ve Usuario eliminado | cubierto |

## Historial

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| HIS-01 | Ver los movimientos del historial | `GET /historial` | `intercambios_historial_test.dart` | Job ve sus tres movimientos de ejemplo | cubierto |
| HIS-02 | Ver la reserva que otra persona hizo | `GET /historial` | `intercambios_historial_test.dart` | Eudenia ve que Job reservó su calculadora | cubierto |
| HIS-03 | Filtrar el historial por reservas | `GET /historial?tipo=reservas` | `intercambios_historial_test.dart` | Job filtra su historial por reservas | cubierto |
| HIS-04 | Filtrar el historial por completados | `GET /historial?tipo=completados` | `intercambios_historial_test.dart` | Job filtra su historial por completados | cubierto |
| HIS-05 | Abrir y cerrar el detalle de un movimiento | `UI /historial` | `intercambios_historial_test.dart` | Job abre el detalle de un movimiento y lo cierra | cubierto |
| HIS-06 | Historial vacío | `GET /historial` | `intercambios_historial_test.dart` | Ana todavía no tiene movimientos en su historial | cubierto |
| HIS-07 | Una reserva nueva aparece en el historial | `GET /historial` | `intercambios_historial_test.dart` | Eudenia reserva el libro de Física y lo ve en su historial | cubierto |
| HIS-08 | Cancelar una reserva queda registrado en el historial | `GET /historial` | `intercambios_historial_test.dart` | Eudenia cancela su reserva y el historial lo registra | cubierto |
| HIS-09 | Volver al perfil desde el historial | `UI /historial` | `intercambios_historial_test.dart` | Eudenia vuelve al perfil desde su historial | cubierto |
| HIS-10 | Historial con un tipo inválido (400, solo API) | `GET /historial?tipo=` | - | - | pendiente (brecha 13) |

## Avisos, Mis datos y cuenta

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| AVI-01 | Ver mis datos y descargarlos (JSON y CSV) | `GET /usuarios/yo/datos` | `salida_honesta_test.dart` | Eudenia ve sus datos y al descargarlos se registra datos_descargados | cubierto |
| AVI-02 | Quitar el teléfono guardado | `DELETE /usuarios/yo/telefono` | - | - | pendiente (brecha 2) |
| AVI-03 | Eliminar la cuenta con la contraseña incorrecta (401) | `DELETE /usuarios/yo` | `salida_honesta_test.dart` | Eudenia se equivoca de contraseña, no se borra nada y se registra el bloqueo | cubierto |
| AVI-04 | Eliminar la cuenta con un trueque acordado y avisar a la otra parte | `DELETE /usuarios/yo, GET /notificaciones` | `salida_honesta_test.dart` | Eudenia elimina su cuenta con un trueque acordado y Carlos recibe el aviso | cubierto |
| AVI-05 | Ver el aviso en la pantalla de avisos | `GET /notificaciones` | `salida_honesta_test.dart` | Eudenia elimina su cuenta con un trueque acordado y Carlos recibe el aviso | cubierto |
| AVI-06 | Una cuenta eliminada ya no inicia sesión (401) | `POST /sesiones` | `salida_honesta_test.dart` | Quien eliminó su cuenta ya no puede iniciar sesión | cubierto |
| AVI-07 | Marcar un aviso como leído | `PUT /notificaciones/:id/leida` | - | - | pendiente (brecha 11) |

## Eventos y analítica

| ID | Flujo o caso | Endpoint | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| EVE-01 | Registrar calificacion_iniciada y calificacion_enviada | `POST /eventos, GET /analitica` | `analitica_calificaciones_test.dart` | Calificar registra calificacion_iniciada y calificacion_enviada | cubierto |
| EVE-02 | Cerrar sin enviar solo registra calificacion_iniciada | `POST /eventos, GET /analitica` | `analitica_calificaciones_test.dart` | Cerrar el diálogo sin enviar solo registra calificacion_iniciada | cubierto |
| EVE-03 | Descargar datos registra datos_descargados | `POST /eventos` | `salida_honesta_test.dart` | Eudenia ve sus datos y al descargarlos se registra datos_descargados | cubierto |
| EVE-04 | Rechazar un evento con datos personales (400) | `POST /eventos` | `salida_honesta_test.dart` | El servidor rechaza un evento con datos personales y no los guarda | cubierto |
| EVE-05 | Los eventos guardados no tienen claves personales | `POST /eventos` | `salida_honesta_test.dart` | Los eventos de este flujo guardados no tienen claves personales | cubierto |

## Totales

| Área | Cubiertos | Total | % |
|---|---|---|---|
| Acceso y cuenta | 17 | 21 | 81.0% |
| Publicaciones | 19 | 24 | 79.2% |
| Feed y reservas | 17 | 20 | 85.0% |
| Ofertas y contraofertas | 34 | 35 | 97.1% |
| Intercambios y entrega | 17 | 17 | 100.0% |
| Calificaciones | 7 | 7 | 100.0% |
| Historial | 9 | 10 | 90.0% |
| Avisos, Mis datos y cuenta | 5 | 7 | 71.4% |
| Eventos y analítica | 5 | 5 | 100.0% |
| **Total** | **130** | **146** | **89.0%** |

Flujos cubiertos: 130 de 146 (89.0%). Pendientes: 16 (brechas 1 a 14; las brechas 1 y 7 ocupan dos filas cada una).
