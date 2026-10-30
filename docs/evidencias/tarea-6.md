# Tarea 6 - Pruebas de punta a punta y contraofertas

## Que se hizo

1. Se escribieron pruebas E2E con `integration_test` para todos los flujos de la app (acceso, publicaciones, feed, ofertas, intercambios e historial).
2. Se corrio toda la suite **antes** de tocar la feature.
3. Se agrego la feature de **contraofertas**: quien recibe una oferta puede responder con otra, los dos ven el historial de la negociacion y cuando alguien acepta la negociacion se cierra.
4. Se volvio a correr toda la suite **despues** de la feature.

## Como se corren las pruebas

Las pruebas usan la app real contra el backend real y la base en Docker. Antes de cada prueba se reinicia la base con los datos de ejemplo.

```bash
cd trueque-u
docker compose up -d
node app/integration_test/herramientas/entorno_e2e.js
msedgedriver --port=4445
node app/integration_test/herramientas/puente_edge.js
cd app
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<archivo>_test.dart -d web-server --browser-name=chrome --chrome-binary="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless
```

Backend:

```bash
cd trueque-u/backend
npm test
```

Se probo en Edge (web) porque en la maquina no esta instalado Visual Studio y `flutter test integration_test -d windows` no compila (la salida esta en `tarea-6/suite-antes-flutter.txt`).

## Resumen

| Suite | Antes | Despues |
|---|---|---|
| Backend (jest) | 4 suites, 38 de 38 pasan | 6 suites, 57 de 57 pasan |
| E2E Flutter | 5 archivos, 83 de 83 pasan | 6 archivos, 99 de 99 pasan |

Las salidas completas estan en la carpeta `tarea-6/`.

## Matriz de pruebas E2E

