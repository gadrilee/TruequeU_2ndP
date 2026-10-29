CREATE TABLE IF NOT EXISTS ofertas (
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

CREATE INDEX IF NOT EXISTS ofertas_pedida_idx    ON ofertas (id_publicacion_pedida);
CREATE INDEX IF NOT EXISTS ofertas_ofrecida_idx  ON ofertas (id_publicacion_ofrecida);
CREATE INDEX IF NOT EXISTS ofertas_usuario_idx   ON ofertas (id_usuario);
CREATE UNIQUE INDEX IF NOT EXISTS ofertas_pendiente_ofrecida_idx
    ON ofertas (id_publicacion_ofrecida)
    WHERE estado = 'pendiente';

INSERT INTO ofertas (id_publicacion_pedida, id_publicacion_ofrecida, id_usuario, estado)
SELECT pedida.id, ofrecida.id, ofrecida.id_usuario, 'pendiente'
FROM publicaciones pedida
JOIN publicaciones ofrecida
  ON ofrecida.titulo = 'Mouse inalambrico'
 AND ofrecida.estado_publicacion = 'disponible'
WHERE pedida.titulo = 'Calculo I - Stewart'
  AND pedida.estado_publicacion = 'disponible'
  AND NOT EXISTS (
    SELECT 1 FROM ofertas o
    WHERE o.id_publicacion_pedida = pedida.id
      AND o.id_publicacion_ofrecida = ofrecida.id
      AND o.estado = 'pendiente'
  );
