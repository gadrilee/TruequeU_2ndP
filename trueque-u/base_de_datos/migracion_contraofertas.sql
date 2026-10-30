ALTER TABLE ofertas
    ADD COLUMN IF NOT EXISTS id_negociacion INTEGER,
    ADD COLUMN IF NOT EXISTS id_oferta_anterior INTEGER REFERENCES ofertas (id) ON DELETE SET NULL;

UPDATE ofertas SET id_negociacion = id WHERE id_negociacion IS NULL;

ALTER TABLE ofertas DROP CONSTRAINT IF EXISTS ofertas_estado_check;
ALTER TABLE ofertas
    ADD CONSTRAINT ofertas_estado_check
    CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'cancelada', 'contraofertada'));

CREATE INDEX IF NOT EXISTS ofertas_negociacion_idx ON ofertas (id_negociacion);
