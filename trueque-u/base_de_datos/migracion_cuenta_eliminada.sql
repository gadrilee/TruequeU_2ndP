ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS eliminado_en TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS notificaciones (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario  INTEGER     NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    mensaje     TEXT        NOT NULL,
    leida       BOOLEAN     NOT NULL DEFAULT FALSE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notificaciones_usuario_idx ON notificaciones (id_usuario, creado_en DESC);
