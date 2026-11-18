# Reporte de pruebas E2E

Ejecución de referencia: [run 44383837877](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877) (workflow E2E, commit `606127e`, conclusión: success).

## Alcance de la cobertura

La cobertura E2E se mide como cobertura de flujos de usuario y no como cobertura de líneas. Cada flujo identificado está asociado a al menos una prueba E2E en la [matriz de flujos](../e2e-matriz-flujos.md), que alcanza 152/152 flujos cubiertos (100%).

## Resumen

| Archivos | Pruebas | Aprobadas | Flujos cubiertos |
|---|---|---|---|
| 12 | 159 | 159 | 152/152 (100%) |

El log de CI de cada job solo reporta la línea `All tests passed.`; no lista las pruebas individuales. Por ello, todas las pruebas de cada archivo se consideran aprobadas según esa línea.

## Resultado por archivo

| Archivo | Pruebas | Job | Resultado | Duración |
|---|---|---|---|---|
| `acceso_test.dart` | 23 | E2E (acceso) | success | 3 min 28 s |
| `analitica_calificaciones_test.dart` | 2 | E2E (analitica_calificaciones) | success | 1 min 28 s |
| `calificar_intercambio_test.dart` | 5 | E2E (calificar_intercambio) | success | 2 min 06 s |
| `contraofertas_test.dart` | 16 | E2E (contraofertas) | success | 4 min 29 s |
| `coordinar_entrega_test.dart` | 5 | E2E (coordinar_entrega) | success | 2 min 36 s |
| `feed_test.dart` | 20 | E2E (feed) | success | 3 min 55 s |
| `intercambio_acordado_test.dart` | 8 | E2E (intercambio_acordado) | success | 2 min 36 s |
| `intercambios_historial_test.dart` | 15 | E2E (intercambios_historial) | success | 3 min 05 s |
| `ofertas_test.dart` | 19 | E2E (ofertas) | success | 4 min 00 s |
| `publicaciones_test.dart` | 31 | E2E (publicaciones) | success | 4 min 20 s |
| `salida_honesta_test.dart` | 11 | E2E (salida_honesta) | success | 2 min 47 s |
| `whatsapp_test.dart` | 4 | E2E (whatsapp) | success | 1 min 48 s |

## Pruebas por archivo

### `acceso_test.dart`

Job: E2E (acceso) | Resultado: success | Duración: 3 min 28 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929871)

1. Un visitante ve la pantalla de inicio con sus dos opciones
2. Un visitante intenta abrir su perfil y lo mandan a iniciar sesión
3. Eudenia inicia sesión y ve su perfil
4. Eudenia escribe mal su contraseña y ve el error
5. Eudenia deja los campos vacíos y la app le pide los datos
6. Eudenia cierra sesión desde su perfil
7. Ana crea su cuenta y entra a su perfil
8. Ana escribe contraseñas distintas y la app se lo avisa
9. Ana usa un teléfono de menos de 8 dígitos y la app lo rechaza
10. Ana escribe un correo inválido y la app se lo avisa
11. Ana escribe un nombre de una sola letra y la app se lo avisa
12. El servidor rechaza un correo inválido y un nombre corto al crear la cuenta
13. Ana intenta crear su cuenta con el correo de Eudenia y ve el error
14. Eudenia pide una contraseña nueva y la app le avisa que revise su correo
15. Eudenia pide una contraseña nueva, la recibe y entra con ella
16. Ana pide recuperar un correo que no existe y ve el error
17. Eudenia vuelve a iniciar sesión desde la pantalla de recuperar
18. Eudenia cambia su contraseña y entra con la nueva
19. Eudenia se equivoca con su contraseña actual y ve el error
20. Eudenia usa una contraseña nueva muy corta y la app se lo avisa
21. Eudenia se arrepiente y cancela el cambio de contraseña
22. Eudenia con sesión iniciada no vuelve a ver iniciar sesión ni crear cuenta
23. Eudenia recarga la app y conserva su sesión

### `analitica_calificaciones_test.dart`

Job: E2E (analitica_calificaciones) | Resultado: success | Duración: 1 min 28 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929897)

1. Calificar registra calificacion_iniciada y calificacion_enviada
2. Cerrar el diálogo sin enviar solo registra calificacion_iniciada

### `calificar_intercambio_test.dart`

Job: E2E (calificar_intercambio) | Resultado: success | Duración: 2 min 06 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929798)

1. Ambas partes califican con estrellas y el perfil muestra el promedio y la cantidad
2. El perfil promedia todas las calificaciones que recibe
3. Cada parte califica una sola vez y la segunda calificación se rechaza
4. Un intercambio cancelado o sin completar no se califica
5. Solo las dos partes califican y el puntaje es de 1 a 5

### `contraofertas_test.dart`

Job: E2E (contraofertas) | Resultado: success | Duración: 4 min 29 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929411)

