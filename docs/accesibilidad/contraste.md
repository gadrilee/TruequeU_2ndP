# Contraste WCAG 2.x AA de la paleta TemaTruequeU

Generado con `flutter test tool/contraste_tabla_test.dart` a partir de `test/ayudantes/pares_contraste.dart`, el mismo listado que verifica `test/contraste_aa_test.dart`.

Criterios: texto normal 4.5:1 (1.4.3), texto grande 3:1 (1.4.3) y elementos de interfaz o bordes de controles 3:1 (1.4.11). La razón es (L1+0.05)/(L2+0.05) con la luminancia relativa de WCAG.

| Par (primer plano / fondo) | Colores | Dónde se usa | Tipo | Mínimo | Antes | Después | Resultado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| texto / fondo | #1C1917 sobre #FAF7F2 | Cuerpo de las pantallas | Texto | 4.5:1 | 16.37:1 | 16.37:1 | Cumple |
| texto / blanco | #1C1917 sobre #FFFFFF | Texto en tarjetas y campos | Texto | 4.5:1 | 17.49:1 | 17.49:1 | Cumple |
| textoSuave / fondo | #57534E sobre #FAF7F2 | Textos secundarios y etiquetas de campo | Texto | 4.5:1 | 7.14:1 | 7.14:1 | Cumple |
| textoSuave / blanco | #57534E sobre #FFFFFF | Descripciones en tarjetas y ayuda de campos | Texto | 4.5:1 | 7.63:1 | 7.63:1 | Cumple |
| textoSuave / superficieAlta | #57534E sobre #F1ECE5 | Chip "No disponible" y oferta cancelada | Texto | 4.5:1 | 6.49:1 | 6.49:1 | Cumple |
| textoSuave / azulClaro | #57534E sobre #DDE3F2 | Texto secundario sobre azul claro | Texto | 4.5:1 | 5.94:1 | 5.94:1 | Cumple |
| contorno / blanco | #78716C sobre #FFFFFF | Autor y pie de la tarjeta del feed | Texto | 4.5:1 | 4.80:1 | 4.80:1 | Cumple |
| blanco / azul | #FFFFFF sobre #2A3964 | Botón principal y chip "Intercambio acordado" | Texto | 4.5:1 | 11.24:1 | 11.24:1 | Cumple |
| blanco / rojo | #FFFFFF sobre #CC100C | Botón "Crear cuenta", botón flotante y rechazar | Texto | 4.5:1 | 5.76:1 | 5.76:1 | Cumple |
| blanco / azulOscuro | #FFFFFF sobre #1B2645 | Título del encabezado y texto del aviso emergente | Texto | 4.5:1 | 14.90:1 | 14.90:1 | Cumple |
| azulClaro / azulOscuro | #DDE3F2 sobre #1B2645 | Acción del aviso emergente y parte alta del encabezado | Texto | 4.5:1 | 11.59:1 | 11.59:1 | Cumple |
| azulClaro / azul | #DDE3F2 sobre #2A3964 | Subtítulo en la parte baja del encabezado | Texto | 4.5:1 | 8.75:1 | 8.75:1 | Cumple |
| azul / fondo | #2A3964 sobre #FAF7F2 | Botones de texto, enlaces y barra superior | Texto | 4.5:1 | 10.52:1 | 10.52:1 | Cumple |
| azul / blanco | #2A3964 sobre #FFFFFF | Botones con borde y texto resaltado en tarjetas | Texto | 4.5:1 | 11.24:1 | 11.24:1 | Cumple |
| azulOscuro / azulClaro | #1B2645 sobre #DDE3F2 | Chip "Disponible" e indicador de navegación | Texto | 4.5:1 | 11.59:1 | 11.59:1 | Cumple |
| azulOscuro / fondo | #1B2645 sobre #FAF7F2 | Título de la barra superior | Texto | 4.5:1 | 13.94:1 | 13.94:1 | Cumple |
| rojoOscuro / rojoClaro | #8F0B08 sobre #FBE3E2 | Chip "Reservado" y banner de error | Texto | 4.5:1 | 7.74:1 | 7.74:1 | Cumple |
| verdeOscuro / verdeClaro | #14532D sobre #DCF2E3 | Chip "Intercambiado" y confirmaciones | Texto | 4.5:1 | 7.75:1 | 7.75:1 | Cumple |
| rojo / fondo | #CC100C sobre #FAF7F2 | Mensaje de error de campos y "Eliminar cuenta" | Texto | 4.5:1 | 5.39:1 | 5.39:1 | Cumple |
| rojo / blanco | #CC100C sobre #FFFFFF | Error en campos blancos y acciones destructivas | Texto | 4.5:1 | 5.76:1 | 5.76:1 | Cumple |
| rojo / rojoClaro | #CC100C sobre #FBE3E2 | Texto de oferta rechazada | Texto | 4.5:1 | 4.71:1 | 4.71:1 | Cumple |
| verdeOscuro / fondo | #14532D sobre #FAF7F2 | Estados confirmados sobre el fondo | Texto | 4.5:1 | 8.53:1 | 8.53:1 | Cumple |
| contorno / blanco | #E7E5E4 a #78716C sobre #FFFFFF | Borde de campos de texto y del buscador | Interfaz | 3.0:1 | 1.26:1 | 4.80:1 | Cumple |
| contorno / blanco | #E7E5E4 a #78716C sobre #FFFFFF | Borde de botones con borde y de los filtros | Interfaz | 3.0:1 | 1.26:1 | 4.80:1 | Cumple |
| contorno / fondo | #78716C sobre #FAF7F2 | Ícono del mensaje vacío | Interfaz | 3.0:1 | 4.49:1 | 4.49:1 | Cumple |
| contorno / superficieAlta | #78716C sobre #F1ECE5 | Ícono de foto vacía | Interfaz | 3.0:1 | 4.08:1 | 4.08:1 | Cumple |
| azul / blanco | #2A3964 sobre #FFFFFF | Borde del campo enfocado | Interfaz | 3.0:1 | 11.24:1 | 11.24:1 | Cumple |
| rojo / blanco | #CC100C sobre #FFFFFF | Estrellas de calificación | Interfaz | 3.0:1 | 5.76:1 | 5.76:1 | Cumple |
| textoSuave / fondo | #57534E sobre #FAF7F2 | Íconos secundarios y flechas de listas | Interfaz | 3.0:1 | 7.14:1 | 7.14:1 | Cumple |
| azul / azulClaro | #2A3964 sobre #DDE3F2 | Íconos sobre azul claro | Interfaz | 3.0:1 | 8.75:1 | 8.75:1 | Cumple |
| blanco / azulOscuro | #FFFFFF sobre #1B2645 | Flecha "Volver" del encabezado | Interfaz | 3.0:1 | 14.90:1 | 14.90:1 | Cumple |

Pares que no cumplen después de la corrección: 0.
