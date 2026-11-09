CREATE TABLE IF NOT EXISTS propuestas_entrega (
    id                    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_oferta             INTEGER      NOT NULL REFERENCES ofertas (id) ON DELETE CASCADE,
    id_usuario            INTEGER      NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    fecha                 DATE         NOT NULL,
    hora                  TIME         NOT NULL,
    lugar                 VARCHAR(120) NOT NULL,
    estado                VARCHAR(15)  NOT NULL DEFAULT 'pendiente'
                          CHECK (estado IN ('pendiente', 'aceptada', 'contrapuesta', 'reemplazada')),
    id_propuesta_anterior INTEGER      REFERENCES propuestas_entrega (id) ON DELETE SET NULL,
    creado_en             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS propuestas_entrega_oferta_idx ON propuestas_entrega (id_oferta);
CREATE UNIQUE INDEX IF NOT EXISTS propuestas_entrega_pendiente_idx
    ON propuestas_entrega (id_oferta)
    WHERE estado = 'pendiente';
CREATE UNIQUE INDEX IF NOT EXISTS propuestas_entrega_vigente_idx
    ON propuestas_entrega (id_oferta)
    WHERE estado = 'aceptada';