| # | Archivo | Flujo | Prueba | Antes | Despues |
|---|---|---|---|---|---|
| 1 | acceso_test.dart | Pantalla de inicio | Un visitante ve la pantalla de inicio con sus dos opciones | Pasa | Pasa |
| 2 | acceso_test.dart | Pantalla de inicio | Un visitante intenta abrir su perfil y lo mandan a iniciar sesión | Pasa | Pasa |
| 3 | acceso_test.dart | Iniciar sesión | Eudenia inicia sesión y ve su perfil | Pasa | Pasa |
| 4 | acceso_test.dart | Iniciar sesión | Eudenia escribe mal su contraseña y ve el error | Pasa | Pasa |
| 5 | acceso_test.dart | Iniciar sesión | Eudenia deja los campos vacíos y la app le pide los datos | Pasa | Pasa |
| 6 | acceso_test.dart | Iniciar sesión | Eudenia cierra sesión desde su perfil | Pasa | Pasa |
| 7 | acceso_test.dart | Crear cuenta | Ana crea su cuenta y entra a su perfil | Pasa | Pasa |
| 8 | acceso_test.dart | Crear cuenta | Ana escribe contraseñas distintas y la app se lo avisa | Pasa | Pasa |
| 9 | acceso_test.dart | Crear cuenta | Ana usa un teléfono de menos de 8 dígitos y la app lo rechaza | Pasa | Pasa |
| 10 | acceso_test.dart | Crear cuenta | Ana intenta crear su cuenta con el correo de Eudenia y ve el error | Pasa | Pasa |
| 11 | acceso_test.dart | Recuperar contraseña | Eudenia pide una contraseña nueva y la app le avisa que revise su correo | Pasa | Pasa |
| 12 | acceso_test.dart | Recuperar contraseña | Ana pide recuperar un correo que no existe y ve el error | Pasa | Pasa |
| 13 | acceso_test.dart | Recuperar contraseña | Eudenia vuelve a iniciar sesión desde la pantalla de recuperar | Pasa | Pasa |
| 14 | acceso_test.dart | Cambiar contraseña | Eudenia cambia su contraseña y entra con la nueva | Pasa | Pasa |
| 15 | acceso_test.dart | Cambiar contraseña | Eudenia se equivoca con su contraseña actual y ve el error | Pasa | Pasa |
| 16 | acceso_test.dart | Cambiar contraseña | Eudenia usa una contraseña nueva muy corta y la app se lo avisa | Pasa | Pasa |
| 17 | acceso_test.dart | Cambiar contraseña | Eudenia se arrepiente y cancela el cambio de contraseña | Pasa | Pasa |
| 18 | publicaciones_test.dart | Publicar un objeto | Eudenia publica un libro usado y lo ve en sus publicaciones | Pasa | Pasa |
| 19 | publicaciones_test.dart | Publicar un objeto | Eudenia deja el nombre vacío y la app se lo pide | Pasa | Pasa |
| 20 | publicaciones_test.dart | Publicar un objeto | Eudenia cancela la publicación y vuelve a su perfil | Pasa | Pasa |
| 21 | publicaciones_test.dart | Mis publicaciones | Eudenia ve sus tres publicaciones | Pasa | Pasa |
| 22 | publicaciones_test.dart | Mis publicaciones | Ana todavía no publicó nada y ve el mensaje de lista vacía | Pasa | Pasa |
| 23 | publicaciones_test.dart | Mis publicaciones | Eudenia corrige el título de su chompa | Pasa | Pasa |
| 24 | publicaciones_test.dart | Mis publicaciones | Eudenia cancela la edición y su chompa queda igual | Pasa | Pasa |
| 25 | publicaciones_test.dart | Mis publicaciones | Eudenia no puede editar la calculadora porque Job la reservó | Pasa | Pasa |
| 26 | publicaciones_test.dart | Mis publicaciones | Eudenia oculta su chompa | Pasa | Pasa |
| 27 | publicaciones_test.dart | Mis publicaciones | Eudenia marca su chompa como no disponible | Pasa | Pasa |
| 28 | publicaciones_test.dart | Mis publicaciones | Eudenia oculta su chompa y después la vuelve a dejar disponible | Pasa | Pasa |
| 29 | publicaciones_test.dart | Mis publicaciones | Eudenia no puede ocultar su libro de cálculo porque tiene una oferta pendiente | Pasa | Pasa |
| 30 | publicaciones_test.dart | Mis publicaciones | Eudenia elimina su chompa | Pasa | Pasa |
| 31 | publicaciones_test.dart | Mis publicaciones | Eudenia se arrepiente y no elimina su chompa | Pasa | Pasa |
| 32 | publicaciones_test.dart | Mis publicaciones | Eudenia no puede eliminar su libro de cálculo porque tiene una oferta pendiente | Pasa | Pasa |
| 33 | publicaciones_test.dart | Mis publicaciones | Eudenia completa el intercambio de su calculadora reservada | Pasa | Pasa |
| 34 | publicaciones_test.dart | Mis publicaciones | Eudenia sale de sus publicaciones con el botón de volver al perfil | Pasa | Pasa |
| 35 | feed_test.dart | Explorar el feed | Eudenia abre el feed y ve las publicaciones recientes | Pasa | Pasa |
| 36 | feed_test.dart | Explorar el feed | Eudenia vuelve al perfil desde el feed | Pasa | Pasa |
| 37 | feed_test.dart | Explorar el feed | Eudenia lee la ayuda del feed y la cierra | Pasa | Pasa |
| 38 | feed_test.dart | Buscar y filtrar | Eudenia busca "Fisica" y solo ve el libro de Job | Pasa | Pasa |
| 39 | feed_test.dart | Buscar y filtrar | Eudenia busca algo que no existe y quita el filtro | Pasa | Pasa |
| 40 | feed_test.dart | Buscar y filtrar | Eudenia filtra por la categoría Ropa | Pasa | Pasa |
| 41 | feed_test.dart | Buscar y filtrar | Eudenia filtra por la condición Nuevo | Pasa | Pasa |
| 42 | feed_test.dart | Buscar y filtrar | Eudenia filtra por disponibilidad Intercambiado y ve los audífonos de Job | Pasa | Pasa |
| 43 | feed_test.dart | Buscar y filtrar | Eudenia combina dos filtros y luego los quita todos | Pasa | Pasa |
| 44 | feed_test.dart | Reservar | Eudenia reserva el libro de Física de Job | Pasa | Pasa |
| 45 | feed_test.dart | Reservar | Eudenia reserva el libro de Física y después cancela su reserva | Pasa | Pasa |
| 46 | feed_test.dart | Reservar | Eudenia piensa cancelar su reserva pero decide mantenerla | Pasa | Pasa |
| 47 | feed_test.dart | Reservar | Eudenia reserva el libro de Física y completa el intercambio desde el feed | Pasa | Pasa |
| 48 | feed_test.dart | Reservar | Job intenta reservar el libro de Cálculo pero tiene una oferta pendiente | Pasa | Pasa |
| 49 | feed_test.dart | Reservar | Job ve que ya reservó la calculadora de Eudenia | Pasa | Pasa |
| 50 | feed_test.dart | Reservar | Carlos ve la calculadora reservada por otra persona sin poder reservarla | Pasa | Pasa |
| 51 | feed_test.dart | Reservar | Eudenia ve su propia publicación y salta a Mis publicaciones | Pasa | Pasa |
| 52 | ofertas_test.dart | Enviar una oferta | Job envía una oferta por la chompa de Eudenia con su libro de Física | Pasa | Pasa |
| 53 | ofertas_test.dart | Enviar una oferta | Job ve su oferta en la lista de enviadas | Pasa | Pasa |
| 54 | ofertas_test.dart | Enviar una oferta | Eudenia recibe la oferta que Job le envió por su chompa | Pasa | Pasa |
| 55 | ofertas_test.dart | Enviar una oferta | Job se arrepiente y cierra el cuadro de oferta sin enviar nada | Pasa | Pasa |
| 56 | ofertas_test.dart | Enviar una oferta | Job no puede enviar la oferta hasta elegir uno de sus objetos | Pasa | Pasa |
| 57 | ofertas_test.dart | Enviar una oferta | Job usa el mismo libro en dos ofertas y la app le avisa | Pasa | Pasa |
| 58 | ofertas_test.dart | Enviar una oferta | Ana no tiene objetos para ofrecer y la app le propone crear uno | Pasa | Pasa |
| 59 | ofertas_test.dart | Ofertas recibidas | Eudenia ve la oferta de Carlos por su libro de Cálculo | Pasa | Pasa |
| 60 | ofertas_test.dart | Ofertas recibidas | Eudenia acepta la oferta de Carlos | Pasa | Pasa |
| 61 | ofertas_test.dart | Ofertas recibidas | Eudenia rechaza la oferta de Carlos | Pasa | Pasa |
| 62 | ofertas_test.dart | Ofertas recibidas | Eudenia piensa en la oferta de Carlos y decide no responder todavía | Pasa | Pasa |
| 63 | ofertas_test.dart | Ofertas recibidas | Job no recibió ofertas y la app le sugiere explorar publicaciones | Pasa | Pasa |
| 64 | ofertas_test.dart | Ofertas recibidas | Job ve cancelada su oferta cuando Eudenia acepta la de Carlos | Pasa | Pasa |
| 65 | ofertas_test.dart | Ofertas enviadas | Carlos ve la oferta que envió a Eudenia | Pasa | Pasa |
| 66 | ofertas_test.dart | Ofertas enviadas | Carlos cancela la oferta que envió | Pasa | Pasa |
| 67 | ofertas_test.dart | Ofertas enviadas | Carlos cancela la oferta y Eudenia ya no puede aceptarla | Pasa | Pasa |
| 68 | ofertas_test.dart | Ofertas enviadas | Job todavía no envió ofertas y la app se lo cuenta | Pasa | Pasa |
| 69 | ofertas_test.dart | Ofertas enviadas | Carlos vuelve al perfil desde las ofertas | Pasa | Pasa |
| 70 | intercambios_historial_test.dart | Intercambios completados | Job ve que entregó sus audífonos a Carlos | Pasa | Pasa |
| 71 | intercambios_historial_test.dart | Intercambios completados | Carlos ve que recibió los audífonos de Job | Pasa | Pasa |
| 72 | intercambios_historial_test.dart | Intercambios completados | Eudenia todavía no completó ningún intercambio | Pasa | Pasa |
| 73 | intercambios_historial_test.dart | Intercambios completados | Eudenia acepta la oferta de Carlos y ve el intercambio completado | Pasa | Pasa |
| 74 | intercambios_historial_test.dart | Intercambios completados | Job vuelve al perfil desde sus intercambios | Pasa | Pasa |
| 75 | intercambios_historial_test.dart | Historial | Job ve sus tres movimientos de ejemplo | Pasa | Pasa |
| 76 | intercambios_historial_test.dart | Historial | Eudenia ve que Job reservó su calculadora | Pasa | Pasa |
| 77 | intercambios_historial_test.dart | Historial | Job filtra su historial por reservas | Pasa | Pasa |
| 78 | intercambios_historial_test.dart | Historial | Job filtra su historial por completados | Pasa | Pasa |
| 79 | intercambios_historial_test.dart | Historial | Job abre el detalle de un movimiento y lo cierra | Pasa | Pasa |
| 80 | intercambios_historial_test.dart | Historial | Ana todavía no tiene movimientos en su historial | Pasa | Pasa |
| 81 | intercambios_historial_test.dart | Historial | Eudenia reserva el libro de Física y lo ve en su historial | Pasa | Pasa |
| 82 | intercambios_historial_test.dart | Historial | Eudenia cancela su reserva y el historial lo registra | Pasa | Pasa |
| 83 | intercambios_historial_test.dart | Historial | Eudenia vuelve al perfil desde su historial | Pasa | Pasa |
| 84 | contraofertas_test.dart | Responder con una contraoferta | Eudenia responde la oferta de Carlos con una contraoferta | No existia | Pasa |
| 85 | contraofertas_test.dart | Responder con una contraoferta | Eudenia solo ve los objetos disponibles de Carlos al contraofertar | No existia | Pasa |
| 86 | contraofertas_test.dart | Responder con una contraoferta | Eudenia cierra el cuadro de contraoferta sin enviar nada | No existia | Pasa |
| 87 | contraofertas_test.dart | Responder con una contraoferta | Carlos recibe la contraoferta de Eudenia y puede responderla | No existia | Pasa |
| 88 | contraofertas_test.dart | Historial de la negociación | Carlos ve el historial de la negociacion con Eudenia | No existia | Pasa |
| 89 | contraofertas_test.dart | Historial de la negociación | Eudenia también ve el historial desde sus ofertas enviadas | No existia | Pasa |
| 90 | contraofertas_test.dart | Historial de la negociación | Job no puede ver la negociacion entre Eudenia y Carlos | No existia | Pasa |
| 91 | contraofertas_test.dart | Cerrar la negociación | Carlos acepta la contraoferta y la negociacion se cierra | No existia | Pasa |
| 92 | contraofertas_test.dart | Cerrar la negociación | Carlos rechaza la contraoferta de Eudenia | No existia | Pasa |
| 93 | contraofertas_test.dart | Cerrar la negociación | Eudenia no puede aceptar su propia contraoferta | No existia | Pasa |
| 94 | contraofertas_test.dart | Cerrar la negociación | Nadie puede contraofertar una negociacion cerrada | No existia | Pasa |
| 95 | contraofertas_test.dart | Cerrar la negociación | Nadie puede contraofertar una negociacion ya aceptada | No existia | Pasa |
| 96 | contraofertas_test.dart | Cerrar la negociación | Job no puede contraofertar la negociacion de Eudenia y Carlos | No existia | Pasa |
| 97 | contraofertas_test.dart | Varias rondas | Eudenia y Carlos negocian tres rondas | No existia | Pasa |
| 98 | contraofertas_test.dart | Varias rondas | Carlos cancela su contraoferta | No existia | Pasa |
| 99 | contraofertas_test.dart | Varias rondas | Carlos no puede reusar un objeto que ya está en otra oferta pendiente | No existia | Pasa |

## Pruebas del backend

| Archivo | Que prueba | Antes | Despues |
|---|---|---|---|
| historial.controlador.test.js | Consultar el historial | Pasa | Pasa |
| historial.registro.test.js | Registrar movimientos en el historial | Pasa | Pasa |
| publicaciones.controlador.test.js | Publicaciones, reservas e intercambios | Pasa | Pasa |
| utils/reglaObjeto.test.js | Reglas para crear una oferta | Pasa | Pasa |
| utils/reglaContraoferta.test.js | Reglas para contraofertar | No existia | Pasa (11) |
| controllers/ofertas.controlador.test.js | Contraoferta, historial y cierre de la negociacion | No existia | Pasa (8) |

## Cambios de la feature

- Base de datos: `migracion_contraofertas.sql` agrega `id_negociacion`, `id_oferta_anterior` y el estado `contraofertada`.
- Backend: `POST /api/ofertas/:id/contraoferta` y `GET /api/ofertas/:id/historial`. Aceptar y rechazar ahora lo hace quien recibio la ultima propuesta.
- App: en Ofertas cada tarjeta muestra la ronda, el boton "Ver historial" y el boton "Contraofertar" en las recibidas pendientes. La ayuda del feed explica las contraofertas.
