-- =====================================================================
-- Trueque U - Estructura de la base de datos (PostgreSQL)
-- =====================================================================
-- Antes de ejecutar este script:
--   1. Crea la base:   CREATE DATABASE trueque_u;
--   2. Conéctate a ella (en pgAdmin: clic derecho en trueque_u > Query Tool).
-- Luego ejecuta este archivo completo, y después datos.sql.
-- =====================================================================

-- Si quieres empezar de cero, descomenta estas líneas:
-- DROP TABLE IF EXISTS sesiones;
-- DROP TABLE IF EXISTS usuarios;

-- Personas registradas en la aplicación.
CREATE TABLE usuarios (
    id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL,
    correo           VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash  VARCHAR(100) NOT NULL,          -- contraseña cifrada con bcrypt, nunca en texto plano
    creado_en        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    telefono         VARCHAR(10),                    -- opcional
    CONSTRAINT usuarios_correo_en_minusculas CHECK (correo = LOWER(correo))
);

-- Cada inicio de sesión (o registro) crea una fila. Cerrar sesión la marca como cerrada.
CREATE TABLE sesiones (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  INTEGER     NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    creada_en   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expira_en   TIMESTAMPTZ NOT NULL,
    cerrada_en  TIMESTAMPTZ                          -- NULL mientras la sesión siga abierta
);

CREATE INDEX sesiones_usuario_idx ON sesiones (usuario_id);

-- Objetos o materiales que publica una persona para intercambiar.
-- Relación uno a muchos: un usuario tiene muchas publicaciones y cada publicación es de un solo usuario.
CREATE TABLE publicaciones (
    id                   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario           INTEGER      NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    titulo               VARCHAR(150) NOT NULL,
    descripcion          TEXT,
    estado               VARCHAR(10)  NOT NULL CHECK (estado IN ('nuevo', 'usado')),
    estado_publicacion   VARCHAR(15)  NOT NULL DEFAULT 'disponible'
                         CHECK (estado_publicacion IN ('oculto', 'disponible', 'reservado', 'no disponible', 'intercambiado')),
    -- libros, electronica, ropa u otros (lo valida el backend)
    categoria            VARCHAR(20)  NOT NULL DEFAULT 'otros',
    -- Usuario que reservó esta publicación (NULL si no está reservada o si se descartó la reserva).
    id_usuario_reserva   INTEGER      REFERENCES usuarios (id) ON DELETE SET NULL
);

CREATE INDEX publicaciones_usuario_idx ON publicaciones (id_usuario);
CREATE INDEX publicaciones_usuario_reserva_idx ON publicaciones (id_usuario_reserva);

-- Eventos de reservas e intercambios (ver docs/historial-issues.md).
-- Título y categoría se copian para que el evento sobreviva si se elimina la publicación.
CREATE TABLE historial (
    id               SERIAL PRIMARY KEY,
    tipo             VARCHAR(20)  NOT NULL
                     CHECK (tipo IN ('reservo', 'cancelo_reserva', 'completo')),
    id_publicacion   INTEGER      REFERENCES publicaciones (id) ON DELETE SET NULL,
    titulo           VARCHAR(150) NOT NULL,
    categoria        VARCHAR(20)  NOT NULL,
    id_usuario       INTEGER      NOT NULL REFERENCES usuarios (id),  -- quien hizo la acción
    id_otro_usuario  INTEGER      NOT NULL REFERENCES usuarios (id),  -- la otra persona
    creado_en        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX historial_usuario_idx ON historial (id_usuario, creado_en DESC);
CREATE INDEX historial_otro_idx    ON historial (id_otro_usuario, creado_en DESC);

CREATE TABLE ofertas (
    id                      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_publicacion_pedida   INTEGER     NOT NULL REFERENCES publicaciones (id) ON DELETE CASCADE,
    id_publicacion_ofrecida INTEGER     NOT NULL REFERENCES publicaciones (id) ON DELETE CASCADE,
    id_usuario              INTEGER     NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    estado                  VARCHAR(15) NOT NULL DEFAULT 'pendiente'
                            CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'cancelada')),
    creado_en               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ofertas_publicaciones_distintas
        CHECK (id_publicacion_pedida <> id_publicacion_ofrecida)
);

CREATE INDEX ofertas_pedida_idx    ON ofertas (id_publicacion_pedida);
CREATE INDEX ofertas_ofrecida_idx  ON ofertas (id_publicacion_ofrecida);
CREATE INDEX ofertas_usuario_idx   ON ofertas (id_usuario);
CREATE UNIQUE INDEX ofertas_pendiente_ofrecida_idx
    ON ofertas (id_publicacion_ofrecida)
    WHERE estado = 'pendiente';

