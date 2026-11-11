CREATE TABLE IF NOT EXISTS calificaciones (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_oferta     INTEGER     NOT NULL REFERENCES ofertas (id) ON DELETE CASCADE,
    id_usuario    INTEGER     NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    id_calificado INTEGER     NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    puntaje       SMALLINT    NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
    comentario    VARCHAR(200),
    creado_en     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT calificaciones_una_por_persona UNIQUE (id_oferta, id_usuario),
    CONSTRAINT calificaciones_a_otra_persona CHECK (id_usuario <> id_calificado)
);

CREATE INDEX IF NOT EXISTS calificaciones_calificado_idx ON calificaciones (id_calificado);