1. Eudenia responde la oferta de Carlos con una contraoferta
2. Eudenia solo ve los objetos disponibles de Carlos al contraofertar
3. Eudenia cierra el cuadro de contraoferta sin enviar nada
4. Carlos recibe la contraoferta de Eudenia y puede responderla
5. Carlos ve el historial de la negociacion con Eudenia
6. Eudenia también ve el historial desde sus ofertas enviadas
7. Job no puede ver la negociacion entre Eudenia y Carlos
8. Carlos acepta la contraoferta y la negociacion se cierra
9. Carlos rechaza la contraoferta de Eudenia
10. Eudenia no puede aceptar su propia contraoferta
11. Nadie puede contraofertar una negociacion cerrada
12. Nadie puede contraofertar una negociacion ya aceptada
13. Job no puede contraofertar la negociacion de Eudenia y Carlos
14. Eudenia y Carlos negocian tres rondas
15. Carlos cancela su contraoferta
16. Carlos no puede reusar un objeto que ya está en otra oferta pendiente

### `coordinar_entrega_test.dart`

Job: E2E (coordinar_entrega) | Resultado: success | Duración: 2 min 36 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929829)

1. propuesta, contrapropuesta, aceptación y una reprogramación aceptada
2. Solo las dos partes participan y nadie responde su propia propuesta
3. Solo hay una propuesta pendiente y el acuerdo vigente no cambia hasta aceptar
4. No se coordina antes de aceptar la oferta ni después de terminar el intercambio
5. Datos incompletos o una fecha pasada no se envían

### `feed_test.dart`

Job: E2E (feed) | Resultado: success | Duración: 3 min 55 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929760)

1. Eudenia abre el feed y ve las publicaciones recientes
2. Eudenia vuelve al perfil desde el feed
3. Eudenia lee la ayuda del feed y la cierra
4. Eudenia busca "Fisica" y solo ve el libro de Job
5. Eudenia busca algo que no existe y quita el filtro
6. Eudenia filtra por la categoría Ropa
7. Eudenia filtra por la condición Nuevo
8. Eudenia filtra por disponibilidad Intercambiado y ve los audífonos de Job
9. Eudenia combina dos filtros y luego los quita todos
10. Eudenia reserva el libro de Física de Job
11. Eudenia reserva el libro de Física y después cancela su reserva
12. Eudenia piensa cancelar su reserva pero decide mantenerla
13. Eudenia reserva el libro de Física y completa el intercambio desde el feed
14. Job intenta reservar el libro de Cálculo pero tiene una oferta pendiente
15. Job ve que ya reservó la calculadora de Eudenia
16. Carlos ve la calculadora reservada por otra persona sin poder reservarla
17. Eudenia ve su propia publicación y salta a Mis publicaciones
18. Carlos no puede cancelar la reserva que hizo Job
19. Eudenia no puede reservar los audífonos que ya fueron intercambiados
20. Job no puede reservar una publicación que su dueña marcó como no disponible

### `intercambio_acordado_test.dart`

Job: E2E (intercambio_acordado) | Resultado: success | Duración: 2 min 36 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929821)

1. Eudenia confirma primero y el intercambio todavía no se completa
2. Carlos confirma después y el intercambio queda completado
3. Eudenia cancela con motivo y su libro vuelve a estar disponible
4. Cancelar no reactiva las ofertas anteriores y conserva el historial
5. Cancelar sin escribir el motivo no deja enviar
6. Solo participan las dos partes y cada una confirma una vez
7. Cancelar exige motivo y después ya no se puede confirmar
8. Una publicación acordada no se reserva ni se edita

### `intercambios_historial_test.dart`

Job: E2E (intercambios_historial) | Resultado: success | Duración: 3 min 05 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929894)

1. Job ve que entregó sus audífonos a Carlos
2. Carlos ve que recibió los audífonos de Job
3. Eudenia todavía no completó ningún intercambio
4. Eudenia acepta la oferta de Carlos, los dos confirman y ve el intercambio completado
5. Job vuelve al perfil desde sus intercambios
6. Job ve sus tres movimientos de ejemplo
7. Eudenia ve que Job reservó su calculadora
8. Job filtra su historial por reservas
9. Job filtra su historial por completados
10. Job abre el detalle de un movimiento y lo cierra
11. Ana todavía no tiene movimientos en su historial
12. Eudenia reserva el libro de Física y lo ve en su historial
13. Eudenia cancela su reserva y el historial lo registra
14. Eudenia vuelve al perfil desde su historial
15. Job pide un tipo de historial que no existe y el servidor lo rechaza

### `ofertas_test.dart`

Job: E2E (ofertas) | Resultado: success | Duración: 4 min 00 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929847)

