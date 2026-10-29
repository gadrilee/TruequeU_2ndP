-- =====================================================================
-- Trueque U - Datos de prueba (3 usuarios, publicaciones e historial)
-- =====================================================================
-- Ejecuta este script DESPUÉS de estructura.sql.
-- Las contraseñas están cifradas con bcrypt. Para iniciar sesión usa:
--
--   eudeniaflores@gmail.com    contraseña: eude1234
--   contrerasjob123@gmail.com  contraseña: contreras123
--   carlosmamani@ejemplo.com   contraseña: carlos1234
-- =====================================================================

INSERT INTO usuarios (nombre, correo, contrasena_hash) VALUES
    ('Eudenia Flores Veizaga', 'eudeniaflores@gmail.com',   '$2a$10$piJ7wa.ts95gkfCBdb5PION9e0mudZ/26fl7OeJY8aU/QrNt0tX0m'),
    ('Job Contreras',          'contrerasjob123@gmail.com', '$2a$10$Ys9ZyCk6aPALwak5vXmt0ejiIZtD8hheK3pYR2p1TU0bQVFL8hq8u'),
    ('Carlos Mamani',          'carlosmamani@ejemplo.com',  '$2a$10$rZVy8y2CGVTRBOpkCg9/UuqiVzXQcLjRLqkjzQT1gJJGwbqlkgwrC');

-- Publicaciones de prueba
-- Usuarios: 1 = Eudenia, 2 = Job, 3 = Carlos
-- Hay de todas las categorias y de todos los estados para probar los filtros
INSERT INTO publicaciones (id_usuario, titulo, descripcion, estado, estado_publicacion, categoria, id_usuario_reserva) VALUES
    (1, 'Calculo I - Stewart',          'Libro de calculo, 7ma edicion. Tiene algunas hojas subrayadas', 'usado', 'disponible',    'libros',      NULL),
    (1, 'Calculadora Casio fx-991',     'Funciona bien, le falta la tapa',                               'usado', 'reservado',     'electronica', 2),
    (1, 'Chompa de la U talla M',       'Solo la use dos veces',                                         'nuevo', 'disponible',    'ropa',        NULL),
    (2, 'Fisica General - Serway',      'Tomo 1, en buen estado',                                        'usado', 'disponible',    'libros',      NULL),
    (2, 'Audifonos con cable',          'Marca generica, funcionan los dos lados',                       'usado', 'intercambiado', 'electronica', 3),
    (2, 'Juego de reglas y escuadras',  'Para dibujo tecnico',                                           'nuevo', 'disponible',    'otros',       NULL),
    (3, 'Mandil de laboratorio',        'Talla L, color blanco',                                         'usado', 'disponible',    'ropa',        NULL),
    (3, 'Mouse inalambrico',            'Necesita pilas AA',                                             'usado', 'disponible',    'electronica', NULL),
    (3, 'Cuadernos cuadriculados x5',   'Sin usar, los compre de mas',                                   'nuevo', 'oculto',        'otros',       NULL);

-- Historial de prueba (tiene que coincidir con las publicaciones de arriba)
-- Publicacion 2: Job reservo la calculadora de Eudenia
-- Publicacion 5: Carlos reservo los audifonos de Job y despues Job completo el intercambio
INSERT INTO historial (tipo, id_publicacion, titulo, categoria, id_usuario, id_otro_usuario, creado_en) VALUES
    ('reservo',  2, 'Calculadora Casio fx-991', 'electronica', 2, 1, NOW() - INTERVAL '2 days'),
    ('reservo',  5, 'Audifonos con cable',      'electronica', 3, 2, NOW() - INTERVAL '5 days'),
    ('completo', 5, 'Audifonos con cable',      'electronica', 2, 3, NOW() - INTERVAL '3 days');

INSERT INTO ofertas (id_publicacion_pedida, id_publicacion_ofrecida, id_usuario, estado) VALUES
    (1, 8, 3, 'pendiente');
