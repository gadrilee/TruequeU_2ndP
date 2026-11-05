ALTER TABLE publicaciones DROP CONSTRAINT IF EXISTS publicaciones_estado_publicacion_check;
ALTER TABLE publicaciones
    ADD CONSTRAINT publicaciones_estado_publicacion_check
    CHECK (estado_publicacion IN ('oculto', 'disponible', 'reservado', 'no disponible', 'acordado', 'intercambiado'));

ALTER TABLE ofertas
    ADD COLUMN IF NOT EXISTS confirma_pedida BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS confirma_ofrecida BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS motivo_cancelacion TEXT,
    ADD COLUMN IF NOT EXISTS id_usuario_cancela INTEGER REFERENCES usuarios (id) ON DELETE SET NULL;

ALTER TABLE ofertas DROP CONSTRAINT IF EXISTS ofertas_estado_check;
ALTER TABLE ofertas
    ADD CONSTRAINT ofertas_estado_check
    CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'cancelada', 'contraofertada', 'completada', 'anulada'));