1. Job envía una oferta por la chompa de Eudenia con su libro de Física
2. Job ve su oferta en la lista de enviadas
3. Eudenia recibe la oferta que Job le envió por su chompa
4. Job se arrepiente y cierra el cuadro de oferta sin enviar nada
5. Job no puede enviar la oferta hasta elegir uno de sus objetos
6. Job usa el mismo libro en dos ofertas y la app le avisa
7. Ana no tiene objetos para ofrecer y la app le propone crear uno
8. Eudenia ve la oferta de Carlos por su libro de Cálculo
9. Eudenia acepta la oferta de Carlos
10. Eudenia rechaza la oferta de Carlos
11. Eudenia piensa en la oferta de Carlos y decide no responder todavía
12. Job no recibió ofertas y la app le sugiere explorar publicaciones
13. Job ve cancelada su oferta cuando Eudenia acepta la de Carlos
14. Carlos ve la oferta que envió a Eudenia
15. Carlos cancela la oferta que envió
16. Carlos cancela la oferta y Eudenia ya no puede aceptarla
17. Job todavía no envió ofertas y la app se lo cuenta
18. Carlos vuelve al perfil desde las ofertas
19. Job no puede ofertar por su propia publicación ni ofrecer un objeto ajeno

### `publicaciones_test.dart`

Job: E2E (publicaciones) | Resultado: success | Duración: 4 min 20 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082930009)

1. Eudenia publica un libro usado y lo ve en sus publicaciones
2. Eudenia deja el nombre vacío y la app se lo pide
3. Eudenia cancela la publicación y vuelve a sus publicaciones
4. Eudenia publica un libro con foto y el servidor la entrega
5. Eudenia elige una foto, se arrepiente y publica sin ella
6. Eudenia elige una foto que no es jpg ni png y la app se lo avisa
7. Eudenia elige una foto de más de 2 MB y la app se lo avisa
8. El servidor rechaza una foto que no es una imagen y no crea la publicación
9. Eudenia agrega una foto a su chompa al editarla y después la quita
10. Eudenia reemplaza la foto de su chompa por otra
11. Eudenia elige una foto de más de 2 MB al editar y la app se lo avisa
12. Eudenia ve sus tres publicaciones
13. Ana todavía no publicó nada y ve el mensaje de lista vacía
14. Eudenia corrige el título de su chompa
15. Eudenia cancela la edición y su chompa queda igual
16. Eudenia no puede editar la calculadora porque Job la reservó
17. Eudenia oculta su chompa
18. Eudenia marca su chompa como no disponible
19. Eudenia oculta su chompa y después la vuelve a dejar disponible
20. Eudenia no puede ocultar su libro de cálculo porque tiene una oferta pendiente
21. Eudenia no puede marcar su libro de cálculo como no disponible porque tiene una oferta pendiente
22. Eudenia puede corregir el título de su libro de cálculo aunque tenga una oferta pendiente
23. Eudenia elimina su chompa
24. Eudenia se arrepiente y no elimina su chompa
25. Eudenia no puede eliminar su libro de cálculo porque tiene una oferta pendiente
26. Eudenia completa el intercambio de su calculadora reservada
27. Eudenia sale de sus publicaciones con la barra inferior
28. Eudenia consulta una publicación por su id y el servidor responde con sus datos
29. Eudenia consulta un id inválido o inexistente y el servidor lo rechaza
30. Una publicación oculta solo la consulta su dueño
31. Carlos no ve quién reservó la calculadora de Eudenia pero ella sí

### `salida_honesta_test.dart`

Job: E2E (salida_honesta) | Resultado: success | Duración: 2 min 47 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929685)

1. Eudenia ve sus datos y al descargarlos se registra datos_descargados
2. Ana quita su teléfono desde Mis datos y la app lo confirma
3. Eudenia no tiene teléfono guardado y no ve el botón para quitarlo
4. Eudenia se equivoca de contraseña, no se borra nada y se registra el bloqueo
5. Eudenia elimina su cuenta con un trueque acordado y Carlos recibe el aviso
6. Quien eliminó su cuenta ya no puede iniciar sesión
7. La calificación de una cuenta eliminada queda y Carlos ve Usuario eliminado
8. El servidor rechaza un evento con datos personales y no los guarda
9. Los eventos de este flujo guardados no tienen claves personales
10. Carlos abre sus avisos y el aviso queda marcado como leído
11. El servidor rechaza marcar como leído un aviso ajeno o inválido

### `whatsapp_test.dart`

Job: E2E (whatsapp) | Resultado: success | Duración: 1 min 48 s | [Ver job](https://github.com/gadrilee/TruequeU_2ndP/actions/runs/44383837877/job/135082929828)

1. Ana todavía no ve el botón de WhatsApp mientras la oferta de Beto está pendiente
2. Ana acepta la oferta y escribe por WhatsApp al teléfono de Beto
3. Beto también ve el botón y escribe por WhatsApp al teléfono de Ana
4. Carlos no recibe los teléfonos de un trueque acordado entre otras dos personas
